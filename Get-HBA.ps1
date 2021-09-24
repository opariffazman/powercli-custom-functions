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
    $viObject = Get-Datacenter $DataCenter | Get-Cluster | Get-VMHost -State 'Connected'
  }
  'ByAll'{
    $viObject = Get-VMHost
  }
  Default {
    Write-Error -Message $PSItem
  }
}

$allInfo = @()

$allInfo += $viObject | ForEach-Object {
  $esx = $_
  foreach($hba in (Get-VMHostHba -VMHost $esx -Type "FibreChannel")){
      $target = ((Get-View $hba.VMhost).Config.StorageDevice.ScsiTopology.Adapter | Where-Object {$_.Adapter -eq $hba.Key}).Target
      $luns = Get-ScsiLun -Hba $hba  -LunType "disk" -ErrorAction SilentlyContinue
      $nrPaths = ($target |  ForEach-Object {$_.Lun.Count} | Measure-Object -Sum).Sum
      $Info = {} | Select-Object VMHost, HBA, Targets, Devices, Paths, Status
      $Info.VMHost = $esx.name
      $Info.HBA = $hba.Name
      $Info.Targets = $target.Count
      $Info.Devices = $luns.Count
      $Info.Paths = $nrPaths
      $Info.Status = $hba.Status
      $Info
  }
}

$allInfo
