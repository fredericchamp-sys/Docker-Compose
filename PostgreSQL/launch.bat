rem docker compose build

docker compose --env-file .env-champ up -d etcd-poc01 etcd-poc02 etcd-poc05 pg-primary pg-replica pgbouncer haproxy prometheus grafana
