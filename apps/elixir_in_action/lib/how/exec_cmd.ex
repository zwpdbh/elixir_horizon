defmodule ExecCmd do
  def run(cmd_str) do
    System.cmd("bash", ["-c", cmd_str],
      stderr_to_stdout: true,
      into: IO.stream()
    )
  end
end
