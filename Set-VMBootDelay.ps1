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
  $Delay = "10000"
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

$vmBootOptions = New-Object VMware.Vim.VirtualMachineBootOptions
$vmBootOptions.BootDelay = $Delay
$vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
$vmConfigSpec.BootOptions = $vmBootOptions

$viObject | ForEach-Object {

	Write-Verbose -Message "Setting $_ boot delay to $Delay milliseconds" -Verbose
  $_.ExtensionData.ReconfigVM($vmConfigSpec)

}
