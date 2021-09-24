param(
  $VMHost,
  $CanonicalName,
  $Resignature
)

$esxcli = $VMHost | Get-EsxCli -WarningAction SilentlyContinue # currently using version 1, version 2 is latest
$snapAvail = $esxcli.storage.vmfs.snapshot.list() # confirming the snapshot availability

if ($snapAvail) {
  Write-Verbose "$VMHost has unresolved VMFS snapshot" -Verbose
  Start-Sleep -Seconds 2
  # Use this to mount with resignature ***************************************
  Write-Verbose "Resignaturing VMFS snapshot [$($snapAvail.VolumeName)]" -Verbose
  $vmfsOutput = $esxcli.storage.vmfs.snapshot.resignature($dsName.Remove(0, 5))
  # **************************************************************************
  # Use this to mount without resignature ************************************
  # Write-Verbose "Mounting VMFS snapshot [$($snapAvail.VolumeName)]" -Verbose
  # $vmfsOutput = $esxcli.storage.vmfs.snapshot.mount($dsName.Remove(0,5))
  # **************************************************************************
  if ($vmfsOutput -eq 'true') {
      Write-Verbose "VMFS snapshot [$($snapAvail.VolumeName)] resignatured sucessfully at [$VMHost]" -Verbose
      Write-Verbose "Allocating [$VMHost] some grace period for 10 seconds" -Verbose
      Start-Sleep -Seconds 10 # pausing for 10 seconds so that ds current name can be captured
      $dsToRename = $VMHost | Get-Datastore | Where-Object Name -Match $dsName.Remove(0, 5) | ForEach-Object { $_.Name }
      Write-Verbose "Current Datastore Name: `"$dsToRename`"" -Verbose
      Write-Verbose "New Datastore Name: `"$dsName`"" -Verbose
      try {
          Write-Verbose "Renaming VMFS datastore" -Verbose
          # rename to name based on BDC with 'snap-xxxxx' on it
          $VMHost | Get-Datastore | Where-Object Name -EQ $dsToRename | Set-Datastore -Name $dsName | Out-Null
      }
      catch { Write-Warning $PSItem }
  }
  else { Write-Warning "Fail to resignature $($snapAvail.VolumeName) at [$VMHost]" }
}
else { Write-Warning "$VMHost has no unresolved VMFS snapshot(s)" }
