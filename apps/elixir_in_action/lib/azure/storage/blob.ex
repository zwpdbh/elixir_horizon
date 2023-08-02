defmodule Azure.Storage.Blob do
  alias Azure.Storage.Common
  alias Azure.AuthAgent
  alias Http.RestClient

  def put_blob(%{
        storage_account: storage_account,
        container: container,
        blob: blob,
        blob_type: "AppendBlob"
      }) do
    request_url = "https://#{storage_account}.blob.core.windows.net/#{container}/#{blob}"

    auth_token = AuthAgent.get_auth_token(AuthAgent.azure_storage())

    headers =
      RestClient.add_header("Content-type", "text/plain; charset=UTF-8")
      |> RestClient.add_header("Authorization", "Bearer #{auth_token.access_token}")
      |> RestClient.add_header("x-ms-date", "#{Common.time_str_from_gmt()}")
      |> RestClient.add_header("x-ms-version", "2020-04-08")
      |> RestClient.add_header("Content-Length", 0)
      |> RestClient.add_header("x-ms-blob-type", "AppendBlob")

    RestClient.put_request(request_url, nil, nil, headers)
  end

  def put_blob(%{
        storage_account: storage_account,
        container: container,
        blob: blob,
        blob_type: "PageBlob",
        page_size: page_size
      }) do
    request_url = "https://#{storage_account}.blob.core.windows.net/#{container}/#{blob}"

    auth_token = AuthAgent.get_auth_token(AuthAgent.azure_storage())

    headers =
      RestClient.add_header("Content-type", "text/plain; charset=UTF-8")
      |> RestClient.add_header("Authorization", "Bearer #{auth_token.access_token}")
      |> RestClient.add_header("x-ms-date", "#{Common.time_str_from_gmt()}")
      |> RestClient.add_header("x-ms-version", "2020-04-08")
      |> RestClient.add_header("Content-Length", 0)
      |> RestClient.add_header("x-ms-blob-content-length", page_size)
      |> RestClient.add_header("x-ms-blob-type", "PageBlob")

    RestClient.put_request(request_url, nil, nil, headers)
  end
end
