# Use a lightweight Linux base image
FROM alpine:latest

# Install dependencies
RUN apk add --no-cache curl unzip bash

# Download and install Terraform 1.14.5
RUN curl -Lo /tmp/terraform.zip https://releases.hashicorp.com/terraform/1.14.5/terraform_1.14.5_linux_amd64.zip \
    && unzip /tmp/terraform.zip -d /usr/local/bin \
    && rm /tmp/terraform.zip

# Set working directory for your Terraform code
WORKDIR /workspace

# Keep the container running
CMD ["tail", "-f", "/dev/null"]
