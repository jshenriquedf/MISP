# INSTALAÇÃO DO MISP - SUSE

## PASSO 1: Configuração INICIAIS.

### 1.1: Instalando o SUDO e editores.

> **Obs.**: Substitua o termo <user> pelo nome do usuário padrão.

```
# Logue no servidor e escale privilégio para root.
su -

# Instale o pacote SUDO e editores 
zypoer in -y sudo nano vim

# Adiciona o usuário padrão ao grupo de superusuário, caso já não esteja.
[[ $(groups <user> | grep wheen) ]] && usermod -aG wheen <user>

# Logue novamente como usuário padrão.
sudo - <user>
```

### 1.1: Criação do arquivo que será utilizado na configuração.

```
```

```

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

### 1.5: Configurando o arquivo /etc/rc.local.
> **Obs.**: Esse arquivo será utilizado para inicializar as variáveil de ambiente ao reniciar.
```
# Criando o arquivo RC.LOCAL, caso não exista..
[[ ! -f /etc/rc.local ]] && echo '#!/bin/sh -e' | sudo tee -a /etc/rc.local ; echo 'exit 0' | sudo tee -a /etc/rc.local ; sudo chmod u+x /etc/rc.local
```


## PASSO 2: Configuração REPOSITÓRIOS e instalando DEPENDÊNCIAS.

### 2.1: Configurando os REPOSITÓRIOS.
```
sudo SUSEConnect -p sle-module-desktop-applications/15.4/x86_64
sudo SUSEConnect -p sle-module-development-tools/15.4/x86_64
sudo SUSEConnect -p PackageHub/15.4/x86_64
sudo SUSEConnect -p sle-module-python3/15.4/x86_64
sudo SUSEConnect -p sle-module-legacy/15.4/x86_64
sudo SUSEConnect -p sle-module-web-scripting/15.4/x86_64
```

### 2.2: Instalando DEPENDÊNCIAS.
```
# Instalando o pacote para configuração de REDE.
sudo zypper in -y NetworkManager

# Instalando os pacotes base para demias instalções.
sudo zypper in -y \
    gcc make \
    git zip unzip \
    nano vim \
    cntlm gpg2 openssl curl unbound bind-utils \
    moreutils \
    redis \
    glibc-locale \
    libxslt-devel zlib-devel libgpg-error-devel libffi-devel libfuzzy-devel libxml2-devel libassuan-devel

# Instalando o GPG.
sudo zypper in -y haveged

# Instalando o APACHE2.
sudo zypper in -y httpd apache2-mod_php7

# Instalando o PYTHON 3.10.
sudo zypper in -y \
    python310 \
    python310-devel \
    python310-pip \
    python310-setuptools

# Instalando o PHP 7
sudo zypper in -y \
    php7 \
    php7-cli \
    php7-gd \
    php7-mysql \
    php7-bcmath \
    php7-opcache \
    php7-intl \
    php7-zip \
    php7-pear \
    php7-redis \
    php-composer2 \
    php7-fileinfo \
    php7-pcntl \
    php7-gmp \
    php7-pecl \
    php7-APCu \
    php7-posix \
    php7-xdebug

# Instalando o MARIADB
sudo zypper in -y \
    mariadb \
    mariadb-server

##### Os pacotes abaixo são recomendados, contudo opcionais.
# Instalando o SUPERVISOR
sudo zypper in -y supervisor

# Instalando o pacote supervisor para o PYTHON
sudo pip3 install supervisor

# Instalando o PHP7-FPM
sudo zypper in -y php7-fpm
```


## PASSO 3: Configuração os PACOTOS instalados.

### 3.1: Configure o aquivo .env com as senhas.
```
cat <<EOF | sudo tee  -a /home/$(echo $USER)/.env > /dev/null
[ADMINISTRACAO]
admin.org=ORGANIZACAO
admin.email=admin@admin.test
admin.pass=3dab0a06a21a3bdf64dd45818fa325ba3320e1c61eda41f027c1a19f3cd44bef

[REDIS]
redis.host=127.0.0.1
redis.port=6379
redis.data=13
redis.pass=53d1b618ba79807e73b9f446b4d5cfdfd8841918654aa1a25ef98710add37586

[SUPERVISOR]
supervisor.host=127.0.0.1
supervisor.port=9001
supervisor.user=supervisor
supervisor.pass=71941be3a5cda818fad1bf29192c3c957fbaff9118368f3f191735448c0fc97b

[MARIADB]
db.host=localhost
db.port=3306
db.admin.user=root
db.admin.pass=414521378ae7661ef921d6a36be785d493c66b6676a1dd08e2aab64366cc2ad6
db.misp.database=misp
db.misp.user=user_misp
db.misp.pass=fd50ef6aa0365598190065dc53af5cbaa595799835674865289e54a998b42df4


EOF
```

### 3.1: Configurando o GPG.
```
sudo systemctl enable --now haveged.service
```

### 3.2: Configurando o PYTHON.
```
# Criando o link simbólico PYTHON3.10, caso não exista.
[[ -e "/usr/bin/python3.10" ]] && sudo rm /usr/bin/python3 && sudo ln -s /usr/bin/python3.10 /usr/bin/python3

# Criando o link simbólico PYTHON, caso não exista.
[[ ! -e "/usr/bin/python" ]] && sudo ln -s /usr/bin/python3 /usr/bin/python

# Adicionando o PYTHON no update-alternatives.
[[ ! $(sudo update-alternatives --list python) ]] && sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 1

# Setando o PYTHON no update-alternatives.
readlink -f /usr/bin/python | grep python3 || sudo alternatives --set python /usr/bin/python3
```

### 3.3: Configurando o REDIS.
```
# Criando os arqios para utilização.
sudo cp -a /etc/redis/default.conf.example /etc/redis/default.conf
sudo cp -a /etc/redis/sentinel.conf.example /etc/redis/sentinel.conf

# Configurnado o arquivo /etc/redis/default.conf para utilização.
sudo sed -i "s/^\(bind\ \).*/\1${REDIS_HOST} -::1/" /etc/redis/default.conf
[[ ${REDIS_PASS} != '' ]] && sudo sed -i "s/^#\ \(requirepass\ \).*/\1${REDIS_PASS}/" /etc/redis/default.conf
sudo sed -i "s/^\(appendonly\ \).*/\1yes/" /etc/redis/default.conf
sudo sed -i 's/^\(appendfilename\ \).*/\1\"appendonly.aof\"/' /etc/redis/default.conf

loginfo "[CONFIG][REDIS]" "Configurando: ${COLOR_RED}vm.overcommit_memory${COLOR_NC}."
[[ ! "$(grep vm.overcommit_memory /etc/rc.local)" ]] && sudo sed -i -e '$i \sysctl vm.overcommit_memory=1\n' /etc/rc.local

sudo chown -R redis:redis /etc/redis

sudo systemctl daemon-reload
sudo systemctl enable --now redis@default
```

### 3.3: Configurando o PHP 7.
```
```








