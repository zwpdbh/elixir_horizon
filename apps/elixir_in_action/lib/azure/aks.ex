defmodule Azure.Aks do
  @moduledoc """
  This is used to manage aks workflows from xscnworkflow console service
  """
  use GenServer
  alias How.Snippets.ConvertTime
  alias Azure.AuthAgent
  alias Http.RestClient
  alias Azure.Aks.TaskSupervisor
  alias Azure.AuthAgent.AuthToken

  require Logger

  @uri "https://xscnworkflowconsole.eastus.cloudapp.azure.com"

  defp get_aks_cluster_name_from_k8s_config(config) do
    %{"name" => cluster_name} = Regex.named_captures(~r/name: (?<name>[a-zA-z0-9-]*)/, config)
    cluster_name
  end

  defp get_auth_token() do
    AuthAgent.get_auth_token(AuthAgent.xscnworkflow_scope())
  end

  @impl true
  def init(_arg) do
    {:ok, %{workflows: []}}
  end

  @impl true
  def handle_call({:update_latest_workflows, count}, _from, %{} = state) do
    with {:ok, workflows} <- list_workflows_aux(count) do
      {:reply, workflows, Map.put(state, :workflows, workflows)}
    else
      {:err, err} ->
        {:reply, err, state}
    end
  end

  # @impl true
  # def handle_call({:list_workflows, count}, _from, %{workflows: []} = state) do
  #   {:ok, workflows} = list_workflows_aux(count)
  #   {:reply, workflows, Map.put(state, :workflows, workflows)}
  # end

  @impl true
  def handle_call({:list_workflows, count}, _from, %{workflows: workflows} = state) do
    if length(workflows) == count do
      {:reply, workflows, state}
    else
      with {:ok, workflows} <- list_workflows_aux(count) do
        {:reply, workflows, Map.put(state, :workflows, workflows)}
      else
        {:err, err} ->
          {:reply, err, state}
      end
    end
  end

  # It fetch {count} records and filter out only k8s related
  defp list_workflows_aux(count) do
    auth_token = get_auth_token()
    query_options = RestClient.add_query("count", count)

    headers =
      RestClient.add_header("Content-type", "application/json")
      |> RestClient.add_header("accept", "text/plain")
      |> RestClient.add_header("Authorization", "Bearer #{auth_token.access_token}")

    response = RestClient.get_request(@uri <> "/api/Workflow", query_options, headers)

    case response do
      {:ok, %HTTPoison.Response{body: body_str}} ->
        {:ok, Jason.decode!(body_str)}

      err ->
        err |> IO.inspect(label: "#{__MODULE__} 64")
        {:err, err}
    end
  end

  # Client API
  def start_link([]) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  # It fetch {count} records and filter_k8s_related workflows which status is not complete.
  # Then, it update the state.
  # To check k8s related workflows use other commands
  def update_latest_workflows(count) do
    GenServer.call(__MODULE__, {:update_latest_workflows, count}, 60_000)
  end

  def list_workflows(count \\ 100) do
    GenServer.call(__MODULE__, {:list_workflows, count}, 60_000)
  end

  def list_aks_workflows() do
    list_workflows()
    |> filter_k8s_related()
    |> process_aks_workflows_data
  end

  def list_aks_failed_workflows() do
    list_aks_workflows()
    |> Enum.filter(fn %{status: status} ->
      status
      |> String.downcase()
      |> String.contains?("complete")
      |> Kernel.not()
    end)
  end

  defp filter_k8s_related(workflows) do
    workflows
    |> Enum.filter(fn each ->
      Map.get(each, "definitionName")
      |> String.downcase()
      |> String.contains?("k8s")
    end)
  end

  defp process_aks_workflows_data(workflows) do
    workflows
    |> Enum.map(fn
      %{
        "data" => data_str,
        "definitionName" => definition_name,
        "definitionVersion" => definition_version,
        "status" => status,
        "id" => id,
        "createTime" => create_time,
        "completeTime" => complete_time
        # "executionPointers" => steps_str
      } = _each ->
        %{
          "DeploymentName" => deployment_name,
          "K8sConfig" => k8s_config
        } = data_json = data_str |> Jason.decode!()

        %{
          id: id,
          definition_name: definition_name,
          deployment_name: deployment_name,
          subscription_id: Map.get(data_json, "SubscriptionId", nil),
          k8s_config: k8s_config,
          deployment_region: Map.get(data_json, "DeploymentLocation", nil),
          definition_version: definition_version,
          status: status,
          create_time:
            create_time |> How.Snippets.ConvertTime.get_datetime_in_shanghai_from_str(),
          complete_time:
            complete_time |> How.Snippets.ConvertTime.get_datetime_in_shanghai_from_str(),
          cluster: k8s_config |> get_aks_cluster_name_from_k8s_config
          # steps: Jason.decode!(steps_str)
        }
    end)
  end

  defp get_aks_config_from_workflow_id(id) do
    workflow_detail = get_workflow_from_id(id)

    Logger.info("get k8s config for cluster: #{workflow_detail.cluster}")
    workflow_detail |> Map.fetch!(:k8s_config)
  end

  def list_aks_workflows_after() do
    list_aks_workflows() |> summary_workflows() |> filter_workflows_after_date()
  end

  def list_aks_workflows_after(date_str) do
    list_aks_workflows() |> summary_workflows() |> filter_workflows_after_date(date_str)
  end

  def filter_workflows_after_date(workflows) do
    filter_workflows_from_time(
      workflows,
      ConvertTime.get_yesterday_native_time()
      |> ConvertTime.build_datetime_with_timezone("Asia/Shanghai")
    )
  end

  def filter_workflows_after_date(workflows, date_str) do
    filter_workflows_from_time(
      workflows,
      ConvertTime.build_native_time_from_date(date_str)
      |> ConvertTime.build_datetime_with_timezone("Asia/Shanghai")
    )
  end

  defp filter_workflows_from_time(workflows, datetime) do
    workflows
    |> Enum.filter(fn %{create_time: create_time} ->
      case DateTime.compare(create_time, datetime) do
        :gt -> :gt
        _ -> nil
      end
    end)
  end

  def summary_workflows(workflows) do
    workflows
    |> Enum.map(fn each -> Map.drop(each, [:k8s_config, :complete_time, :deployment_region]) end)
  end

  def overwrite_default_k8s_config(id) do
    k8s_config = get_aks_config_from_workflow_id(id)

    File.write("/home/zw/.kube/config", k8s_config)
  end

  def terminate_workflow(workflow_id) do
    auth_token = get_auth_token()
    url = @uri <> "/api/Workflow/#{workflow_id}/terminate"

    headers =
      RestClient.add_header("Content-type", "application/json")
      |> RestClient.add_header("accept", "text/plain")
      |> RestClient.add_header("Authorization", "Bearer #{auth_token.access_token}")

    {:ok, %HTTPoison.Response{body: body, status_code: 200}} =
      RestClient.put_request(url, nil, nil, headers)

    Logger.info("terminate_workflow result: #{body}")

    workflow_id
  end

  defp get_workflow_data_from_id(workflow_id) do
    auth_token = get_auth_token()
    url = @uri <> "/api/Workflow/#{workflow_id}"

    headers =
      RestClient.add_header("Content-type", "application/json")
      |> RestClient.add_header("accept", "text/plain")
      |> RestClient.add_header("Authorization", "Bearer #{auth_token.access_token}")

    response = RestClient.get_request(url, nil, headers)

    case response do
      {:ok, %HTTPoison.Response{body: body_str}} ->
        {:ok, Jason.decode!(body_str)}

      err ->
        err |> IO.inspect(label: "#{__MODULE__} 64")
        {:err, err}
    end
  end

  def get_workflow_from_id(workflow_id) do
    {:ok, workflow} = get_workflow_data_from_id(workflow_id)

    [workflow]
    |> process_aks_workflows_data
    |> List.first()
  end

  def cleanup_all_failed_workflows() do
    # From: https://hexdocs.pm/elixir/Task.html#async_stream/3-example
    # I use this: https://hexdocs.pm/elixir/Task.Supervisor.html#async_stream/4
    # For supervisor and task, see this example: https://hexdocs.pm/elixir/Task.html#await/2-compatibility-with-otp-behaviours
    Task.Supervisor.async_stream_nolink(
      TaskSupervisor,
      list_aks_failed_workflows(),
      &cleanup_aks_workflow/1,
      max_concurrency: 1,
      timeout: 5_000,
      on_timeout: :kill_task,
      zip_input_on_exit: true
    )
    |> Enum.reduce(%{}, fn result, acc ->
      case result do
        {:ok, {:ok, workflow_id}} ->
          Map.update(acc, :succeed, [workflow_id], fn existing_ones ->
            [workflow_id | existing_ones]
          end)

        {:ok, {:error, %{id: workflow_id}}} ->
          Map.update(acc, :failed, [workflow_id], fn existing_ones ->
            [workflow_id | existing_ones]
          end)

        {:exit, reason} ->
          handle_unexpected_task_result(acc, reason)

        unknown ->
          handle_unexpected_task_result(acc, unknown)
      end
    end)
  end

  defp handle_unexpected_task_result(acc, reason) do
    case reason do
      {%{id: id}, :timeout} ->
        Map.update(acc, :exception, [{:timeout, id}], fn existing_ones ->
          [{:timeout, id} | existing_ones]
        end)

      unknown ->
        # IO.inspect(unknown, label: "#{__MODULE__}")
        Map.update(acc, :exception, [unknown], fn existing_ones -> [unknown | existing_ones] end)
    end
  end

  def cleanup_aks_workflow(%{id: workflow_id}) do
    try do
      Logger.warning("cleanup aks workflow: #{workflow_id}")

      workflow_id
      |> terminate_workflow()
      |> clean_up_pod_from_workflow_id()
      |> clean_up_pvc_from_workflow_id()
      |> clean_up_pv_from_workflow_id()

      {:ok, workflow_id}
    rescue
      err ->
        {:error, %{msg: err, id: workflow_id}}
    end
  end

  def clean_up_pod_from_workflow_id(workflow_id) do
    workflow_id
    |> run_kubectl_cmd_for_id("kubectl delete --all pods")

    workflow_id
  end

  def clean_up_pvc_from_workflow_id(workflow_id) do
    workflow_id
    |> run_kubectl_cmd_for_id("kubectl delete --all pvc")

    workflow_id
  end

  def clean_up_pv_from_workflow_id(workflow_id) do
    workflow_id
    |> run_kubectl_cmd_for_id("kubectl delete --all pv")

    workflow_id
  end

  def run_kubectl_cmd_for_id(id, command_str) do
    get_aks_config_from_workflow_id(id)
    |> run_kubectl_cmd(command_str)

    # id
  end

  # Suppose we need to operate multiple AKS clusters using kubectl, then we need to specify different kubeconfig for each cluster.
  defp run_kubectl_cmd(kubectl_config_data, command_str) do
    [command | arguments] = command_str |> String.split(" ") |> Enum.filter(fn x -> x != "" end)
    Logger.debug("run_kubectl_cmd: #{command_str}")

    # generate a tmp file for storing the kubectl_config_data
    tmp_config_file = Path.join(System.tmp_dir!(), UUID.uuid1())
    File.write!(tmp_config_file, kubectl_config_data)

    System.cmd(command, arguments,
      stderr_to_stdout: true,
      into: IO.stream(),
      env: [{"KUBECONFIG", tmp_config_file}]
    )
  end

  def list_aks_clusters_from_workflows(workflows) do
    workflows
    |> Enum.map(& &1.cluster)
    |> Enum.uniq()
  end

  def test_run_kubectl_cmd_for_id() do
    run_kubectl_cmd_for_id("77748486-b3ec-4468-a81b-2145276a0c6d", "kubectl get nodes")
  end

  def get_aks_config(%{subscription_id: sub_id, rg: rg_name, aks: aks_name}) do
    # Need to get the Aks configuration from created cluster
    %AuthToken{expires_at: _, access_token: access_token} =
      AuthAgent.get_auth_token(AuthAgent.azure_scope())

    headers =
      RestClient.add_header("Content-type", "application/json")
      |> RestClient.add_header("Authorization", "Bearer #{access_token}")

    query_options = RestClient.add_query("api-version", "2023-01-01")

    # POST https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ContainerService/managedClusters/{resourceName}/listClusterAdminCredential
    url =
      "https://management.azure.com/subscriptions/#{sub_id}/resourceGroups/#{rg_name}/providers/Microsoft.ContainerService/managedClusters/#{aks_name}/listClusterAdminCredential"

    {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} =
      RestClient.post_request(url, %{}, headers, query_options)

    response_body
    |> Jason.decode!()
    |> Map.get("kubeconfigs")
    |> List.first()
    |> Map.get("value")
    |> Base.decode64!()
  end

  def enable_aks_node_pool_os_auto_upgrade(aks_clusters) do
    aks_clusters
    |> Enum.map(fn aks_name ->
      {:ok, output} =
        ExecCmd.run("""
        az aks update \
          --resource-group #{aks_name} \
          --name #{aks_name} \
          --node-os-upgrade-channel NodeImage
        """)

      profile = output |> Jason.decode!()
      %{"aks" => aks_name, "autoUpgradeProfile" => Map.get(profile, "autoUpgradeProfile")}
    end)
  end

  def list_node_pools_for_aks_cluster(aks_cluster) do
    {:ok, node_pools} =
      ExecCmd.run(
        "az aks nodepool list --cluster-name #{aks_cluster} --resource-group #{aks_cluster}"
      )

    node_pools
    |> Jason.decode!()
    |> Enum.map(fn each ->
      %{
        id: Map.get(each, "id"),
        name: Map.get(each, "name"),
        nodeImageVersion: Map.get(each, "nodeImageVersion"),
        aks: aks_cluster
      }
    end)
  end

  def list_node_pools_for_aks_clusters(aks_clusters) do
    Task.async_stream(
      aks_clusters,
      fn aks -> list_node_pools_for_aks_cluster(aks) end,
      max_concurrency: 3,
      timeout: 30_000,
      on_timeout: :kill_task,
      zip_input_on_exit: true
    )
    |> Enum.reduce(%{}, fn result, acc ->
      case result do
        {:ok, pools} ->
          Map.update(acc, :ok, pools, fn existing_pools -> pools ++ existing_pools end)

        {_err, reason} ->
          Map.update(acc, :err, [reason], fn existing_ones -> [reason | existing_ones] end)
      end
    end)
  end
end
