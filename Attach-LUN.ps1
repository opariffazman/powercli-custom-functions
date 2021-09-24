[CmdletBinding(DefaultParameterSetName = 'ByCluster')]
Param (
  [Parameter(ValueFromPipeline = $true, ParameterSetName = 'ByVMHost')]
  $VMHost,
  [Parameter(ValueFromPipeline = $true, ParameterSetName = 'ByCluster')]
  $Cluster,
  [Parameter(Mandatory = $true)]
  $CanonicalName
)

switch ($PSCmdlet.ParameterSetName) {
  'ByVMhost' {
    $viObject = Get-VMHost -Name $VMHost -State Connected
  }
  'ByCluster' {
    $viObject = Get-Cluster $Cluster | Get-VMHost -State Connected
  }
  Default { Write-Error $PSItem }
}

$viObject | ForEach-Object {
  $storSys = Get-View $_.Extensiondata.ConfigManager.StorageSystem
  $VMHost = $_
  foreach ($lun in $CanonicalName) {
    $device = $storSys.StorageDeviceInfo.ScsiLun | Where-Object { $_.CanonicalName -eq $lun }
    $lunUUID = $device.Uuid
    Write-Verbose "Attach LUN $($device.CanonicalName) to host $VMHost" -Verbose
    try { $storSys.AttachScsiLun($lunUUID) }
    catch { Write-Warning $PSItem }
  }
}
