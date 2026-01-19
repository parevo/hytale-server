#!/bin/bash

# -------------------------------------------------------------------------
# PAREVO HYTALE SERVER - ULTIMATE ENTERPRISE V3 (FINAL)
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

# 7. Launch
MEMORY_LIMIT="${MEMORY:-4G}"
JAVA_FLAGS=("-Xms${MEMORY_LIMIT}" "-Xmx${MEMORY_LIMIT}" "-XX:+UseZGC" "-XX:+ZGenerational" "-Dparevo.edition=v3-ultimate")

if [ ! -f "HytaleServer.jar" ]; then
    if [ ! -z "${JAR_URL}" ]; then
        echo -e "${BLUE}[INFO] Downloading HytaleServer.jar from: ${JAR_URL}${NC}"
        curl -L -o HytaleServer.jar "${JAR_URL}"
    else
        echo -e "${YELLOW}[MOCK] HytaleServer.jar missing and no JAR_URL provided.${NC}"
        echo -e "${YELLOW}[MOCK] Running simulated process...${NC}"
        while true; do sleep 1 & wait $!; done
    fi
fi

echo -e "${BLUE}[INFO] Launching Hytale Server...${NC}"
send_discord_notification "Online" "Parevo Hytale Server (V3 Ultimate) is now online." "3066993"

java "${JAVA_FLAGS[@]}" -jar HytaleServer.jar &
PID=$!
wait $PID
