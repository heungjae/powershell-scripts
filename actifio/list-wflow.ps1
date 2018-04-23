# 
## File: list-wflow.ps1
#
param (
[string]$csvfile = "input.csv"
)

if (Test-Path $csvfile) {
$csv = Import-Csv $csvfile -delimiter ";"
} else {
write-output "Unable to open CSV file - $csvfile"
write-output "Use -csvfile to specify the name of the CSV file"
exit 1
}

function write-not-null ($val, $label)
{
    if ($val -ne $null) {
        write-output "$label $val"
    }
}


function listwflow {

$localWFname = $args[0]

write-output "`nListing workflow $localWFname"
$rc = udsinfo lsworkflow $localWFname
if ($rc -ne $null) {

write-output "workflow name: $($rc.name)"
write-output "modified: $($rc.modifydate)"
write-output "scheduleday: $($rc.scheduleday)"
write-output "scheduled: $($rc.scheduletime)"
write-output "scheduletype: $($rc.scheduletype)"
write-output "scheduled: $($rc.scheduled)"
write-output "disabled: $($rc.disabled)"
write-output "workflow id: $($rc.workflowid)"
write-output "appid: $($rc.appid)"
 
$app_type = $($(reportapps -a $($rc.appid)).AppType)
write-output "apptype: $app_type"

[xml]$TaskXML = $($rc.tasks) 

write-not-null $($TaskXML.workflow.policy)              "policy : "
write-not-null $($TaskXML.workflow.mount.appaware)      "appaware : "
write-not-null $($TaskXML.workflow.mount.label)         "label : "

if ($($TaskXML.workflow.mount.script) -ne $null) {
	$($TaskXML.workflow.mount.script) -split ";" | foreach-object { 
	if ( $_ -like "*PRE*" ) {
    	write-not-null $_ "prescript : "
        }
    elseif ( $_ -like "*POST*" ) {
        write-not-null $_ "postscript : "
        }  ## end elseif
    }  ## foreach-object
	}  ## end if

$curHost = udsinfo lshost | where { $_.id -eq $($TaskXML.workflow.mount.host.hostid) } 
write-Host "hostid : $($TaskXML.workflow.mount.host.hostid) , Hostname = $($curHost.hostname)"

if ($app_type -eq "Oracle") {
	write-not-null $TaskXML.workflow.mount."provisioning-options".databasesid."#text"   "db sid : "
	write-not-null $TaskXML.workflow.mount."provisioning-options".username."#text"      "username : " 
	write-not-null $TaskXML.workflow.mount."provisioning-options".orahome."#text"       "oracle home : " 
	write-not-null $TaskXML.workflow.mount."provisioning-options".tnsadmindir."#text"   "tns admindir : "  

	write-not-null $TaskXML.workflow.mount."provisioning-options".totalmemory."#text"   "total memory : " 
	write-not-null $TaskXML.workflow.mount."provisioning-options".sgapct."#text"        "sga pct : " 
	write-not-null $TaskXML.workflow.mount."provisioning-options".processes."#text"     "processes : " 
	write-not-null $TaskXML.workflow.mount."provisioning-options".rrecovery."#text"     "rrecovery : " 
} elseif ($app_type -eq "SQLServer") {
	write-not-null $TaskXML.workflow.mount."provisioning-options".sqlinstance."#text"   "sql instance : "
	write-not-null $TaskXML.workflow.mount."provisioning-options".dbname."#text"   		"dbname : "
	write-not-null $TaskXML.workflow.mount."provisioning-options".recover."#text"   	"recover : "
} else {
### SqlInstance
	write-not-null $TaskXML.workflow.mount."provisioning-options".sqlinstance."#text"   "sql instance : "
	write-not-null $TaskXML.workflow.mount."provisioning-options".cgname."#text"   		"cgname : "
	write-not-null $TaskXML.workflow.mount."provisioning-options".recover."#text"   	"recover : "
	write-not-null $TaskXML.workflow.mount."provisioning-options".dbnameprefix."#text"  "dbnameprefix : "
}  ## end if app_type

} else {
write-output "Unable to locate $localWFname !!"
}

}

foreach ($item in $csv) {
listwflow $($item.wfName)
}
