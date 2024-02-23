# INSTALAÇÃO DO MISP - SUSE

## PASSO 1: Configuração INICIAIS.

### 1.1: Habilitando o serviço SSH para habilitar acesso remoto.

> **Obs.**: Caso não consiga acessar o servidor via SSH verifique se está habilitado no FIREWALL.

```
# Verificando se o serviço SSH está habilitado.
firewall-cmd --list-all

# Adicionando o serviço SSH na Zona PUBLIC de forma permanente.
firewall-cmd --zone=public --add-service=ssh --permanent

# Reiniciando o servico para aplicar as configurações.
systemctl restart firewalld.service
```

### 1.2: Configurnado o IPTABLES.

```
...
```

### 1.3: Instalando o SUDO e realizando configurações de uso do SUDO.

> **Obs1.**: Instala os pacotes SUDO e VIM.

> **Obs2.**: Adiciona o usuário ao grupo wheel.

> **Obs3.**: Configura a perissão do usuário no sudoers.

```
# Acesse o servido com via SSH
su -c 'zypper in -y sudo vim \
    && [ -z $(groups "${USER}" | grep wheel) ] && usermod -aG wheel "${USER}" \
    && echo "${USER} ALL=(ALL:ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/"${USER}"'

# Habilitando a gravação de log dos comando SUDO.
sudo sed -i '/Defaults\ log_output/i Defaults\ logfile=\/var\/log/\sudo.log' /etc/sudoers

# Definindo o tempo para que não seja solicitado a senha novamente.
sudo sed -i '/Defaults\ log_output/i Defaults\ timestamp_timeout=60' /etc/sudoers
```

### 1.4: Criação do diretório "admin" para arquivos de configuração.

```
# Cria o diretório /admin
sudo mkdir /admin

# Entra na pasta /admin
cd /admin
```

### 1.5: Criação do arquivo que será utilizado na configuração.

```
# Criando o arquivo /admin/.env
sudo touch /admin/.env

# Alterando a permissão do arqui para READ e WRITE apenas para o dono do arquivo.
sudo chmod 0600 /admin/.env

# Abra o arquivo .env com o coimando abaixo e cole as configurações abaixo.
sudo vim /admin/.env
```

## Configurações.

> **Obs1.**: Abra o arquivo .env com o coimando abaixo e cole as configurações abaixo.

> **Obs2.**: Utilize o condando **sudo vim /admin/.env**.

```
[ADMIN]
ADMIN_HOSTNAME=misp
ADMIN_SITE=misp.local
AMDIN_PROXY=http://<user><pass>@<host>:<port>

[MISP]
WWW_USER=wwwrun
SUDO_WWW=sudo sudo -H -u wwwrun
SALT_PASS=
PATH_TO_MISP=/srv/www/MISP
PATH_TO_CAKE=/srv/www/MISP/app/Console/cake

[PYTHON]
VERSION_PYTHON=310

[PHP]
PHP_FPM=false
PHP_PECL=true
PHP_DIR_REDIS=/etc/php7/conf.d/redis.ini
PHP_DIR_CLI=/etc/php7/cli/php.ini
PHP_DIR_APACHE=/etc/php7/apache2/php.ini

[SWAP]
SWAP_ENABLE=true
SWAP_FILE=/swapfile
SWAP_SIZE=3

[REDIS]
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
REDIS_DATA=13
REDIS_PASS=

[SUPERVISOR]
SUPERVISOR_ENABLE=true
SUPERVISOR_HOST=127.0.0.1
SUPERVISOR_PORT=9001
SUPERVISOR_USER=supervisor
SUPERVISOR_PASS=

[DB]
DB_ADMIN_HOST=localhost
DB_ADMIN_PORT=3306
DB_ADMIN_USE=root
DB_ADMIN_PASS=

DB_MISP_DATABASE=misp
DB_MISP_USE=misp
DB_MISP_PASS=
```

> Após inserir as informações acima, faça as alterações necessárias, como adição senha e e-mail de login.

> Caso deseje, o comando abaixo gera senhas automaticamento com openssl.

```
sudo sed -i "s/^\(.*_PASS=\).*/\1$(openssl rand -hex 32)/" /admin/.env
```

### 1.6: Exportando as variáveis setadas no arquivo .env.

```
export $(sudo egrep -v "^\s*(;|$|\[)" /admin/.env | cut -f1 -d$'\t' | cut -f1 -d' ' | xargs)
```

## PASSO 2: Configurações LOCAIS.

### 2.1: Configuração do DATATIME.

```
sudo timedatectl set-timezone America/Sao_Paulo
sudo sed -i "s/^#\(NTP=\).*/\1a.ntp.br/g" /etc/systemd/timesyncd.conf
sudo sed -i "s/^#\(FallbackNTP=\).*/\1a.ntp.br/g" /etc/systemd/timesyncd.conf
sudo timedatectl set-ntp true
sudo sudo hwclock --systohc --localtime
sudo service systemd-timesyncd restart

sudo localectl set-locale LC_TIME=pt_BR.UTF-8
export LC_TIME=pt_BR.UTF-8
```

### 2.2: Configuração do HOSTNAME.

```
sudo hostnamectl set-hostname ${ADMIN_HOSTNAME}
```

### 2.3: Configuração do HOSTS.

```
echo "127.0.0.1       ${ADMIN_SITE} ${ADMIN_HOSTNAME}" | sudo tee -a /etc/hosts
```

### 2.4: Configuração do RC.LOCAL.

Criação e configuração do arquivo /etc/rc.local caso não exista.

```
# Criação do arquivo /etc/rc.local.
echo '#!/bin/sh -e' | sudo tee /etc/rc.local
echo 'exit 0' | sudo tee -a /etc/rc.local

# Aplicando as permissões de execução do arquivo /etc/rc.local.
sudo chmod u+x /etc/rc.local
```

## PASSO 3: REPOSITÓRIOS.

### 3.1: Repositórios necessários para SUSE SLE 15 SP4.

> **Obs.**: Esses repositórios deverão ser adicionadas, caso não existam.

```
sudo SUSEConnect -p sle-module-desktop-applications/15.4/x86_64
sudo SUSEConnect -p sle-module-development-tools/15.4/x86_64
sudo SUSEConnect -p PackageHub/15.4/x86_64
sudo SUSEConnect -p sle-module-python3/15.4/x86_64
sudo SUSEConnect -p sle-module-legacy/15.4/x86_64
sudo SUSEConnect -p sle-module-web-scripting/15.4/x86_64
```

### 3.2: Instalação de DEPENDÊNCIAS.

```
sudo zypper in -y \
    gcc make \
    git zip unzip \
    nano \
    cntlm gpg2 openssl curl unbound bind-utils \
    moreutils \
    redis \
    glibc-locale \
    libxslt-devel zlib-devel libgpg-error-devel libffi-devel libfuzzy-devel libxml2-devel libassuan-devel

sudo zypper in -y haveged

sudo zypper in -y httpd apache2-mod_php7

sudo zypper in -y \
    python310 \
    python310-devel \
    python310-pip \
    python310-setuptools

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

sudo zypper in -y \
  mariadb \
  mariadb-server
```

### 3.3: Instalação do SUPERVISOR.

> **Obs.**: Essa instalação derevá ser realizada caso deseje que o **SUPERVISOR** gerencie os **Works** do **MISP**.
```
[[ ${SUPERVISOR_ENABLE} == true ]] && sudo zypper in -y supervisor

[[ ${SUPERVISOR_ENABLE} == true ]] && pip3 install --proxy=${AMDIN_PROXY} -U --no-warn-script-location supervisor
```

## PASSO 4: Configuração das DEPENDÊNCIAS.

### 4.1: Configuração do GPG.

```
sudo systemctl enable --now haveged.service
```

### 4.2: Configuração do PYTHON.

```
sudo rm /usr/bin/python3
sudo ln -s /usr/bin/python3.10 /usr/bin/python3
[[ ! -e "/usr/bin/python" ]] && sudo ln -s /usr/bin/python3 /usr/bin/python

[[ ! $(sudo update-alternatives --list python) ]] && sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 1
readlink -f /usr/bin/python | grep python3 || sudo alternatives --set python /usr/bin/python3
```
### 4.3: Configuração do REDIS.

```
sudo cp -a /etc/redis/default.conf.example /etc/redis/default.conf
sudo cp -a /etc/redis/sentinel.conf.example /etc/redis/sentinel.conf

sudo sed -i "s/^\(bind\ \).*/\1127.0.0.1 -::1/" /etc/redis/default.conf
sudo sed -i "s/^\(appendonly\ \).*/\1yes/" /etc/redis/default.conf
sudo sed -i 's/^\(appendfilename\ \).*/\1\"appendonly.aof\"/' /etc/redis/default.conf

[[ ! "$(grep vm.overcommit_memory /etc/rc.local)" ]] && sudo sed -i -e '$i \sysctl vm.overcommit_memory=1\n' /etc/rc.local

sudo chown -R redis:redis /etc/redis

sudo systemctl daemon-reload
sudo systemctl enable --now redis@default
```
> **Obs1.**: Como de medida de segurança é recomendado a utilização de senha para acesso ao REDIS.

> **Obs2.**: O comando abaixo verifica se a variável REDIS_PASS existe e se foi definido senha, caso positivo será configurado.


```
# Verificada e adição senha, caso exista.
[[ ! -z ${REDIS_PASS} ]] && sudo sed -i "s/^#\ \(requirepass\ \).*/\1${REDIS_PASS}/" /etc/redis/default.conf

# Reiniciando o servidor REDIS
sudo systemctl restart redis@default
```

### 4.4: Configuração do PHP 7.

```
# Configuração do módulo REDIS no PHP7.
sudo sed -i "s|.*redis.session.locking_enabled = .*|redis.session.locking_enabled = 1|" ${PHP_DIR_REDIS}
sudo sed -i "s|.*redis.session.lock_expire = .*|redis.session.lock_expire = 30|" ${PHP_DIR_REDIS}
sudo sed -i "s|.*redis.session.lock_wait_time = .*|redis.session.lock_wait_time = 50000|" ${PHP_DIR_REDIS}
sudo sed -i "s|.*redis.session.lock_retries = .*|redis.session.lock_retries = 30|" ${PHP_DIR_REDIS}

# Cópia de backup do aruivo /etc/php7/cli/php.ini.
sudo cp -a ${PHP_DIR_CLI} ${PHP_DIR_CLI}_old

sudo sed -i "s/memory_limit = .*/memory_limit = 2048M/" "${PHP_DIR_CLI}"
sudo sed -i "s/max_execution_time = .*/max_execution_time = 300/" "${PHP_DIR_CLI}"
sudo sed -i "s/upload_max_filesize = .*/upload_max_filesize = 50M/" "${PHP_DIR_CLI}"
sudo sed -i "s/post_max_size = .*/post_max_size = 50M/" "${PHP_DIR_CLI}"

sudo sed -i "s|.*session.use_strict_mode = .*|session.use_strict_mode = 1|" "${PHP_DIR_CLI}"
sudo sed -i "s|.*session.serialize_handler = .*|session.serialize_handler = php|" "${PHP_DIR_CLI}"
sudo sed -i "s|.*session.sid_length = .*|session.sid_length = 32|" "${PHP_DIR_CLI}"
sudo sed -i "s|.*session.sid_bits_per_character = .*|session.sid_bits_per_character = 5|" "${PHP_DIR_CLI}"

sudo sed -i '/expose_php =/ s/.*/expose_php = Off/' "${PHP_DIR_CLI}"

sudo sed -i "s|^session.save_handler = .*|session.save_handler = redis|" "${PHP_DIR_CLI}"
sudo sed -i "s|^session.save_path = .*|session.save_path = 'tcp://127.0.0.1:6379'|" "${PHP_DIR_CLI}"

[[ ! -z ${REDIS_PASS} ]] && sudo sed -i "s|.*session.save_path = .*|session.save_path = 'tcp://${REDIS_HOST}:${REDIS_PORT}?auth=${REDIS_PASS}'|" "${PHP_DIR_CLI}"


# Cópia de backup do aruivo /etc/php7/apache2/php.ini.
sudo cp -a ${PHP_DIR_APACHE} ${PHP_DIR_APACHE}_old

sudo sed -i "s/memory_limit = .*/memory_limit = 2048M/" "${PHP_DIR_APACHE}"
sudo sed -i "s/max_execution_time = .*/max_execution_time = 300/" "${PHP_DIR_APACHE}"
sudo sed -i "s/upload_max_filesize = .*/upload_max_filesize = 50M/" "${PHP_DIR_APACHE}"
sudo sed -i "s/post_max_size = .*/post_max_size = 50M/" "${PHP_DIR_APACHE}"

sudo sed -i "s|.*session.use_strict_mode = .*|session.use_strict_mode = 1|" "${PHP_DIR_APACHE}"
sudo sed -i "s|.*session.serialize_handler = .*|session.serialize_handler = php|" "${PHP_DIR_APACHE}"
sudo sed -i "s|.*session.sid_length = .*|session.sid_length = 32|" "${PHP_DIR_APACHE}"
sudo sed -i "s|.*session.sid_bits_per_character = .*|session.sid_bits_per_character = 5|" "${PHP_DIR_APACHE}"

sudo sed -i '/expose_php =/ s/.*/expose_php = Off/' "${PHP_DIR_APACHE}"

sudo sed -i "s|^session.save_handler = .*|session.save_handler = redis|" "${PHP_DIR_APACHE}"
sudo sed -i "s|^session.save_path = .*|session.save_path = 'tcp://127.0.0.1:6379'|" "${PHP_DIR_APACHE}"

[[ ! -z ${REDIS_PASS} ]] && sudo sed -i "s|.*session.save_path = .*|session.save_path = 'tcp://${REDIS_HOST}:${REDIS_PORT}?auth=${REDIS_PASS}'|" "${PHP_DIR_APACHE}"
```

### 4.5: Configuração do PHP 7 - PECL.


**4.5.1.** Instalando dependênicas

```
sudo zypper in -y \
	librdkafka-devel \
	libbrotli-devel \
	php7-devel

sudo cp -a /usr/lib64/libfuzzy.* /usr/lib
```
**4.5.2.** Copilando dependências
```
sudo pear config-set http_proxy http://<user><pass>@<host>:<port>
sudo pecl channel-update pecl.php.net

# Compile simdjson
mkdir /tmp/simdjson
cd /tmp/simdjson
curl --proto '=https' --tlsv1.3 -sS --location --fail -o simdjson.tar.gz https://github.com/crazyxman/simdjson_php/releases/download/3.0.0/simdjson-3.0.0.tgz
echo "23cdf65ee50d7f1d5c2aa623a885349c3208d10dbfe289a71f26bfe105ea8db9 simdjson.tar.gz" | sha256sum -c
tar zxf simdjson.tar.gz --strip-components=1
rm -f simdjson.tar.gz
phpize
./configure
sudo make 
sudo make install

# Compile brotli
mkdir /tmp/brotli
cd /tmp/brotli
curl --proto '=https' --tlsv1.3 -sS --location --fail -o brotli.tar.gz https://github.com/kjdev/php-ext-brotli/archive/refs/tags/0.14.2.tar.gz
echo "40b00f6ab75a4ce54b8af009e8ad2ac5077a4a35d6bbb50807324565b8472bee brotli.tar.gz" | sha256sum -c
tar zxf brotli.tar.gz --strip-components=1
rm -f brotli.tar.gz
phpize
./configure
sudo make 
sudo make install

# Compile ssdeep
mkdir /tmp/ssdeep
cd /tmp/ssdeep
curl --proto '=https' --tlsv1.3 -sS --location --fail -o ssdeep.tar.gz https://github.com/php/pecl-text-ssdeep/archive/refs/tags/1.1.0.tar.gz
echo "256c5c1d6b965f1c6e0f262b6548b1868f4857c5145ca255031a92d602e8b88d ssdeep.tar.gz" | sha256sum -c
tar zxf ssdeep.tar.gz --strip-components=1
rm -f ssdeep.tar.gz
phpize
./configure
sudo make 
sudo make install

# Compile rdkafka
mkdir /tmp/rdkafka
cd /tmp/rdkafka
curl --proto '=https' --tlsv1.3 -sS --location --fail -o rdkafka.tar.gz https://github.com/arnaud-lb/php-rdkafka/archive/refs/tags/6.0.3.tar.gz
echo "058bac839a84f773c931776e7f6cbfdb76443849d3ea2b43ba43b80f64df7453 rdkafka.tar.gz" | sha256sum -c
tar zxf rdkafka.tar.gz --strip-components=1
rm -f rdkafka.tar.gz
phpize
./configure
sudo make 
sudo make install

cd ~

# /usr/lib64/php7/extensions/
set -- "ssdeep" "rdkafka" "brotli" "simdjson"
for mod in "$@"; do
  echo "extension=${mod}.so" | sudo tee "/etc/php7/conf.d/${mod}.ini"
  sudo rm -rf /tmp/${mod}
done;
```

### 4.6: Configuração do SUPERVISOR.

> **Obs1.**: Esse configuração deverá ser aplicada caso o SUPERVISOR esteja instalado e habilitado no arquivo .env.

> **Obs2.**: Caso deseje gerecial o SUPERVISOR via web, basta inserir "*" na opção SUPERVISOR_HOST no arquivo .env.

> **Obs3.**: Foi definido o usuário e senha padrão, mas é recomendado alterar.

```
echo "
[supervisord]
user=root
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0

[inet_http_server]
port=${SUPERVISOR_HOST}:${SUPERVISOR_PORT}
username=${SUPERVISOR_USER}
password=${SUPERVISOR_PASS}
" | sudo tee /etc/supervisord.d/10-supervisor.conf

sudo systemctl enable supervisord.service
sudo systemctl start supervisord.service
```

## PASSO 5: configurações do MISP.

### 5.1: Baixando o MISP.

```
sudo mkdir ${PATH_TO_MISP}
sudo chown ${WWW_USER}:${WWW_USER} ${PATH_TO_MISP}
cd ${PATH_TO_MISP}

# Fetch submodules
${SUDO_WWW} git clone https://github.com/MISP/MISP.git ${PATH_TO_MISP}

${SUDO_WWW} git submodule sync
${SUDO_WWW} git -C ${PATH_TO_MISP} submodule update --progress --init --recursive
${SUDO_WWW} git -C ${PATH_TO_MISP} submodule foreach --recursive git config core.filemode false
${SUDO_WWW} git -C ${PATH_TO_MISP} config core.filemode false
```

### 5.2: Baixando dependências do MISP.

```
cd ${PATH_TO_MISP}

# Create a python3 virtualenv
[[ -e $(which virtualenv 2>/dev/null) ]] && ${SUDO_WWW} virtualenv -p python3 ${PATH_TO_MISP}/venv
${SUDO_WWW} python3 -m venv ${PATH_TO_MISP}/venv

# make pip happy
sudo mkdir /srv/www/.cache
sudo chown ${WWW_USER}:${WWW_USER} /srv/www/.cache

${SUDO_WWW} ${PATH_TO_MISP}/venv/bin/pip install -U pip setuptools
#sudo pip3 install -U pip setuptools

${SUDO_WWW} ${PATH_TO_MISP}/venv/bin/pip --no-cache-dir install --disable-pip-version-check -r ${PATH_TO_MISP}/requirements.txt

UMASK=$(umask)
umask 0022

# Install python-cybox
cd ${PATH_TO_MISP}/app/files/scripts/python-cybox
${SUDO_WWW} ${PATH_TO_MISP}/venv/bin/pip install .

# Install python-stix
cd ${PATH_TO_MISP}/app/files/scripts/python-stix
${SUDO_WWW} ${PATH_TO_MISP}/venv/bin/pip install .

# Install python-maec
cd ${PATH_TO_MISP}/app/files/scripts/python-maec
${SUDO_WWW} ${PATH_TO_MISP}/venv/bin/pip install .

# Install misp-stix
cd ${PATH_TO_MISP}/app/files/scripts/misp-stix
${SUDO_WWW} ${PATH_TO_MISP}/venv/bin/pip install .

# Install mixbox
cd ${PATH_TO_MISP}/app/files/scripts/mixbox
${SUDO_WWW} ${PATH_TO_MISP}/venv/bin/pip install .

# install PyMISP
cd ${PATH_TO_MISP}/PyMISP
${SUDO_WWW} ${PATH_TO_MISP}/venv/bin/pip install .

# install pydeep
${SUDO_WWW} ${PATH_TO_MISP}/venv/bin/pip install git+https://github.com/kbandla/pydeep.git

# install lief
${SUDO_WWW} ${PATH_TO_MISP}/venv/bin/pip install lief

# install python-magic
${SUDO_WWW} ${PATH_TO_MISP}/venv/bin/pip install python-magic

# install plyara
${SUDO_WWW} ${PATH_TO_MISP}/venv/bin/pip install plyara

# install zmq needed by mispzmq
${SUDO_WWW} ${PATH_TO_MISP}/venv/bin/pip install zmq

umask $UMASK
```

### 5.3: Instalando o CAKE.

```
sudo mkdir -p /srv/www/.composer ; sudo chown ${WWW_USER}:${WWW_USER} /srv/www/.composer
${SUDO_WWW} sh -c "cd ${PATH_TO_MISP}/app ; php composer.phar config --no-interaction allow-plugins.composer/installers true"
${SUDO_WWW} sh -c "cd ${PATH_TO_MISP}/app ; php composer.phar install --no-dev"  

${SUDO_WWW} sh -c "cd ${PATH_TO_MISP}/app ; php composer.phar require --with-all-dependencies --no-interaction supervisorphp/supervisor:^4.0 \
    guzzlehttp/guzzle \
    php-http/message \
    php-http/message-factory \
    lstrojny/fxmlrpc \
    elasticsearch/elasticsearch \
    aws/aws-sdk-php \
    jakub-onderka/openid-connect-php" 

# To use the scheduler worker for scheduled tasks, do the following:
${SUDO_WWW} cp -fa ${PATH_TO_MISP}/INSTALL/setup/config.php ${PATH_TO_MISP}/app/Plugin/CakeResque/Config/config.php

sudo sed -i  "/'host' / s/\(=> \).*/\1\'127.0.0.1\',/" ${PATH_TO_MISP}/app/Plugin/CakeResque/Config/config.php

[[ ! -z $(sudo grep "^requirepass" /etc/redis/default.conf) ]] && sudo sed -i  "/'password' / s/\(=> \).*/\1\'$(sudo grep "^requirepass" /etc/redis/default.conf | cut -f2 -d' ')\'/" ${PATH_TO_MISP}/app/Plugin/CakeResque/Config/config.php

```

### 5.4: Aplicando as permissões no diretório do MISP.

```
sudo chown -R ${WWW_USER}:${WWW_USER} ${PATH_TO_MISP}
sudo chmod -R g+r,o= ${PATH_TO_MISP}

sudo chmod -R 750 ${PATH_TO_MISP}
sudo chmod -R g+xws ${PATH_TO_MISP}/app/tmp
sudo chmod -R g+ws ${PATH_TO_MISP}/app/files
sudo chmod -R g+ws ${PATH_TO_MISP}/app/files/scripts/tmp
sudo chmod -R g+rw ${PATH_TO_MISP}/venv
sudo chmod -R g+rw ${PATH_TO_MISP}/.git
sudo chown ${WWW_USER}:${WWW_USER} ${PATH_TO_MISP}/app/files
sudo chown ${WWW_USER}:${WWW_USER} ${PATH_TO_MISP}/app/files/terms
sudo chown ${WWW_USER}:${WWW_USER} ${PATH_TO_MISP}/app/files/scripts/tmp
sudo chown ${WWW_USER}:${WWW_USER} ${PATH_TO_MISP}/app/Plugin/CakeResque/tmp
sudo chown -R ${WWW_USER}:${WWW_USER} ${PATH_TO_MISP}/app/Config
sudo chown -R ${WWW_USER}:${WWW_USER} ${PATH_TO_MISP}/app/tmp
sudo chown -R ${WWW_USER}:${WWW_USER} ${PATH_TO_MISP}/app/webroot/img/custom
```

### 5.5: Configurando e iniciando o BANCO DE DADOS.

```
# Enable, start and secure your mysql database server
sudo systemctl enable --now mariadb.service
echo [mysqld] |sudo tee /etc/my.cnf.d/bind-address.cnf
echo bind-address=127.0.0.1 |sudo tee -a /etc/my.cnf.d/bind-address.cnf
sudo systemctl restart mariadb

# Kill the anonymous users
sudo mysql -h ${DB_ADMIN_HOST} -e "DROP USER IF EXISTS ''@'localhost'"

# Because our hostname varies we'll use some Bash magic here.
sudo mysql -h ${DB_ADMIN_HOST} -e "DROP USER IF EXISTS ''@'$(hostname)'"

# Kill off the demo database
sudo mysql -h ${DB_ADMIN_HOST} -e "DROP DATABASE IF EXISTS test"

# No root remote logins
sudo mysql -h ${DB_ADMIN_HOST} -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"

# Make sure that NOBODY can access the server without a password
sudo mysqladmin -h ${DB_ADMIN_HOST} -u "${DB_ADMIN_USE}" password "${DB_ADMIN_PASS}"

# Make our changes take effect
sudo mysql -h ${DB_ADMIN_HOST} -u "${DB_ADMIN_USE}" -p"${DB_ADMIN_PASS}" -e "FLUSH PRIVILEGES"


sudo mysql -h ${DB_ADMIN_HOST} -u "${DB_ADMIN_USE}" -p"${DB_ADMIN_PASS}" -e "CREATE DATABASE ${DB_MISP_DATABASE};"

sudo mysql -h ${DB_ADMIN_HOST} -u "${DB_ADMIN_USE}" -p"${DB_ADMIN_PASS}" -e "CREATE USER '${DB_MISP_USE}'@'localhost' IDENTIFIED BY '${DB_MISP_PASS}';"

sudo mysql -h ${DB_ADMIN_HOST} -u "${DB_ADMIN_USE}" -p"${DB_ADMIN_PASS}" -e "GRANT USAGE ON *.* to '${DB_MISP_USE}'@'localhost';"

sudo mysql -h ${DB_ADMIN_HOST} -u "${DB_ADMIN_USE}" -p"${DB_ADMIN_PASS}" -e "GRANT ALL PRIVILEGES on ${MYSQL_DATABASE}.* to '${DB_MISP_USE}'@'localhost';"

sudo mysql -h ${DB_ADMIN_HOST} -u "${DB_ADMIN_USE}" -p"${DB_ADMIN_PASS}" -e "FLUSH PRIVILEGES;"

# Import the empty MISP database from MYSQL.sql
# ${SUDO_WWW} cat ${PATH_TO_MISP}/INSTALL/MYSQL.sql | mysql -h ${DB_ADMIN_HOST} -u "${DB_MISP_USE}" -p"${DB_MISP_PASS}" ${DB_MISP_DATABASE}
```

### 5.6: Configurando os arquivos do MISP.

```
${SUDO_WWW} cp -a ${PATH_TO_MISP}/app/Config/bootstrap.default.php ${PATH_TO_MISP}/app/Config/bootstrap.php
${SUDO_WWW} cp -a ${PATH_TO_MISP}/app/Config/database.default.php ${PATH_TO_MISP}/app/Config/database.php
${SUDO_WWW} cp -a ${PATH_TO_MISP}/app/Config/core.default.php ${PATH_TO_MISP}/app/Config/core.php
${SUDO_WWW} cp -a ${PATH_TO_MISP}/app/Config/config.default.php ${PATH_TO_MISP}/app/Config/config.php

echo "<?php
class DATABASE_CONFIG {
        public \$default = array(
                'datasource' => 'Database/Mysql',
                //'datasource' => 'Database/Postgres',
                'persistent' => false,
                'host' => '${DB_ADMIN_HOST}',
                'login' => '${DB_MISP_USE}',
                'port' => ${DB_ADMIN_PORT}, // MySQL & MariaDB
                //'port' => 5432, // PostgreSQL
                'password' => '${DB_MISP_PASS}',
                'database' => '${DB_MISP_DATABASE}',
                'prefix' => '',
                'encoding' => 'utf8',
        );
}" | ${SUDO_WWW} tee ${PATH_TO_MISP}/app/Config/database.php

sudo sed -i "/'osuser'/s/\(=>\ \).*/\1\'${WWW_USER}\',/" /srv/www/MISP/app/Config/config.php

sudo sed -i "/'salt'/ s/\(=>\ \).*/\1\'${SALT_PASS}\',/" /srv/www/MISP/app/Config/config.php

# and make sure the file permissions are still OK
sudo chown -R ${WWW_USER}:${WWW_USER} ${PATH_TO_MISP}/app/Config
sudo chmod -R 750 ${PATH_TO_MISP}/app/Config
```

### 5.7: Configurando o LogRotation.

```
sudo cp ${PATH_TO_MISP}/INSTALL/misp.logrotate /etc/logrotate.d/misp
sudo chmod 0640 /etc/logrotate.d/misp
```



