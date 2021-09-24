[CmdletBinding(DefaultParameterSetName = 'ByVM')]
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
    $viObject = Get-VMHost | Get-VM
  }
  Default {
    Write-Error -Message $PSItem
  }
}
# this script require VM to be in powered off state

$viObject | ForEach-Object {
  $VMName = $_.Name
  $date = Get-date -Format "dd hh mm ss"
  $newUuid = "00 11 22 33 44 55 66 77-aa bb cc dd" + $date
  $spec = New-Object VMware.Vim.VirtualMachineConfigSpec
  $spec.uuid = $newUuid

  Write-Verbose "Configuring `"$VMName`" with New UUID" -Verbose
  try {
    ($_).Extensiondata.ReconfigVM_Task($spec) | Out-Null
  }
  catch {
    Write-Warning $PSItem
  }
  Start-Sleep -Seconds 1
}
