#!/bin/bash
# Function to check if a package is installed
check_package_installed() {
    if ! command -v "$1" &> /dev/null; then
        return 1
    else
        return 0
    fi
}
check_dpkg_package_installed() {
    dpkg -s "$1" >/dev/null 2>&1
}
# Function to validate the port number
validate_port() {
    local port=$1
    # Check if the port is a valid number and within the range 1-65535
    if [[ $port =~ ^[0-9]+$ ]] && ((port >= 1 && port <= 65535)); then
        return 0  # Valid port
    else
        return 1  # Invalid port
    fi
}

# Check if curl is installed
if ! check_dpkg_package_installed curl; then
    echo "Installing curl..."
    apt update -y 
    apt install -y curl >/dev/null 2>&1
fi
# Check if wget is installed
if ! check_dpkg_package_installed wget; then
    echo "Installing wget..."
    apt update -y 
    apt install -y wget >/dev/null 2>&1
fi

# Check if git is installed
if ! check_dpkg_package_installed git; then
    echo "Installing git..."
    apt update -y 
    apt install -y git >/dev/null 2>&1
fi

# Check if git is installed
if ! check_dpkg_package_installed sudo; then
    echo "Installing sudo..."
    apt update -y 
    apt install -y sudo >/dev/null 2>&1
fi
# Clear screen
clear
interface=$(ip route list default | awk '$1 == "default" {print $5}')
# Display ASCII art and introduction
echo "                                  WireGuard Panel & Server"
echo ""
echo -e "\e[1;31mWARNING ! Install only in Ubuntu 20.04, Ubuntu 22.04, Ubuntu 24.02 & Debian 11 & 12 system ONLY\e[0m"
echo -e "\e[32mRECOMMENDED ==> Ubuntu 22.04 \e[0m"
echo ""
echo "The following software will be installed on your system:"
echo "   - Wire Guard Server"
echo "   - WireGuard-Tools"
echo "   - WGDashboard by donaldzou"
echo "   - Gunicorn WSGI Server"
echo "   - Python3-pip"
echo "   - Git"
echo "   - UFW - firewall"
echo "   - inotifywait"
echo ""
 # Check if the system is CentOS, Debian, or Ubuntu
if [ -f "/etc/centos-release" ]; then
    # CentOS
    centos_version=$(rpm -q --queryformat '%{VERSION}' centos-release)
    printf "Detected CentOS %s...\n" "$centos_version"
    pkg_manager="yum"
    ufw_package="ufw"
elif [ -f "/etc/debian_version" ]; then
    # Debian or Ubuntu
    if [ -f "/etc/os-release" ]; then
        source "/etc/os-release"
        if [ "$ID" = "debian" ]; then
            debian_version=$(cat /etc/debian_version)
            printf "Detected Debian %s...\n" "$debian_version"
        elif [ "$ID" = "ubuntu" ]; then
            ubuntu_version=$(lsb_release -rs)
            printf "Detected Ubuntu %s...\n" "$ubuntu_version"
        else
            printf "Unsupported distribution.\n"
            exit 1
        fi
    else
        printf "Unsupported distribution.\n"
        exit 1
    fi
    pkg_manager="apt"
    ufw_package="ufw"
else
    printf "Unsupported distribution.\n"
    exit 1
fi

printf "\n\n"
# Prompt the user to continue
read -p "Would you like to continue now ? [y/n]: " choice
if [[ "$choice" =~ ^[Yy]$ ]]; then

# Prompt the user to enter hostname until a valid one is provided
# Function to validate hostname
validate_hostname() {
    local hostname="$1"
        if [[ "$hostname" =~ ^[a-zA-Z0-9\.\-_]+$ ]]; then
        return 0  # Valid hostname
    else
        return 1  # Invalid hostname
    fi
}
    # Prompt the user to enter hostname until a valid one is provided
    while true; do
        read -p "Please enter FQDN hostname [eg. localhost]: " hostname
        if [[ -z "$hostname" ]]; then
            hostname="localhost"  # Default hostname if user hits Enter
            break
        elif validate_hostname "$hostname"; then
            break
        else
            echo "Invalid hostname. Please enter a valid hostname."
        fi
    done
    # Prompt the user to enter a username
while true; do
    read -p "Specify a Username Login for WGDashboard: " username
    if [[ -n "$username" ]]; then
        break
    else
        echo "Username cannot be empty. Please specify a username."
    fi
done
while true; do
    # Prompt the user to enter a password (without showing the input)
    read -s -p "Specify a Password: " password
    echo ""
    # Prompt the user to confirm the password
    read -s -p "Confirm Password: " confirm_password
    echo ""
    # Check if the passwords match
    if [ "$password" != "$confirm_password" ]; then
        echo -e "\e[1;31mError: Passwords do not match. Please try again.\e[0m"
    elif [ -z "$password" ]; then
        echo "Password cannot be empty. Please specify a password."
    else
        # Hash the password using SHA-256
        #hashed_password=$(echo -n "$password" | sha256sum | awk '{print $1}')
        # Generate a bcrypt hash for the password with a cost of 12
        #hashed_password=$(openssl passwd -bcrypt -salt "$(openssl rand -base64 6)" -cost 12 "$password")

        break  # Exit the loop if passwords match
    fi
done
   # Prompt for other installation details with default values
    read -p "Please Specify new DNS [eg. 8.8.8.8, 1.1.1.1]: " dns
    dns="${dns:-1.1.1.1,8.8.8.8}"  # Default DNS if user hits Enter
    #read -p "Please enter Wireguard Port [eg. 51820]: " wg_port
    #wg_port="${wg_port:-51820}"  # Default port if user hits Enter
    # Loop to ensure a valid port is entered
        while true; do
            read -p "Please enter Wireguard Port [eg. 51820]: " wg_port
            wg_port="${wg_port:-51820}"  # Default port if user hits Enter
            if validate_port "$wg_port"; then
                break  # Exit the loop if the port is valid
            else
                echo "Error: Invalid port. Please enter a number between 1 and 65535."
            fi
        done
    read -p "Please enter Admin Dashboard Port [eg. 8080]: " dashboard_port
    dashboard_port="${dashboard_port:-8080}"  # Default port if user hits Enter
echo ""

# Function to check if IPv6 is available
ipv6_available() {
if ip -6 addr show $interface | grep -q inet6 && ip -6 addr show $interface | grep -qv fe80; then
        return 0
    else
        return 1
    fi
}
# Function to convert IPv4 address format
convert_ipv4_format() {
    local ipv4_address=$1
    local subnet_mask=$2
    # Extract the network portion of the IPv4 address
    local network=$(echo "$ipv4_address" | cut -d'/' -f1 | cut -d'.' -f1-3)
    # Append ".0" to the network portion and concatenate with the subnet mask
    local converted_ipv4="$network.0/24"
    echo "$converted_ipv4"
}
#!/bin/bash
# Function to check if an IPv6 address is global
is_global_ipv6() {
    local ipv6_address=$1
    # Check if the address is not link-local (starts with fe80) and contains '::'
    if [[ $ipv6_address != fe80:* && $ipv6_address == *::* ]]; then
        return 0
    else
        return 1
    fi
}
# Check if IPv6 is available on the default interface
if ipv6_available; then
    ipv6_available=true
else
    ipv6_available=false
fi
# Function to convert IPv4 address format
convert_ipv4_format() {
    local ipv4_address=$1
    local subnet_mask=$2
    # Extract the network portion of the IPv4 address
    local network=$(echo "$ipv4_address" | cut -d'/' -f1 | cut -d'.' -f1-3)
    # Append ".0" to the network portion and concatenate with the subnet mask
    local converted_ipv4="$network.0/24"
    echo "$converted_ipv4"
}
# Function to generate IPv4 addresses
generate_ipv4() {
    local range_type=$1
    case $range_type in
       1)
            ipv4_address_pvt="10.$((RANDOM%256)).$((RANDOM%256)).1/24"
            ;;
        2)
            ipv4_address_pvt="172.$((RANDOM%16+16)).$((RANDOM%256)).1/24"
            ;;
        3)
            ipv4_address_pvt="110.20.0.1/24"
            ;;
        4)
            read -p "Enter custom Private IPv4 address: " ipv4_address_pvt
            ;;
        *)
            echo "Invalid option for IPv4 range."
            exit 1
            ;;
    esac
    echo "$ipv4_address_pvt"  # Return the generated IP address with subnet
}
# Function to generate IPv6 addresses
generate_ipv6() {
    local range_type=$1
    case $range_type in
        1)
            # Fixed prefix FC00:: for Unique Local Addresses (ULA)
            ipv6_address_pvt=$(printf "FC00:%04x:%04x::1/64" $((RANDOM % 65536)) $((RANDOM % 65536)))
            ;;
        2)
            # Fixed prefix FD00:: for Unique Local Addresses (ULA)
            ipv6_address_pvt=$(printf "FD86:EA04:%04x::1/64" $((RANDOM % 65536)))
            ;;
        3)
            read -p "Enter custom Private IPv6 address: " ipv6_address_pvt
            ;;
        *)
            echo "Invalid option for IPv6 range."
            exit 1
            ;;
    esac
    echo "$ipv6_address_pvt"  # Return the generated IP address with subnet
}
# Function to validate user input within a range
validate_input() {
    local input=$1
    local min=$2
    local max=$3
    if (( input < min || input > max )); then
        echo "Invalid option. Please choose an option between $min and $max."
        return 1
    fi
    return 0
}
# Main script
while true; do
    echo "Choose IP range type for IPv4:"
    echo "1) Class A: 10.0.0.0 to 10.255.255.255"
    echo "2) Class B: 172.16.0.0 to 172.31.255.255"
    echo "3) Class C: 192.168.0.0 to 192.168.255.255"
    echo "4) Specify custom Private IPv4"
    read -p "Enter your choice (1-4): " ipv4_option
    case $ipv4_option in
        1|2|3|4)
            ipv4_address_pvt=$(generate_ipv4 $ipv4_option)
            break
            ;;
        *)
            echo "Invalid option for IPv4 range."
            ;;
    esac
done
ipv6_option=""
if $ipv6_available; then
    while true; do
        echo "Choose IP range type for IPv6:"
        echo "1) FC00::/7"
        echo "2) FD00::/7"
        echo "3) Specify custom Private IPv6"
        read -p "Enter your choice (1-3): " ipv6_option
        case $ipv6_option in
            1|2|3)
                ipv6_address_pvt=$(generate_ipv6 $ipv6_option)
                break
                ;;
            *)
                echo "Invalid option for IPv6 range."
                ;;
        esac
    done
fi
echo "IPv4 Address: $ipv4_address_pvt"
if [ -n "$ipv6_address_pvt" ]; then
    echo "IPv6 Address: $ipv6_address_pvt"
fi
echo ""
read -p "Specify a Peer Endpoint Allowed IPs OR [press enter to use - 0.0.0.0/0,::/0]: " allowed_ip
allowed_ip="${allowed_ip:-0.0.0.0/0,::/0}"  # Default IPs if user hits Enter
echo ""
# Function to retrieve IPv4 addresses (excluding loopback address)
get_ipv4_addresses() {
    ip -o -4 addr show $interface | awk '$4 !~ /^127\.0\.0\.1/ {print $4}' | cut -d'/' -f1
}
# Function to retrieve IPv6 addresses (excluding link-local and loopback addresses)
get_ipv6_addresses() {
    ip -o -6 addr show $interface | awk '$4 !~ /^fe80:/ && $4 !~ /^::1/ {print $4}' | cut -d'/' -f1
}
# Function to validate user input within a range
validate_input() {
    local input=$1
    local min=$2
    local max=$3
    if (( input < min || input > max )); then
        echo "Invalid option. Please choose an option between $min and $max."
        return 1
    fi
    return 0
}
# Main script
# Prompt for interface name
read -p "Enter the internet interface OR (press Enter for detected: $interface)" net_interface
#read -p "Enter the internet interface (detected is: $interface)" interface
interface="${net_interface:-$interface}"  # Default IPs if user hits Enter
echo ""
# Check if IPv6 is available
if ipv6_available; then
    ipv6_available=true
else
    ipv6_available=false
fi
# Prompt for IP version selection 
echo "Select an option for preferred IP version: "
PS3="Select an option: "
options=("Public IPv4")
if [ "$ipv6_available" = true ]; then
    options+=("Public IPv6")
fi
select opt in "${options[@]}"; do
    case $REPLY in
        1)
            # Display IPv4 addresses as options
            echo "Available Public IPv4 addresses:"
            ipv4_addresses=$(get_ipv4_addresses)
            select ipv4_address in $ipv4_addresses; do
                if validate_input $REPLY 1 $(wc -w <<< "$ipv4_addresses"); then
                    break
                fi
            done
            echo "Selected Public IPv4 Address: $ipv4_address"
            # If IPv6 is available, present options to choose an IPv6 address
            if [ "$ipv6_available" = true ]; then
                echo "Choose a Public IPv6 address:"
                ipv6_addresses=$(get_ipv6_addresses)
                select ipv6_address in $ipv6_addresses; do
                    if validate_input $REPLY 1 $(wc -w <<< "$ipv6_addresses"); then
                        break
                    fi
                done
                echo "Selected Public IPv6 Address: $ipv6_address"
            fi
            break
            ;;
        2)
            if [ "$ipv6_available" = true ]; then
                # Display IPv6 addresses as options
                echo "Available Public IPv6 addresses (excluding link-local addresses):"
                ipv6_addresses=$(get_ipv6_addresses)
                select ipv6_address in $ipv6_addresses; do
                    if validate_input $REPLY 1 $(wc -w <<< "$ipv6_addresses"); then
                        break
                    fi
                done
                echo "Selected Public IPv6 Address: $ipv6_address"
            else
                echo "Public IPv6 is not available."
            fi
            break
            ;;
        *)
            echo "Invalid option. Please select again."
            ;;
    esac
done
echo ""
clear
    # Continue with the rest of your installation script...
    echo "Starting with installation..."
    echo ""
    # Your installation commands here...
# Update hostname
echo "$hostname" | tee /etc/hostname > /dev/null
hostnamectl set-hostname "$hostname"
echo "Updating Repo & System..."
echo "Please wait to complete process..."
apt update -y  >/dev/null 2>&1


# Check if lsb_release is available; install if missing
if ! command -v lsb_release &> /dev/null; then
     apt update
     apt install -y lsb-release >/dev/null 2>&1
fi

# Detect the OS distribution and version
distro=$(lsb_release -is)
version=$(lsb_release -rs)

if [[ "$distro" == "Ubuntu" && "$version" == "20.04" ]]; then
    echo "Detected Ubuntu 20.04 LTS. Installing Python 3.10 and WireGuard dependencies..."
     add-apt-repository ppa:deadsnakes/ppa -y >/dev/null 2>&1
     apt-get update -y >/dev/null 2>&1
     apt-get install -y python3.10 python3.10-distutils wireguard-tools net-tools --no-install-recommends >/dev/null 2>&1

elif [[ ( "$distro" == "Ubuntu" && ( "$version" == "22.04" || "$version" == "24.02" ) ) || ( "$distro" == "Debian" && "$version" == "12" ) ]]; then
    echo "Detected $distro $version. Proceeding with installation..."
        # Check if Python 3 is installed
        if ! check_dpkg_package_installed python3; then
            echo "Python 3 is not installed. Installing Python 3..."
            # Install Python 3 system-wide
            apt install -y python3 >/dev/null 2>&1
            # Make Python 3 the default version
            update-alternatives --install /usr/bin/python python /usr/bin/python3 1
        fi
        # Function to check the version of Python installed
        get_python_version() {
            python3 --version | awk '{print $2}'
        }
        # Check the Python version
        python_version=$(get_python_version)
        # Compare the Python version
       #if [[ "$(echo "$python_version" | cut -d. -f1)" -lt 3 || "$(echo "$python_version" | cut -d. -f2)" -lt 7 ]]; then
        if [[ "$(echo "$python_version" | cut -d. -f1)" -lt 3 || ( "$(echo "$python_version" | cut -d. -f1)" -eq 3 && "$(echo "$python_version" | cut -d. -f2)" -lt 10 ) ]]; then

            echo "Python version is below 3.10. Upgrading Python..."
            # Perform the system upgrade of Python
            apt update -y  >/dev/null 2>&1
            apt install -y python3 >/dev/null 2>&1
        else
            echo "Python version is 3.10 or above."
        fi

elif [[ "$distro" == "Debian" && "$version" == "11" ]]; then
    echo "Detected Debian 11. Installing Python 3.10 and WireGuard dependencies..."
    echo "Please wait."
    # Suppress output of the apt installation
     apt install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev \
    libssl-dev libreadline-dev libffi-dev libsqlite3-dev wget libbz2-dev wireguard-tools \
    net-tools >/dev/null 2>&1
    echo "Please wait.."
    # Download Python source and suppress output
    wget https://www.python.org/ftp/python/3.10.0/Python-3.10.0.tgz -q
    echo "Please wait..."
    # Extract Python source and suppress output
    tar -xvf Python-3.10.0.tgz >/dev/null 2>&1
    cd Python-3.10.0
    echo "Please wait...."
    # Suppress output of the configure, make, and make install commands
     ./configure --enable-optimizations >/dev/null 2>&1
    echo "Please wait....."
     make >/dev/null 2>&1
    echo "Please wait......"
    echo "Please wait...... Upgrading Python to v3.10 could take a while"
    echo "Please wait......"
     make altinstall >/dev/null 2>&1
    echo "Python installation...... success"
else

    echo "This script supports only Ubuntu 20.04 LTS, 22.04, 24.02, and Debian 11 & 12."
    echo "Your version, $distro $version, is not supported at this time."
    exit 1
fi


# Check if pip is installed
if ! command -v pip &> /dev/null; then
    echo "pip is not installed. Installing pip..."
    apt update >/dev/null 2>&1
    apt install -y python3-pip >/dev/null 2>&1
fi

# Check if bcrypt is installed
if ! python3 -c "import bcrypt" &> /dev/null; then
    echo "bcrypt is not installed. Installing bcrypt..."
    pip install bcrypt >/dev/null 2>&1
else
    echo "bcrypt is already installed."
fi
# Check for WireGuard dependencies and install them if not present
if ! check_dpkg_package_installed wireguard-tools; then
    echo "Installing WireGuard dependencies..."
    apt install -y wireguard-tools >/dev/null 2>&1
fi
# Install git if not installed
if ! check_package_installed git; then
    echo "Installing git..."
    apt install -y git >/dev/null 2>&1
fi
# Install ufw if not installed
if ! check_package_installed ufw; then
    echo "Installing ufw..."
    apt install -y ufw >/dev/null 2>&1
fi
# Install inotifywait if not installed
if ! check_package_installed inotifywait ; then
    echo "Installing inotifywait..."
    apt install -y inotify-tools >/dev/null 2>&1
fi
# Install cron  if not installed
if ! check_package_installed cron ; then
    echo "Cron is not installed. Installing..."
    apt install -y cron >/dev/null 2>&1
fi
# Now that dependencies are ensured to be installed, install WireGuard
echo "Installing WireGuard..."
apt install -y wireguard >/dev/null 2>&1
# Generate Wireguard keys
private_key=$(wg genkey 2>/dev/null)
echo "$private_key" | tee /etc/wireguard/private.key >/dev/null
public_key=$(echo "$private_key" | wg pubkey 2>/dev/null)
# Enable IPv4 forwarding if it's not already enabled
if ! grep -q '^#net.ipv4.ip_forward=1' /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
elif grep -q '^#net.ipv4.ip_forward=1' /etc/sysctl.conf; then
    # If it's commented, uncomment it
    sed -i '/^#net.ipv4.ip_forward=1/s/^#//' /etc/sysctl.conf >/dev/null
fi

# Enable IPv6 forwarding if it's not already enabled
if ! grep -q '^#net.ipv6.conf.all.forwarding=1' /etc/sysctl.conf; then
    echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
elif grep -q '^#net.ipv6.conf.all.forwarding=1' /etc/sysctl.conf; then
    # If it's commented, uncomment it
    sed -i '/^#net.ipv6.conf.all.forwarding=1/s/^#//' /etc/sysctl.conf >/dev/null
fi
# Apply changes
sysctl -p >/dev/null
ssh_port=$(ss -tlnp | grep 'sshd' | awk '{print $4}' | awk -F ':' '{print $NF}' | sort -u)
echo "Configuring firewall (UFW) ....."
# Configure firewall (UFW)
echo "Stopping firewall (UFW) ....."
ufw disable
echo "Creating firewall rules ....."
ufw allow 10086/tcp
echo "Creating ($ssh_port) firewall rules ....."
ufw allow $ssh_port/tcp
echo "Creating ($dashboard_port) firewall rules ....."
ufw allow $dashboard_port/tcp
ufw allow 10086/tcp
echo "Creating ($wg_port) firewall rules ....."
ufw allow $wg_port/udp
echo "Creating (53) firewall rules ....."
ufw allow 53/udp
echo "Creating (OpenSSH) firewall rules ....."
ufw allow OpenSSH
echo "Enabling firewall rules ....."
ufw --force enable
mkdir /etc/wireguard/network
iptables_script="/etc/wireguard/network/iptables.sh"
#sed -i "s|^ListenPort =.*|ListenPort = $wg_port|g" /etc/wireguard/wg0.conf
if [[ -n $ipv6_address ]]; then
# Add Wireguard configuration
cat <<EOF | tee -a /etc/wireguard/wg0.conf >/dev/null
[Interface]
PrivateKey = $private_key
Address = $ipv4_address_pvt, $ipv6_address_pvt
ListenPort = $wg_port
EOF
else
 # Add Wireguard configuration
cat <<EOF | tee -a /etc/wireguard/wg0.conf >/dev/null
[Interface]
PrivateKey = $private_key
Address = $ipv4_address_pvt
ListenPort = $wg_port
EOF
fi
echo "Setting up Wireguard configuration ....."

# Add Wireguard Network configuration
echo "Setting up Wireguard Network ....."
ipv4_address_pvt0=$(convert_ipv4_format "$ipv4_address_pvt")
# Define the path to the iptables.sh script
cat <<EOF | tee -a "$iptables_script" >/dev/null
#!/bin/bash
# Wait for the network interface to be up
while ! ip link show dev $interface up; do
    sleep 1
done
# Set iptables rules for WireGuard
iptables -t nat -I POSTROUTING --source $ipv4_address_pvt0 -o $interface -j SNAT --to $ipv4_address
iptables -t nat -D POSTROUTING -o $interface -j MASQUERADE
# Set ip6tables rules for WireGuard (IPv6)
#ip6tables -t nat -I POSTROUTING --source ::/0 -o $interface -j SNAT --to $ipv6_address
# Add custom route for WireGuard interface
ip route add default dev wg0
# Add custom route for incoming traffic from WireGuard
ufw route allow in on wg0 out on $interface
EOF
cat <<EOF | tee -a /etc/systemd/system/wireguard-iptables.service >/dev/null
[Unit]
Description=Setup iptables rules for WireGuard
After=network-online.target
[Service]
Type=oneshot
ExecStart=$iptables_script
[Install]
WantedBy=multi-user.target
EOF
chmod +x $iptables_script
# Uncomment the ip6tables command if IPv6 is available
#if $ipv6_address && grep -q "#ip6tables" "$iptables_script"; then
if [[ -n $ipv6_address ]] && grep -q "#ip6tables" "$iptables_script"; then
    sed -i 's/#ip6tables/ip6tables/' "$iptables_script" >/dev/null
    sed -i "s|::/0|$ipv6_address_pvt|" "$iptables_script" >/dev/null
    #echo "Uncommented ip6tables command in $iptables_script"
fi
systemctl enable wireguard-iptables.service --quiet
# Enable Wireguard service
echo "Enabling Wireguard Service ....."
systemctl enable wg-quick@wg0.service --quiet
systemctl start wg-quick@wg0.service
# Change directory to /etc
cd /etc || exit
# Create a directory Easy-WGDashboard if it doesn't exist
if [ ! -d "Easy-WGDashboard" ]; then
    mkdir Easy-WGDashboard
    mkdir /etc/Easy-WGDashboard/monitor
fi
# Change directory to /etc/Easy-WGDashboard
cd Easy-WGDashboard || exit
# Install WGDashboard
echo "Installing WGDashboard ....."
git clone  -q https://github.com/iPmartNetwork/WGDashboard.git iPWGDashboard
cd WGDashboard/src
#apt install python3-pip -y && pip install gunicorn && pip install -r requirements.txt --ignore-installed
apt install python3-pip -y >/dev/null 2>&1 && pip install gunicorn >/dev/null 2>&1 && pip install -r requirements.txt --ignore-installed >/dev/null 2>&1
chmod u+x wgd.sh
./wgd.sh install >/dev/null 2>&1
# Set permissions
chmod -R 755 /etc/wireguard
# Start WGDashboard
./wgd.sh start >/dev/null 2>&1
# Autostart WGDashboard on boot
DASHBOARD_DIR=$(pwd)
SERVICE_FILE="$DASHBOARD_DIR/wg-dashboard.service"
# Get the absolute path of python3 interpreter
PYTHON_PATH=$(which python3)
# Update service file with the correct directory and python path
sed -i "s|<absolute_path_of_wgdashboard_src>|$DASHBOARD_DIR|g" "$SERVICE_FILE" >/dev/null
sed -i "/Environment=\"VIRTUAL_ENV={{VIRTUAL_ENV}}\"/d" "$SERVICE_FILE" >/dev/null
sed -i "s|{{VIRTUAL_ENV}}/bin/python3|$PYTHON_PATH|g" "$SERVICE_FILE" >/dev/null
# Copy the service file to systemd folder
cp "$SERVICE_FILE" /etc/systemd/system/wg-dashboard.service
# Set permissions
chmod 664 /etc/systemd/system/wg-dashboard.service

# Enable and start iPWGDashboard service
systemctl enable wg-dashboard.service --quiet
systemctl restart wg-dashboard.service

hashed_password=$(python3 -c "import bcrypt; print(bcrypt.hashpw(b'$password', bcrypt.gensalt(12)).decode())")
# Seed to wg-dashboard.ini
sed -i "s|^app_port =.*|app_port = $dashboard_port|g" $DASHBOARD_DIR/wg-dashboard.ini >/dev/null
sed -i "s|^peer_global_dns =.*|peer_global_dns = $dns|g" $DASHBOARD_DIR/wg-dashboard.ini >/dev/null
sed -i "s|^peer_endpoint_allowed_ip =.*|peer_endpoint_allowed_ip = $allowed_ip|g" $DASHBOARD_DIR/wg-dashboard.ini >/dev/null
sed -i "s|^password =.*|password = $hashed_password|g" $DASHBOARD_DIR/wg-dashboard.ini >/dev/null
sed -i "s|^username =.*|username = $username|g" $DASHBOARD_DIR/wg-dashboard.ini >/dev/null
sed -i "s|^welcome_session =.*|welcome_session = false|g" $DASHBOARD_DIR/wg-dashboard.ini >/dev/null
sed -i "s|^dashboard_theme =.*|dashboard_theme = dark|g" $DASHBOARD_DIR/wg-dashboard.ini >/dev/null
systemctl restart wg-dashboard.service

echo "Restarting Wireguard & WGDashboard services ....."

    echo ""
    echo ""

wg_status=$(systemctl is-active wg-quick@wg0.service)
dashboard_status=$(systemctl is-active wg-dashboard.service)
#wgmonitor_status=$(systemctl is-active wgmonitor.service)
    echo ""
echo "Wireguard Status: $wg_status"
echo "WGDashboard Status: $dashboard_status"
#echo "WGConfig Monitor Status: $wgmonitor_status"
    echo ""



if [ "$wg_status" = "active" ] && [ "$dashboard_status" = "active" ]; then
    # Get the server IPv4 address
    server_ip=$(curl -s4 ifconfig.me)
    # Display success message in green font
    echo -e "\e[32mGreat! Installation was successful!"
    echo "You can access Wireguard Dashboard now:"
    echo 'URL: http://'"$server_ip:$dashboard_port"
    echo "Username: $username"
    echo "Password: ***(hidden)***"
    echo ""
    echo "System will reboot now and after that Go ahead and create your first peers"
    echo -e "\e[0m" # Reset font color
# Reload systemd daemon
#systemctl daemon-reload
#systemctl restart wireguard-iptables.service
echo ""
echo ""
#echo "Rebooting system ......."
reboot
else
    echo "Error: Installation failed. Please check the services and try again."
fi
else
    echo "Installation aborted."
    exit 0
fi
#working
# Enhanced colorful and stylish welcome section
clear
print_separator

# Colorful ASCII Art Title
cat <<'EOF'
${CYAN} __        __ _                            _   _                 _   
  ____________________________________________________________________________
      ____                             _     _
 ,   /    )                           /|   /                                 
-----/____/---_--_----__---)__--_/_---/-| -/-----__--_/_-----------__---)__--
 /   /        / /  ) /   ) /   ) /    /  | /    /___) /   | /| /  /   ) /   ) 
_/___/________/_/__/_(___(_/_____(_ __/___|/____(___ _(_ __|/_|/__(___/_/____

${NC}
EOF

print_separator

# Stylish warning and info messages

# ...existing code...
echo -e "${RED}WARNING! Install only on Ubuntu 20.04, Ubuntu 22.04, Ubuntu 24.02 & Debian 11 & 12 systems ONLY${NC}"
echo -e "${GREEN}RECOMMENDED ==> Ubuntu 22.04${NC}"
print_separator

echo -e "${YELLOW}The following software will be installed on your system:${NC}"
echo -e "${BLUE}   - WireGuard Server\n   - WireGuard-Tools\n   - WGDashboard by donaldzou\n   - Gunicorn WSGI Server\n   - Python3-pip\n   - Git\n   - UFW - firewall\n   - inotifywait${NC}"
print_separator
# ...existing code...
# Add more color to final success and error messages
# ...existing code...
if [ "$wg_status" = "active" ] && [ "$dashboard_status" = "active" ]; then
    server_ip=$(curl -s4 ifconfig.me)
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✔ Great! Installation was successful!${NC}"
    echo -e "${CYAN}You can access WireGuard Dashboard now:${NC}"
    echo -e "${YELLOW}URL: http://$server_ip:$dashboard_port${NC}"
    echo -e "${BLUE}Username: $username${NC}"
    echo -e "${BLUE}Password: ***(hidden)***${NC}"
    echo -e "${CYAN}System will reboot now and after that you can create your first peers.${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    reboot
else
    echo -e "${RED}✖ Error: Installation failed. Please check the services and try again.${NC}"
fi
# ...existing code...
