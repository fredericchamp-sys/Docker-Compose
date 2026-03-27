param(
    [string]$Topic = "orders.a",
    [string]$Broker = "kafka-b-1:9092",
    [string]$Group = "monitor-group"
)

Write-Host "Consuming messages from topic '$Topic' on broker $Broker"
Write-Host "Consumer group: $Group"
Write-Host "Press Ctrl+C to stop."

docker exec -i kafka-b-1 bash -c "/opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server $Broker --topic $Topic --group $Group --from-beginning"
