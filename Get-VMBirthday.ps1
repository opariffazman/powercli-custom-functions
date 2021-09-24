Param(
  [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
  $VM
)

$VMInfo = @()
Write-Verbose "Gathering Info" -Verbose

Get-VM $VM | ForEach-Object {
  # Search for events where the VM was deployed from a template
  $vmevents = Get-VIEvent $_ -MaxSamples([int]::MaxValue) | Where-Object {$_.FullFormattedMessage -like "Deploying*"} | `
  Select-Object VM, CreatedTime, Username, FullFormattedMessage
  if ($vmevents){
    $type = "From Template"
  }

  # If no events were found, search for events where the VM was created from scratch
  if (!$vmevents) {
    $vmevents = Get-VIEvent $_ -MaxSamples([int]::MaxValue) | Where-Object {$_.FullFormattedMessage -like "Created*"} | `
    Select-Object VM, CreatedTime, Username, FullFormattedMessage
    $type = "From Scratch"
  }

  # If no events were found, search for events where the VM was cloned
  if (!$vmevents) {
    $vmevents = Get-VIEvent $_ -MaxSamples([int]::MaxValue) | Where-Object {$_.FullFormattedMessage -like "Clone*"} | `
    Select-Object VM, CreatedTime, Username, FullFormattedMessage
    $type = "Cloned"
  }

  # If no events were found, search for events where the VM was discovered
  if (!$vmevents) {
    $vmevents = Get-VIEvent $_ -MaxSamples([int]::MaxValue) | Where-Object {$_.FullFormattedMessage -like "Discovered*"} | `
    Select-Object VM, CreatedTime, Username, FullFormattedMessage
    $type = "Discovered"
  }

  # If no events were found, search for events where the VM was connected (typically from Backup Restores)
  if (!$vmevents) {
    $vmevents = Get-VIEvent $_ -MaxSamples([int]::MaxValue) | Where-Object {$_.FullFormattedMessage -like "* connected"} |
    Select-Object VM, CreatedTime, Username, FullFormattedMessage
    $type = "Connected"
  }

  if (!$vmevents) { $type = "Immaculate Conception" }

  # In some cases there may be more than one event found (typically from VM restores). This will include each event in the CSV for the user to interpret.
  foreach ($event in $vmevents) {

    # Prepare the entries
    $name = $event.vm.Name
    $birthday = $event.CreatedTime.ToString("MM/dd/yy")
    $parent = $event.Username
    $message = $event.FullFormattedMessage

    $Info = {} | Select-Object Name, Birthday, Parent, Type, Message
    $Info.Name = $name
    $Info.Birthday = $birthday
    $Info.Parent = $parent
    $Info.Type = $type
    $Info.Message = $message

    $VMInfo += $Info
  }
}

$VMInfo
