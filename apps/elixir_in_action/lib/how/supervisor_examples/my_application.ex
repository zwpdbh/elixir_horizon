defmodule How.SupervisorExamples.MyApplication do
  alias How.SupervisorExamples.Scheduler

  def start(_type, _args) do
    children = [
      {Scheduler, name: :scheduler1}
    ]

    opts = [strategy: :one_for_one, name: MyApplicationSupervisor]
    Supervisor.start_link(children, opts)

  end
end
