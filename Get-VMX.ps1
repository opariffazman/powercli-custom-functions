[CmdletBinding(DefaultParameterSetName = 'ByAll')]
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
    $viObject = Get-VM
  }
  Default {
    Write-Error -Message $PSItem
  }
}

$destination = "$PSScriptRoot\vmx"

try {
  New-Item -ItemType Directory -Path $destination -Verbose -ErrorAction Stop | Out-Null
}
catch {
  Write-Warning $PSItem.Exception.Message
}

$viObject | ForEach-Object {
  $vmview = $_ | Get-View
  $vmxfile = $vmview.Config.Files.VmPathName
  $dsName = $vmxfile.split(" ")[0].TrimStart("[").TrimEnd("]")

  Write-Verbose "Downloading $vmxfile" -Verbose

  New-PSDrive -Name ds -PSProvider 'VimDatastore' -Root '/' -Location (Get-Datastore $dsName) | Out-Null

  Copy-DatastoreItem -Item "ds:\$($vmxfile.split(']')[1].TrimStart(' '))" -Destination $destination

  Remove-PSDrive -Name ds | Out-Null
}
