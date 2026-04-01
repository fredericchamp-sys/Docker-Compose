# =============================================================================
# Patroni + PostgreSQL 16 image
# Includes: patroni, pgbouncer, pg_rewind, pg_basebackup
# =============================================================================
FROM postgres:16-bookworm

LABEL maintainer="dba-team"
LABEL description="PostgreSQL 16 + Patroni 3.x + PGBouncer"

ENV PATRONI_VERSION=3.2.2
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    python3 \
    python3-pip \
    python3-venv \
    pgbouncer \
    jq \
    ca-certificates \
    openssl \
    netcat-traditional \
    && rm -rf /var/lib/apt/lists/*

# Install Patroni with etcd3 support
RUN python3 -m venv /opt/patroni \
    && /opt/patroni/bin/pip install --no-cache-dir \
       "patroni[etcd3]==${PATRONI_VERSION}" \
       psycopg2-binary \
    && ln -s /opt/patroni/bin/patroni      /usr/local/bin/patroni \
    && ln -s /opt/patroni/bin/patronictl   /usr/local/bin/patronictl \
    && ln -s /opt/patroni/bin/patroni_raft_controller /usr/local/bin/patroni_raft_controller 2>/dev/null || true

# Directories
RUN mkdir -p \
    /etc/patroni \
    /etc/pgbouncer \
    /var/lib/postgresql/data \
    /var/lib/postgresql/wal \
    /var/lib/postgresql/wal_archive \
    /var/run/pgbouncer \
    /var/log/pgbouncer \
    /var/log/postgresql \
    && chown -R postgres:postgres \
       /etc/patroni \
       /etc/pgbouncer \
       /var/lib/postgresql \
       /var/run/pgbouncer \
       /var/log/pgbouncer \
       /var/log/postgresql

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN sed -i 's/\r//' /entrypoint.sh && chmod +x /entrypoint.sh

# Ports
# 5432  – PostgreSQL
# 5433  – PGBouncer (mapped internally)
# 8008  – Patroni REST API
# 8404  – Patroni health endpoint
EXPOSE 5432 5433 8008 8404

USER postgres
ENTRYPOINT ["/entrypoint.sh"]