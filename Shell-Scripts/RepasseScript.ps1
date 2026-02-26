
# Script: zabbix_vbr_job
# Author: Felipe Galeti e Nathan Schiavon
# Description: Query Veeam job information - 100% XML Cache Mode
# Updated for Veeam v13 & PowerShell 7

$pathxml = 'C:\Program Files\Zabbix Agent\scripts\TempXmlVeeam'
$days = '-31'

$ITEM = [string]$args[0]
$ID   = [string]$args[1]
$ID0  = [string]$args[2]

$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'

# --- TRADUÇÃO DE STATUS ---
function VeeamStatusReplace {
    Param ([Parameter(ValueFromPipeline = $true)]$item)
    process {
        $status = "$item".Trim()
        if ([string]::IsNullOrWhiteSpace($status)) { return "4" }
        switch -regex ($status) {
            "(?i)Failed"             { "0" }
            "(?i)Warning"            { "1" }
            "(?i)Success|None"       { "2" }
            "(?i)idle"               { "3" }
            "(?i)InProgress|Working" { "5" }
            "(?i)Pending"            { "6" }
            "(?i)Pausing"            { "7" }
            "(?i)Postprocessing"     { "8" }
            "(?i)Resuming"           { "9" }
            "(?i)Starting"           { "10" }
            "(?i)Stopped"            { "11" }
            "(?i)Stopping"           { "12" }
            "(?i)Waiting"            { "13" }
            default                  { "4" }
        }
    }
}

# --- FUNÇÃO EXPORTAÇÃO XML ---
function ExportXml {
    Param ([string]$switch, [string]$name, [string]$command, [string]$type, [string]$options)
    PROCESS {
        $path = "$pathxml\$name" + "temp.xml"; $newpath = "$pathxml\$name" + ".xml"
        try {
            if ($switch -eq "normal") {
                [System.DateTime]$Date = (Get-Date).AddDays([int]$days)
                $data = Invoke-Expression "$command -WarningAction SilentlyContinue"
                if ($options -eq "true") { $data = $data | Where-Object { $_.CreationTimeUTC -ge $Date } }
                $data | Export-Clixml $path -Depth 3
            }
            if ($switch -eq "byvm") {
                $rawJobs = Invoke-Expression "$command -WarningAction SilentlyContinue"
                $data = $rawJobs | Where-Object { $_.JobType -eq $type } | ForEach-Object {
                    $JobName = $_.Name
                    $_ | Get-VBRJobObject | Where-Object { $_.Object.Type -eq "VM" } | 
                    Select-Object @{ L = "Job"; E = { $JobName } }, Name
                }
                $data | Export-Clixml $path -Depth 3
            }
            if ($switch -eq "bytaskswithretry") {
                 $StartDate = (Get-Date).AddDays([int]$days)
                 $BackupSessions = Get-VBRBackupSession | Where-Object { $_.CreationTimeUTC -ge $StartDate }
                 $Result = foreach ($BS in ($BackupSessions | Where-Object { $_.IsRetryMode -eq $false })) {
                        [System.Collections.ArrayList]$TaskSessions = @($BS | Get-VBRTaskSession)
                        if ($BS.Result -eq "Failed") {
                            $RetrySessions = $BackupSessions | Where-Object { ($_.IsRetryMode -eq $true) -and ($_.OriginalSessionId -eq $BS.Id) }
                            foreach ($RS in $RetrySessions) {
                                foreach ($RT in ($RS | Get-VBRTaskSession)) {
                                    $Prior = @($TaskSessions | Where-Object { $_.Name -eq $RT.Name })
                                    if ($Prior.Count -gt 0) {
                                        foreach ($P in $Prior) { [void]$TaskSessions.Remove($P) }
                                    }
                                    $TaskSessions.Add($RT) | Out-Null
                                }
                            }
                        }
                        $TaskSessions | Select-Object @{N="JobName";E={$BS.JobName}}, @{N="JobId";E={$BS.JobId}}, 
                        @{N="JobResult";E={[string]$_.JobSess.Result}}, @{N="JobStart";E={$_.JobSess.CreationTimeUTC}}, name, status
                 }
                 $Result | Export-Clixml $path -Depth 3
            }
            if ($switch -eq "repos") {
                $repos = Get-VBRBackupRepository
                $repoExport = foreach ($r in $repos) {
                    try {
                        $cont = $r.GetContainer()
                        
                        $freeVal = if ($cont.CachedFreeSpace.Value -ne $null) { $cont.CachedFreeSpace.Value } else { $cont.CachedFreeSpace }
                        $totalVal = if ($cont.CachedTotalSpace.Value -ne $null) { $cont.CachedTotalSpace.Value } else { $cont.CachedTotalSpace }
                        
                        [PSCustomObject]@{
                            Name       = $r.Name
                            FreeSpace  = [int64]$freeVal
                            TotalSpace = [int64]$totalVal
                        }
                    } catch {}
                }
                $repoExport | Export-Clixml $path -Depth 2
            }
            if (Test-Path $path) { Move-Item -Path $path -Destination $newpath -Force }
        } catch { Write-Error "Erro XML $name : $_" }
    }
}

function ImportXml { Param ($item) $path = "$pathxml\$item.xml"; if (!(Test-Path $path)) { return $null }; try { Import-Clixml $path } catch { $null } }

function Get-ObjectPropertyValue {
    param(
        $Object,
        [string]$PropertyPath
    )
    if ($null -eq $Object -or [string]::IsNullOrWhiteSpace($PropertyPath)) { return $null }

    $current = $Object
    foreach ($segment in ($PropertyPath -split '\.')) {
        if ($null -eq $current) { return $null }
        $match = $current.PSObject.Properties | Where-Object { $_.Name -eq $segment } | Select-Object -First 1
        if ($null -eq $match) { return $null }
        $current = $match.Value
    }
    return $current
}

function Get-FirstNonNullValue {
    param(
        $Object,
        [string[]]$CandidatePaths
    )
    foreach ($path in $CandidatePaths) {
        $value = Get-ObjectPropertyValue -Object $Object -PropertyPath $path
        if ($null -ne $value -and "$value" -ne "") { return $value }
    }
    return $null
}

function ConvertTo-Int64Safe {
    param($Value, [int64]$Default = 0)
    if ($null -eq $Value) { return $Default }
    try { return [int64]$Value } catch { return $Default }
}

function Get-LatestSessionByJob {
    param(
        $JobIdOrName,
        $Sessions
    )
    if ($null -eq $Sessions) { return $null }
    @($Sessions | Where-Object {
        [string]$_.JobId -eq [string]$JobIdOrName -or [string]$_.JobName -eq [string]$JobIdOrName
    } | Sort-Object CreationTimeUTC -Descending) | Select-Object -First 1
}

function Get-AllJobsFromCache {
    $allJobs = @()
    $allJobs += @(ImportXml -item backupjob)
    $allJobs += @(ImportXml -item backupendpoint)
    $allJobs += @(ImportXml -item backuptape)
    return @($allJobs | Where-Object { $_ -ne $null })
}

function Get-JobByIdOrName {
    param($JobIdOrName)
    $allJobs = Get-AllJobsFromCache
    @($allJobs | Where-Object { [string]$_.Id -eq [string]$JobIdOrName -or [string]$_.Name -eq [string]$JobIdOrName }) | Select-Object -First 1
}

function Get-JobTypeSafe {
    param($Job)
    if ($null -eq $Job) { return "Unknown" }

    $jobType = Get-FirstNonNullValue -Object $Job -CandidatePaths @('JobType', 'TypeToString', 'Type')
    if ($jobType) { return [string]$jobType }

    if (Get-ObjectPropertyValue -Object $Job -PropertyPath 'JobScheduleOptions') { return 'ComputerBackup' }
    if (Get-ObjectPropertyValue -Object $Job -PropertyPath 'MediaPool') { return 'Tape' }
    return "Unknown"
}

function Get-RunStatusSafe {
    param($Job)
    if ($null -eq $Job) { return "0" }

    $isRunning = Get-FirstNonNullValue -Object $Job -CandidatePaths @('IsRunning')
    if ($isRunning -eq $true) { return "1" }

    $state = [string](Get-FirstNonNullValue -Object $Job -CandidatePaths @('LastState', 'State', 'Status'))
    if ($state -match '(?i)InProgress|Working|Running|Starting|Stopping') { return "1" }
    return "0"
}

function Convert-DateToUnix {
    param($DateValue)
    if ($null -eq $DateValue) { return "0" }
    try {
        [int64](New-TimeSpan -Start (Get-Date "01/01/1970") -End ([datetime]$DateValue)).TotalSeconds
    } catch {
        "0"
    }
}

function ConvertTo-ZabbixDiscoveryJson {
    param ($InputObject, [String[]]$Property)
    $out = foreach ($obj in $InputObject) {
        if ($obj) {
            $Element = @{ }; foreach ($P in $Property) { $Element["{#$($P.ToUpper())}"] = [String]$obj.$P }
            $Element["{#IFALIAS}"] = "ignore"; $Element["{#FSLABEL}"] = "ignore"; $Element
        }
    }
    @{ 'data' = $out } | ConvertTo-Json -Compress
}

# --- SWITCH PRINCIPAL ---
switch ($ITEM) {
    "DiscoveryBackupJobs" {
        $xml = ImportXml -item backupjob
        $xml | Where-Object { $_.JobType -match "Backup|EpAgentBackup|EpAgentPolicy" } | 
        Select-Object @{N="JOBID";E={$_.ID}}, @{N="JOBNAME";E={$_.NAME}} | ConvertTo-ZabbixDiscoveryJson -Property JOBNAME, JOBID
    }
    "DiscoveryBackupSyncJobs" {
        $xml = ImportXml -item backupjob
        $xml | Where-Object { $_.IsScheduleEnabled -eq $true -and $_.JobType -eq "BackupSync" } | 
        Select-Object @{N="JOBBSID";E={$_.ID}}, @{N="JOBBSNAME";E={$_.NAME}} | ConvertTo-ZabbixDiscoveryJson -Property JOBBSNAME, JOBBSID
    }
    "DiscoveryTapeJobs" {
        $xml = ImportXml -item backuptape
        $xml | Select-Object @{N="JOBTAPEID";E={$_.ID}}, @{N="JOBTAPENAME";E={$_.NAME}} | ConvertTo-ZabbixDiscoveryJson -Property JOBTAPENAME, JOBTAPEID
    }
    "DiscoveryEndpointJobs" {
        $xml = ImportXml -item backupendpoint
        $xml | Select-Object @{N="JOBENDPOINTID";E={$_.ID}}, @{N="JOBENDPOINTNAME";E={$_.NAME}} | ConvertTo-ZabbixDiscoveryJson -Property JOBENDPOINTNAME, JOBENDPOINTID
    }
    "DiscoveryAgentJobs" {
        $xml = ImportXml -item backupendpoint
        $xml | Select-Object @{N="JOBAGENTID";E={$_.ID}}, @{N="JOBAGENTNAME";E={$_.NAME}} | ConvertTo-ZabbixDiscoveryJson -Property JOBAGENTNAME, JOBAGENTID
    }
    "DiscoveryReplicaJobs" {
        $xml = ImportXml -item backupjob
        $xml | Where-Object { $_.IsScheduleEnabled -eq $true -and $_.JobType -eq "Replica" } | 
        Select-Object @{N="JOBREPLICAID";E={$_.ID}}, @{N="JOBREPLICANAME";E={$_.NAME}} | ConvertTo-ZabbixDiscoveryJson -Property JOBREPLICANAME, JOBREPLICAID
    }
    "DiscoveryRepo" {
        $xml = ImportXml -item backuprepo
        $xml | Select-Object @{N="REPONAME";E={$_.Name}} | ConvertTo-ZabbixDiscoveryJson -Property REPONAME
    }
    "DiscoveryBackupVmsByJobs" {
        $file = if ($ID -like "BackupSync") { "backupsyncvmbyjob" } else { "backupvmbyjob" }
        $xml = ImportXml -item $file
        $xml | Select-Object @{N="JOBNAME";E={$_.Job}}, @{N="JOBVMNAME";E={$_.NAME}} | ConvertTo-ZabbixDiscoveryJson -Property JOBVMNAME, JOBNAME
    }
    "ExportXml" {
        if (!(Test-Path $pathxml)) { New-Item -ItemType Directory -Path $pathxml -Force | Out-Null }
        if (-not (Get-Module Veeam.Backup.PowerShell)) { Import-Module Veeam.Backup.PowerShell -DisableNameChecking | Out-Null }
        if (-not (Get-VBRServerSession)) { Connect-VBRServer -Server "localhost" | Out-Null }
        ExportXml -command "Get-VBRBackupSession" -name backupsession -switch normal -options true
        ExportXml -command "Get-VBRJob" -name backupjob -switch normal
        ExportXml -command "Get-VBRTapeJob" -name backuptape -switch normal
        ExportXml -command "Get-VBRComputerBackupJob" -name backupendpoint -switch normal
        ExportXml -command "Get-VBRJob" -name backupvmbyjob -switch byvm -type Backup
        ExportXml -command "Get-VBRJob" -name backupsyncvmbyjob -switch byvm -type BackupSync
        ExportXml -name backuptaskswithretry -switch bytaskswithretry
        ExportXml -name backuprepo -switch repos
        Write-Output "1"
    }
    "ResultBackup" {
        $xml = ImportXml -item backuptaskswithretry
        $res = $xml | Where-Object { $_.jobId -eq $ID -or $_.JobName -eq $ID } | Sort-Object JobStart -Descending | Select-Object -First 1
        if (!$res) {
            $sessions = ImportXml -item backupsession
            $fallback = Get-LatestSessionByJob -JobIdOrName $ID -Sessions $sessions
            if (!$fallback) { "4" } else { ([string]$fallback.Result) | VeeamStatusReplace }
        } else {
            ([string]$res.JobResult) | VeeamStatusReplace
        }
    }
    "ResultBackupSync" {
        $xml = ImportXml -item backuptaskswithretry
        $res = $xml | Where-Object { $_.jobId -eq $ID -or $_.JobName -eq $ID } | Sort-Object JobStart -Descending | Select-Object -First 1
        if (!$res) {
            $sessions = ImportXml -item backupsession
            $fallback = Get-LatestSessionByJob -JobIdOrName $ID -Sessions $sessions
            if (!$fallback) { "4" } else { ([string]$fallback.Result) | VeeamStatusReplace }
        } else {
            ([string]$res.JobResult) | VeeamStatusReplace
        }
    }
    "VmResultBackup" {
        $xml = ImportXml -item backuptaskswithretry
        $res = $xml | Where-Object { $_.Name -eq $ID -and $_.JobName -eq $ID0 } | Sort-Object JobStart -Descending | Select-Object -First 1
        if (!$res) { "4" } else { ([string]$res.Status) | VeeamStatusReplace }
    }
    "VMResultBackup" {
        $xml = ImportXml -item backuptaskswithretry
        $res = $xml | Where-Object { $_.Name -eq $ID -and $_.JobName -eq $ID0 } | Sort-Object JobStart -Descending | Select-Object -First 1
        if (!$res) { "4" } else { ([string]$res.Status) | VeeamStatusReplace }
    }
    "VmResultBackupSync" {
        $xml = ImportXml -item backuptaskswithretry
        $res = $xml | Where-Object { $_.Name -eq $ID -and $_.JobName -eq $ID0 } | Sort-Object JobStart -Descending | Select-Object -First 1
        if (!$res) { "4" } else { ([string]$res.Status) | VeeamStatusReplace }
    }
    "VMResultBackupSync" {
        $xml = ImportXml -item backuptaskswithretry
        $res = $xml | Where-Object { $_.Name -eq $ID -and $_.JobName -eq $ID0 } | Sort-Object JobStart -Descending | Select-Object -First 1
        if (!$res) { "4" } else { ([string]$res.Status) | VeeamStatusReplace }
    }
    "ResultEndpoint" {
        $sessions = ImportXml -item backupsession
        $res = Get-LatestSessionByJob -JobIdOrName $ID -Sessions $sessions
        if (!$res) { "4" } else { ([string]$res.Result) | VeeamStatusReplace }
    }
    "ResultReplica" {
        $xml = ImportXml -item backupsession
        $res = $xml | Where-Object { $_.jobId -eq $ID -or $_.JobName -eq $ID } | Sort-Object CreationTimeUTC -Descending | Select-Object -First 1
        if (!$res) { "4" } else { ([string]$res.Result) | VeeamStatusReplace }
    }
    "ResultTape" {
        $xml = ImportXml -item backuptape
        $job = $xml | Where-Object { $_.Id -eq $ID -or $_.Name -eq $ID } | Select-Object -First 1
        if (!$job) { "4" } else {
            $status = Get-FirstNonNullValue -Object $job -CandidatePaths @('LastResult', 'Status', 'LastState')
            if ($null -eq $status) { "4" } else { ([string]$status) | VeeamStatusReplace }
        }
    }
    "RunStatus" {
        $job = Get-JobByIdOrName -JobIdOrName $ID
        Get-RunStatusSafe -Job $job
    }
    "RunningJob" {
        $allJobs = Get-AllJobsFromCache
        $running = @($allJobs | Where-Object { (Get-RunStatusSafe -Job $_) -eq "1" })
        [string]$running.Count
    }
    "LastRunTime" {
        $xml = ImportXml -item backupsession
        $res = $xml | Where-Object { $_.JobId -eq $ID -or $_.JobName -eq $ID } | Sort-Object CreationTimeUTC -Descending | Select-Object -First 1
        if ($res) { Convert-DateToUnix -DateValue $res.CreationTimeUTC } else { "0" }
    }
    "LastEndTime" {
        $xml = ImportXml -item backupsession
        $res = $xml | Where-Object { $_.JobId -eq $ID -or $_.JobName -eq $ID } | Sort-Object CreationTimeUTC -Descending | Select-Object -First 1
        if ($res) {
            $endDate = Get-FirstNonNullValue -Object $res -CandidatePaths @('EndTimeUTC', 'EndTime', 'Progress.StopTimeLocal')
            Convert-DateToUnix -DateValue $endDate
        } else {
            "0"
        }
    }
    "NextRunTime" {
        $job = Get-JobByIdOrName -JobIdOrName $ID
        if (!$job) {
            "0"
        } else {
            $nextRun = Get-FirstNonNullValue -Object $job -CandidatePaths @('NextRun', 'NextRunTimeUtc', 'NextRunTime', 'ScheduleOptions.NextRun')
            if ($null -eq $nextRun) { "0" } else { [string]$nextRun }
        }
    }
    "JobsCount" {
        $allJobs = Get-AllJobsFromCache
        [string](@($allJobs).Count)
    }
    "IncludedSize" {
        $sessions = ImportXml -item backupsession
        $res = Get-LatestSessionByJob -JobIdOrName $ID -Sessions $sessions
        if (!$res) { "0" } else {
            $included = Get-FirstNonNullValue -Object $res -CandidatePaths @('Progress.TransferedSize', 'Progress.TransferredSize', 'Progress.ProcessedSize', 'BackupStats.BackupSize', 'BackupSize', 'TransferredSize')
            [string](ConvertTo-Int64Safe -Value $included)
        }
    }
    "ExcludedSize" {
        $sessions = ImportXml -item backupsession
        $res = Get-LatestSessionByJob -JobIdOrName $ID -Sessions $sessions
        if (!$res) { "0" } else {
            $included = ConvertTo-Int64Safe -Value (Get-FirstNonNullValue -Object $res -CandidatePaths @('Progress.TransferedSize', 'Progress.TransferredSize', 'Progress.ProcessedSize', 'BackupStats.BackupSize', 'BackupSize', 'TransferredSize'))
            $source = ConvertTo-Int64Safe -Value (Get-FirstNonNullValue -Object $res -CandidatePaths @('Progress.ReadSize', 'Progress.TotalUsedSize', 'BackupStats.DataSize', 'DataSize', 'ReadSize'))
            if ($source -gt $included) { [string]($source - $included) } else { "0" }
        }
    }
    "VmCount" {
        $backup = @(ImportXml -item backupvmbyjob)
        $sync = @(ImportXml -item backupsyncvmbyjob)
        $all = @($backup + $sync)
        [string](@($all | Where-Object { $_.Job -eq $ID }).Count)
    }
    "VmCountResultBackup" {
        $xml = ImportXml -item backuptaskswithretry
        $statusFilter = if ($ID0) { [string]$ID0 } else { "Failed" }
        [string](@($xml | Where-Object { $_.JobName -eq $ID -and ([string]$_.Status) -match "(?i)$statusFilter" }).Count)
    }
    "VmCountResultBackupSync" {
        $xml = ImportXml -item backuptaskswithretry
        $statusFilter = if ($ID0) { [string]$ID0 } else { "Failed" }
        [string](@($xml | Where-Object { $_.JobName -eq $ID -and ([string]$_.Status) -match "(?i)$statusFilter" }).Count)
    }
    "RepoFree" { 
        $xml = ImportXml -item backuprepo
        $repo = $xml | Where-Object { $_.Name -eq $ID }
        if ($repo.FreeSpace -ne $null) { Write-Output $repo.FreeSpace } else { Write-Output 0 } 
    }
    "RepoCapacity" { 
        $xml = ImportXml -item backuprepo
        $repo = $xml | Where-Object { $_.Name -eq $ID }
        if ($repo.TotalSpace -ne $null) { Write-Output $repo.TotalSpace } else { Write-Output 0 } 
    }
"Type" {
    $job = Get-JobByIdOrName -JobIdOrName $ID
    Write-Output (Get-JobTypeSafe -Job $job)
    }  
    default { write-output "4" }
}
    