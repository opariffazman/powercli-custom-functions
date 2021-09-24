[CmdletBinding(DefaultParameterSetName = 'ByAll')]
Param (
  [Parameter(ParameterSetName = 'ByVMHost')]
  $VMHost,
  [Parameter(ParameterSetName = 'ByDatastore')]
  $Datastore,
  [Parameter(ParameterSetName = 'ByCluster')]
  $Cluster,
  [Parameter(ParameterSetName = 'ByDataCenter')]
  $DataCenter
)

switch ($PSCmdlet.ParameterSetName) {
  'ByAll' {
    $viObject = Get-Datastore | Where-Object {$_.Accessible -eq 'True' -and $_.State -eq 'Available'}
  }
  'ByVMHost' {
    $viObject = Get-VMHost $VMHost | Get-Datastore | Where-Object {$_.Accessible -eq 'True' -and $_.State -eq 'Available'}
  }
  'ByDatastore' {
    $viObject = Get-Datastore $Datastore | Where-Object {$_.Accessible -eq 'True' -and $_.State -eq 'Available'}
  }
  'ByCluster' {
    $viObject = Get-Cluster $Cluster | Get-Datastore | Where-Object {$_.Accessible -eq 'True' -and $_.State -eq 'Available'}
  }
  'ByDataCenter'{
    $viObject = Get-Datacenter $DataCenter | Get-Cluster | Get-Datastore | Where-Object {$_.Accessible -eq 'True' -and $_.State -eq 'Available'}
  }
  Default {
    Write-Error -Message $PSItem
  }
}

$viObject | ForEach-Object {
  Write-Progress -Activity "Collecting Info" -CurrentOperation $_.Name
  New-PSDrive -Location $_ -Name ds -PSProvider VimDatastore -Root '\' > $null
  Get-ChildItem -Path ds: -Recurse -Filter *.iso | `
  Select-Object DatastoreFullPath, Datastore, FolderPath, Name, @{N="CapacityGB";E={[Math]::Round($_.Length/1GB,2)}}
  Remove-PSDrive -Name ds -Confirm:$false
}
