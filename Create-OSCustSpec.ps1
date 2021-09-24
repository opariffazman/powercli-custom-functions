$osCustSpecInfo = @{
  Name           = "WINOSCustomSpec"
  Type           = "Persistent"
  Description    = "Standard Os Customization Spec for Windows Server"
  AutoLogonCount = "1"
  ChangeSid      = $true
  FullName       = "administrator"
  OrgName        = "petronas"
  TimeZone       = "Singapore"
  Workgroup      = "WORKGROUP"
  AdminPassword  = Read-Host -Prompt "AdminPassword"
  NamingScheme   = "vm"
  ErrorAction    = "Stop"
}

Write-Verbose "Creating OS Customization Specifications" -Verbose
New-OSCustomizationSpec @osCustSpecInfo
Start-Sleep -Seconds 1

Write-Verbose "Removing OS Customization Nic Mapping" -Verbose
Get-OSCustomizationNicMapping -OSCustomizationSpec 'WINOSCustomSpec' | Remove-OSCustomizationNicMapping -Confirm:$false
