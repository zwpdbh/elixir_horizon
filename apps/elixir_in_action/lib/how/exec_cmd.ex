defmodule ExecCmd do
  require Logger

  def run(cmd_str) do
    Logger.info("#{cmd_str}")

    System.cmd("bash", ["-c", cmd_str],
      stderr_to_stdout: true,
      into: IO.stream()
    )
  end
end


