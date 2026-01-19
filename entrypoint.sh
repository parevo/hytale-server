#!/bin/bash

# -------------------------------------------------------------------------
# PAREVO HYTALE SERVER - ULTIMATE ENTERPRISE V3
# Version: 2026-01-20_01-55 (Architecture-Fix)
# -------------------------------------------------------------------------

# Color Definitions
CYAN='\033[0;36m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# 1. Branding
clear
echo -e "${CYAN}"
echo "  _____                _              "
echo " |  __ \              | |             "
echo " | |__) |_ _ _ __ ___| | _____       "
echo " |  ___/ _' | '__/ _ \ \ / / _ \      "
echo " | |  | (_| | | |  __/\ V / (_) |     "
echo " |_|   \__,_|_|  \___| \_/ \___/      "
echo -e "${BLUE}"
echo "  _    _       _        _              "
echo " | |  | |     | |      | |             "
echo " | |__| |_   _| |_ __ _| | ___         "
echo " |  __  | | | | __/ _' | |/ _ \        "
echo " | |  | | |_| | || (_| | |  __/        "
echo " |_|  |_|\__, |\__\__,_|_|\___|        "
echo "          __/ |                        "
echo "         |___/                         "
echo -e "${NC}"
echo -e "${CYAN}--- ULTIMATE ENTERPRISE EDITION V3 ---${NC}"
echo -e "${GREEN}Features: Graceful Shutdown | Discord | Git Sync | S3 Backups${NC}"
echo ""

# Function: Discord Notification
send_discord_notification() {
    local status=$1; local message=$2; local color=$3
    if [ ! -z "${DISCORD_WEBHOOK_URL}" ]; then
        payload=$(jq -n --arg title "Parevo Hytale - ${status}" --arg desc "${message}" --arg color "${color}" \
            '{embeds: [{title: $title, description: $desc, color: $color, timestamp: (now | strftime("%Y-%m-%dT%H:%M:%SZ"))}]}')
        curl -H "Content-Type: application/json" -d "${payload}" "${DISCORD_WEBHOOK_URL}" > /dev/null 2>&1
    fi
}

# 2. Git Mod Sync
if [ ! -z "${MODS_GIT_URL}" ]; then
    echo -e "${BLUE}[GIT] Syncing mods from: ${MODS_GIT_URL}${NC}"
    if [ ! -d "mods/.git" ]; then
        git clone "${MODS_GIT_URL}" mods
    else
        cd mods && git pull && cd ..
    fi
    echo -e "${GREEN}[GIT] Mods synchronized successfully.${NC}"
fi

# 3. S3 Backup Configuration
setup_rclone() {
    if [ ! -z "${S3_BUCKET}" ]; then
        echo -e "${BLUE}[S3] Configuring cloud backup...${NC}"
        mkdir -p ~/.config/rclone
        cat <<EOF > ~/.config/rclone/rclone.conf
[s3-backup]
type = s3
provider = AWS
access_key_id = ${S3_ACCESS_KEY}
secret_access_key = ${S3_SECRET_KEY}
endpoint = ${S3_ENDPOINT}
region = ${S3_REGION}
EOF
    fi
}
setup_rclone

# 4. Backup Loop (Background)
backup_loop() {
    local interval="${BACKUP_INTERVAL:-24h}"
    while true; do
        sleep "${interval}"
        if [ ! -z "${S3_BUCKET}" ]; then
            echo -e "${BLUE}[S3] Starting scheduled backup...${NC}"
            send_discord_notification "Backup" "Scheduled cloud backup started..." "3447003" # Blue
            rclone sync ./data s3-backup:"${S3_BUCKET}/$(date +%Y-%m-%d)"
            send_discord_notification "Backup" "Cloud backup completed successfully." "3066993" # Green
        fi
    done
}
if [ ! -z "${S3_BUCKET}" ]; then backup_loop & fi

# 5. Security & Update & Config (Simplified for V3)
if [ -f "config.json" ]; then
    [[ ! -z "${H_VIEW_DISTANCE}" ]] && jq ".WorldConfig.ViewDistance = ${H_VIEW_DISTANCE}" config.json > config.json.tmp && mv config.json.tmp config.json
    [[ ! -z "${H_PLAYER_LIMIT}" ]] && jq ".PlayerConfig.MaxPlayers = ${H_PLAYER_LIMIT}" config.json > config.json.tmp && mv config.json.tmp config.json
fi

# 6. Graceful Shutdown
cleanup() {
    echo -e "\n${RED}[SHUTDOWN] Initiating graceful exit...${NC}"
    send_discord_notification "Shutdown" "Server shutting down. Saving world..." "15158332"
    
    # Final Backup before exit
    if [ ! -z "${S3_BUCKET}" ]; then
        echo -e "${BLUE}[S3] Performing final cloud sync...${NC}"
        rclone sync ./data s3-backup:"${S3_BUCKET}/final-$(date +%Y%m%d-%H%M)"
    fi
    
    sleep 5
    echo -e "${GREEN}[SHUTDOWN] Clean exit completed.${NC}"
    exit 0
}
trap cleanup SIGTERM SIGINT

# 7. Acquisition & Launch Phase
MEMORY_LIMIT="${MEMORY:-4G}"
JAVA_FLAGS=(
    "-Xms${MEMORY_LIMIT}" 
    "-Xmx${MEMORY_LIMIT}" 
    "-XX:+UseZGC" 
    "-Dparevo.edition=v3-ultimate"
)

# Define Assets Path
ASSETS_PATH="${H_ASSETS_PATH:-Assets.zip}"

# Check for write permissions
if [ ! -w "." ]; then
    echo -e "${RED}[ERROR] No write permission in $(pwd).${NC}"
    echo -e "${YELLOW}[TIP] Run 'sudo chown -R 998:998 data' on your host machine.${NC}"
    exit 1
fi

# 8. File Acquisition (Downloader)
if [ ! -f "HytaleServer.jar" ] && [ ! -f "Server/HytaleServer.jar" ]; then
    if [ ! -z "${JAR_URL}" ]; then
        echo -e "${BLUE}[INFO] Downloading custom JAR...${NC}"
        curl -L -o HytaleServer.jar "${JAR_URL}"
    else
        echo -e "${YELLOW}[INFO] HytaleServer.jar not found. Starting OFFICIAL DOWNLOADER...${NC}"
        cd /tmp
        curl -L -o hytale-downloader.zip https://downloader.hytale.com/hytale-downloader.zip
        unzip -o hytale-downloader.zip
        DOWNLOAD_BIN=$(ls hytale-downloader-linux-* 2>/dev/null | head -n 1)
        if [ ! -z "${DOWNLOAD_BIN}" ]; then
            mv "${DOWNLOAD_BIN}" hytale-downloader && chmod +x hytale-downloader
            ./hytale-downloader -download-path /home/container/game.zip
            cd /home/container
            if [ -f "game.zip" ]; then
                echo -e "${BLUE}[INFO] Extracting game files...${NC}"
                unzip -o game.zip && rm game.zip
            fi
        fi
        rm /tmp/hytale-downloader.zip /tmp/hytale-downloader 2>/dev/null
    fi
fi

# 9. Directory Flattening
if [ -d "Server" ]; then
    echo -e "${BLUE}[INFO] Flattening directory structure...${NC}"
    mv Server/* . 2>/dev/null && rmdir Server 2>/dev/null
fi

# 10. Final Start
if [ -f "HytaleServer.jar" ]; then
    [ -f "HytaleServer.aot" ] && JAVA_FLAGS+=("-XX:AOTCache=HytaleServer.aot")
    echo -e "${BLUE}[INFO] Launching Hytale Server...${NC}"
    send_discord_notification "Online" "Parevo Hytale Server is now online." "3066993"
    java "${JAVA_FLAGS[@]}" -jar HytaleServer.jar --assets "${ASSETS_PATH}" &
    PID=$!
    wait $PID
else
    echo -e "${RED}[ERROR] HytaleServer.jar not found.${NC}"
    exit 1
fi
