# Secure-SSH-Setup
This Bash script sets up a secure SSH server on a Linux machine by performing several tasks including package installation, SSH port configuration, UFW firewall setup, SSH key generation, and public key transfer.


Install Necessary Packages: Installs openssh-server, openssh-client, and ufw firewall.

Configure SSH Port: Allows setting a custom SSH port and disables root login.

Enable UFW Firewall: Configures UFW to allow the custom SSH port and sets default firewall rules.

Generate SSH Key Pair: Generates a new SSH key pair for secure authentication.

Send Public Key via SSH: Copies the generated public key to a specified remote server for passwordless SSH login.

Requirements
Root or sudo privileges
Supported package manager (apt, pacman, dnf, or zypper)
