Param (
    [Parameter(ValueFromPipeline=$true)]
    $VM,
    [ValidateSet("Flat", "RawPhysical","RawVirtual")]
    $DiskType
)

$DiskInfo = @()

Get-VM $VM | Get-View | ForEach-Object {
    $vmview = $_
    foreach ($VirtualSCSIController in ($vmview.Config.Hardware.Device | Where-Object {$_.DeviceInfo.Label -match "SCSI Controller"})) {
        foreach ($VirtualDiskDevice in ($vmview.Config.Hardware.Device | Where-Object {$_.ControllerKey -eq $VirtualSCSIController.Key})) {
            $Info ={} | Select-Object VM, Disk, DiskMode, CompatibilityMode, CapacityGB, Controller, DeviceName, FileName
            $Info.VM = $vmview.Name
            $Info.Disk = $VirtualDiskDevice.DeviceInfo.Label
            $Info.DiskMode = $VirtualDiskDevice.Backing.DiskMode
            $Info.CompatibilityMode = $VirtualDiskDevice.Backing.CompatibilityMode
            $Info.CapacityGB = $VirtualDiskDevice.CapacityInKB * 1KB / 1GB
            $Info.Controller =  "SCSI($($VirtualSCSIController.BusNumber):$($VirtualDiskDevice.UnitNumber))"
            $Info.DeviceName = if($VirtualDiskDevice.Backing.DeviceName){ 'naa.'+($VirtualDiskDevice.Backing.DeviceName).Substring(14,32) }
            $Info.FileName = $VirtualDiskDevice.Backing.FileName
            $DiskInfo += $Info
        }

    }

}

switch ($DiskType) {
    'Flat' {
        $DiskInfo | Where-Object {$_.DiskMode -EQ 'persistent'}
      }
    'RawPhysical'{
        $DiskInfo | Where-Object {$_.DiskMode -EQ 'independent_persistent' -and $_.CompatibilityMode -eq 'physicalMode'}
    }
    'RawVirtual'{
        $DiskInfo | Where-Object {$_.DiskMode -EQ 'independent_persistent' -and $_.CompatibilityMode -eq 'virtualMode'}
    }
    Default {
        $DiskInfo
    }
}


