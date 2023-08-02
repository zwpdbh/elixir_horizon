defmodule Azure.Dsts do
  @moduledoc """
  This module is used to obtain access_token from Datacenter Security Token Service (dSTS)
  See: https://review.learn.microsoft.com/en-us/identity/dsts/?branch=main

  For calling REST API for "https://xscenariodeployments.cloudapp.net/swagger/ui/index#/VirtualMachineDeployments".
  The access token must be obtained from DSTS instead of from Azure AD.

  See How scte use C# code to obtain token:
  https://msazure.visualstudio.com/One/_git/Storage-storagetests-SCTE?path=/src/scte/AzureStorage/ActivityLibrary/SrpActivites/StorageManagementHelper.cs&version=GBmaster&_a=contents

  See How the authentication is constructed in WebAuthenticationClient
  https://msazure.visualstudio.com/One/_git/EngSys-Security-dSTS?path=%2FSecurity%2FSamples%2FDatacenterAuthentication%2FRestClient%2FWebAuthenticationClientSample.cs&version=GBmaster
  """
end
