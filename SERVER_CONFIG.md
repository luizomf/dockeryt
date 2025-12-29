# Initial configs for our production server

I made a video explaining everything you'll read below.

- [Server para Deploy Docker em Produção](https://youtu.be/0eG9Vorc-TY)

---

## The server specs on GCP

I'm using a VM (Virtual Machine) from Google Cloud Platform.

- Region: us-central1 (Iowa)
- Preset: e2-medium (2 vCPU, 1 core, 4 GB memory)
- OS: Ubuntu 24.04 LTS (x86/64, amd64 noble)
- Disk: Default disk with 10 GB
- Ports: 22/80/443 opened

---

## SSH Keys for your user

Those are the commands I used in the video:

```sh
# ON YOUR COMPUTER
# I'm naming my keys "delete-me" to remember to delete it later
# you can add a good name here for your own keys.
# The -C option is usually used for e-mail. But, as GCP uses
# it to create a user, I'm adding the username I want to use.
# Press ENTER til the end (or add a passphrase if you wish)
ssh-keygen -t ed25519 -a 100 -f ~/.ssh/delete-me -C "luizotavio"

# Now open the ~/.ssh/delete-me.pub (note the .pub at the end)
# and copy everything inside this file (CTRL+C)
cat ~/.ssh/delete-me.pub | pbcopy # pbcopy is for macOS only
# Use if you are in another OS.
cat ~/.ssh/delete-me.pub # This WILL SHOW the key in your terminal

# ON GOOGLE CLOUD PLATFORM
# Go to Compute Engine > Metadata > SSH Keys
# Edit > Add Item > Save

# ON YOUR COMPUTER
# For testing, copy the external IP Address of your VM and type
ssh YOUR_USER@YOUR_VM_IP -i ~/.ssh/delete-me

# I'm in. You can change your ~/.ssh/config so that it uses
# the ~/.ssh/delete-me key always. That way, you wont need to type
# -i anymore. Here is an example of that:
Host whatever
    IgnoreUnknown AddKeysToAgent,UseKeychain
    UseKeychain yes
    AddKeysToAgent yes
    IdentityFile ~/.ssh/delete-me
    HostName YOUR_VM_IP_OR_HOST
    User YOUR_USER
    Port 22

# And now just do something like
ssh whatever

# P.S. on macOS I did not need to restart the ssh server or client, but
# maybe you would need to do that.
```

---

## Prepare the server

More commands I used in the video:

```sh
# Update the packages
sudo apt update && sudo apt upgrade -y

# Let's prepare the users and permissions
# Group for the GitHub user (keep track of the --uid and --gid)
sudo groupadd github --gid 1010
sudo useradd github --create-home --shell /bin/bash --uid 1010 --gid 1010
# Or shorter
# sudo useradd github -m -s /bin/bash --uid 1010 --gid 1010

# Now we create a group for the whole project. That way, we will be able
# to set permissions on the group, not the user. It will allow multiple
# users to have permissions on the project.
sudo groupadd project --gid 1020

# In case you wanna check those users and groups
cat /etc/passwd # shows users
cat /etc/group # shows groups and member users

# Let's add all the users to the "project" group
sudo usermod -aG project github
sudo usermod -aG project $USER # your user

# If you want to test the GitHub user
sudo passwd github # set its password
su github # login you'll have to type the password
cd ~ # Goes to the user home and do whatever you want
```

---

## Project Directory (Folder)

Avoid creating the project directory in your user's home directory. If you do
so, you'll need to change the permissions of your own home. That's not a good
idea.

Instead, create the project directory in the root directory of the server (e.g.
`/your_project_name`).

```sh
# Let's do that.
# My project is called `dockerlabs`
sudo mkdir -p /dockerlabs

# Now, Let's fix the permissions and group
# Remember the `project` group I told you to create (project)? That group will
# have # permissions on this folder. Since our users are members of that group,
# they will also have the same permissions.
sudo chgrp -R project /dockerlabs

# That 7[7]5 (7) in the middle, means that our group have the same permissions
# as the owner of that directory (the first 7 is the owner).
# The 5 means everyone else (not the owner and not our group) can read and
# execute, but not write.
# This works like that:
# Owner    Group    Others
# Read=4   Write=2  Execute=1
#      4+        2+         1   = 7 to the owner
#      4+        2+         1   = 7 to the group
#      4+        0+         1   = 5 to the others
sudo chmod -R 775 /dockerlabs

# Now we have to make sure that all files created in that folder will
# belong to the project group. That is called SetGID.
sudo chmod g+s /dockerlabs/
# Test it out with the github user
# I talked about this permission in the video below
# https://youtu.be/iuO3fOuyNFk
# But in short, this will make your "ls -l" show:
# rwxrwsr-x <- that rws in the middle means READ, WRITE, EXECUTE and SGID.
#  7 7+s 5
# SGID -> All files in that directory will have the group "project"
```

---

## SSH settings

```sh
# I don't know if I'm mistaken here, but I'm pretty sure in some Linux
# distributions, the "/etc/ssh" can be "/etc/sshd" instead. You'll
# have to check it out on your own server.
sudo vim /etc/ssh/sshd_config

# Look for these options (they can be commented or not even exist at all)
PubkeyAuthentication yes # only allow access with ssh keys
PasswordAuthentication no # do not allow no password login
KbdInteractiveAuthentication no # we don't need that (it's a 2FA)
ChallengeResponseAuthentication no # we also don't need that
PermitRootLogin no # never allow root login
PermitEmptyPasswords no # never allow empty password
UsePAM yes # this is the authentication method

# If you want even more security, add users and groups allowed to login
# If you do something wrong here, you wont be able to login later.
# ALWAYS TEST BEFORE CLOSING YOUR CURRENT CONNECTION.
AllowUsers github YOUR_USER
AllowGroups github YOUR_USER_GROUP project

# Save the file and restart the ssh server.
sudo systemctl restart ssh
# or
# sudo systemctl restart sshd

# PLEASE, DO NOT CLOSE YOUR CURRENT CONNECTION
# First, test if you can login in another terminal window
```

---

## Fail2Ban jails

This is a service that will watch logs and ban IPs trying to do something
suspicious. I'm configuring only `sshd`, so it will block base on wrong
authentications. But Fail2Ban can do A LOT more.

- [Fail2Ban - Daemon to ban hosts that cause multiple authentication errors](https://github.com/fail2ban/fail2ban)

```sh
# If you don't have python, install it
sudo apt install python3

# Install Fail2Ban
sudo apt install fail2ban

# Create a jail.local. The default uses jail.conf and it can
# be replaced when you install a new Fail2Ban version.
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Change the configuration as needed.
# Here I'm configuring Fail2Ban to ban people trying to to login via SSH.
sudo nano /etc/fail2ban/jail.local

# Copy, paste and uncomment all lines below
#
# [sshd]
#
# enabled = true
# port = ssh
# maxretry = 1
# bantime = 24h
#
# # 🛑 END. YOU MUST DELETE THIS

# Restart Fail2Ban service
sudo systemctl restart fail2ban

# Verify
sudo fail2ban-client status # All jails
sudo fail2ban-client status sshd # Or sshd jail
```

---

## A simple firewall (ufw)

We know that GCP has a firewall but, in case you are using another service, here
is how to set it up:

```sh
# Install UFW
sudo apt update && sudo apt install -y ufw

# The default rule is:
# Deny everything that is coming from outside our server (from out to in)
# Allow everything that we are sending out from our server (from in to out)
sudo ufw default deny incoming # 🔴 deny every incoming request
sudo ufw default allow outgoing # 🟢 allow every outgoing request

# We are connected to the service using this port
# Caution here. SSH is port 22 if you need it.
sudo ufw allow ssh

# If you have a list of IPs you want to allow on port 80 and 443 (e.g. cloudflare)
# use something like this.
# for ip in $(curl -s https://www.cloudflare.com/ips-v4); do
#     sudo ufw allow proto tcp from $ip to any port 80,443 comment 'Cloudflare IPv4'
# done

# Same thing, but for IPv6
# for ip in $(curl -s https://www.cloudflare.com/ips-v6); do
#     sudo ufw allow proto tcp from $ip to any port 80,443 comment 'Cloudflare IPv6'
# done

# I'm going to allow anything on port 80 and 443
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable the firewall
sudo ufw enable
# Check
sudo ufw status

# Before you do anything, first check if all the rules are ok
# them we can reboot the server.
sudo ufw status verbose

# Example:
# To                         Action      From
# --                         ------      ----
# 22/tcp                     ALLOW IN    Anywhere
# 80/tcp                     ALLOW IN    Anywhere
# 443/tcp                    ALLOW IN    Anywhere
# 22/tcp (v6)                ALLOW IN    Anywhere (v6)
# 80/tcp (v6)                ALLOW IN    Anywhere (v6)
# 443/tcp (v6)               ALLOW IN    Anywhere (v6)

```

---

## Simple Python HTTP Server for testing

After rebooting the server, to make sure it is working correctly, we can spawn a
simples Python HTTP server for testing.

This is really simples, just create an HTML file on your project directory:

```sh
# My project directory is `/dockerlabs`
touch /dockerlabs/index.html
# Open that file in your editor of choice (I'm using vim)
vim /dockerlabs/index.html
```

Now add a dummy HTML in the file. We need it to check the response.

```html
<!doctype html>
<html>
  <head>
    <title>Hello, world!</title>
  </head>

  <body>
    <h1>Hello, world!</h1>
  </body>
</html>
```

Now just run this python command:

```sh
# python or python3
# 0.0.0.0 is the host and 80 is the port (you don't have to change anything)
# We want to test the HTTP and the port is 80
# The only thing you may need to change in this command is the "/dockerlabs/"
# to the name of your project.
python -m http.server -d /dockerlabs/ -b 0.0.0.0 80
```

Now, just test your server's external IP or domains in your browser with:

- `http://YOUR_SERVER_EXTERNAL_IP`
- `http://YOUR_SERVER_DOMAIN`

You should see "Hello, world!" on your browser.

That is it.

---

## Docker installation

There is no secrets here. I'm following Docker's documentation:

- [Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)

As of today (Dec 28, 2025), it goes like this:

```sh
# Remove any previous installations
sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)

# Add Docker's official GPG key:
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

# Update and install
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Now you can check the installation
sudo systemctl status docker

# For me, the service was "active", but you can start if it is not
sudo systemctl start docker

# DOCKER COMMANDS REQUIRE SUDO ON LINUX
# If you wish to use docker without "sudo", add you user to "docker" group
sudo usermod -aG docker $USER
# We have the GitHub user as well
sudo usermod -aG docker github

# Maybe you should reboot the server to see if the service will start on its own (I will)

# After all that, if you want to test it out
docker run --rm hello-world

# Now clean
```

---
