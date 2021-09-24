[CmdletBinding(DefaultParameterSetName = 'ByAll')]
Param (
  [Parameter(ParameterSetName = 'ByVMHost')]
  $VMHost,
  [Parameter(ParameterSetName = 'ByCluster')]
  $Cluster,
  [Parameter(ParameterSetName = 'ByDataCenter')]
  $DataCenter
)

switch ($PSCmdlet.ParameterSetName) {
  'ByVMHost' {
    $viObject = Get-VMHost $VMHost -State 'Connected'
  }
  'ByCluster' {
    $viObject = Get-Cluster $Cluster | Get-VMHost -State 'Connected'
  }
  'ByDataCenter' {
    $viObject = Get-Datacenter $DataCenter | Get-Cluster $Cluster | Get-VMHost -State 'Connected'
  }
  'ByAll'{
    $viObject = Get-VMHost
  }
  Default {
    Write-Error -Message $PSItem
  }
}

$report = @()

$report += $viObject | ForEach-Object {
  # fc or fnic for UCS VIC-Cards
  $esx = $_
  foreach ($hba in ($esx.ExtensionData.Config.StorageDevice.HostBusAdapter | Where-Object { $_.Driver -match 'fc' -or $_.Driver -match 'fnic' })) {
    $paths = @()
    foreach ($lun in $esx.ExtensionData.Config.StorageDevice.MultipathInfo.Lun) {
      $paths += $lun.Path | Where-Object { $_.Adapter -match "$($hba.Device)" -and $_.Adapter -match 'FibreChannel' }
    }
    $groups = $paths | Group-Object -Property PathState

    $Info = {} | Select-Object Cluster, VMHost, Device, Active, Standby, Dead
    $Info.Cluster = $esx.Parent
    $Info.VMHost = $esx.Name
    $Info.Device = $hba.Device
    $Info.Active =  ($groups | Where-Object { $_.Name -eq 'active' }).Count
    $Info.Standby = ($groups | Where-Object { $_.Name -eq 'standby' }).Count
    $Info.Dead = ($groups | Where-Object { $_.Name -eq 'dead' }).Count
    $Info
  }
}

$report
