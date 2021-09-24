[CmdletBinding()]
Param (
		[Parameter(ValueFromPipeline = $true, Mandatory = $true)]
		$Datastore
)

Get-Datastore $Datastore | ForEach-Object {
  if ($_.ExtensionData.Host) {
    $attachedHosts = $_.ExtensionData.Host
    Foreach ($VMHost in $attachedHosts) {
      $hostview = Get-View $VMHost.Key
      $storageSys = Get-View $HostView.ConfigManager.StorageSystem
      Write-Verbose "Unmounting VMFS Datastore $($_.Name) from host $($hostview.Name)" -Verbose
      try { $storageSys.UnmountVmfsVolume($_.ExtensionData.Info.vmfs.uuid) }
      catch { Write-Warning $PSItem }
    }
  }
}
