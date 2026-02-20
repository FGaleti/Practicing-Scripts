"VmResultBackup" {
        $query = veeam-backuptask-unique -ID $ID0 -jobtype jobname
        $result = $query | Where-Object { $_.Name -like "$ID" }
        
        if (!$result) { 
            write-output "4" 
        } else {
            # Ajuste para ler Status mesmo que não tenha a subpropriedade .Value
            $statusRaw = if ($null -ne $result.Status.Value) { $result.Status.Value } else { $result.Status }
            
            if ([string]::IsNullOrWhiteSpace($statusRaw)) {
                write-output "4"
            } else {
                $query4 = "$statusRaw" | VeeamStatusReplace
                write-output "$query4"
            }
        }
    }