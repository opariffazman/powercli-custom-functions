Param(
  [Parameter(Mandatory = $true)]
  $VM,
  [Parameter(Mandatory = $true)]
  [ValidateSet("SCSI Controller 1", "SCSI Controller 2", "SCSI Controller 3")]
  $Controller,
  [Parameter(Mandatory = $true)]
  $CanonicalName
)

$viObject = Get-VM $VM

# Select first VM & assign as parent VM
$parentVM = $viObject | Select-Object -First 1

$diskInfo = @()

# Add new RDM disk to first parent VM & Build array info for later use
$CanonicalName | ForEach-Object {
  $diskInfo += New-Harddisk -VM $parentVM -DiskType RawPhysical -DeviceName /vmfs/devices/disks/$_ -Controller $Controller -Verbose
}

# Based on array info built on first parent VM, attach accordingly to next subsequent VM other than parent vm
$diskInfo | ForEach-Object {
  $Filename = $_.Filename
  $viObject | Where-Object Name -NE $parentVM.Name | New-Harddisk -DiskPath $Filename -Controller $Controller -Verbose | Out-Null
}
