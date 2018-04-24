#
## File: extract-wflow.ps1
## Extracts all the workflow definitions to separate files - $pfx_oracle.csv $pfx_sqlserver.csv and $pfx_sqlinstance.csv
#

# Function Export-Workflow ([string]$csvdir = $null,[switch]$help, [string]$pfx = "v")

param([string]$csvdir = $null, [switch]$help, [string]$pfx = "v")

function write-not-null ($val, $label)
{
    if ($val -ne $null) {
        write-host "$label $val"
    }
}

if ($help) {
	$helpstring = @"
    NAME
      Export-Workflow
    SYNOPSIS
      Exports all the workflow definitions from an Actifio appliance
    SYNTAX
      Export-Workflow [[-csvfile] [filename]] [[-apptype] [string]] [-help]
    EXAMPLE
      C:\ > Export-Workflow -csvfile c:\temp\oracle.csv -apptype oracle
      This command extracts all the Oracle workflows
      C:\ > Export-Workflow -help
"@
    
    $helpString
    break  # Exits the function early
    }

if ($csvdir -eq $null) {
$csvdir = ".\"
}

# srch_app_type =  SQLServer  SqlInstance  Oracle
$srch_app_type = "Oracle"

$srch_app_flag = ($srch_app_type -eq "Oracle" -or $srch_app_type -eq "SQLServer" -or $srch_app_type -eq "SqlInstance") 

$WorkFlows = udsinfo lsworkflow         # Get the list of workflows
$ii = 0
$table = @()
foreach ($wf_Item in $WorkFlows) {
    $myObject = New-Object System.Object

    $app_type = $($(reportapps -a $($wf_Item.appid)).AppType)

    if ($srch_app_flag -eq $True)  {
        $ii ++
        write-host "`n--> $ii "
        $curApp = reportapps -a $($wf_Item.appid)

	    write-host "App Type = $app_type |  WF Name : $($wf_Item.name)"

        $myObject | Add-Member -type NoteProperty -name AppType -value $app_type
        $myObject | Add-Member -type NoteProperty -name WfName -value $($wf_Item.name)
        $myObject | Add-Member -type NoteProperty -name AppId -value $($wf_Item.appid)
        $myObject | Add-Member -type NoteProperty -name AppName -value $($curApp.AppName)
        $myObject | Add-Member -type NoteProperty -name Disabled -value $($wf_Item.disabled)
        $myObject | Add-Member -type NoteProperty -name SchedType -value $($wf_Item.scheduletype)
        $myObject | Add-Member -type NoteProperty -name SchedDay -value $($wf_Item.scheduleday)    
        $myObject | Add-Member -type NoteProperty -name SchedTime -value $($wf_Item.scheduletime)                  

    	write-Host "App ID : $($wf_Item.appid) | SrcHostName : $($curApp.HostName) | App Name : $($curApp.AppName) | disabled : $($wf_Item.disabled)"

        $myObject | Add-Member -type NoteProperty -name SourceHostname -value $($curApp.HostName)

# 30 = scheduled, (monthly) ; 20 = weekly ; 10 = daily    
    	write-Host "scheduletype : $($wf_Item.scheduletype)"
# if 10, it's null    
    	write-Host "scheduleday : $($wf_Item.scheduleday)"
    	write-Host "scheduletime : $($wf_Item.scheduletime)"

    	$curWorkFlow = udsinfo lsworkflow $($wf_Item.id)
    	write-Host "Workflow Id = $($curWorkFlow.id)"

    	if ($($curWorkFlow.tasks) -ne $null) {
    		[xml]$TaskXML = $($curWorkFlow.tasks) 
# $TaskXML
#    write-Host "WF Name : $($TaskXML.workflow.name)"
#    write-Host "xApp ID : $($TaskXML.workflow.appid)"
			
            write-not-null $($TaskXML.workflow.policy)              "policy : "
            write-not-null $($TaskXML.workflow.mount.appaware)      "appaware : "
            write-not-null $($TaskXML.workflow.mount.label)         "label : "

            $myObject | Add-Member -type NoteProperty -name Label -value $($TaskXML.workflow.mount.label)
            $myObject | Add-Member -type NoteProperty -name Policy -value $($TaskXML.workflow.policy)
            $myObject | Add-Member -type NoteProperty -name AppAware -value $($TaskXML.workflow.mount.appaware)
            $myObject | Add-Member -type NoteProperty -name prescript -value $null
            $myObject | Add-Member -type NoteProperty -name postscript -value $null  

            if ($($TaskXML.workflow.mount.script) -ne $null) {
              write-Host "`nscript : $($TaskXML.workflow.mount.script)"

    		  $($TaskXML.workflow.mount.script) -split ";" | foreach-object { 
                write-host $_ 
                if ( $_ -like "*PRE*" ) {
                    $myObject.prescript = $_
                    }
                elseif ( $_ -like "*POST*" ) {
                    $myObject.postscript = $_
                    }
                }
    		  write-host "`n"
    		} ## end-if

            ## $curHostId = 
            $curHost = udsinfo lshost | where { $_.id -eq $($TaskXML.workflow.mount.host.hostid) } 
            write-Host "hostid : $($TaskXML.workflow.mount.host.hostid) , Hostname = $($curHost.hostname)"

            $myObject | Add-Member -type NoteProperty -name TargetHostname -value $($curHost.hostname)

            if ($app_type -eq "Oracle") {

                write-not-null $TaskXML.workflow.mount."provisioning-options".databasesid."#text"   "db sid : "
                write-not-null $TaskXML.workflow.mount."provisioning-options".username."#text"      "username : " 
                write-not-null $TaskXML.workflow.mount."provisioning-options".orahome."#text"       "oracle home : " 
                write-not-null $TaskXML.workflow.mount."provisioning-options".tnsadmindir."#text"   "tns admindir : "  

                write-not-null $TaskXML.workflow.mount."provisioning-options".totalmemory."#text"   "total memory : " 
                write-not-null $TaskXML.workflow.mount."provisioning-options".sgapct."#text"        "sga pct : " 
                write-not-null $TaskXML.workflow.mount."provisioning-options".processes."#text"     "processes : " 
                write-not-null $TaskXML.workflow.mount."provisioning-options".rrecovery."#text"     "rrecovery : " 

                $myObject | Add-Member -type NoteProperty -name dbsid -value $TaskXML.workflow.mount."provisioning-options".databasesid."#text"
                $myObject | Add-Member -type NoteProperty -name username -value $TaskXML.workflow.mount."provisioning-options".username."#text"
                $myObject | Add-Member -type NoteProperty -name orahome -value $TaskXML.workflow.mount."provisioning-options".orahome."#text"
                $myObject | Add-Member -type NoteProperty -name tnsadmindir -value $TaskXML.workflow.mount."provisioning-options".tnsadmindir."#text"
                $myObject | Add-Member -type NoteProperty -name processes -value $TaskXML.workflow.mount."provisioning-options".processes."#text"
                $myObject | Add-Member -type NoteProperty -name totalmemory -value $TaskXML.workflow.mount."provisioning-options".totalmemory."#text"
                $myObject | Add-Member -type NoteProperty -name sgapct -value $TaskXML.workflow.mount."provisioning-options".sgapct."#text"
                $myObject | Add-Member -type NoteProperty -name rrecovery -value $TaskXML.workflow.mount."provisioning-options".rrecovery."#text"

            } elseif ($app_type -eq "SQLServer") {
                $myObject | Add-Member -type NoteProperty -name sqlinstance -value $TaskXML.workflow.mount."provisioning-options".sqlinstance."#text"
                $myObject | Add-Member -type NoteProperty -name dbname -value $TaskXML.workflow.mount."provisioning-options".dbname."#text"
                $myObject | Add-Member -type NoteProperty -name recover -value $TaskXML.workflow.mount."provisioning-options".recover."#text"
            } else {
### SqlInstance
                $members = $($wf_Item.members)

                write-host "List of members = $members" 
                $myObject | Add-Member -type NoteProperty -name sqlinstance -value $TaskXML.workflow.mount."provisioning-options".sqlinstance."#text"
                $myObject | Add-Member -type NoteProperty -name cgname -value $TaskXML.workflow.mount."provisioning-options".ConsistencyGroupName."#text"
                $myObject | Add-Member -type NoteProperty -name recover -value $TaskXML.workflow.mount."provisioning-options".recover."#text"
                $myObject | Add-Member -type NoteProperty -name dbprefix -value $TaskXML.workflow.mount."provisioning-options".dbnameprefix."#text"
            }

        $table += $myObject
    	
        }   ## end-if curWorkFlow.tasks
    
    }   ## end-if app_type    
        
}   ## end-foreach

$table | where-object { $_.AppType -eq "Oracle" } | export-csv $csvdir$pfx_oracle.csv -NoTypeInformation -Delimiter ";"
$table | where-object { $_.AppType -eq "SQLServer" } | export-csv $csvdir$pfx_sqlserver.csv -NoTypeInformation -Delimiter ";"
$table | where-object { $_.AppType -eq "SqlInstance" } | export-csv $csvdir$pfx_sqlinstance.csv -NoTypeInformation -Delimiter ";"
