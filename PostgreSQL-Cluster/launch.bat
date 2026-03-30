rem docker compose build

docker compose up -d etcd-poc01 etcd-poc02 etcd-poc05 pg-primary pg-replica pgbouncer haproxy prometheus grafana
