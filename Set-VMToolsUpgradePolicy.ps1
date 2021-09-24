Param (
  $VM,
  [ValidateSet("Manual", "UpgradeAtPowerCycle")]
  $Policy = "UpgradeAtPowerCycle"
)

if ($VM) {
  $viObject = Get-VM $VM | Get-View
}
else {
  $viObject = Get-View -viewtype VirtualMachine
}

$vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
$vmConfigSpec.Tools = New-Object VMware.Vim.ToolsConfigInfo
$vmConfigSpec.Tools.ToolsUpgradePolicy = $Policy

$viObject | ForEach-Object {
  $vmview = $_
  Write-Verbose "Configuring $($_.Name) VMtools Upgrade Policy to $Policy" -Verbose
  try {
    $vmview.ReconfigVM($vmConfigSpec)
  }
  catch {
    Write-Warning $PSItem
  }
  $vmview.UpdateViewData()
}
