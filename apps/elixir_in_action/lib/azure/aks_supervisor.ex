defmodule Azure.AksSupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      Azure.Aks,
      {Task.Supervisor, name: Azure.Aks.TaskSupervisor},
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
