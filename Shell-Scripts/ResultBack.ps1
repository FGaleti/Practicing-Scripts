"ResultBackup" {
        $xml = ImportXml -item backuptaskswithretry
        $query1 = $xml | Where-Object { $_.jobId -like "$ID" } | Sort-Object JobStart -Descending | Select-Object -First 1
        
        # Tenta pegar .Value, se não existir (XML), pega o objeto direto
        $statusRaw = if ($null -ne $query1.JobResult.Value) { $query1.JobResult.Value } else { $query1.JobResult }
        
        if ([string]::IsNullOrWhiteSpace($statusRaw)) { 
            write-output "4" 
        } else {
            $query4 = "$statusRaw" | VeeamStatusReplace
            write-output "$query4"
        }
    }