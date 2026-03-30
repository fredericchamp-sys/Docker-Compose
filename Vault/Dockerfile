FROM hashicorp/vault:latest

LABEL description="HashiCorp Vault - Production config for pg-ha-cluster"

# Install curl for health checks
RUN apk add --no-cache curl

# Copy server config
COPY vault.hcl /vault/config/vault.hcl

# Runtime dirs (data + logs + tls mounted as volumes at runtime)
RUN mkdir -p /vault/data /vault/logs /vault/tls /vault/config
RUN chmod 700 /vault/data /vault/logs /vault/tls

EXPOSE 8200 8201

ENTRYPOINT ["vault"]
CMD ["server", "-config=vault.hcl"]
