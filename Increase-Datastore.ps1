param(
  [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
  $Datastore
)

Get-Datastore $Datastore | ForEach-Object {
  $ESXi = Get-View -Id ($_.ExtensionData.Host | Select-Object -Last 1 | ForEach-Object Key)
  $DatastoreSystem = Get-View -Id $ESXi.ConfigManager.DatastoreSystem
  $ExpandOptions = $DatastoreSystem.QueryVmfsDatastoreExpandOptions($Datastore.ExtensionData.MoRef)
  Write-Verbose "$($_.Name) - $($ExpandOptions.Info.Layout.Total.BlockSize)" -Verbose
  try { $DatastoreSystem.ExpandVmfsDatastore($Datastore.ExtensionData.MoRef,$ExpandOptions.spec) }
  catch { Write-Warning $PSItem }
}
