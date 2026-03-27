FROM registry.access.redhat.com/ubi9/ubi:latest

USER root

# Install essential packages (without Python)
RUN dnf install -y \
      findutils \
      git \
      make \
      procps-ng \
      tar \
      wget \
      which \
      bc \
      jq \
      gcc \
      gcc-c++ \
      gettext \
      sqlite-devel \
      ca-certificates \
      dnf-plugins-core \
    && dnf clean all

WORKDIR /tmp

# Download and build ProFTPD
RUN wget https://github.com/proftpd/proftpd/archive/refs/tags/v1.3.8.tar.gz && \
    tar -xzf v1.3.8.tar.gz && \
    cd proftpd-1.3.8 && \
    ./configure && \
    make && \
    make install

EXPOSE 21 30000-30009

CMD ["/usr/local/sbin/proftpd", "--nodaemon"]
