#!/bin/bash

# Function to check OS type and install ACL if needed
install_acl() {
    if ! command -v setfacl &> /dev/null; then
        echo "ACL not found. Installing..."

        # Check if the user has sudo privileges
        if ! sudo -n true 2>/dev/null; then
            echo "Error: This script requires sudo privileges to install packages."
            exit 1
        fi

        # Detect OS and install ACL accordingly
        if [[ -f /etc/os-release ]]; then
            source /etc/os-release
            case "$ID" in
                ubuntu|debian)
                    sudo apt update && sudo apt install acl -y
                    ;;
                centos|rhel|fedora)
                    sudo yum install acl -y
                    ;;
                arch)
                    sudo pacman -Sy acl --noconfirm
                    ;;
                *)
                    echo "Error: Unsupported OS. Please install ACL manually."
                    exit 1
                    ;;
            esac
        else
            echo "Error: Unable to determine OS type."
            exit 1
        fi
    fi
}

# Ensure script is run with sudo/root privileges
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root or with sudo."
    exit 1
fi

# Install ACL if needed
install_acl

# Prompt for username
read -p "Enter the username to restrict: " USER

# Check if user exists
if ! id "$USER" &>/dev/null; then
    echo "Error: User '$USER' does not exist. Please create the user first."
    exit 1
fi

# Prompt for web project directory (default: /var/www/html)
read -p "Enter the web project directory (default: /var/www/html): " WEB_DIR
WEB_DIR=${WEB_DIR:-/var/www/html}

# Confirm web project directory exists
if [ ! -d "$WEB_DIR" ]; then
    echo "Error: Directory '$WEB_DIR' does not exist!"
    exit 1
fi

# Ask for the web server group
echo "Select the web server group:"
echo "1. web-data"
echo "2. www-data"
echo "3. apache"
echo "4. daemon"
read -p "Enter the corresponding number (default: www-data): " GROUP_CHOICE

case $GROUP_CHOICE in
    1) WEB_GROUP="web-data" ;;
    2) WEB_GROUP="www-data" ;;
    3) WEB_GROUP="apache" ;;
    4) WEB_GROUP="daemon" ;;
    *) WEB_GROUP="www-data" ;;  # Default to www-data
esac

# Prompt for the base directory (default: /opt/lampp/htdocs)
read -p "Enter the base directory to restrict access (default: /opt/lampp/htdocs): " ROOT_DIR
ROOT_DIR=${ROOT_DIR:-/opt/lampp/htdocs}

# Confirm base directory exists
if [ ! -d "$ROOT_DIR" ]; then
    echo "Error: Directory '$ROOT_DIR' does not exist!"
    exit 1
fi

# Prompt for allowed directories (comma-separated)
read -p "Enter the directories the user should access inside '$ROOT_DIR' (comma-separated): " ALLOWED_DIRS_INPUT

# Convert comma-separated input to an array
IFS=',' read -r -a ALLOWED_DIRS <<< "$ALLOWED_DIRS_INPUT"

# Set ownership and permissions for the web project
echo "Setting permissions for $WEB_DIR..."
sudo chown -R $USER:$WEB_GROUP "$WEB_DIR"
find "$WEB_DIR" -type d -exec chmod 750 {} \;
find "$WEB_DIR" -type f -exec chmod 640 {} \;
echo "Web project permissions set."

# Set ownership and permissions for base directory
echo "Setting ownership and permissions for $ROOT_DIR..."
sudo chmod 750 "$ROOT_DIR"
sudo chown "$WEB_GROUP:$WEB_GROUP" "$ROOT_DIR"

# Restrict traversal but no listing for the user
echo "Restricting user $USER from listing $ROOT_DIR..."
sudo setfacl -m u:$USER:--x "$ROOT_DIR"

# Change ownership and permissions for all directories and files inside htdocs
echo "Setting ownership and permissions for directories and files inside $ROOT_DIR..."
find "$ROOT_DIR" -type d -execdir chown "$WEB_GROUP:$WEB_GROUP" {} \; -execdir chmod 750 {} \;
find "$ROOT_DIR" -type f -execdir chown "$WEB_GROUP:$WEB_GROUP" {} \; -execdir chmod 640 {} \;

# Grant access to allowed directories
for DIR in "${ALLOWED_DIRS[@]}"; do
    FULL_PATH="$ROOT_DIR/$DIR"
    if [ -d "$FULL_PATH" ]; then
        echo "Granting access to $FULL_PATH for user $USER..."
        sudo setfacl -R -m u:$USER:rwx "$FULL_PATH"
    else
        echo "Warning: Directory $FULL_PATH does not exist. Skipping..."
    fi
done

# Restrict access to all other directories and files inside the base directory
echo "Restricting access to all other directories and files..."
find "$ROOT_DIR" -mindepth 1 -maxdepth 1 ! \( $(printf "! -name \"%s\" " "${ALLOWED_DIRS[@]}") \) -type d -exec chmod 750 {} \;
find "$ROOT_DIR" -mindepth 1 -maxdepth 1 ! \( $(printf "! -name \"%s\" " "${ALLOWED_DIRS[@]}") \) -type f -exec chmod 640 {} \;

echo "Access restrictions applied successfully for user $USER!"
