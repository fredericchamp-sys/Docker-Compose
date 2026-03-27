param(
    [string]$Topic = "orders.a"
)

# List of brokers per DC
$DCs = @{
    "DC-A" = @("kafka-a-1:9092","kafka-a-2:9094","kafka-a-3:9095")
    "DC-B" = @("kafka-b-1:9092","kafka-b-2:9094","kafka-b-3:9095")
    "DC-C" = @("kafka-c-1:9092","kafka-c-2:9094","kafka-c-3:9095")
}

Write-Host "Monitoring replication lag for topic '$Topic' (press Ctrl+C to stop)..."

while ($true) {
    Write-Host "------ $(Get-Date) ------"
    foreach ($DC in $DCs.Keys) {
        $TotalOffset = 0
        foreach ($Broker in $DCs[$DC]) {
            try {
                $Offset = docker exec kafka-a-1 bash -c "/opt/kafka/bin/kafka-run-class.sh kafka.tools.GetOffsetShell --broker-list $Broker --topic $Topic --time -1" `
                    | ForEach-Object { ($_ -split ':')[2] } `
                    | Measure-Object -Sum `
                    | Select-Object -ExpandProperty Sum
                if (-not $Offset) { $Offset = 0 }
                $TotalOffset += [int]$Offset
            } catch {
                $TotalOffset += 0
            }
        }
        Write-Host "$DC total offset: $TotalOffset"
    }
    Start-Sleep -Seconds 5
}
