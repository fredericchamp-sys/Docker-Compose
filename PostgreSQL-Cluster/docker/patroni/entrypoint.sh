#!/bin/bash



set -e

PATRONI_CONFIG=${PATRONI_CONFIG:-/etc/patroni/patroni.yml}
PGBOUNCER_CONFIG=${PGBOUNCER_CONFIG:-/etc/pgbouncer/pgbouncer.ini}
PG_ROLE=${PG_ROLE:-primary}
LATE_REPLICA_DELAY=${LATE_REPLICA_DELAY:-86400}

echo "==> Starting node: ${PATRONI_NAME} | role: ${PG_ROLE}"

# Remove whatever Docker created at this path (file or directory)
rm -rf "$PATRONI_CONFIG"
mkdir -p /etc/patroni

echo "==> Generating ${PATRONI_CONFIG} from environment"

# Build late replica block conditionally
LATE_REPLICA_BLOCK=""
if [ "$PG_ROLE" = "late_replica" ]; then
  LATE_REPLICA_BLOCK="  recovery_conf:
    recovery_min_apply_delay: \"${LATE_REPLICA_DELAY}s\""
fi

NOFAILOVER=false
NOSYNC=false
if [ "$PG_ROLE" = "late_replica" ]; then
  NOFAILOVER=true
  NOSYNC=true
fi

cat > "$PATRONI_CONFIG" <<EOF
scope: ${PATRONI_SCOPE:-pg-ha-cluster}
name: ${PATRONI_NAME:-patroni-node}

restapi:
  listen: ${PATRONI_RESTAPI_LISTEN:-0.0.0.0:8008}
  connect_address: ${PATRONI_RESTAPI_CONNECT_ADDRESS:-patroni-node:8008}

etcd3:
  hosts: ${PATRONI_ETCD3_HOSTS:-etcd-poc01:2379,etcd-poc02:2379,etcd-poc05:2379}

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      use_slots: true
      parameters:
        wal_level: replica
        hot_standby: "on"
        wal_keep_size: 512
        max_wal_senders: 10
        max_replication_slots: 10
        wal_log_hints: "on"
        archive_mode: "off"
        max_connections: 200
        shared_buffers: 256MB
        effective_cache_size: 768MB
        work_mem: 16MB
        maintenance_work_mem: 256MB
        checkpoint_completion_target: 0.9
        log_min_duration_statement: 1000
        log_checkpoints: "on"
        log_connections: "on"
        log_disconnections: "on"
        shared_preload_libraries: "pg_stat_statements"
  initdb:
    - encoding: UTF8
    - data-checksums
  pg_hba:
    - host replication ${PATRONI_REPLICATION_USERNAME:-replicator} 0.0.0.0/0 scram-sha-256
    - host all all 0.0.0.0/0 scram-sha-256
  users:
    ${PATRONI_REPLICATION_USERNAME:-replicator}:
      password: "${PATRONI_REPLICATION_PASSWORD:-replicator_pass}"
      options:
        - replication
    rewind_user:
      password: "${PATRONI_REWIND_PASSWORD:-rewind_pass}"
      options:
        - login
        - superuser

postgresql:
  listen: ${PATRONI_POSTGRESQL_LISTEN:-0.0.0.0:5432}
  connect_address: ${PATRONI_POSTGRESQL_CONNECT_ADDRESS:-patroni-node:5432}
  data_dir: /var/lib/postgresql/data
  bin_dir: /usr/lib/postgresql/16/bin
  pgpass: /tmp/pgpass
  authentication:
    replication:
      username: ${PATRONI_REPLICATION_USERNAME:-replicator}
      password: "${PATRONI_REPLICATION_PASSWORD:-replicator_pass}"
    superuser:
      username: ${PATRONI_SUPERUSER_USERNAME:-postgres}
      password: "${PATRONI_SUPERUSER_PASSWORD:-postgres}"
    rewind:
      username: rewind_user
      password: "${PATRONI_REWIND_PASSWORD:-rewind_pass}"
${LATE_REPLICA_BLOCK}

tags:
  nofailover:    ${NOFAILOVER}
  noloadbalance: false
  nosync:        ${NOSYNC}
  clonefrom:     false
EOF

echo "==> patroni.yml written"

echo "==> Waiting for ETCD..."
ETCD_HOST=$(echo "${PATRONI_ETCD3_HOSTS:-etcd-poc01:2379}" | cut -d',' -f1 | cut -d':' -f1)
ETCD_PORT=$(echo "${PATRONI_ETCD3_HOSTS:-etcd-poc01:2379}" | cut -d',' -f1 | cut -d':' -f2)
RETRIES=0
until nc -z "$ETCD_HOST" "$ETCD_PORT" 2>/dev/null; do
  RETRIES=$((RETRIES + 1))
  if [ "$RETRIES" -ge 30 ]; then
    echo "ERROR: ETCD not reachable after 90s, aborting"
    exit 1
  fi
  echo "  ETCD ${ETCD_HOST}:${ETCD_PORT} not ready, retrying in 3s... (${RETRIES}/30)"
  sleep 3
done
echo "==> ETCD is up, starting Patroni"

exec patroni "$PATRONI_CONFIG"
