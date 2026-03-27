#!/usr/bin/env bash
docker compose up -d
echo "Waiting 20s for Kafka clusters to start..."
sleep 20
docker ps
