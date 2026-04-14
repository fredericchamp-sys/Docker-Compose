#!/bin/bash
# init-cluster.sh
# Idempotently initialises shard replica sets and registers them with mongos.
# Config replica set is already initialised by the config-init service,
# which must complete before mongos (and therefore this script) starts.

set -euo pipefail

MONGOSH="mongosh --quiet --norc"

log() { echo "[init-cluster] $*"; }

wait_for() {
  local host=$1 port=$2 label=$3
  log "Waiting for $label ($host:$port)..."
  until $MONGOSH --host "$host" --port "$port" --eval "db.adminCommand('ping').ok" 2>/dev/null | grep -q 1; do
    sleep 2
  done
  log "$label is up."
}

init_replset() {
  local host=$1 port=$2 config=$3 label=$4
  local status
  status=$($MONGOSH --host "$host" --port "$port" --eval "rs.status().ok" 2>/dev/null || echo "0")
  if [ "$status" = "1" ]; then
    log "$label already initialised — skipping."
  else
    log "Initiating $label..."
    $MONGOSH --host "$host" --port "$port" --eval "$config"
    # Wait for primary election
    log "Waiting for $label primary..."
    until $MONGOSH --host "$host" --port "$port" --eval "rs.isMaster().ismaster" 2>/dev/null | grep -q true; do
      sleep 2
    done
    log "$label primary elected."
  fi
}

add_shard_if_missing() {
  local shard_string=$1
  local shard_id=$2
  local already
  already=$($MONGOSH --host mongos --port 27017 \
    --eval "db.adminCommand({listShards:1}).shards.map(s=>s._id).includes('$shard_id')" \
    2>/dev/null || echo "false")
  if [ "$already" = "true" ]; then
    log "Shard $shard_id already registered — skipping."
  else
    log "Adding shard $shard_id..."
    $MONGOSH --host mongos --port 27017 --eval "sh.addShard('$shard_string')"
    log "Shard $shard_id added."
  fi
}

# ── 1. Confirm all shard nodes and mongos are reachable ────────────────────
wait_for shard1a 27018 "shard1a"
wait_for shard1b 27018 "shard1b"
wait_for shard1c 27018 "shard1c"
wait_for shard2a 27018 "shard2a"
wait_for shard2b 27018 "shard2b"
wait_for shard2c 27018 "shard2c"
wait_for mongos  27017 "mongos"

# ── 2. Init shard replica sets ─────────────────────────────────────────────
init_replset shard1a 27018 "
rs.initiate({
  _id: 'shard1',
  members: [
    { _id: 0, host: 'shard1a:27018' },
    { _id: 1, host: 'shard1b:27018' },
    { _id: 2, host: 'shard1c:27018' }
  ]
})" "shard1"

init_replset shard2a 27018 "
rs.initiate({
  _id: 'shard2',
  members: [
    { _id: 0, host: 'shard2a:27018' },
    { _id: 1, host: 'shard2b:27018' },
    { _id: 2, host: 'shard2c:27018' }
  ]
})" "shard2"

# ── 3. Register shards with mongos ─────────────────────────────────────────
add_shard_if_missing "shard1/shard1a:27018,shard1b:27018,shard1c:27018" "shard1"
add_shard_if_missing "shard2/shard2a:27018,shard2b:27018,shard2c:27018" "shard2"

log "✅ Cluster initialisation complete."
$MONGOSH --host mongos --port 27017 --eval "sh.status()"