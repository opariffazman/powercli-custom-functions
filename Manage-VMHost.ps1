[CmdletBinding(DefaultParameterSetName = 'ByVMHost')]
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
    $viObject = Get-VMHost $VMHost | Get-VMHostNetworkAdapter | Where-Object ManagementTrafficEnabled
  }
  'ByCluster' {
    $viObject = Get-Cluster $Cluster | Get-VMHost | Get-VMHostNetworkAdapter | Where-Object ManagementTrafficEnabled
  }
  'ByDataCenter' {
    $viObject = Get-Datacenter $DataCenter | Get-Cluster $Cluster | Get-VMHost | Get-VMHostNetworkAdapter | Where-Object ManagementTrafficEnabled
  }
  'ByAll'{
    $viObject = Get-VMHost | Get-VMHostNetworkAdapter | Where-Object ManagementTrafficEnabled
  }
  Default {
    Write-Error -Message $PSItem
  }
}

$viObject | ForEach-Object {
  $ManagementIP = $_.IP
  Write-Progress -Activity "Accessing VMHost Management Web Console" -CurrentOperation $_.Name
  Start-Process "https://$ManagementIP"
}
