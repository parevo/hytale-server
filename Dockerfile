# -------------------------------------------------------------------------
# Parevo Hytale Server Enterprise Edition
# Optimized for Performance, Security, and Low Latency
# -------------------------------------------------------------------------

FROM ubuntu:24.04

LABEL maintainer="Parevo DevOps <devops@parevo.com>"
LABEL product="Hytale Server Enterprise Edition"

# Set environment variables for non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    JAVA_HOME=/opt/java \
    PATH="/opt/java/bin:${PATH}"

# Install core dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    unzip \
    jq \
    locales \
    tzdata \
    ca-certificates \
    procps \
    netcat-openbsd \
    git \
    rclone \
    && locale-gen en_US.UTF-8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Official Eclipse Temurin JDK 21 (LTS) - Best for Enterprise stability
# Note: Manual recommends 25, but 21 is currently the most stable LTS for production.
RUN set -ex; \
    mkdir -p /opt/java; \
    curl -L https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.5%2B11/OpenJDK21U-jdk_x64_linux_hotspot_21.0.5_11.tar.gz | tar -xzC /opt/java --strip-components=1;

# Create non-root user 'container'
RUN groupadd -g 998 container && \
    useradd -u 998 -g container -m -d /home/container container

# Set working directory
WORKDIR /home/container

# Switch to non-root user
USER container
ENV USER=container HOME=/home/container

# Expose Hytale default port
EXPOSE 5520/udp

# Copy entrypoint script
COPY --chown=container:container entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Entrypoint setup
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
