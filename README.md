# 🛡️ Parevo Hytale Server: Ultimate Enterprise Edition (V3)

[![Docker Multi-Arch](https://img.shields.io/badge/Platform-AMD64%20%7C%20ARM64-blue?style=for-the-badge&logo=docker)](https://github.com/parevo/hytale-server)
[![Java Version](https://img.shields.io/badge/Java-25-orange?style=for-the-badge&logo=openjdk)](https://openjdk.org/projects/jdk/25/)
[![License](https://img.shields.io/badge/License-Enterprise-red?style=for-the-badge)](https://parevo.io)

The **Ultimate Edition** is a high-performance, containerized distribution of the Hytale Dedicated Server. Engineered by **Parevo Technology**, this image provides a "SaaS-ready" infrastructure for professional hosting providers and community leaders who demand 100% uptime and data integrity.

---

## ✨ Enterprise Features

### 🚀 Performance Engineering

- **ZGC & Generational GC**: Pre-configured for Java 25 to eliminate gameplay stutters.
- **Multi-Arch Support**: Native binaries for both **x86_64** (Standard Cloud) and **ARM64** (Apple Silicon, AWS Graviton).
- **Vector API Optimization**: Prepared for high-throughput world calculations.

### 🛡️ Data Reliability & Safety

- **S3 Cloud Sync**: Automated backups to AWS S3, Cloudflare R2, or Minio every 12h and on container exit.
- **Graceful Shutdown**: SIGTERM signal handling ensures `save-all` and clean stops, preventing world corruption.
- **Health Monitoring**: Integrated UDP health probes for auto-healing orchestration.

### 🔄 DevOps & Automation

- **Git Mod Sync**: Synchronize your server mods directly from any Git repository on startup.
- **Discord Webhooks**: Real-time rich embeds for status updates, backups, and security alerts.
- **Config Injection**: Manage complex `config.json` settings via Environment Variables—no manual editing required.

---

## 🛠️ Quick Start

### 1. Minimal Launch

```bash
docker run -d \
  --name hytale-server \
  -p 5520:5520/udp \
  -e MEMORY=8G \
  -v $(pwd)/data:/home/container \
  ghcr.io/parevo/hytale-server:latest
```

### 2. Ultimate Production (Docker Compose)

Create a `docker-compose.yml` and run `docker-compose up -d`:

```yaml
services:
  hytale:
    image: ghcr.io/parevo/hytale-server:latest
    environment:
      - DISCORD_WEBHOOK_URL=your_webhook_here
      - MODS_GIT_URL=https://github.com/your/hytale-mods.git
      - S3_BUCKET=my-hytale-backups
      - S3_ACCESS_KEY=AKIA...
      - S3_SECRET_KEY=secret...
      - S3_ENDPOINT=https://your-s3-endpoint.com
    volumes:
      - ./data:/home/container
      - /etc/machine-id:/etc/machine-id:ro
    restart: unless-stopped
```

---

## 🚀 Initial Setup & Authentication

On the first launch, the image will automatically download the official **Hytale Downloader CLI** to fetch the server binaries.

1. **Watch Logs**: Run `docker logs -f hytale-server`.
2. **Authorize**: Look for a message: `Visit: https://accounts.hytale.com/device and enter code: XXXX-XXXX`.
3. **Download**: Once authorized, the container will download the server files and boot automatically.

> [!TIP]
> You only need to do this once. The server files are stored in your mounted `./data` volume.

---

## ⚙️ Environment Variables

| Variable              | Default      | Function                                   |
| :-------------------- | :----------- | :----------------------------------------- |
| `MEMORY`              | `8G`         | Allocated RAM (Xms/Xmx).                   |
| `JAR_URL`             | `null`       | Optional: Direct link to HytaleServer.jar. |
| `H_ASSETS_PATH`       | `Assets.zip` | Path to assets file/folder.                |
| `AUTO_UPDATE`         | `true`       | Fetch latest Hytale patches on startup.    |
| `DISCORD_WEBHOOK_URL` | `null`       | Target URL for status notifications.       |
| `MODS_GIT_URL`        | `null`       | Git repository for automatic mod syncing.  |
| `S3_BUCKET`           | `null`       | Primary backup destination.                |
| `BACKUP_INTERVAL`     | `12h`        | Frequency of scheduled cloud backups.      |
| `H_VIEW_DISTANCE`     | `16`         | WorldConfig.ViewDistance injection.        |
| `H_PLAYER_LIMIT`      | `150`        | PlayerConfig.MaxPlayers injection.         |

---

## 🛡️ Security & Compliance

This image enforces **Security Best Practices**:

- **Non-Root Execution**: Runs under UID `998` (`container` user).
- **Machine-ID Binding**: Optional `/etc/machine-id` mount for unique instance identification.
- **Read-Only Roots**: Compatible with read-only filesystems (logs and data are in volumes).

---

## 💬 Support & Enterprise Licensing

For custom integrations, high-traffic cluster configurations, or enterprise support, please reach out to our DevOps team:

- **Website**: [parevo.io](https://parevo.io)
- **Email**: [devops@parevo.com](mailto:devops@parevo.com)
- **Discord**: [Join Parevo Community](https://discord.gg/parevo)

---

© 2026 **Parevo Technology**. Built for the future of Hytale.
