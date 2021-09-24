[CmdletBinding(DefaultParameterSetName = 'ByAll')]
Param (
  [Parameter(ParameterSetName = 'ByVM')]
  $VM,
  [Parameter(ParameterSetName = 'ByVMHost')]
  $VMHost,
  [Parameter(ParameterSetName = 'ByCluster')]
  $Cluster,
  [Parameter(ParameterSetName = 'ByDataCenter')]
  $DataCenter
)

switch ($PSCmdlet.ParameterSetName) {
  'ByVM' {
    $viObject = Get-VM $VM
  }
  'ByVMHost' {
    $viObject = Get-VMHost $VMHost | Get-VM
  }
  'ByCluster' {
    $viObject = Get-Cluster $Cluster | Get-VMHost | Get-VM
  }
  'ByDataCenter' {
    $viObject = Get-Datacenter $DataCenter | Get-Cluster $Cluster | Get-VMHost | Get-VM
  }
  'ByAll'{
    $viObject = Get-VM
  }
  Default {
    Write-Error -Message $PSItem
  }
}

$viObject | Select-Object Name, @{N="Avg vCPU, Mhz" ; E={[Math]::Round((($_ | `
Get-Stat -Stat cpu.usagemhz.average -Start (Get-Date).AddDays(-$Days) -IntervalMins 5 | `
Measure-Object Value -Average).Average),2)}}, @{N="Avg vRAM, %" ; E={[Math]::Round((($_ | `
Get-Stat -Stat mem.usage.average -Start (Get-Date).AddDays(-$Days) -IntervalMins 5 | `
Measure-Object Value -Average).Average),2)}}, @{N="Avg Net, KBps" ; E={[Math]::Round((($_ | `
Get-Stat -Stat net.usage.average -Start (Get-Date).AddDays(-$Days) -IntervalMins 5 | `
Measure-Object Value -Average).Average),2)}}, @{N="Avg Disk, KBps" ; E={[Math]::Round((($_ | `
Get-Stat -Stat disk.usage.average -Start (Get-Date).AddDays(-$Days) -IntervalMins 5 | `
Measure-Object Value -Average).Average),2)}}
