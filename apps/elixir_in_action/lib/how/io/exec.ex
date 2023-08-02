defmodule How.Io.Exec do
  require Logger

  def run01 do
    # run command and direct output to terminal
    project_folder = File.cwd!()
    log_file_path = project_folder <> "/apps/elixir_in_action/lib/how/io/log.txt"

    {output, _status} =
      System.cmd("bash", ["-c", "ls /non-existent-dir"],
        stderr_to_stdout: true,
        into: IO.stream()
      )

    File.write(log_file_path, output)
    {:ok, "exec finished"}
  end

  def run02 do
    # run command and direct output to a file. (overwrite)
    project_folder = File.cwd!()
    log_file_path = project_folder <> "/apps/elixir_in_action/lib/how/io/log.txt"

    {_output, _status} =
      System.cmd("bash", ["-c", "ls /non-existent-dir"],
        stderr_to_stdout: true,
        into: File.stream!(log_file_path)
      )

    {:ok, "exec finished"}
  end

  def run03 do
    # run command and direct and append to a file (not overwrite)
    project_folder = File.cwd!()
    log_file_path = project_folder <> "/apps/elixir_in_action/lib/how/io/log.txt"

    {_output, _status} =
      System.cmd("bash", ["-c", "ls /non-existent-dir"],
        stderr_to_stdout: true,
        into: File.stream!(log_file_path, [:append])
      )

    {_output, _status} =
      System.cmd("bash", ["-c", "ls /non-existent-dir"],
        stderr_to_stdout: true,
        into: File.stream!(log_file_path, [:append])
      )

    {:ok, "exec finished"}
  end
end

defmodule How.Parse.PhoneNumber do
  alias How.Parse.Example02

  defstruct [
    :country_code,
    :area_code,
    :subscriber_number
  ]

  def new(str) when is_binary(str) do
    case Example02.parse(str) do
      {:ok, results, "", _, _, _} -> {:ok, struct!(__MODULE__, results)}
      {:error, reason, _rest, _, _, _} -> {:error, reason}
    end
  end
end
