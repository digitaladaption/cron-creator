#!/bin/bash
#
# Cron Creator Skill Installer
# Installs the cron-creator skill and configures Clawdbot to allow automatic cron job creation
#

set -e

echo "🛠️  Cron Creator Skill Installer"
echo "================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Clone/install the skill
echo "📦 Step 1: Installing cron-creator skill..."
SKILL_DIR="$HOME/.clawdbot/skills/cron-creator"
mkdir -p "$HOME/.clawdbot/skills"

if [ -d "$SKILL_DIR" ]; then
    echo "  Skill already exists, updating..."
    cd "$SKILL_DIR"
    git pull 2>/dev/null || echo "  (using existing installation)"
else
    echo "  Cloning skill from GitHub..."
    git clone https://github.com/digitaladaption/cron-creator.git "$SKILL_DIR" 2>/dev/null || {
        echo "  Creating skill directory..."
        mkdir -p "$SKILL_DIR/scripts"
        # Skill will be copied from /root/clawd if available
        if [ -d "/root/clawd/skills/cron-creator" ]; then
            cp -r /root/clawd/skills/cron-creator/* "$SKILL_DIR/"
        fi
    }
fi

# Make scripts executable
chmod +x "$SKILL_DIR/scripts/"*.py 2>/dev/null || true

echo "  ✅ Skill installed at: $SKILL_DIR"
echo ""

# Step 2: Configure Clawdbot to allow gateway exec
echo "⚙️  Step 2: Configuring Clawdbot for automatic cron creation..."

CONFIG_FILE="$HOME/.clawdbot/clawdbot.json"

if [ -f "$CONFIG_FILE" ]; then
    # Check if tools.exec.host is already configured
    if grep -q '"host":\s*"gateway"' "$CONFIG_FILE" || grep -q '"host":\s*"sandbox"' "$CONFIG_FILE"; then
        echo "  ✅ Gateway exec already configured"
    else
        echo "  📝 Updating config to allow gateway exec..."
        
        # Use Python to safely update the JSON config
        python3 << 'PYTHON_SCRIPT'
import json
import sys

config_file = sys.argv[1] if len(sys.argv) > 1 else '/root/.clawdbot/clawdbot.json'

try:
    with open(config_file, 'r') as f:
        config = json.load(f)
    
    # Ensure tools section exists
    if 'tools' not in config:
        config['tools'] = {}
    
    # Ensure exec section exists with host = gateway
    config['tools']['exec'] = {
        'host': 'gateway',
        'security': 'allowlist',
        'ask': 'off'
    }
    config['tools']['exec']['safeBins'] = ['clawdbot']
    
    with open(config_file, 'w') as f:
        json.dump(config, f, indent=2)
    
    print('SUCCESS')
except Exception as e:
    print(f'ERROR: {e}')
    sys.exit(1)
PYTHON_SCRIPT

        if [ $? -eq 0 ]; then
            echo "  ✅ Config updated: tools.exec.host=gateway"
        else
            echo "  ⚠️  Could not update config automatically"
            echo "  📝 You may need to manually add to $CONFIG_FILE:"
            echo '     "tools": {"exec": {"host": "gateway"}}'
        fi
    fi
else
    echo "  ⚠️  Config file not found at: $CONFIG_FILE"
    echo "  📝 Creating default config..."
    
    # Create default config
    python3 << 'PYTHON_SCRIPT'
import json
import os

config = {
    "commands": {
        "native": "auto",
        "nativeSkills": "auto"
    },
    "tools": {
        "exec": {
            "host": "gateway",
            "security": "allowlist",
            "ask": "off",
            "safeBins": ["clawdbot"]
        }
    }
}

config_file = os.path.expanduser("~/.clawdbot/clawdbot.json")
os.makedirs(os.path.dirname(config_file), exist_ok=True)

with open(config_file, 'w') as f:
    json.dump(config, f, indent=2)

print('SUCCESS')
PYTHON_SCRIPT

    if [ $? -eq 0 ]; then
        echo "  ✅ Default config created"
    fi
fi

echo ""

# Step 3: Restart gateway if needed
echo "🔄 Step 3: Restarting Clawdbot gateway..."

# Check if clawdbot is running
if pgrep -f "clawdbot gateway" > /dev/null 2>&1; then
    echo "  Restarting gateway..."
    clawdbot gateway restart 2>/dev/null || {
        echo "  ⚠️  Could not restart automatically"
        echo "  📝 Please run: clawdbot gateway restart"
    }
    if [ $? -eq 0 ]; then
        echo "  ✅ Gateway restarted"
    fi
else
    echo "  ℹ️  Gateway not running (start with: clawdbot gateway start)"
fi

echo ""
echo "================================"
echo "✅ Installation Complete!"
echo ""
echo "📖 Usage:"
echo "   Just say things like:"
echo "   - 'Create a daily Ikigai reminder at 8:45am'"
echo "   - 'Remind me to drink water every 2 hours'"
echo "   - 'Set up a weekly check-in on Mondays at 9am'"
echo ""
echo "🔧 The skill will automatically:"
echo "   1. Parse your request"
echo "   2. Create the cron job"
echo "   3. Confirm it's done"
echo ""
