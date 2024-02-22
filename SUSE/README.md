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
```

### 1.3: Instalando o SUDO e editor VIM.

> **Obs.**: Substitua o termo "\<user\>" pelo nome do usuário padrão.

```
# Acesse o servido com via SSH
ssh <use>@<IP> -p 22

# Logue no servidor e escale privilégio para root.
su -

# Instale o pacote SUDO e editores 
zypoer in -y sudo vim

# Adiciona o usuário padrão ao grupo de superusuário, caso já não esteja.
usermod -aG wheel <user>


# Configurando o usuário padrão na pasta sudoers.
echo "<user> ALL=(ALL:ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/<user>

# Habilitando a gravação de log dos comando SUDO.
sed -i '/Defaults\ log_output/i Defaults\ logfile=\/var\/log/\sudo.log' /etc/sudoers

# Definindo o tempo para que não seja solicitado a senha novamente.
sed -i '/Defaults\ log_output/i Defaults\ timestamp_timeout=60' /etc/sudoers

# Logue novamente como usuário padrão.
sudo - <user>
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

# Configurações.

```
[SWAP]
SWAP_ENABLE=true		## Habilita a criação de SWAP local
SWAP_FILE=/swapfile		## Nome do arquivo de SWAP
SWAP_SIZE=3			## Tamanho do arquivo de SWAP em GB

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
```

> Após inserir as informações acima, faça as alterações necessários, como adição senha e e-mail de login.

> Caso deseje, o comando abaixo gera senhas automaticamento com openssl.

```
sudo sed -i "s/^\(.*_PASS=\).*/\1$(openssl rand -hex 32)/" /admin/.env
```

### 1.6: Exportando as variáveis setadas no arquivo .env.

```
export $(sudo egrep -v "^\s*(;|$|\[)" /admin/.env | cut -f1 -d$'\t' | cut -f1 -d' ' | xargs)
unset $(sudo egrep -v "^\s*(;|$|\[)" /admin/.env | cut -f1 -d'=')
```

## PASSO 2: Configurações LOCAIS.

**2.1.** Configuração do **DATATIME**.
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

**2.2.** Configuração do **HOSTS**.
```
echo "127.0.0.1       $(hostname).brb.com.br $(hostname)" | sudo tee -a /etc/hosts
```

**2.3.** Configuração do **RC.LOCAL**.

Criação e configuração do arquivo /etc/rc.local caso não exista.
```
if [[ ! -f /etc/rc.local ]]; then
  echo '#!/bin/sh -e' | sudo tee -a /etc/rc.local
  echo 'exit 0' | sudo tee -a /etc/rc.local
  sudo chmod u+x /etc/rc.local
fi

```

## PASSO 3: REPOSITÓRIOS.

**3.1.** Repositórios necessários para **SUSE SLE 15 SP4**.

> **Obs.**: Esses repositórios deverão ser adicionadas, caso não existam.
```
sudo SUSEConnect -p sle-module-desktop-applications/15.4/x86_64
sudo SUSEConnect -p sle-module-development-tools/15.4/x86_64
sudo SUSEConnect -p PackageHub/15.4/x86_64
sudo SUSEConnect -p sle-module-python3/15.4/x86_64
sudo SUSEConnect -p sle-module-legacy/15.4/x86_64
sudo SUSEConnect -p sle-module-web-scripting/15.4/x86_64
```

**3.2.** Instalação de **DEPENDÊNCIAS**.
```
sudo zypper in -y \
	gcc make \
	git zip unzip \
	nano vim \
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
```

**3.3.** Instalação do **SUPERVISOR**.

> **Obs.**: Essa instalação derevá ser realizada caso deseje que o **SUPERVISOR** gerencie os **Works** do **MISP**.
```
sudo zypper in -y supervisor

pip3 install --proxy=http://<user><pass>@<host>:<port> -U supervisor
```

## PASSO 4: Configuração das DEPENDÊNCIAS.

**4.1.** Configuração **GPG**.
```
sudo systemctl enable --now haveged.service
```

**4.2.** Configuração **PYTHON**.
```
sudo rm /usr/bin/python3
sudo ln -s /usr/bin/python3.10 /usr/bin/python3
[[ ! -e "/usr/bin/python" ]] && sudo ln -s /usr/bin/python3 /usr/bin/python

[[ ! $(sudo update-alternatives --list python) ]] && sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 1
readlink -f /usr/bin/python | grep python3 || sudo alternatives --set python /usr/bin/python3
```

**4.3.** Configuração **REDIS**.
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
> **Obs1.**: Como de medida de segurança é recomendado a aplicação de senha na utilização do REDIS.

> **Obs2.**: Altere "<REDIS_PASS>" para a senha desejada.

> **Obs3.**: Para utilização de senha ao acesso ao REDIS, utilizado o camando abaixo.


```
sudo sed -i "s/^#\ \(requirepass\ \).*/\1<REDIS_PASS>/" /etc/redis/default.conf
```


**4.4.** Configuração **PHP 7**.
```
sudo sed -i "s|.*redis.session.locking_enabled = .*|redis.session.locking_enabled = 1|" /etc/php7/conf.d/redis.ini
sudo sed -i "s|.*redis.session.lock_expire = .*|redis.session.lock_expire = 30|" /etc/php7/conf.d/redis.ini
sudo sed -i "s|.*redis.session.lock_wait_time = .*|redis.session.lock_wait_time = 50000|" /etc/php7/conf.d/redis.ini
sudo sed -i "s|.*redis.session.lock_retries = .*|redis.session.lock_retries = 30|" /etc/php7/conf.d/redis.ini

for FILE in /etc/php7/*/php.ini
do
	[[ -e ${FILE} ]] || break
	sudo cp -a ${FILE} ${FILE}_old

	sudo sed -i "s/memory_limit = .*/memory_limit = 2048M/" "${FILE}"
	sudo sed -i "s/max_execution_time = .*/max_execution_time = 300/" "${FILE}"
	sudo sed -i "s/upload_max_filesize = .*/upload_max_filesize = 50M/" "${FILE}"
	sudo sed -i "s/post_max_size = .*/post_max_size = 50M/" "${FILE}"

	sudo sed -i "s|.*session.use_strict_mode = .*|session.use_strict_mode = 1|" "${FILE}"
	sudo sed -i "s|.*session.serialize_handler = .*|session.serialize_handler = php|" "${FILE}"
	sudo sed -i "s|.*session.sid_length = .*|session.sid_length = 32|" "${FILE}"
	sudo sed -i "s|.*session.sid_bits_per_character = .*|session.sid_bits_per_character = 5|" "${FILE}"

	sudo sed -i '/expose_php =/ s/.*/expose_php = Off/' "${FILE}"

	sudo sed -i "s|^session.save_handler = .*|session.save_handler = redis|" "${FILE}"
	sudo sed -i "s|^session.save_path = .*|session.save_path = 'tcp://127.0.0.1:6379'|" "${FILE}"

	# O comando abaixo verifica se foi definido uma senha para o REDIS, caso positivo e essa senha é adicionada ao arquivo PHP.
	[[ ! -z $(sudo grep "^requirepass" /etc/redis/default.conf) ]] && sudo sed -i "s|.*session.save_path = .*|session.save_path = 'tcp://127.0.0.1:6379?auth=$(sudo grep "^requirepass" /etc/redis/default.conf | cut -f2 -d' ')'|" "${FILE}"
done
```

4.5. Configuração **PHP 7 - PECL**.

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
**4.6.** Configuração **SUPERVISOR**.

> **Obs1.**: Esse configuração deverá ser aplicada caso deseje que o SUPERVISOR gerencia os Works e que o item 3.3 tenha sido aplicado.

> **Obs2.**: Caso deseje gerecial o SUPERVISOR via web, basta inserir "*" no lugar do endereço de loopback "127.0.0.1".

> **Obs3.**: Foi definido o usuário e senha "supervisor" com padrão, dessa forma é essencial sua alteração.

```
echo "
[supervisord]
user=root
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0

[inet_http_server]
port=127.0.0.1:9001
username=supervisor
password=supervisor

" | sudo tee /etc/supervisord.d/10-supervisor.conf

sudo systemctl enable supervisord.service
sudo systemctl start supervisord.service
```

## PASSO 5: configurações do MISP.

**5.1.** Baixando o **MISP**.

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

**5.2.** Baixando dependências do **MISP**.

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

**5.3.** Instalando o **CAKE**.

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

**5.4.** Aplicando as permissões no diretório do **MISP**.

```
sudo chown -R ${WWW_USER}:${WWW_USER} ${PATH_TO_MISP}
sudo find ${PATH_TO_MISP} -type d -exec chmod g=rx {} \;
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
#sudo chown -R ${WWW_USER}:${WWW_USER} ${PATH_TO_MISP}/app/webroot/img/orgs
sudo chown -R ${WWW_USER}:${WWW_USER} ${PATH_TO_MISP}/app/webroot/img/custom
```

**5.5.** Configurando e iniciando o **BANCO DE DADOS**.

```
# Enable, start and secure your mysql database server
sudo systemctl enable --now mariadb.service
echo [mysqld] |sudo tee /etc/my.cnf.d/bind-address.cnf
echo bind-address=127.0.0.1 |sudo tee -a /etc/my.cnf.d/bind-address.cnf
sudo systemctl restart mariadb

# Kill the anonymous users
sudo mysql -h 127.0.0.1 -e "DROP USER IF EXISTS ''@'localhost'"
# Because our hostname varies we'll use some Bash magic here.
sudo mysql -h 127.0.0.1 -e "DROP USER IF EXISTS ''@'$(hostname)'"
# Kill off the demo database
sudo mysql -h 127.0.0.1 -e "DROP DATABASE IF EXISTS test"
# No root remote logins
sudo mysql -h 127.0.0.1 -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
# Make sure that NOBODY can access the server without a password
sudo mysqladmin -h 127.0.0.1 -u "<MYSQL_USE_ADMIN>" password "<MYSQL_PASSWORD_ADMIN>"
# Make our changes take effect
sudo mysql -h 127.0.0.1 -u "<MYSQL_USE_ADMIN>" -p"<MYSQL_PASSWORD_ADMIN>" -e "FLUSH PRIVILEGES"

sudo mysql -h 127.0.0.1 -u "<MYSQL_USE_ADMIN>" -p"<MYSQL_PASSWORD_ADMIN>" -e "CREATE DATABASE ${MYSQL_DATABASE};"
sudo mysql -h 127.0.0.1 -u "<MYSQL_USE_ADMIN>" -p"<MYSQL_PASSWORD_ADMIN>" -e "CREATE USER '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';"
  sudo mysql -h 127.0.0.1 -u "<MYSQL_USE_ADMIN>" -p"<MYSQL_PASSWORD_ADMIN>" -e "GRANT USAGE ON *.* to '${MYSQL_USER}'@'localhost';"
  sudo mysql -h 127.0.0.1 -u "<MYSQL_USE_ADMIN>" -p"<MYSQL_PASSWORD_ADMIN>" -e "GRANT ALL PRIVILEGES on ${MYSQL_DATABASE}.* to '${MYSQL_USER}'@'localhost';"
  sudo mysql -h 127.0.0.1 -u "${MYSQL_USE_ADMIN}" -p"<MYSQL_PASSWORD_ADMIN>" -e "FLUSH PRIVILEGES;"
  # Import the empty MISP database from MYSQL.sql
  # ${SUDO_WWW} cat ${PATH_TO_MISP}/INSTALL/MYSQL.sql | mysql -h 127.0.0.1 -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" ${MYSQL_DATABASE}
  ${SUDO_WWW} cat ${PATH_TO_MISP}/INSTALL/MYSQL.sql | ${MYSQL_CMD_USER}
```
