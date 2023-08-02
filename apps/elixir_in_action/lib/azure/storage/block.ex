defmodule Azure.Storage.Block do
  @moduledoc """
  This module is used to try features related with block blob, especially
  PutBlockFromUrl.

  How to create a block blob:
  1) write a set of blocks via the pub block operation
  2) commit the blocks to a blob with the PutBlockList operation.
  """
  alias Azure.Storage.Common
  alias Azure.AuthAgent
  alias Http.RestClient
  alias Azure.Storage.Blob

  @block_blob "block01"
  @blob_for_append "blob_for_append"

  # A valid Base64 string value that identifies the block. Before it's encoded, the string must be less than or equal to 64 bytes in size.
  def generate_block_id() do
    # How to determine the size of Base64 encoded string?
    # In base64, each character is represented by 6 bits (log2(64) = 6).
    # In addition, the base64 length must be %4 == 0.
    # So, 4 chars in base64 is 4 * 6 = 24 bits = 3 bytes.
    # So, we 4 * (n / 3) chars to represent n bytes and the result needed to be rounded up to a multiple of 4.

    # Here, we just use base64 encoded unix time stamp as ID since it is less or equal to 64 bytes
    DateTime.utc_now() |> DateTime.to_unix() |> to_string |> Base.url_encode64()
  end

  def create_block_blob_at_source() do
    %HTTPoison.Response{status_code: 201} =
      put_block(%{
        storage_account: Common.nsp_source(),
        container: Common.container(),
        block_blob: @block_blob
      })
      |> put_block_list()
  end

  def create_block_blob_at_dst() do
    put_block(%{
      storage_account: Common.nsp_dst(),
      container: Common.container(),
      block_blob: @block_blob
    })
    |> put_block_list()
  end

  defp put_block_list(%{
         storage_account: storage_account,
         container: container,
         block_blob: block_blob,
         block_id: block_id
       }) do
    request_url = "https://#{storage_account}.blob.core.windows.net/#{container}/#{block_blob}"

    query_options = RestClient.add_query("comp", "blocklist")
    auth_token = AuthAgent.get_auth_token(AuthAgent.azure_storage())

    headers =
      RestClient.add_header("Content-type", "text/plain; charset=UTF-8")
      |> RestClient.add_header("Authorization", "Bearer #{auth_token.access_token}")
      |> RestClient.add_header("x-ms-date", "#{Common.time_str_from_gmt()}")
      |> RestClient.add_header("x-ms-version", "2020-04-08")

    body =
      %{
        "BlockList" => %{
          "Latest" => block_id
        }
      }
      |> MapToXml.from_map()

    {:ok, %HTTPoison.Response{} = response} =
      RestClient.put_request(request_url, body, query_options, headers)

    response
    |> handle_response_from_pub_block_list
  end

  defp handle_response_from_pub_block_list(%HTTPoison.Response{status_code: 400, body: body_str}) do
    body_str
    |> XmlToMap.naive_map()
  end

  defp handle_response_from_pub_block_list(%HTTPoison.Response{status_code: 201} = response) do
    response
  end

  # For REST API:  https://learn.microsoft.com/en-us/rest/api/storageservices/put-block?tabs=azure-ad
  def put_block(
        %{storage_account: storage_account, container: container, block_blob: block_blob} =
          storage_settings
      ) do
    request_url = "https://#{storage_account}.blob.core.windows.net/#{container}/#{block_blob}"

    block_id = generate_block_id()

    query_options =
      RestClient.add_query("comp", "block")
      |> RestClient.add_query("blockid", block_id)

    auth_token = AuthAgent.get_auth_token(AuthAgent.azure_storage())
    body = Common.generate_bytes_with_size(512 * 4)
    content_length = body |> byte_size()

    headers =
      RestClient.add_header("Content-type", "application/json")
      |> RestClient.add_header("Authorization", "Bearer #{auth_token.access_token}")
      |> RestClient.add_header("x-ms-date", "#{Common.time_str_from_gmt()}")
      |> RestClient.add_header("x-ms-version", "2020-04-08")
      |> RestClient.add_header("Content-Length", content_length)

    # A successful operation returns status code 201 (Created).
    {:ok, %HTTPoison.Response{status_code: 201}} =
      RestClient.put_request(request_url, body, query_options, headers)

    Map.put(storage_settings, :block_id, block_id)
    |> Map.put(:block_content, body)
  end

  # For REST API: https://learn.microsoft.com/en-us/rest/api/storageservices/put-block-from-url?tabs=azure-ad
  defp put_block_from_url(
         %{
           storage_account: storage_account,
           container: container,
           block_blob: block_blob,
           source_blob_url: source_blob_url
         } = storage_settings
       ) do
    auth_token = AuthAgent.get_auth_token(AuthAgent.azure_storage())

    request_url = "https://#{storage_account}.blob.core.windows.net/#{container}/#{block_blob}"
    block_id = generate_block_id()

    query_options =
      RestClient.add_query("comp", "block")
      |> RestClient.add_query("blockid", block_id)

    headers =
      RestClient.add_header("Content-type", "application/json")
      |> RestClient.add_header("Authorization", "Bearer #{auth_token.access_token}")
      |> RestClient.add_header("x-ms-date", "#{Common.time_str_from_gmt()}")
      |> RestClient.add_header("x-ms-version", "2020-04-08")
      |> RestClient.add_header("Content-Length", 0)
      |> RestClient.add_header("x-ms-copy-source", source_blob_url)
      # This is optional
      |> RestClient.add_header("x-ms-source-range", "bytes=0-511")

    {:ok, %HTTPoison.Response{status_code: 201}} =
      RestClient.put_request(request_url, nil, query_options, headers)

    Map.put(storage_settings, :block_id, block_id)
  end

  def pub_block_from_source_to_dst() do
    # Currently, this will trigger 404 error
    # "Error" => %{
    #   "Code" => "CannotVerifyCopySource",
    #   "Message" => "The specified resource does not exist.\nRequestId:7c330b14-501e-00f9-218e-b86a0c000000\nTime:2023-07-17T09:07:03.3368509Z"
    # }
    # source_blob_url = "https://#{Common.nsp_source()}.blob.core.windows.net/#{Common.container()}/#{@block_blob}"

    # It seems we need to add SAS token for access
    sas_token =
      "sp=r&st=2023-07-17T09:07:56Z&se=2023-07-28T17:07:56Z&spr=https&sv=2022-11-02&sr=b&sig=yvMc8ORATrD%2BEaRktrkeaidtvm%2FieYa81iqGc8UIZYM%3D"

    source_blob_url =
      "https://#{Common.nsp_source()}.blob.core.windows.net/#{Common.container()}/#{@block_blob}" <>
        "?" <> sas_token

    put_block_from_url(%{
      storage_account: Common.nsp_dst(),
      container: Common.container(),
      block_blob: @block_blob,
      source_blob_url: source_blob_url
    })

    # |> put_block_list()
  end

  # The Append Block From URL operation commits a new block of data to the end of an existing append blob.
  defp append_block_from_url(%{
         storage_account: storage_account,
         container: container,
         block_blob: block_blob,
         source_blob_url: source_blob_url
         #  block_content: block_content
       }) do
    auth_token = AuthAgent.get_auth_token(AuthAgent.azure_storage())

    request_url = "https://#{storage_account}.blob.core.windows.net/#{container}/#{block_blob}"

    query_options = RestClient.add_query("comp", "appendblock")

    headers =
      RestClient.add_header("Content-type", "application/json")
      |> RestClient.add_header("Authorization", "Bearer #{auth_token.access_token}")
      |> RestClient.add_header("x-ms-copy-source-authorization", "bearer")
      |> RestClient.add_header("x-ms-date", "#{Common.time_str_from_gmt()}")
      |> RestClient.add_header("x-ms-version", "2020-04-08")
      |> RestClient.add_header("Content-Length", 0)
      |> RestClient.add_header("x-ms-copy-source", source_blob_url)

    RestClient.put_request(request_url, nil, query_options, headers)
  end

  def append_block_from_source_to_dst() do
    # The source blob must either be public or must be authorized via a shared access signature.
    sas_token =
      "sp=r&st=2023-07-17T09:07:56Z&se=2023-07-28T17:07:56Z&spr=https&sv=2022-11-02&sr=b&sig=yvMc8ORATrD%2BEaRktrkeaidtvm%2FieYa81iqGc8UIZYM%3D"

    source_blob_url =
      "https://#{Common.nsp_source()}.blob.core.windows.net/#{Common.container()}/#{@block_blob}" <>
        "?" <> sas_token

    # Append a block from source to dst
    append_block_from_url(%{
      storage_account: Common.nsp_dst(),
      container: Common.container(),
      block_blob: @blob_for_append,
      source_blob_url: source_blob_url
      # block_content: Common.generate_bytes_with_size(512)
    })
  end

  # This create an append blob at dst storage_account.
  # To add content to the append blob, we must call append_block
  def create_append_blob_at_dst() do
    Blob.put_blob(%{
      storage_account: Common.nsp_dst(),
      container: Common.container(),
      blob: @blob_for_append,
      blob_type: "AppendBlob"
    })
  end

  def test_append_block_from_url_workflow() do
    create_block_blob_at_source()
    create_append_blob_at_dst()
    append_block_from_source_to_dst()
  end

  def test_put_block_from_url_workflow() do
    create_block_blob_at_source()

    pub_block_from_source_to_dst()
    |> put_block_list()
  end
end
