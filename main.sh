#!/bin/bash


check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root or use sudo."
        exit 1
    fi
}

detect_package_manager(){
    if command -v apt-get &> /dev/null; then
        echo "apt"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v zypper &> /dev/null; then
        echo "zypper"
    else
        echo "Unsupported package manager."
        exit 1
    fi
}

install_packages() {
    echo "installing openssh-server, openssh-client and ufw firewall"

    local package_manager=$(detect_package_manager)
    echo "Detected package manager: $package_manager"

    case "$package_manager" in
        apt)
            apt-get update
            apt-get install -y openssh-server openssh-client ufw
	    apt-get update
            systemctl start ssh
	    systemctl enable ssh
            systemctl start sshd
	    systemctl enable sshd

            ;;
        pacman)
            pacman -Sy
            pacman -S --noconfirm openssh ufw 
            pacman -Sy
	    systemctl start sshd
	    systemctl enable sshd

            ;;
        dnf)
            dnf install -y openssh ufw
            ;;
        zypper)
            zypper refresh
            zypper install -y openssh  ufw
            ;;
        *)
            echo "Unsupported package manager."
            exit 1
            ;;
    esac
}

config_ssh_port(){

    # Backup sshd_config
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

    echo -n "set custom port for ssh(default 22): "
    read port

    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
        echo "Error: Port must be a number."
        exit 1
    fi

    if ((port < 1 || port > 65535)); then
        echo "Error: Port number out of range (1-65535)."
        exit 1
    fi
    
   	echo "Port $port" >> /etc/ssh/sshd_config
    #sed -i "/^Port/c\Port $port" /etc/ssh/sshd_config
    echo "AddressFamily inet" >> /etc/ssh/sshd_config
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config
    

    echo "port $port is set for ssh connection"
    echo "next time you connect to this server via ssh type ssh hostname@ip_address -P$port"
    
	systemctl restart sshd
 	systemctl restart ssh

}

config_ufw(){
    echo "setting ufw firewall"
    sudo ufw enable
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow "$port" 
    
    sudo ufw status verbose

    sudo sed -i 's/^\(ENABLE_LOGGING=\).*/\1yes/' /etc/ufw/ufw.conf
    sudo ufw reload
}

generate_ssh_key() {
    read -p "Enter your email : " email
    ssh-keygen -t rsa -b 4096 -C "$email" -f ~/.ssh/id_rsa -N ""
    echo "Done:"
    echo "Public key: ~/.ssh/id_rsa.pub"
    echo "Private key: ~/.ssh/id_rsa"
}

send_public_key_via_ssh() {
    read -p "Enter SSH username@hostname : " server_ssh_address

    if [ -f ~/.ssh/id_rsa.pub ]; then
        ssh-copy-id -i ~/.ssh/id_rsa.pub "$server_ssh_address"
        if [ $? -eq 0 ]; then
            echo "Public key successfully copied to $server_ssh_address"
        else
            echo "Failed to copy public key to $server_ssh_address"
        fi
    else
        echo "Public key file not found. Generate SSH key pair first."
    fi
}


show_menu() {
    clear
    echo "##############################################"
    echo "########## Secure SSH Setup Script ###########"
    echo "##############################################"
    echo "1. Install necessary packages"
    echo "2. Config SSH port"
    echo "3. Enable ufw firewall"
    echo "4. Generate SSH key pair"
    echo "5. Send public key via SSH"
    echo "6. Exit"
    echo "##############################################"

    read -p "Enter [1-6] > " choice
    case $choice in
        1) install_packages  ;;
        2) config_ssh_port ;;
        3) config_ufw ;;
        4) generate_ssh_key ;;
        5) send_public_key_via_ssh ;;
        6) echo "Setup complete."; exit ;;
        *) echo "Invalid choice. Please enter a number from 1 to 4." ;;
    esac
}

main() {
    check_root
    while true; do
        show_menu
        read -p "Press Enter to continue..."
    done
}

main
