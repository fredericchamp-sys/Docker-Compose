# Use a lightweight Linux base image
FROM alpine:latest

# Install dependencies
RUN apk add --no-cache aws-cli

RUN curl -Lo /tmp/terraform.zip https://releases.hashicorp.com/terraform/1.15.6/terraform_1.15.6_linux_amd64.zip \
    && unzip /tmp/terraform.zip -d /usr/local/bin \
    && rm /tmp/terraform.zip

# Set working directory for your Terraform code
WORKDIR /workspace

# Keep the container running
CMD ["tail", "-f", "/dev/null"]
