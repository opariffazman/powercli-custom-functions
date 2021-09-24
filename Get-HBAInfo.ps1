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

$viObject | ForEach-Object {
  Get-VMHostHba -VMHost $_ -Type FibreChannel | Where-Object {$_.STatus -eq 'online'} | `
  Select-Object VMHost, `
  @{N='HBA Node WWN';E={$wwn = "{0:X}" -f $_.NodeWorldWideName; (0..7 | Where-Object {$wwn.Substring($_*2,2)}) -join ':'}}, `
  @{N='HBA Node WWP';E={$wwp = "{0:X}" -f $_.PortWorldWideName; (0..7 | Where-Object {$wwp.Substring($_*2,2)}) -join ':'}}
}
