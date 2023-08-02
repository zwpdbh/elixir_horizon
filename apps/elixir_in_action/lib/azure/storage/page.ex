defmodule Azure.Storage.Page do
  require Logger

  @page_blob "page01"

  alias Azure.Storage.Common
  alias Azure.AuthAgent
  alias Http.RestClient
  alias Azure.Storage.Blob

  # To grand permission: in a Storage Account IAM:
  # 1. Assign Storage Account Contributor role
  # 2. Assign Storage Blob Data Contributor role
  # Last, Require access_token using storage_scope
  # Notice, put page could NOT be used to create page blob.
  # It can only operation on an existing page blob.
  defp put_page(%{
         storage_account: storage_account,
         container: container,
         page_blob: page_blob
       }) do
    request_url = "https://#{storage_account}.blob.core.windows.net/#{container}/#{page_blob}"
    query_options = RestClient.add_query("comp", "page")
    auth_token = AuthAgent.get_auth_token(AuthAgent.azure_storage())

    # The length of body need to match with the range we specified in x-ms-range.
    # In range, it is 0-511, so the length of body should be 512.
    body = Common.generate_bytes_with_size(512)
    content_length = body |> byte_size()

    current_time_str = Common.time_str_from_gmt()

    headers =
      RestClient.add_header("Content-type", "application/json")
      |> RestClient.add_header("accept", "text/plain")
      |> RestClient.add_header("Authorization", "Bearer #{auth_token.access_token}")
      |> RestClient.add_header("x-ms-date", "#{current_time_str}")
      |> RestClient.add_header("x-ms-version", "2020-04-08")
      |> RestClient.add_header("x-ms-range", "bytes=0-#{content_length - 1}")
      |> RestClient.add_header("Content-Length", content_length)
      |> RestClient.add_header("x-ms-page-write", "Update")

    RestClient.put_request(request_url, body, query_options, headers)
  end

  def put_page_to_nsp_source() do
    put_page(%{
      storage_account: Common.nsp_source(),
      container: Common.container(),
      page_blob: @page_blob
    })
  end

  def put_page_to_nsp_dst() do
    put_page(%{
      storage_account: Common.nsp_dst(),
      container: Common.container(),
      page_blob: @page_blob
    })
  end

  # To call put_page_from_url, we need two page blob: one for source, another is for dest.
  # To create page blob with content, we need to call: put_blob (create page_blob) + put_page (write content into it).
  def put_page_from_url() do
    sas_token =
      "sp=r&st=2023-07-20T09:00:07Z&se=2023-08-04T17:00:07Z&spr=https&sv=2022-11-02&sr=b&sig=PEMU7D7hLmIXHrYjQptUeNVT3Zj48hwTTiyyEBOy60k%3D"

    source_page_blob_url =
      "https://#{Common.nsp_source()}.blob.core.windows.net/#{Common.container()}/#{@page_blob}" <>
        "?" <> sas_token

    request_url =
      "https://#{Common.nsp_dst()}.blob.core.windows.net/#{Common.container()}/#{@page_blob}"

    query_options = RestClient.add_query("comp", "page")
    auth_token = AuthAgent.get_auth_token(AuthAgent.azure_storage())

    headers =
      RestClient.add_header("Content-type", "application/json")
      |> RestClient.add_header("Authorization", "Bearer #{auth_token.access_token}")
      |> RestClient.add_header("x-ms-date", "#{Common.time_str_from_gmt()}")
      |> RestClient.add_header("x-ms-version", "2020-04-08")
      |> RestClient.add_header("x-ms-range", "bytes=0-511")
      |> RestClient.add_header("Content-Length", 0)
      |> RestClient.add_header("x-ms-copy-source", source_page_blob_url)
      |> RestClient.add_header("x-ms-source-range", "bytes=0-511")
      # This parameter is not listed in the document of "PutPageFromUrl", but it is listed in "PutPage" API !
      |> RestClient.add_header("x-ms-page-write", "Update")

    RestClient.put_request(request_url, %{}, query_options, headers)
  end

  # See: https://learn.microsoft.com/en-us/rest/api/storageservices/put-page?tabs=azure-ad#remarks
  # Basically, we ned to use put blob to create a page blob.
  def create_page_blob_in_nsp_source do
    Blob.put_blob(%{
      storage_account: Common.nsp_source(),
      container: Common.container(),
      blob: @page_blob,
      page_size: 1024,
      blob_type: "PageBlob"
    })
  end

  def create_page_blob_in_nsp_dst do
    Blob.put_blob(%{
      storage_account: Common.nsp_dst(),
      container: Common.container(),
      blob: @page_blob,
      page_size: 1024,
      blob_type: "PageBlob"
    })
  end

  def test_put_page_from_url_workflow do
    create_page_blob_in_nsp_source()
    put_page_to_nsp_source()
    create_page_blob_in_nsp_dst()
    # This is optional
    put_page_to_nsp_dst()
    put_page_from_url()
  end
end
