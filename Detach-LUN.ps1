[CmdletBinding(DefaultParameterSetName = 'ByCluster')]
Param (
  [Parameter(ValueFromPipeline = $true, ParameterSetName = 'ByVMHost')]
  $VMHost,
  [Parameter(ValueFromPipeline = $true, ParameterSetName = 'ByCluster')]
  $Cluster,
  [Parameter(ParameterSetName = 'ByDatastore')]
  $Datastore,
  $CanonicalName
)

$ErrorActionPreference = 'SilentlyContinue'

switch ($PSCmdlet.ParameterSetName) {
  'ByVMhost' {
    $viObject = Get-VMHost -Name $VMHost -State 'Connected'
  }
  'ByCluster' {
    $viObject = Get-Cluster $Cluster | Get-VMHost -State 'Connected'
  }
  'ByDatastore' {
    $viObject = Get-Datastore $Datastore | Get-VMHost -State 'Connected'
    $CanonicalName = (Get-Datastore $Datastore).Extensiondata.Info.Vmfs.Extent[0].DiskName
  }
  Default { Write-Error $PSItem }
}


$viObject | ForEach-Object {
  $storSys = Get-View $_.Extensiondata.ConfigManager.StorageSystem
  $VMHost = $_
  $CanonicalName | ForEach-Object {
    $lun = $_
    $device = $storSys.StorageDeviceInfo.ScsiLun | Where-Object { $_.CanonicalName -eq $lun }
    $lunUUID = $device.Uuid
    Write-Verbose "Detaching LUN $($device.CanonicalName) from host $VMHost" -Verbose
    try { $storSys.DetachScsiLun($lunUUID) }
    catch { Write-Warning $PSItem }
  }
}
