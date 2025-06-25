defmodule ExecCmd do
  require Logger

  def run(cmd_str, env_settings \\ nil) do
    Logger.info("#{cmd_str}")

    {output, status} =
      case env_settings do
        nil ->
          System.cmd(
            "bash",
            ["-c", cmd_str],
            stderr_to_stdout: true
          )

        settings ->
          System.cmd(
            "bash",
            ["-c", cmd_str],
            stderr_to_stdout: true,
            env: settings
          )
      end

    Logger.info("#{output}")

    case status do
      0 -> {:ok, output}
      _err_code -> {:err, output}
    end
  end
end
