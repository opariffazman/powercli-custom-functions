[CmdletBinding(DefaultParameterSetName = 'ByNetworkName')]
param(
  [Parameter(Mandatory = $true)]
  $VM,
  [Parameter(ParameterSetName = 'ByName')]
  $Name,
  [Parameter(ParameterSetName = 'ByNetworkName')]
  $NetworkName,
  [Parameter(ParameterSetName = 'ByMacAddress')]
  $MacAddress
)

$VMS = Get-VM $VM

$VMS | ForEach-Object {

  $VMName = $_.Name
  switch ($PSCmdlet.ParameterSetName) {
    'ByName' {
      $viObject = Get-NetworkAdapter -VM $VMName | Where-Object NetworkName -EQ $Name
    }
    'ByNetworkName' {
      $viObject = Get-NetworkAdapter -VM $VMName | Where-Object NetworkName -EQ $NetworkName
    }
    'ByMacAddress' {
      $viObject = Get-NetworkAdapter -VM $VMName | Where-Object MacAddress -EQ $MacAddress
    }
    Default { Write-Error $PSItem }
  }

  $vmview = Get-View $_

  $spec = New-Object VMware.Vim.VirtualMachineConfigSpec
  $devSpec = New-Object VMware.Vim.VirtualDeviceConfigSpec
  $devSpec.operation = "remove"
  $adapter = $viObject
  $devSpec.device += $adapter.ExtensionData
  $spec.deviceChange += $devSpec

  Write-Verbose "$VMName - Removing Network Adapter, Network Name: $($adapter.NetworkName), Mac Address: $($adapter.MacAddress)" -Verbose
  try { $vmview.ReconfigVM($spec) }
  catch { Write-Warning $PSItem }
}


