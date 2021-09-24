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
  'ByVMHost' {
    $viObject = Get-VMHost $VMHost | Where-Object ConnectionState -EQ 'Connected'
  }
  'ByCluster' {
    $viObject = Get-Cluster $Cluster | Get-VMHost | Where-Object ConnectionState -EQ 'Connected'
  }
  Default {
    Write-Error -Message $PSItem
  }
}

$allInfo = @()

$allInfo += $viObject | ForEach-Object {
  $storSys = Get-View $_.Extensiondata.ConfigManager.StorageSystem
  $VMHost = $_
  foreach ($lun in $CanonicalName) {
    $Info = { } | Select-Object VMHost, DeviceState, CanonicalName, CapacityGB
    $device = $storSys.StorageDeviceInfo.ScsiLun | Where-Object { $_.CanonicalName -eq $lun }
    switch ($device.OperationalState) {
      'error' {
        $Info.DeviceState = 'Error'
      }
      'ok' {
        $Info.DeviceState = 'Attached'
      }
      'off' {
        $Info.DeviceState = 'Detached'
      }
      Default {
        $Info.DeviceState = 'Unknown'
      }
    }
    $Info.VMHost = $VMHost
    $Info.CanonicalName = $lun
    $Info.CapacityGB = $device.Capacity.BlockSize * ($device.Capacity.Block/1GB)
    $Info
  }
}

$allInfo
