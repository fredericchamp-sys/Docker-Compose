# PostgreSQL HA Cluster – Docker Compose

> Very Large Database Design · Read Replica + 24h Late Replica  
> Patroni · ETCD · PGBouncer · HAProxy

---

## Architecture

```
                     ┌─────────────────────────────────────────┐
  Client Apps        │         PRD NET  172.20.0.0/24          │
  ─────────────      │                                         │
  Port 6432 (RW) ───►│  haproxy-prd  ──► pgbouncer-poc01      │
  Port 6433 (RO) ───►│               ──► pgbouncer-poc03       │
  Port 6435  (DR)───►│  haproxy-dr   ──► pgbouncer-poc02       │
  Port 6436  (LR)───►│  haproxy-lr   ──► pgbouncer-poc04       │
                     └──────────────┬──────────────────────────┘
                                    │
                     ┌──────────────▼──────────────────────────┐
                     │       PRD CLS  172.21.0.0/24            │
                     │                                         │
                     │  poc01 (RW primary)   172.21.0.21:5432  │
                     │  poc03 (RO replica)   172.21.0.23:5432  │
                     │  poc02 (DR replica)   172.21.0.22:5432  │
                     │  poc04 (LR 24h lag)   172.21.0.24:5432  │
                     │                                         │
                     │  Patroni REST   :8008  (all nodes)      │
                     │  Patroni Health :8404  (all nodes)      │
                     │                                         │
                     │  ETCD Quorum:                           │
                     │    etcd-poc01  172.21.0.11              │
                     │    etcd-poc02  172.21.0.12              │
                     │    etcd-poc05  172.21.0.15 (dedicated)  │
                     │  ETCD No-Vote:                          │
                     │    etcd-poc03  172.21.0.13              │
                     │    etcd-poc04  172.21.0.14              │
                     └─────────────────────────────────────────┘
                     
                     HeartBeat Net  172.22.0.0/24  (ETCD peers)
                     Backup Net     172.23.0.0/24  (pg_basebackup)
                     Mgmt Net       172.24.0.0/24  (Prometheus/Grafana)
```

## Host Port Map

| Host Port | Service           | Purpose                   |
|-----------|-------------------|---------------------------|
| **6432**  | haproxy-prd       | Read-Write (primary)      |
| **6433**  | haproxy-prd       | Read-Only (replicas)      |
| 6434      | haproxy-ro        | RO-only load balancer     |
| 6435      | haproxy-dr        | DR replica RW             |
| 6436      | haproxy-lr        | Late replica (24h lag) RO |
| 8008      | pg-poc01 Patroni  | REST API                  |
| 2379      | etcd-poc01        | ETCD client               |
| 9090      | Prometheus        | Metrics scrape            |
| 3000      | Grafana           | Dashboards                |

---

## Quick Start

```bash
# 1. Prerequisites: Docker 24+ and Docker Compose v2
docker --version && docker compose version

# 2. Configure secrets
cp .env.example .env
$EDITOR .env   # fill all CHANGE_ME values

# 3. Build the Patroni image
docker compose build

# 4. Start ETCD first, then PostgreSQL nodes
docker compose up -d etcd-poc01 etcd-poc02 etcd-poc05
sleep 10

# 5. Bring up the primary
docker exec etcd-poc01 etcdctl --endpoints=http://etcd-poc01:2379,http://etcd-poc02:2379,http://etcd-poc05:2379 endpoint health

docker compose up -d pg-primary


sleep 30

# 6. Bring up replicas (they auto-clone from primary via pg_basebackup)
docker compose up -d pg-replica

# 7. Start load balancers
docker compose up -d pgbouncer haproxy


# 8. Start monitoring
docker compose up -d prometheus grafana

# 9. Verify cluster health
docker exec cs-v1-pgs-poc01 patronictl -c /etc/patroni/patroni.yml list
```

---

## Verify the Cluster
# Patroni cluster topology
docker exec pg-primary patronictl -c /etc/patroni/patroni.yml list

# Write via PGBouncer (port 6432)
psql "postgresql://postgres:postgres@localhost:6432/postgres?sslmode=disable" -c "SELECT pg_is_in_recovery(), version();"

# Read via HAProxy RO (port 6433)
psql "postgresql://postgres:postgres@localhost:6433/postgres?sslmode=disable" -c "SELECT pg_is_in_recovery();"

# Grafana dashboard
open http://localhost:3000   # admin / admin (first login)




```bash
# Patroni topology
docker exec cs-v1-pgs-poc01 patronictl -c /etc/patroni/patroni.yml list

# ETCD quorum health
docker exec cs-v1-etcd-poc01 etcdctl endpoint health \
  --endpoints=http://172.21.0.11:2379,http://172.21.0.12:2379,http://172.21.0.15:2379

# Write via HAProxy RW port
psql "postgresql://postgres:YOURPASS@localhost:6432/postgres?sslmode=disable" \
  -c "CREATE TABLE test (id serial, val text);"

# Read via RO port
psql "postgresql://postgres:YOURPASS@localhost:6433/postgres?sslmode=disable" \
  -c "SELECT * FROM test;"

# Confirm late replica lag (should be ~24h after steady state)
psql "postgresql://postgres:YOURPASS@localhost:6436/postgres?sslmode=disable" \
  -c "SELECT now() - pg_last_xact_replay_timestamp() AS lag;"

# Grafana dashboards
open http://localhost:3000   # admin / GRAFANA_PASSWORD from .env
```

---

## Failover Test

```bash
# Simulate primary failure
docker stop cs-v1-pgs-poc01

# Watch Patroni elect a new leader (takes ~30s)
watch -n2 "docker exec cs-v3-pgs-poc03 patronictl \
  -c /etc/patroni/patroni.yml list"

# Restore old primary as replica
docker start cs-v1-pgs-poc01
```

---

## File Structure

```
docker-pg-cluster/
├── docker-compose.yml
├── .env.example
├── docker/
│   └── patroni/
│       ├── Dockerfile          # PostgreSQL 16 + Patroni 3 + PGBouncer
│       └── entrypoint.sh       # Starts Patroni + PGBouncer
└── config/
    ├── haproxy/
    │   ├── haproxy-prd.cfg     # RW(6432) + RO(6433) frontend
    │   ├── haproxy-ro.cfg      # RO-only across all replicas
    │   ├── haproxy-dr.cfg      # DR replica
    │   └── haproxy-lr.cfg      # Late replica (24h timeout)
    ├── pgbouncer/
    │   ├── poc01.ini            # Primary PGBouncer
    │   ├── poc02.ini            # DR PGBouncer
    │   ├── poc03.ini            # RO PGBouncer
    │   ├── poc04.ini            # LR PGBouncer
    │   └── userlist.txt         # PGBouncer auth (replace with hashed passwords)
    └── monitoring/
        └── prometheus.yml       # Scrape config for all nodes
```
