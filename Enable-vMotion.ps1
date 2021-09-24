[CmdletBinding(DefaultParameterSetName = 'ByVM')]
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

# Initial variables
$viServer = $global:DefaultVIServer.Name
$Credential = Get-Credential -Message 'Provide petronas\a- id'
$enableMethod = "RelocateVM_Task"

$viObject | ForEach-Object {
  $vmMoRef = $_.ExtensionData.MoRef.Value

  # vSphere MOB URL to private enableMethods
  $mob_url = "https://$viServer/mob/?moid=AuthorizationManager&method=enableMethods"

  # Ingore SSL Warnings
  add-type -TypeDefinition  @"
      using System.Net;
      using System.Security.Cryptography.X509Certificates;
      public class TrustAllCertsPolicy : ICertificatePolicy {
          public bool CheckValidationResult(
              ServicePoint srvPoint, X509Certificate certificate,
              WebRequest request, int certificateProblem) {
              return true;
          }
      }
"@
  [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

  # Initial login to vSphere MOB using GET and store session using $vmware variable
  $results = Invoke-WebRequest -Uri $mob_url -SessionVariable vmware -Credential $credential -Method GET

  # Extract hidden vmware-session-nonce which must be included in future requests to prevent CSRF error
  # Credit to https://blog.netnerds.net/2013/07/use-powershell-to-keep-a-cookiejar-and-post-to-a-web-form/ for parsing vmware-session-nonce via Powershell
  if ($results.StatusCode -eq 200) {
    $null = $results -match 'name="vmware-session-nonce" type="hidden" value="?([^\s^"]+)"'
    $sessionnonce = $matches[1]
  }
  else {
    Write-host "Failed to login to vSphere MOB"
    exit 1
  }

  # The POST data payload must include the vmware-session-nonce variable + URL-encoded
  $body = @"
vmware-session-nonce=$sessionnonce&entity=%3Centity+type%3D%22ManagedEntity%22+xsi%3Atype%3D%22ManagedObjectReference%22%3E$vmMoRef%3C%2Fentity%3E%0D%0A&method=%3Cmethod%3E$enableMethod%3C%2Fmethod%3E
"@

  Write-Verbose "$($_.Name) - Enabling Method $enableMethod" -Verbose
  # Second request using a POST and specifying our session from initial login + body request
  $results = Invoke-WebRequest -Uri $mob_url -WebSession $vmware -Method POST -Body $body

  # Logout out of vSphere MOB
  $mob_logout_url = "https://$viServer/mob/logout"
  Invoke-WebRequest -Uri $mob_logout_url -WebSession $vmware -Method GET | Out-Null
}
