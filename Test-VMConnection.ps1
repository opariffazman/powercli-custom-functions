[CmdletBinding(DefaultParameterSetName = 'ByVMHost')]
Param (
  [Parameter(ValueFromPipeline = $true, ParameterSetName = 'ByVM')]
  $VM,
  [Parameter(ValueFromPipeline = $true, ParameterSetName = 'ByVMHost')]
  $VMHost
)

switch ($PSCmdlet.ParameterSetName) {
  'ByVM' {
    $viObject = Get-VM $VM | Where-Object {$_.Guest.State -eq 'Running'}
  }
  'ByVMHost' {
    $viObject = Get-VMHost $VMHost | Get-VM | Where-Object {$_.Guest.State -eq 'Running'}
  }
  Default {
    Write-Error -Message $PSItem
  }
}

$vmPingInfo = @()
if ($viObject) {
  $vmPingInfo += $viObject | ForEach-Object {
    $dnsName = $_.Guest.HostName
    if ($dnsName -match 'PETRO') {
      # for vm that has joined petronas domain
      try { $pingTest = Test-Connection $dnsName -Count 1 -Quiet -ErrorAction Stop }
      catch { Write-Warning $PSItem }
      $ipAddress = Test-Connection $dnsName -Count 1 -ErrorAction SilentlyContinue | ForEach-Object IPV4Address | ForEach-Object IPAddressToString
    }
    else {
      # for vm that hasn't join domain, try ping using network adapter that doesn't match backup
      $niclist = $_.Guest.Nics
      $niclist | ForEach-Object {
        # determine the network adapter first
        if ($_.NetworkName -match 'Network') {
          # for vm using default network
          $vNic = $nic.Device.NetworkName
        }
        else {
          $vPort = 'DistributedVirtualPortgroup-' + $_.Device.NetworkName
          $vNic = (Get-VDPortgroup -Id $vPort -ErrorAction 'SilentlyContinue').Name
        }

        if ($vNic -notmatch 'BKP|Backup' -and $_.IPAddress[0] -ne '$null') {
          try { $pingTest = Test-Connection $_.IPAddress[0] -Count 1 -Quiet -ErrorAction Stop }
          catch { Write-Warning $PSItem }
        }
        else {
          # skips other adapters
        }
      }
    }

    $Info = { } | Select-Object Name, HostName, IPAddress, ConnectionStatus
    $Info.Name = $_.Name
    $Info.HostName = $dnsName
    $Info.IPAddress = $ipAddress
    $Info.ConnectionStatus = $pingTest
    $Info
  }
  $vmPingInfo
}
else {
  Write-Verbose "Virtual Machine discovered: 'NULL'" -Verbose
}
