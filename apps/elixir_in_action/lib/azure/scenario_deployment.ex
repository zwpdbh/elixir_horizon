defmodule Azure.ScenarioDeployment do
  @moduledoc """
  This module is responsible for handling daily task for ScenarioDeploymentService

  ScenarioDeploymentService is deployed in Azure:
  subscription id: 65490f91-f2c2-4514-80ba-4ec1de89aeda  (XStore Internal Infrastructure)
  resource group: XSCENARIODEPLOYMENTS-MIGRATED
  location: west us
  cloudservice: xscenariodeployments
  cloudservice url: https://ms.portal.azure.com/#@microsoft.onmicrosoft.com/resource/subscriptions/65490f91-f2c2-4514-80ba-4ec1de89aeda/resourceGroups/XSCENARIODEPLOYMENTS-MIGRATED/providers/Microsoft.Compute/cloudServices/xscenariodeployments/overview

  """

  alias Http.RestClient
  alias Azure.AuthAgent

  @host_url "https://xscenariodeployments.cloudapp.net/"

  @doc """
  From: DELETE /api/virtualmachinedeployments/{deploymentName}
  See: https://xscenariodeployments.cloudapp.net/swagger/ui/index#!/VirtualMachineDeployments/VirtualMachineDeployments_DeleteDeployment

  we could also test delete api by:
    export access_token="xxx"
    curl -X DELETE -H "Accept: application/json" -H "Authorization: Bearer $TOKEN" "https://xscenariodeployments.cloudapp.net/api/virtualmachinedeployments/22" --verbose
  """
  def delete_virtual_machine(virtual_machine_name) do
    auth_token = get_auth_token()

    headers =
      RestClient.add_header("Content-type", "application/json; charset=utf-8")
      |> RestClient.add_header("accept", "text/plain")
      |> RestClient.add_header("Authorization", "Bearer #{auth_token.access_token}")

    RestClient.delete_request(
      @host_url <> "api/virtualmachinedeployments/" <> virtual_machine_name,
      headers
    )
  end

  defp get_auth_token() do
    AuthAgent.get_auth_token(AuthAgent.scenario_deployment_api())
  end
end
