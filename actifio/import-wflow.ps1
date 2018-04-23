param (
[string]$csvfile = "input.csv"
)

if (Test-Path $csvfile) {
$csv = Import-Csv "input.csv"
} else {
write-output "Unable to open CSV file - $csvfile"
write-output "Use -csvfile to specify the name of the CSV file"
exit 1
}

function addwflow {
$localWFname = $args[0]
$localHostname = $args[1]
$localAppname = $args[2]
$localPathname = $args[3]
$localLabel = $args[4]
$localMountpt = $args[5]
$localPrepost = $args[6]
$localTgthost = $args[7]
$localTgtinst = $args[8]
$localTgtdbname = $args[9]

$pre_sh = $localPrepost.split("|")[0]
$pre_timeout = $localPrepost.split("|")[1]
$post_sh = $localPrepost.split("|")[2]
$post_timeout = $localPrepost.split("|")[3]

$UseScript = $False
if ($pre_sh -eq $null -or $pre_sh -eq "") {
$localScript = $null
} else {
$localScript = "phase=PRE:name="+$pre_sh+":timeout="+$pre_timeout
$UseScript = $True
}

if ($post_sh -ne $null -and $post_sh -ne "") {
if ($localScript -ne $null) {
$localScript += ";"
}
$localScript += "phase=POST:name="+$post_sh+":timeout="+$post_timeout
$UseScript = $True
}

write-output "`nAdding workflow $localWFname"
$localHost = udsinfo lshost | where-object hostname -ieq $localHostname
if ($localHost -ne $null) {
write-host "Host ID is $($localHost.id)"
$localApp = udsinfo lsapplication | where-object hostid -eq $($localHost.id) | where-object appname -ieq $localAppname | where-object pathname -ieq $localPathname
write-host "App ID is $($localApp.id)"

$rc1 = udstask mkworkflow -name $localWFname -appid $($localApp.id) -frequency monthly -time '23:59' -day 31
udstask addflowproperty -name policy -value snap $rc1.result

$rc3 = udstask mkflowitem -workflow $rc1.result -type mount
$rc4 = udstask addflowitemproperty -workflow $($rc1.result) -itemid $rc3.result -name label -value $localLabel

if ($UseScript -eq $True) {
$rc5 = udstask addflowitemproperty -workflow $($rc1.result) -itemid $rc3.result -name script -value $localScript
}

$rc6 = udstask addflowitemproperty -workflow $rc1.result -itemid $rc3.result -name appaware -value true
$rc7 = udstask addflowitemproperty -workflow $rc1.result -itemid $rc3.result -name restoreoption -value "mountpointperimage=$localMountpt"

$localTmpHost = udsinfo lshost | where-object hostname -ieq $localTgthost
if ($localTmpHost -ne $null) {
$rc8 = udstask mkflowitem -workflow $rc1.result -type host -depends $rc3.result
$rc9 = udstask addflowitemproperty -workflow $rc1.result -itemid $rc8.result -name hostid -value $localTmpHost.id
}

$rf1 = udstask mkflowitem -workflow $rc1.result -type provisioning-options -depends $rc3.result
$rf2 = udstask mkflowitem -workflow $rc1.result -type dbname -depends $rf1.result
$rf3 = udstask addflowitemvalue -workflow $rc1.result -itemid $rf2.result -value $localTgtdbname

$rf4 = udstask mkflowitem -workflow $rc1.result -type sqlinstance -depends $rf1.result
$rf5 = udstask addflowitemvalue -workflow $rc1.result -itemid $rf4.result -value $localTgtinst

# $rf6 = udstask mkflowitem -workflow $rc1.result -type username -depends $rf1.result
# $rf7 = udstask addflowitemvalue -workflow $rc1.result -itemid $rf6.result -value administrator

# $rf8 = udstask mkflowitem -workflow $rc1.result -type password -depends $rf1.result
# $rf9 = udstask addflowitemvalue -workflow $rc1.result -itemid $rf8.result -value secret

 


} else {
write-output "Unable to locate the host $localHostname"
}

}

foreach($item in $csv) {

$myDbtype = $($item.dbtype)
$myWfname = $($item.wfname)
$myAppname = $($item.appname)
$myPathname = $($item.pathname)
$mySrcHost = $($item.srchost)
$myLabel = $($item.label)
$myMountpt = $($item.mountpt)
$myPrepost = $($item.prepost)
$myTgthost = $($item.tgthost)
$myTgtinst = $($item.tgtinst)
$myTgtdbname = $($item.tgtdbname)
$myTgtuser = $($item.tgtuser)
$myTgtpasswd = $($item.tgtpasswd)

addwflow $myWfname $mySrcHost $myAppname $myPathname $myLabel $myMountpt $myPrepost $myTgthost $myTgtinst $myTgtdbname

}
