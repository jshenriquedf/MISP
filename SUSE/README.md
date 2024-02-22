# INSTALAÇÃO DO MISP - SUSE

## PASSO 1: Configuração INICIAIS.

### 1.1: Instalando e configurando o sudo.
```
# Logue no servidor e escale privilégio para root.
su -

# Instale o pacote SUDO
zypoer in -y sudo

# Adiciona o usuário padrão ao grupo de superusuário, caso já não esteja.
[[ $(groups cerberus | grep wheen) ]] && usermod -aG wheen <user>

# Logue novamente como usuário padrão.
sudo - <user>

# Configurando o usuário padrão na pasta sudoers.
[[ ! -f /etc/sudoers.d/<user> ]] && echo "<user> ALL=(ALL:ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/<user>

# Habilitando a gravação de log dos comando SUDO.
sudo sed -i '/Defaults\ log_output/i Defaults\ logfile=\/var\/log/\sudo.log' /etc/sudoers

# Definindo o tempo para que não seja solicitado a senha novamente.
sudo sed -i '/Defaults\ log_output/i Defaults\ timestamp_timeout=60' /etc/sudoers
```

### 1.2: Configurando o TimeZone.
```
# Definidno o TimeZone de São Paulo - BR.
sudo timedatectl set-timezone America/Sao_Paulo

# Configurnaod o NTP e o FallbackNTP par antp.br.
sudo sed -i "s/^#\(NTP=\).*/\1a.ntp.br/g" /etc/systemd/timesyncd.conf
sudo sed -i "s/^#\(FallbackNTP=\).*/\1a.ntp.br/g" /etc/systemd/timesyncd.conf

# Habilitando o NTP
sudo timedatectl set-ntp true

# Sicronizando o relógio para a referência local.
sudo sudo hwclock --systohc --localtime

# Reiniciando o serviço para aplicar as configurações.
sudo service systemd-timesyncd restart

# Setando a configuração do DATE no padrão BR.
sudo localectl set-locale LC_TIME=pt_BR.UTF-8

# Expotando variável local.
export LC_TIME=pt_BR.UTF-8
```

### 1.3: Configuração do arquivo **SWAP**.

> Criando arquivo e habilitando o seu uso.
```
# Criando o arquivo que será utilizado como SWAP.
sudo touch /swapfile

# Alterando a permissão do arquivo, de forma a não permitir atualizações de cópias.
sudo chattr +C /swapfile

# Definindo o tamanho do aquivo de SWAP.
sudo fallocate -l 2G /swapfile

# Permitindo read e write para apenas o dono do arquivo.
sudo chmod 0600 /swapfile

# Prepara uma partição ou arquivo para ser usado como área de memória virtual (swap).
sudo mkswap /swapfile

#  Habilita uma área de swap.
sudo swapon /swapfile

#  Adiciona o arquivo para carregamento durante o boot.
echo /swapfile none swap defaults 0 0" | sudo tee -a /etc/fstab
```

> **Obs.**: Para verificar o espaço ataual apos configuração da **SWAP**.
```
# Verifica e mostra a swap configurada.
sudo swapon --show

# Mostra todo espaço para utilização como memória.
sudo free -th
```

### 1.4: Configurando o arquivo /etc/hosts.
```
# Configurnado o arquivo HOSTS com o hostname.
echo "127.0.0.1       $(hostname).brb.com.br $(hostname)" | sudo tee -a /etc/hosts
```

### 1.4: Configurando o arquivo /etc/rc.local.
> **Obs.**: Esse arquivo será utilizado para inicializar as variáveil de ambiente ao reniciar.
```
# Criando o arquivo RC.LOCAL, caso não exista..
[[ ! -f /etc/rc.local ]] && echo '#!/bin/sh -e' | sudo tee -a /etc/rc.local ; echo 'exit 0' | sudo tee -a /etc/rc.local ; sudo chmod u+x /etc/rc.local
```















