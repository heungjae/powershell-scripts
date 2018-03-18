Overview
========

Useful one-liner:
```
Start-VM <Mounted VM name> -Confirm:$false 
Stop-VM <VM name> -Confirm:$false 
```

To find the NIC MAC address:
```
Get-VM <VM name> | Get-NetworkAdapter | Select-Object MacAddress
```
