Get-View -ViewType VirtualMachine | ForEach-Object {
  $name = $_.name
  $_.Config.Hardware.Device | Where-Object {$_ -is [vmware.vim.virtualcdrom]} | ForEach-Object {

    if($_.Connectable.Connected -eq $true) {

      Write-Progress -Activity "Collecting VMs" -CurrentOperation $name
      $_ | Select-Object @{e={$Name};n='VM'},@{n='Label';e={$_.DeviceInfo.Label}},@{n='Summary';e={$_.DeviceInfo.Summary}}

    }
  }
}
