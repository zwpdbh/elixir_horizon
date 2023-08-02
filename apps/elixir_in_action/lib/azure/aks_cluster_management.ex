defmodule Azure.AksClusterManagement do
  @moduledoc """
  This is used to manage AKS clusters in Azure
  """
  alias Azure.AuthAgent
  alias Http.RestClient
  alias Azure.AzureCli

  defp get_azure_auth_token() do
    # AuthAgent.get_auth_token(AuthAgent.azure_scope())
    AuthAgent.get_new_auth_token(AuthAgent.azure_scope())
  end

  def subscription_id_for_storage_aks() do
    "33922553-c28a-4d50-ac93-a5c682692168"
  end

  def list_agent_pools(%{rg: rg, aks: aks}) do
    auth_token = get_azure_auth_token()

    url =
      "https://management.azure.com/subscriptions/#{subscription_id_for_storage_aks()}/resourceGroups/#{rg}/providers/Microsoft.ContainerService/managedClusters/#{aks}/agentPools?api-version=2023-04-01"

    headers =
      RestClient.add_header("Content-type", "application/json")
      |> RestClient.add_header("accept", "application/json")
      |> RestClient.add_header("Authorization", "Bearer #{auth_token.access_token}")

    {:ok, %HTTPoison.Response{body: body}} = RestClient.get_request(url, nil, headers)
    %{"value" => pools} = body |> Jason.decode!()
    pools
  end

  defp resource_group_name_for_vmss(aks_cluster_rg) do
    "MC_#{aks_cluster_rg}_#{aks_cluster_rg}_eastus2euap"
  end

  def list_virtual_machine_scale_sets(rg) do
    auth_token = get_azure_auth_token()

    url =
      "https://management.azure.com/subscriptions/#{subscription_id_for_storage_aks()}/resourceGroups/#{resource_group_name_for_vmss(rg)}/providers/Microsoft.Compute/virtualMachineScaleSets?api-version=2023-03-01"

    headers =
      RestClient.add_header("Content-type", "application/json")
      |> RestClient.add_header("accept", "application/json")
      |> RestClient.add_header("Authorization", "Bearer #{auth_token.access_token}")

    {:ok, %HTTPoison.Response{body: body}} = RestClient.get_request(url, nil, headers)
    # body |> Jason.decode!()
    %{"value" => vmss} = body |> Jason.decode!()
    vmss
  end

  def list_virtual_machine_scale_sets_test() do
    list_virtual_machine_scale_sets("k8s-dynamic-r4vxst")
  end

  def get_vmss_instance_status(%{rg: rg, vmss: vmss}) do
    auth_token = get_azure_auth_token()

    url =
      "https://management.azure.com/subscriptions/#{subscription_id_for_storage_aks()}/resourceGroups/#{resource_group_name_for_vmss(rg)}/providers/Microsoft.Compute/virtualMachineScaleSets/#{vmss}/instanceView?api-version=2023-03-01"

    headers =
      RestClient.add_header("Content-type", "application/json")
      |> RestClient.add_header("accept", "application/json")
      |> RestClient.add_header("Authorization", "Bearer #{auth_token.access_token}")

    # RestClient.get_request(url, nil, headers)
    {:ok, %HTTPoison.Response{body: body}} = RestClient.get_request(url, nil, headers)
    %{"virtualMachine" => status} = body |> Jason.decode!()
    status
  end

  def get_vmss_instance_status_test() do
    get_vmss_instance_status(%{rg: "k8s-dynamic-r4vxst", vmss: "aks-linuxpool-46098243-vmss"})
  end

  def list_aks_nodes_status() do
    list_agent_pools(%{rg: "k8s-dynamic-r4vxst", aks: "k8s-dynamic-r4vxst"})
  end

  def create_windows_vm() do
    # deploy an AKS cluster by:
    # https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-cli#parameter-files
    # Use a JSON file that contains the parameter values.
    # The parameter file must be a local file:
    # --parameters '@storage.parameters.json' use @ to specify a local file named storage.parameters.json.
    template_file =
      Path.join([File.cwd!(), "apps/elixir_in_action/lib/azure/windows_vm_template.json"])

    %AuthAgent.ServicePrinciple{}
    |> AzureCli.create_cli_session()
    |> AzureCli.run_az_cli("""
    az deployment group create --resource-group zw_aks_001 --template-file #{template_file}
    """)

    # The total parameters I needed are:
    # deployment name
    # subscription id
    # resource group name
    # armTemplate parameters are:
    # aksClusterName => deployment name
    # dnsPrefix => deployment name
  end

  # def create_linux_vm() do
  #   template_file =
  #     Path.join([File.cwd!(), "apps/elixir_in_action/lib/azure/linux_vm_template.json"])

  #   :not_implemeted
  # end
end
