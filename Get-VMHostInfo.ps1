[CmdletBinding(DefaultParameterSetName = 'ByAll')]
Param (
  [Parameter(ParameterSetName = 'ByVMHost')]
  $VMHost,
  [Parameter(ParameterSetName = 'ByCluster')]
  $Cluster,
  [Parameter(ParameterSetName = 'ByDataCenter')]
  $DataCenter
)

switch ($PSCmdlet.ParameterSetName) {
  'ByVMHost' {
    $viObject = Get-VMHost $VMHost
  }
  'ByCluster' {
    $viObject = Get-Cluster $Cluster | Get-VMHost
  }
  'ByDataCenter' {
    $viObject = Get-Datacenter $DataCenter | Get-Cluster | Get-VMHost
  }
  'ByAll'{
    $viObject = Get-VMHost
  }
  Default {
    Write-Error -Message $PSItem
  }
}

$viObject | Get-View | Select-Object Name, `
@{N='ManagementIP';E={Get-VMHostNetworkAdapter -VMHost $_.Name | Where-Object ManagementTrafficEnabled | ForEach-Object IP}},
@{N='Product';E={$_.Config.Product.FullName}}, `
@{N='Build';E={$_.Config.Product.Build}}, `
@{N="SerialNo"; E={($_.Hardware.SystemInfo.OtherIdentifyingInfo | Where-Object {$_.IdentifierType.Key -eq "ServiceTag"}).IdentifierValue}}, `
@{N='Vendor';E={$_.Hardware.SystemInfo.Vendor}}, `
@{N='Model';E={$_.Hardware.SystemInfo.Model}}, `
@{N='MemoryGB';E={[Math]::Round($_.Hardware.MemorySize/1GB,2)}}, `
@{N='CPUModel';E={$_.Hardware.CpuPkg[0].Description}}, `
@{N='CPUPackages';E={$_.Hardware.CpuInfo.NumCpuPackages}}, `
@{N='CPUCores';E={$_.Hardware.CpuInfo.NumCpuCores}}, `
@{N='CPUThreads';E={$_.Hardware.CpuInfo.NumCpuThreads}}
