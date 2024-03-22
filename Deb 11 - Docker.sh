#!/bin/bash
######################################################### Sistema Operacional  #
# Operating System: Debian GNU/Linux 10 (buster)
# Kernel: Linux 4.19.0-21-amd64
# Architecture: x86-64
# Swap: 1024 MB
######################################################### Usuários  #
# root: H1@23hn!
# cerberus: h1a23hn1

# Obs: cerberus (sudo)
######################################################### Rede  #
# enp0s3: NAT
# enp0s8: Host-Only
# enp0s9: Bridge

# Obs: enp0s3 e enp0s9 podem mudar de IP.

# /----------------------------------------------------------------- Conexaõ SSH
ssh root@127.0.0.2 -p 2222                   # Acesso a máquina via SSH

# /----------------------------------------------------------------- Pacote Sudo
apt install -y sudo                          # Instalação do pacote SUDO
sudo usermod -aG sudo cerberus               # Atribuido o usuário ao grupo SUDO

# /----------------------------------------------------------------- Interfaces
su - cerberus                                # Logando com usuário cerberus

# Configurando as intefaces de rede
sudo bash -c 'cat >> /etc/network/interfaces' << EOF

# The NAT network interface
allow-hotplug enp0s3
iface enp0s3 inet dhcp

# The Host-Only Static IP address
auto enp0s8
iface enp0s8 inet static
        address 192.168.56.10
        netmask 255.255.255.0
        network 192.168.56.0

# The primary network interface
allow-hotplug enp0s9
iface enp0s9 inet dhcp

EOF

sudo ifup enp0s3                             # Habilitando a interface NAT
sudo ifup enp0s8                             # Habilitando a interface Host-Only
sudo ifup enp0s9                             # Habilitando a interface Bridge

# /----------------------------------------------------------------- Repositórios
# Atualizando os repositórios do debian
# repositórios Debian 10: https://debgen.github.io/
#cat << EOF > /etc/apt/sources.list
sudo bash -c 'cat > /etc/apt/sources.list' << EOF
deb http://cdn-fastly.deb.debian.org/debian/ buster main contrib non-free
deb-src http://cdn-fastly.deb.debian.org/debian/ buster main contrib non-free

deb http://cdn-fastly.deb.debian.org/debian/ buster-updates main contrib non-free
deb-src http://cdn-fastly.deb.debian.org/debian/ buster-updates main contrib non-free

deb http://security.debian.org/ buster/updates main contrib non-free
deb-src http://security.debian.org/ buster/updates main contrib non-free

EOF

# Atualização do sistema
sudo apt -y update && sudo apt -y upgrade    # Atualização do sistema

######################################################################################################### Swap
# /----------------------------------------------------------------- SWAP
sudo swapon --show                           # Verificando se existe alguma swap
sudo free -h                                 # Varificano o espaço de memória
sudo fallocate -l 1G /swapfile               # Criando o arquivo para swap

################# Caso o comando acima não funcione, utiliza o comando abaixo
sudo dd if=/dev/zero of=/swapfile bs=1024 count=1048576
#################

sudo chmod 600 /swapfile                     # Permissão RW do usuário para o arquivo swap
sudo mkswap /swapfile                        # Comando para configurar a swap
sudo swapon /swapfile                        # Ativando a swap
sudo nano /etc/fstab                         # Para tornar as configurações permanentes, adicione a linha abaixo.
/swapfile swap swap defaults 0 0

sudo swapon --show                           # Verificando se existe alguma swap
sudo free -h                                 # Varificano o espaço de memória
cat /proc/sys/vm/swappiness                  # Verificando a frequência de uso da Swap (Padrão: 60)
# Para os ambientes em Produção deve-se utilizar um valor menor.

# Alterando o valor para 10.
sudo bash -c 'cat >> /etc/sysctl.conf' << EOF

vm.swappiness=10
EOF

sudo reboot                                  # Reinicie paa persistir as configurãções

#########################################################################################################
# /----------------------------------------------------------------- Docker
################# Removendo alguma instalação do Docker
sudo apt-get remove docker docker-engine docker.io containerd runc

# Instalação de dependências
sudo apt-get update

sudo apt-get -y install \
    ca-certificates \
    curl \
    gnupg

# Instalação das chaves GPG
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Instalação do Repositório
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalação do Docker
sudo apt-get update

sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin


sudo usermod -aG docker cerberus 
# newgrp docker
systemctl restart docker

docker --version