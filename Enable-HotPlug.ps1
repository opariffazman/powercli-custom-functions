[CmdletBinding(DefaultParameterSetName = 'ByVM')]
Param (
  [Parameter(ParameterSetName = 'ByVM')]
  $VM,
  [Parameter(ParameterSetName = 'ByVMHost')]
  $VMHost,
  [Parameter(ParameterSetName = 'ByCluster')]
  $Cluster,
  [Parameter(ParameterSetName = 'ByDataCenter')]
  $DataCenter,
  [switch] $Memory,
  [switch] $CPU
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
    $viObject = Get-VMHost | Get-VM
  }
  Default {
    Write-Error -Message $PSItem
  }
}
# this script require VM to be in powered off state

function EnableMemHotAdd($VM) {
  $vmview = Get-VM $VM | Get-view
  $vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
  $vmConfigSpec.MemoryHotAddEnabled = $true
  $vmview.ReconfigVM($vmConfigSpec)
}

function EnableCpuHotAdd($VM) {
  $vmview = Get-VM $VM | Get-view
  $vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
  $vmConfigSpec.CPUHotAddEnabled = $true
  $vmview.ReconfigVM($vmConfigSpec)
}

$viObject | ForEach-Object {
  if ($Memory) {
    EnableMemHotAdd -VM $_
    Write-Verbose -Message "Enabling Memory Hot Add for $_" -Verbose
  }

  if ($CPU) {
    EnableCpuHotAdd -VM $_
    Write-Verbose -Message "Enabling CPU Hot Add for $_" -Verbose
  }
}
