defmodule Azure.Storage.Common do
  alias Azure.AuthAgent
  alias Http.RestClient

  require Logger

  @subscription_id "65490f91-f2c2-4514-80ba-4ec1de89aeda"
  def subscription_id do
    @subscription_id
  end

  @resource_group "zhaowei"
  def resource_group do
    @resource_group
  end

  @region "eastus"
  def region do
    @region
  end

  @container "container01"
  def container do
    @container
  end

  @api_version "2022-12-01"
  def api_version do
    @api_version
  end

  @nsp_source "nspsource"
  def nsp_source do
    @nsp_source
  end

  @nsp_dst "nspdst"
  def nsp_dst do
    @nsp_dst
  end

  # Currently my SP don't have permission to do so.
  def create_resource_group() do
    request_url =
      "https://management.azure.com/subscriptions/#{@subscription_id}/resourcegroups/#{@resource_group}"

    auth_token = AuthAgent.get_auth_token(AuthAgent.azure_storage())
    query_options = RestClient.add_query("api-version", @api_version)
    request_body = RestClient.add_body("location", @region)

    headers =
      RestClient.add_header("Content-type", "application/json")
      |> RestClient.add_header("accept", "text/plain")
      |> RestClient.add_header("Authorization", "Bearer #{auth_token.access_token}")

    RestClient.put_request(request_url, request_body, query_options, headers)
  end

  # Currently my SP don't have permission to do so.
  def create_storage_account(storage_account) do
    request_url =
      "https://management.azure.com/subscriptions/#{@subscription_id}/resourceGroups/#{@resource_group}/providers/Microsoft.Storage/storageAccounts/#{storage_account}?api-version=2018-02-01"

    auth_token = AuthAgent.get_auth_token(AuthAgent.azure_storage())
    query_options = RestClient.add_query("api-version", @api_version)

    headers =
      RestClient.add_header("Content-type", "application/json")
      |> RestClient.add_header("accept", "text/plain")
      |> RestClient.add_header("Authorization", "Bearer #{auth_token.access_token}")

    request_body = %{
      "sku" => %{"name" => "Standard_GRS"},
      "kind" => "StorageV2",
      "location" => @region
    }

    RestClient.put_request(request_url, request_body, query_options, headers)
  end

  def generate_bytes_with_size(n) do
    result = for _ <- 0..(n - 1), do: 1
    result |> Enum.join("")
  end

  def time_str_from_gmt() do
    DateTime.now!("GMT")
    |> Calendar.strftime("%a, %d %b %Y %H:%M:%S %Z")
  end
end
