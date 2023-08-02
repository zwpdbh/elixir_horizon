defmodule App do
  use Application

  @impl true
  def start(_type, _args) do
    Azure.AuthSupervisor.start_link(name: Azure.AuthSupervisor)
    Azure.AksSupervisor.start_link(name: Azure.AksSupervisor)
  end
end
