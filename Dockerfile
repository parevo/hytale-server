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

# Install Java 25 (Simulated Download)
# In a real scenario, this would point to the official OpenJDK 25 binary
RUN set -ex; \
    mkdir -p /opt/java; \
    # Simulated download URL for Java 25
    JAVA_URL="https://download.java.net/java/GA/jdk25/archive/latest/binaries/openjdk-25_linux-x64_bin.tar.gz"; \
    echo "Simulating Java 25 Installation..."; \
    # Mocking the binaries for demonstration if the URL isn't live yet
    # curl -fL $JAVA_URL | tar -xzC /opt/java --strip-components=1 || \
    (mkdir -p /opt/java/bin && touch /opt/java/bin/java && chmod +x /opt/java/bin/java && echo "Mock Java 25 Binary Created")

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
