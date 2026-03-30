# =============================================================================
# Vault Production Configuration
# Storage: Integrated Raft (no external Consul needed)
# TLS: enabled (certificates mounted from host)
# UI: enabled for ops access
# =============================================================================

ui            = true
disable_mlock = false   # mlock prevents secrets being swapped to disk
log_level     = "info"
log_file      = "/vault/logs/vault.log"

# Integrated Raft storage – persists across restarts
storage "raft" {
  path    = "/vault/data"
  node_id = "vault-node-01"

  # Performance tuning
  performance_multiplier        = 1
  trailing_logs                 = 10000
  snapshot_threshold            = 8192
}

# TCP listener with TLS
listener "tcp" {
  address            = "0.0.0.0:8200"
  cluster_address    = "0.0.0.0:8201"

  tls_cert_file      = "/vault/tls/vault.crt"
  tls_key_file       = "/vault/tls/vault.key"
  tls_min_version    = "tls13"

  # Disable TLS only for health check path
  tls_disable_client_certs = true
}

# Telemetry for Prometheus
telemetry {
  prometheus_retention_time = "30s"
  disable_hostname          = true
}

# API address (must match TLS cert SAN)
api_addr     = "https://vault:8200"
cluster_addr = "https://vault:8201"

# Seal configuration – use auto-unseal in prod (AWS KMS / Azure Key Vault)
# For self-hosted, use Shamir (default) with at least 5 shares, 3 threshold
# seal "awskms" {
#   region     = "eu-west-1"
#   kms_key_id = "alias/vault-unseal"
# }
