# Pre-requisites

## VMWare PowerCLI Modules Installed

```powershell
Install-Module -Name VMware.PowerCLI -Scope CurrentUser
```

## Connected to VIServer

```powershell
Connect-VIServer -Server $vCenterIPorFQDN
```

These script functions/cmdlets have been thoroughly tested when being used against a vSphere vCenter.

## Invalid certificate Ignored

```powershell
Set-PowerCLIConfiguration -Scope AllUsers -ParticipateInCeip $false -InvalidCertificateAction Ignore
```

## Full Script Usage Information

These PowerCLI scripts are made to behave as VMWare PowerCLI cmdlets as similar as possible.

Alternatively, these scripts were made to complement and fill some void left by VMWare PowerCLI developers.

Download and extract this .zip package and change directory to main folder to run these much like functions/cmdlets.
