param(
    [string]$Topic = "orders.a",
    [string]$Broker = "localhost:19092"
)

Write-Host "Producing messages to topic '$Topic' on broker $Broker"
Write-Host "Press Ctrl+C to stop."

docker exec -i kafka-a-1 bash -c "/opt/kafka/bin/kafka-console-producer.sh --bootstrap-server $Broker --topic $Topic"
