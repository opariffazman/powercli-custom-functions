Param (
  [Parameter(Mandatory = $true,ValueFromPipeline = $true)]
  $VM,
  $CostCenter,
  $CompletionDate,
  $Requester,
  $Custodian,
  $PSR,
  $ProjectName,
  $eCIRFNumber,
  $SRNumber
)

$VMS = Get-VM $VM

$VMS | ForEach-Object {
  $VMName = $_.Name
  if($CostCenter){ Set-Annotation -Entity $VMName -CustomAttribute 'Cost Center' -Value $CostCenter -Verbose | Out-Null }
  if($CompletionDate){ Set-Annotation -Entity $VMName -CustomAttribute 'Completion Date' -Value $CompletionDate -Verbose | Out-Null }
  else { Set-Annotation -Entity $VMName -CustomAttribute 'Completion Date' -Value (Get-date) -Verbose | Out-Null}
  if($requester){ Set-Annotation -Entity $VMName -CustomAttribute 'Requester' -Value $requester -Verbose | Out-Null }
  if($custodian){ Set-Annotation -Entity $VMName -CustomAttribute 'Custodian' -Value $custodian -Verbose | Out-Null }
  if($PSR){ Set-Annotation -Entity $VMName -CustomAttribute 'PSR' -Value $PSR -Verbose | Out-Null }
  if($ProjectName){ Set-Annotation -Entity $VMName -CustomAttribute 'Project Name' -Value $ProjectName -Verbose | Out-Null }
  if($eCIRFNumber){ Set-Annotation -Entity $VMName -CustomAttribute 'eCIRF Number' -Value $eCIRFNumber -Verbose | Out-Null }
  if($SRNumber){ Set-Annotation -Entity $VMName -CustomAttribute 'SR Number' -Value $SRNumber -Verbose | Out-Null }
}
