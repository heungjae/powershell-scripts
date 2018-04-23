#
## File: delete-wflow.ps1
#

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


function delwflow {
$localWFname = $args[0]
write-output "`nRemoving workflow $localWFname"
$rc = udsinfo lsworkflow $localWFname
if ($rc -ne $null) {
write-output "`nRemoving workflow $localWFname "
udstask rmworkflow $rc.id
} else {
write-output "Unable to locate $localWFname !!"
}
}


foreach($item in $csv) {

delwflow $myWfname

}
