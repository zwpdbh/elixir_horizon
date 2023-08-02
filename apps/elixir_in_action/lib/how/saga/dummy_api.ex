defmodule How.Saga.DummyApi do
  require Logger
  @behaviour Sage.CompensationErrorHandler

  defp simulate_external_api_failure_ratio(n) do
    Process.sleep(500)

    case :rand.uniform(10) do
      x when x > n ->
        :ok

      err ->
        raise "external API error: #{err}"
    end
  end

  def create_rg(%{rg_name: rg_name, sub_id: sub_id}) do
    try do
      simulate_external_api_failure_ratio(7)
      Logger.info("create resource group: #{rg_name} in subscription: #{sub_id}")
      {:ok, rg_name}
    catch
      err ->
        {:error, "failed to create rg, err: #{err}"}
    end
  end

  def create_ask(%{rg_name: rg_name, aks: aks_name}) do
    try do
      simulate_external_api_failure_ratio(5)
      Logger.info("create aks cluster in resource group: #{rg_name}, aks_name: #{aks_name}")
      {:ok, aks_name}
    catch
      err ->
        {:error, "failed to create aks, err: #{err}"}
    end
  end

  def create_pods(%{sub_id: _sub_id, rg_name: _rg_name, aks: aks_name}) do
    try do
      simulate_external_api_failure_ratio(7)
      Logger.info("create pods in #{aks_name}")
      {:ok, "pod: #{aks_name}"}
    catch
      err ->
        {:error, "failed to create pod in #{aks_name}, err: #{err}"}
    end
  end

  def create_rg_breaker(%{rg_name: rg_name}) do
    Logger.info("===Rg Compensation callback, delete resource group, rg: #{rg_name}")
    # :abort
    {:retry, [retry_limit: 1, base_backoff: 1_000, max_backoff: 5_000, enable_jitter: true]}
  end

  def create_ask_breaker(%{rg_name: rg_name, aks: aks_name}) do
    Logger.info(
      "===Aks Compensation callback, delete aks cluster in resource group: #{rg_name}, aks_name: #{aks_name}"
    )

    # compensate could also raise exception
    # This could be handled by register Sage.with_compensation_error_handler
    simulate_external_api_failure_ratio(1)

    # :abort
    {:retry, [retry_limit: 2, base_backoff: 1_000, max_backoff: 5_000, enable_jitter: true]}
    # {:continue, nil}
  end

  def create_pods_breaker(%{sub_id: sub_id, rg_name: rg_name, aks: aks_name}) do
    Logger.info(
      "===Pod Compensation callback, delete aks cluster and retry, subscription: #{sub_id}, rg_name: #{rg_name}, aks: #{aks_name}"
    )

    # when :abort, it will apply compensation for "delete aks cluster", then "delete resource group"
    # :abort
    {:retry, [retry_limit: 3, base_backoff: 1_000, max_backoff: 5_000, enable_jitter: true]}
  end

  @impl Sage.CompensationErrorHandler
  def handle_error(error, compensations_to_run, opts) do
    IO.inspect(%{error: error, compensationstorun: compensations_to_run, opts: opts})
    {:error, "===CompensationErrorHandler"}
  end
end
