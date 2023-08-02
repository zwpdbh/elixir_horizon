defmodule Azure.AzureCli do
  require Logger

  @moduledoc """
  An module which dedicate to run commands for az-cli

  It needs to support multiple az-cli operation sessions.
  The basic idea is:
  1. For multiple az-cli commands belong to the same session, we need to specify the same environment variable: AZURE_CONFIG_DIR
  2. Log in with Service Principal
    az login --service-principal -u <username> -p <secret> --tenant <tenant_id>
    (Use appId for -u, password for -p and tenant for -t)
    This will put access_token related into into the folder specified by AZURE_CONFIG_DIR
  3. Any following commands with the same AZURE_CONFIG_DIR setting will use the same access_token
    So, we could support multiple azure-cli credentials for different sessions.

  Ref:
    - https://learn.microsoft.com/en-us/cli/azure/reference-index?view=azure-cli-latest#az-login
    - https://jiasli.github.io/azure-notes/aad/Service-Principal-cli.html
    - https://endjin.com/blog/2020/05/using-multiple-azure-cli-credentials-within-automation
  """

  def test_run_cli_commands do
    %Azure.AuthAgent.ServicePrinciple{}
    |> create_cli_session()
    |> run_az_cli("""
    az group list \
    """)

    # Notice the "\" at the end of the command, it is to prevent the "\n" character.
  end

  def create_cli_session(%Azure.AuthAgent.ServicePrinciple{
        tenant_id: tenant_id,
        client_id: client_id,
        client_secret: client_secret
      }) do
    session_dir = make_session_dir()

    az_login_command_str =
      "az login --service-principal -u #{client_id} -p #{client_secret} --tenant #{tenant_id}"

    run_az_cli(session_dir, az_login_command_str)
  end

  def run_az_cli(session_dir, command_str) do
    %{cmd: command, args: arguments} =
      command_str
      |> from_command_str_to_command_and_argument

    {%IO.Stream{}, 0} =
      System.cmd(command, arguments,
        stderr_to_stdout: true,
        into: IO.stream(),
        env: [{"AZURE_CONFIG_DIR", session_dir}]
      )

    session_dir
  end

  defp from_command_str_to_command_and_argument(str) do
    [command | arguments] =
      str
      |> String.split(" ")
      |> Enum.filter(fn x -> x != "" end)

    %{cmd: command, args: arguments}
  end

  defp get_random_str() do
    "abcdefghijklmnopqrstuvwxyz0123456789"
    |> String.graphemes()
    |> Enum.take_random(6)
    |> Enum.join("")
  end

  defp make_session_dir() do
    path = Path.join([System.tmp_dir!(), "az_cli_sessions", get_random_str()])

    if not File.exists?(path) do
      # Logger.info("create session dir: #{path}")
      File.mkdir_p!(path)
    end

    path
  end
end
