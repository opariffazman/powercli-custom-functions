[CmdletBinding(DefaultParameterSetName = 'ByController')]
Param(
  [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
  $VM,
  [Parameter(Mandatory = $true, ParameterSetName = 'ByController')]
  [ValidateSet("SCSI Controller 1", "SCSI Controller 2","SCSI Controller 3")]
  $Controller,
  [Parameter(ParameterSetName = 'ByBusNumber')]
  [ValidateSet("1", "2","3")]
  $BusNumber
)

switch ($PSCmdlet.ParameterSetName) {
  'ByController' {
    switch ($Controller) {
      'SCSI Controller 1' { $BusNumber = 1 }
      'SCSI Controller 2' { $BusNumber = 2 }
      'SCSI Controller 3' { $BusNumber = 3 }
      Default { $BusNumber = 1 }
    }
    $viObject = $BusNumber
  }
  'ByBusNumber' {
    $viObject = $BusNumber
  }
  Default { Write-Error $PSItem }
}

# Loop through each VM and remove controller accordingly
Get-VM $VM | ForEach-Object {
  $vmview = Get-View $_

  $SCSIController = $vmview.Config.Hardware.Device | Where-Object {
    $PSItem -is [VMware.Vim.ParaVirtualSCSIController] -or `
      $PSItem -is [VMware.Vim.VirtualLsiLogicSASController] -or `
      $PSItem -is [VMware.Vim.VirtualLsiLogicController] -and `
      $PSItem.BusNumber -eq $viObject
  }

  $storagespec = New-Object VMware.Vim.VirtualMachineConfigSpec
  $removeSCSIDevice = New-Object VMware.Vim.VirtualDeviceConfigSpec
  $removeSCSIDevice.operation = "remove"
  $removeSCSIDevice.device = $SCSIController
  $removeSCSIDevice.device.busNumber = $BusNumber

  $storageSpec.deviceChange = $removeSCSIDevice

  Write-Verbose "$($vmview.Name) - Removing $SCSIController, Bus Number: $($BusNumber)" -Verbose
  try { $vmview.ReconfigVM($storageSpec) }
  catch { Write-Warning $PSItem }
  $vmview.UpdateViewData()
}

