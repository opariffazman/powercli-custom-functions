Param(
  [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
  $VM,
  [ValidateSet("ParaVirtualSCSIController", "VirtualLsiLogicSASController", "VirtualLsiLogicController")]
  $Controller = "VirtualLsiLogicSASController", # VMWare use this by default
  [ValidateSet("noSharing", "physicalSharing")]
  $SharedBus = "physicalSharing"
)

# Loop through each VM and assign controller accordingly
Get-VM $VM | ForEach-Object {
  $vmview = Get-View $_

  $Controllers = $vmview.Config.Hardware.Device | Where-Object {
    $PSItem -is [VMware.Vim.ParaVirtualSCSIController] -or `
      $PSItem -is [VMware.Vim.VirtualLsiLogicSASController] -or `
      $PSItem -is [VMware.Vim.VirtualLsiLogicController]
  }

  # 1 VM can only have max of 4 scsi controllers
  while ($Controllers.BusNumber -contains [int]$BusNumber -or $BusNumber -ge 10) {
    $BusNumber++
  }

  $storagespec = New-Object VMware.Vim.VirtualMachineConfigSpec
  $NewSCSIDevice = New-Object VMware.Vim.VirtualDeviceConfigSpec
  $NewSCSIDevice.operation = "add"
  $NewSCSIDevice.device = New-Object VMware.Vim.$Controller
  $NewSCSIDevice.device.key = -222
  $NewSCSIDevice.device.busNumber = $BusNumber
  $NewSCSIDevice.device.sharedBus = $SharedBus

  $storageSpec.deviceChange += $NewSCSIDevice

  Write-Verbose "$($vmview.Name) - Adding $Controller, Bus Number: $($BusNumber)" -Verbose
  try { $vmview.ReconfigVM($storageSpec) }
  catch { Write-Warning $PSItem }
  $vmview.UpdateViewData()
}

