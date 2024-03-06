#!/bin/bash 

## SCRIPT de INSTALAÇÂO do MISP em servidores SUSE
# 
# Systemas suportados:
# - SUSE 15 SP5 & SP4
#
# AUTOR: Jose Henrique da Silva
# Gerência: GECIB
#
##

VERSION='1.0'
SCRIPT_NAME="INSTALL_MISP_BRB.sh"

# Saida para qualquer erro.
set -e

# Configuração de cores para visualização
function colors () {
  COLOR_NC='\033[0m' 
  COLOR_WHITE='\033[1;37m'
  COLOR_BLACK='\033[0;30m'
  COLOR_BLUE='\033[0;34m'
  COLOR_LIGHT_BLUE='\033[1;34m'
  COLOR_GREEN='\033[0;32m'
  COLOR_LIGHT_GREEN='\033[1;32m'
  COLOR_CYAN='\033[0;36m'
  COLOR_LIGHT_CYAN='\033[1;36m'
  COLOR_RED='\033[0;31m'
  COLOR_LIGHT_RED='\033[1;31m'
  COLOR_PURPLE='\033[0;35m'
  COLOR_LIGHT_PURPLE='\033[1;35m'
  COLOR_BROWN='\033[0;33m'
  COLOR_YELLOW='\033[1;33m'
  COLOR_GRAY='\033[1;30m'
  COLOR_LIGHT_GRAY='\033[0;37m'
}

###################### FUNÇÕES DE LOG ---------------------------------------------------
function space () { for i in `seq 1 $(tput cols)`; do echo -n "-";  done ; }

# Substitui a função de data.
function prepare_date () {  date "$@"; }

# LOG central
function log () { echo -e "${1} ${2} ${3}" ; }

# Log information
function loginfo () { log "${COLOR_YELLOW}[INFO]${COLOR_NC}" "${COLOR_GREEN}${1}${COLOR_NC}" "${2}" ; }
###################### FIM FUNÇÕES DE LOG -----------------------------------------------


###################### CONFIG FIREWALLD -------------------------------------------------
function enableSSH () {
  # Verificando se o serviço SSH está habilitado.
  firewall-cmd --list-all

  # Adicionando o serviço SSH na Zona PUBLIC de forma permanente.
  firewall-cmd --zone=public --add-service=ssh --permanent

  # Reiniciando o servico para aplicar as configurações.
  systemctl restart firewalld.service
}
###################### FIM CONFIG FIREWALLD ----------------------------------------------

###################### CONFIG SUDO E SUDOERS ---------------------------------------------
function checkSudoers () {
  space
  loginfo "[CHECK][SUDO-VIM]" "Verificando se o ${COLOR_RED}SUDO${COLOR_NC} e o ${COLOR_RED}VIM${COLOR_NC} estão instalados."
  loginfo "[CHECK][PASS]" "Digite a senha de root para intalação do sudo."
  # Obs.: Instala os pacotes SUDO e VIM.
  # Obs.: Adiciona o usuário ao grupo wheel.
  # Obs.: Configura a perissão do usuário no sudoers.
  su -c 'zypper in -y sudo vim \
      && [ -z $(groups "${USER}" | grep wheel) ] && usermod -aG wheel "${USER}" \
      && echo "${USER} ALL=(ALL:ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/"${USER}"'

  # Habilitando a gravação de log dos comando SUDO.
  sudo sed -i '/Defaults\ log_output/i Defaults\ logfile=\/var\/log/\sudo.log' /etc/sudoers

  # Definindo o tempo para que não seja solicitado a senha novamente.
  sudo sed -i '/Defaults\ log_output/i Defaults\ timestamp_timeout=60' /etc/sudoers
}
###################### FIM CONFIG SUDO E SUDOERS -----------------------------------------

###################### CONFIG ADMIN ------------------------------------------------------
function adminDirectory () {
  if [[ ! -d "/admin" ]]; then  
    space && loginfo "[ADMIN][DIRECTORY]" "Criando diretótio ${COLOR_RED}ADMIN${COLOR_NC}."
    # Cria o diretório /admin
    sudo mkdir /admin
  fi
  # Entra na pasta /admin
  cd /admin
}

function adminFileEnv () {
  space && loginfo "[ADMIN][.ENV]" "Criando arquivo ${COLOR_RED}.ENV${COLOR_NC}."

  # Remove o arquivo /admin/.env, caso exista.
  [[ -f "/admin/.env" ]] && sudo rm -f /admin/.env

  # Criando o arquivo /admin/.env
  sudo touch /admin/.env

  # Alterando a permissão do arqui para READ e WRITE apenas para o dono do arquivo.
  sudo chmod 0600 /admin/.env
}

function adminFileEnvConfig () {
  # Abra o arquivo .env com o coimando abaixo e cole as configurações abaixo.
  space && loginfo "[ADMIN][.ENV]" "Populando o arquivo ${COLOR_RED}.ENV${COLOR_NC}."
  cat <<EOF | sudo tee /admin/.env > /dev/null
[O.S.]
SUSE_SP=$(. /etc/os-release && echo ${VERSION_ID})
FLAVOUR=$(. /etc/os-release && echo ${ID} | tr '[:lower:]' '[:upper:]')
PRETTY="$(. /etc/os-release && echo ${PRETTY_NAME} | tr '[:lower:]' '[:upper:]')"


[ADMIN]
ADMIN_ORG=BRB
ADMIN_NAT=Brazil
ADMIN_SEC=Financial
ADMIN_DES=

ADMIN_EMAIL="admin@brb.com.br"
ADMIN_PASS=
ADMIN_CONTATO="soc@brb.com.br"

ADMIN_HOSTNAME=misp
ADMIN_DOMINIO=local
ADMIN_SITE="\${ADMIN_HOSTNAME}.\${ADMIN_DOMINIO}"

ADMIN_PROXY=false
AMDIN_PROXY_CA=
AMDIN_PROXY_HOST=
AMDIN_PROXY_PORT=
AMDIN_PROXY_USER=
AMDIN_PROXY_PASS=


ADMIN_CERT_ENABLE=false
ADMIN_CERT_SORCE_CRT=
ADMIN_CERT_SORCE_KEY=
ADMIN_CERT_SORCE_PER=
ADMIN_CERT_DEST="/etc/ssl/certs/\${ADMIN_HOSTNAME}"
ADMIN_CERT_DEST_KEY="\${ADMIN_CERT_DEST}/private/\${ADMIN_SITE}.key"
ADMIN_CERT_DEST_PER="\${ADMIN_CERT_DEST}/certs/\${ADMIN_SITE}.pem"
ADMIN_CERT_DEST_CRT="\${ADMIN_CERT_DEST}/certs/\${ADMIN_SITE}.crt"
ADMIN_CERT_DEST_CRT_CHAIN="\${ADMIN_CERT_DEST}/certs/\${ADMIN_SITE}-chain.cst"
ADMIN_CERT_DEST_CSR="\${ADMIN_CERT_DEST}/certs/\${ADMIN_SITE}.csr"

[ADMIN-OPENSSL]
OPENSSL_ENABLE=true
OPENSSL_CN="\${ADMIN_SITE}"
OPENSSL_C=BR
OPENSSL_ST="Distrito Federal"
OPENSSL_L="Brasília"
OPENSSL_O=BRB
OPENSSL_OU="Banco de Brasilia"
OPENSSL_EMAILADDRESS="soc@brb.com.br"

[ADMIN-OGPG]
GPG_ENABLE=true
GPG_REAL_NAME="Autogenerated Key"
GPG_COMMENT="WARNING: MISP AutoGenerated Key consider this Key VOID!"
GPG_EMAIL="soc@brb.com.br"
GPG_KEY_LENGTH=3072
GPG_PASS=

[MISP]
MISP_GIT_TAG_CORE_ENABLE=false
MISP_GIT_TAG_CORE=v2.4.185
MISP_GIT_TAG_MODULE_ENABLE=false
MISP_GIT_TAG_MODULE=v2.4.185
WWW_USER=wwwrun
SUDO_WWW="sudo sudo -H -u \${WWW_USER}"
SALT_PASS=
PATH_TO_MISP="/srv/www/MISP"
CAKE="\${PATH_TO_MISP}/app/Console/cake"

MISP_CA_DEFAULT="\${PATH_TO_MISP}/app/Lib/cakephp/lib/Cake/Config/cacert.pem"
MISP_CA_NEW="/etc/ssl/certs/misp_ca_bundle.pem"


[MISP-CONFIG]

[PHP]
PHP_FPM=false
PHP_PECL=true
PHP_ETC_BASE="/etc/php7"

[SWAP]
SWAP_ENABLE=true
SWAP_FILE=/swapfile
SWAP_SIZE=3

[REDIS]
REDIS_ENABLE=true
REDIS_HOST="127.0.0.1"
REDIS_PORT=6379
REDIS_DATA=13
REDIS_PASS=

[SUPERVISOR]
SUPERVISOR_ENABLE=true
SUPERVISOR_HOST="127.0.0.1"
SUPERVISOR_PORT=9001
SUPERVISOR_USER=supervisor
SUPERVISOR_PASS=

[DB]
DB_ADMIN_HOST=localhost
DB_ADMIN_PORT=3306
DB_ADMIN_USE=root
DB_ADMIN_PASS=

DB_MISP_DATABASE=misp
DB_MISP_PREFIX=
DB_MISP_USE=user_misp
DB_MISP_PASS=
EOF
}

function adminGeneratingPass () {
  space && loginfo "[ADMIN][.ENV][PASS]" "Gerando as senhas do arquivo ${COLOR_RED}.ENV${COLOR_NC}."
  sudo grep -E "^.*_PASS=($| )" /admin/.env | while read line; do sudo sed -i "s/^\($line\).*/\1$(openssl rand -hex 32)/" /admin/.env ; done
}

function adminGeneratingExport () {
  space && loginfo "[ADMIN][EXPORT][GENERATING]" "Gerando as variáveis temporárias pelo ${COLOR_RED}EXPORT${COLOR_NC}."
  eval $(sudo grep -v -E "^\s*(;|$|\[|#)" /admin/.env | xargs -i echo {} | sed 's/=/=\"/;s/$/\"/')
}

function adminConfig () {
  adminDirectory
  adminFileEnv
  adminFileEnvConfig
  adminGeneratingPass
  adminGeneratingExport
}
###################### FIM CONFIG ADMIN --------------------------------------------------

###################### CONFIGURAÇÕES LOCAIS ----------------------------------------------
function localTimeZone () {
  space && loginfo "[LOCAL][TIMEZONE]" "Definindo o ${COLOR_RED}TIMEZONE - America/Sao_Paulo${COLOR_NC} e aplicando."
  sudo timedatectl set-timezone America/Sao_Paulo
  sudo sed -i "s/^#\(NTP=\).*/\1a.ntp.br/g" /etc/systemd/timesyncd.conf
  sudo sed -i "s/^#\(FallbackNTP=\).*/\1a.ntp.br/g" /etc/systemd/timesyncd.conf
  sudo timedatectl set-ntp true
  sudo sudo hwclock --systohc --localtime
  sudo service systemd-timesyncd restart

  sudo localectl set-locale LC_TIME=pt_BR.UTF-8

  export LC_TIME="pt_BR.UTF-8"
}

function localSetHostname () {
  if [[ ! -z ${ADMIN_HOSTNAME} ]]; then  
    space && loginfo "[LOCAL][HOSTNAME]" "Configurando o HOSTNAME para ${COLOR_RED}${ADMIN_HOSTNAME}${COLOR_NC}."
    sudo hostnamectl set-hostname ${ADMIN_HOSTNAME}
  fi  
}

function localHosts () {
  space && loginfo "[LOCAL][HOSTS]" "Configurando o HOSTS ${COLOR_RED}${FQDN}${COLOR_NC}."
  echo "127.0.0.1       ${ADMIN_SITE} ${ADMIN_HOSTNAME}" | sudo tee -a /etc/hosts
}

function localSwap () {
  if [[ ${SWAP_ENABLE} == true ]]; then
    if [[ ! $(sudo swapon -v) ]]; then
      space && loginfo "[LOCAL][SWAP]" "Configurnado ${COLOR_YELLOW}SWAP${COLOR_NC}."

      # sudo touch ${SWAP_FILE}
      sudo truncate -s 0 ${SWAP_FILE}
      # sudo chattr +C ${SWAP_FILE}
      # sudo btrfs property set /swapfile compression none
      sudo fallocate -l ${SWAP_SIZE}G ${SWAP_FILE}
      sudo chmod 0600 ${SWAP_FILE}
      sudo mkswap ${SWAP_FILE}
      sudo swapon ${SWAP_FILE}
      echo "${SWAP_FILE} none swap defaults 0 0" | sudo tee -a /etc/fstab

      sudo swapon --show
      sudo free -th

      # sudo findmnt --verify --verbose
      # cat /proc/sys/vm/swappiness
      cat <<EOF | sudo tee /etc/sysctl.d/swappiness.conf > /dev/null
# Alterando o valor do swappiness de 60 para 10
vm.swappiness=10
EOF
      sudo sysctl -p /etc/sysctl.d/swappiness.conf
    else
      space && loginfo "[LOCAL][SWAP]" "FALHA: ${COLOR_YELLOW}SWAP${COLOR_NC} existente."

      sudo swapon --show
      sudo free -th
    fi
  fi
}

function localConfig () {
  localTimeZone
  localSetHostname
  localHosts
  localSwap
}
###################### FIM CONFIGURAÇÕES LOCAIS ------------------------------------------


###################### REPOSITÓRIOS E DEPENFÊNCIAS ---------------------------------------
function localRepo () {
  space && loginfo "[LOCAL][REPO]" "Configurnado ${COLOR_RED}REPOSITÓRIOS${COLOR_NC}."

  REPO=(sle-module-desktop-applications/${SUSE_SP}/x86_64
    sle-module-development-tools/${SUSE_SP}/x86_64
    PackageHub/${SUSE_SP}/x86_64
    sle-module-python3/${SUSE_SP}/x86_64
    sle-module-legacy/${SUSE_SP}/x86_64
    sle-module-web-scripting/${SUSE_SP}/x86_64
  )

  for REP in "${REPO[@]}"; do
    [[ -z $(sudo zypper lr -d | cut -d"|" -f9 | grep -i "$( echo ${REP} | cut -d'/' -f1)") ]] && sudo SUSEConnect -p ${REP}
  done
   
}

# Instala DEPENDÊNCIA
function localInstallDep (){
  space && loginfo "[DEPE]" "Instalando ${COLOR_BLUE}DEPENDÊNCIAS${COLOR_NC}."

  loginfo "[DEPE][CORE]" "Instalando ${COLOR_RED}NetworkManager${COLOR_NC}."
  sudo zypper in -y NetworkManager

  loginfo "[DEPE][CORE]" "Instalando ${COLOR_RED}DEPENDÊNCIAS${COLOR_NC}."
  sudo zypper in -y \
    gcc make \
    git zip unzip \
    nano \
    cntlm gpg2 openssl curl unbound bind-utils \
    moreutils \
    redis \
    glibc-locale \
    libxslt-devel zlib-devel libgpg-error-devel libffi-devel libfuzzy-devel libxml2-devel libassuan-devel

  loginfo "[DEPE][GPG]" "Instalando ${COLOR_RED}GPG${COLOR_NC}."
  sudo zypper in -y haveged

  loginfo "[DEPE][HTTPD]" "Instalando ${COLOR_RED}HTTPD${COLOR_NC}."
  sudo zypper in -y httpd apache2-mod_php7

  if [[ ${SUSE_SP} == '15.4' ]]; then
    loginfo "[DEPE][PYTHON]" "Instalando ${COLOR_RED}PYTHON 310${COLOR_NC}."
    sudo zypper in -y \
      python310 \
      python310-devel \
      python310-pip \
      python310-setuptools
  fi

  if [[ ${SUSE_SP} == '15.5' ]]; then
    loginfo "[DEPE][PYTHON]" "Instalando ${COLOR_RED}PYTHON 311${COLOR_NC}."
    sudo zypper in -y \
      python311 \
      python311-devel \
      python311-pip \
      python311-wheel \
      python311-urllib3 \
      python311-idna \
      python311-lxml \
      python311-ply \
      python311-virtualenv \
      python311-cryptography
  fi

    loginfo "[DEPE][PHP]" "Instalando ${COLOR_RED}PHP 7${COLOR_NC}."
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

  #php -r "xdebug_info();"
  if [[ ${SUPERVISOR_ENABLE} == true ]]; then
    loginfo "[CONFIG][SUPERVISOR]" "Configurando: ${COLOR_RED}SUPERVISOR${COLOR_NC}."
    sudo zypper in -y supervisor

    loginfo "[DEPE][SUPERVISOR-PIP]" "Instalando ${COLOR_RED}PIP SUPERVISOR${COLOR_NC}."
    if [[ ${ADMIN_PROXY} == true ]]; then
    # *********************
      [[ ! -z ${AMDIN_PROXY_CA} ]] && sudo pip3 install --proxy=${ADMIN_PROXY} -U supervisor
      [[ -z ${AMDIN_PROXY_CA} ]] && [[ ! -z ${AMDIN_PROXY_USER} ]] && sudo pip3 install --proxy=${ADMIN_PROXY} -U supervisor
    else
      sudo pip3 install -U supervisor
    fi
  fi
  
  [[ ${PHP_FPM} == true ]] && loginfo "[DEPE][PHP_FPM]" "Instalando ${COLOR_RED}PHP_FPM${COLOR_NC}." && sudo zypper in -y php7-fpm

  loginfo "[DEPE][MSQL]" "Instalando ${COLOR_RED}MARIADB${COLOR_NC}."
  sudo zypper in -y \
      mariadb \
      mariadb-server
}

function repoDep () {
  localRepo
  localInstallDep
}
###################### FIM REPOSITÓRIOS E DEPENFÊNCIAS -----------------------------------

###################### CONFIG DEPENDÊNCIAS -----------------------------------------------
function configGpg () {
  space && loginfo "[CONFIG][GPG]" "Configurando: ${COLOR_RED}GPG${COLOR_NC}."
  sudo systemctl enable --now haveged.service
}

function configPyton () {
  VERSION_PYTHON=$([[ "${SUSE_SP}" == 15.4 ]] && echo "3.10" || echo "3.11")

  space && loginfo "[CONFIG][PYTHON]" "Configurando: ${COLOR_RED}${VERSION_PYTHON}${COLOR_NC}."  

  [[ -e "/usr/bin/python${VERSION_PYTHON}" ]] && sudo rm /usr/bin/python3 && sudo ln -s /usr/bin/python${VERSION_PYTHON} /usr/bin/python3
  [[ ! -e "/usr/bin/python" ]] && sudo ln -s /usr/bin/python3 /usr/bin/python

  [[ ! $(sudo update-alternatives --list python) ]] && sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 1
  readlink -f /usr/bin/python | grep python3 || sudo alternatives --set python /usr/bin/python3
}

function configRedis () {
  if [[ ${REDIS_ENABLE} == true ]]; then
    space && loginfo "[CONFIG][REDIS]" "Configurando: ${COLOR_RED}REDIS${COLOR_NC}."

    sudo cp -a /etc/redis/default.conf.example /etc/redis/default.conf
    sudo cp -a /etc/redis/sentinel.conf.example /etc/redis/sentinel.conf

    sudo sed -i "s/^\(bind\ \).*/\1${REDIS_HOST} -::1/" /etc/redis/default.conf
    sudo sed -i "s/^\(appendonly\ \).*/\1yes/" /etc/redis/default.conf
    sudo sed -i 's/^\(appendfilename\ \).*/\1\"appendonly.aof\"/' /etc/redis/default.conf

    [[ ! -z ${REDIS_PASS} ]] && sudo sed -i "s/^#\ \(requirepass\ \).*/\1${REDIS_PASS}/" /etc/redis/default.conf

    loginfo "[CONFIG][REDIS]" "Configurando: ${COLOR_RED}vm.overcommit_memory${COLOR_NC}."
    # cat /proc/sys/vm/overcommit_memory
    cat <<EOF | sudo tee /etc/sysctl.d/overcommit_memory.conf > /dev/null
# Alterando o valor do overcommit_memory de 0 para 1
vm.overcommit_memory=1
EOF
    sudo sysctl -p /etc/sysctl.d/overcommit_memory.conf

    sudo chown -R redis:redis /etc/redis

    sudo systemctl daemon-reload
    sudo systemctl enable --now redis@default
  fi
}

function configPhp () {
  space && loginfo "[CONFIG][PHP]" "Configurando: ${COLOR_RED}PHP 7${COLOR_NC}."

  loginfo "[CONFIG][PHP][REDIS]" "Configurando: ${COLOR_RED}PHP 7 - REDIS.INI${COLOR_NC}."
  # REDIS config
  sudo sed -i "s|.*redis.session.locking_enabled = .*|redis.session.locking_enabled = 1|" ${PHP_ETC_BASE}/conf.d/redis.ini
  sudo sed -i "s|.*redis.session.lock_expire = .*|redis.session.lock_expire = 30|" ${PHP_ETC_BASE}/conf.d/redis.ini
  sudo sed -i "s|.*redis.session.lock_wait_time = .*|redis.session.lock_wait_time = 50000|" ${PHP_ETC_BASE}/conf.d/redis.ini
  sudo sed -i "s|.*redis.session.lock_retries = .*|redis.session.lock_retries = 30|" ${PHP_ETC_BASE}/conf.d/redis.ini

  for FILE in ${PHP_ETC_BASE}/*/php.ini
    do
      [[ -e ${FILE} ]] || break
      loginfo "[CONFIG][PHP][*.INI]" "Configurando: ${COLOR_RED}${FILE}${COLOR_NC}."

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

      if [[ ${REDIS_ENABLE} == true ]]; then
        sudo sed -i "s|^session.save_handler = .*|session.save_handler = redis|" "${FILE}"
        sudo sed -i "s|^session.save_path = .*|session.save_path = 'tcp://${REDIS_HOST}:${REDIS_PORT}'|" "${FILE}"
        [[ ! -z ${REDIS_PASS} ]] && sudo sed -i "s|.*session.save_path = .*|session.save_path = 'tcp://${REDIS_HOST}:${REDIS_PORT}?auth=${REDIS_PASS}'|" "${FILE}"
      else
        sudo sed -i "s|^session.save_handler = .*|session.save_handler = files|" "${FILE}"
        sudo sed -i "s|^session.save_path = .*|session.save_path = '/var/lib/php7'|" "${FILE}"
      fi
    done 
}

function configPhpPecl () {
  if [[ ${PHP_PECL} == true  ]]; then
    space && loginfo "[CONFIG][PHP][PECL]" "Configurando: ${COLOR_RED}PHP PECL${COLOR_NC}."

    sudo zypper in -y \
          librdkafka-devel \
          libbrotli-devel \
          php7-devel

    sudo cp -a /usr/lib64/libfuzzy.* /usr/lib

    sudo pecl channel-update pecl.php.net

    sudo pecl install ssdeep 
    sudo pecl install rdkafka 
    sudo pecl install simdjson
    sudo pecl install brotli

    # /usr/lib64/php7/extensions/
    loginfo "[CONFIG][PHP][EXTENSIONS]" "Configurando: ${COLOR_RED}PHP EXTENSIONS${COLOR_NC}."
    set -- "ssdeep" "rdkafka" "brotli" "simdjson"
    for mod in "$@"; do
      echo "extension=${mod}.so" | sudo tee "${PHP_ETC_BASE}/conf.d/${mod}.ini"
    done;
  fi
}


function configPhpFmp () {
  if [[ ${PHP_FPM} == true  ]]; then
    space && loginfo "[CONFIG][PHP][FMP]" "Configurando: ${COLOR_RED}PHP FMP${COLOR_NC}."

    #sudo cp -a ${PHP_ETC_BASE}/fpm/php-fpm.d/www.conf.default ${PHP_ETC_BASE}/fpm/php-fpm.d/www.conf
    sudo cp -a ${PHP_ETC_BASE}/fpm/php-fpm.conf.default ${PHP_ETC_BASE}/fpm/php-fpm.conf

    cat << EOF | sudo tee ${PHP_ETC_BASE}/fpm/php-fpm.d/misp.conf
[misp]
env[PATH] = /usr/local/bin:/usr/bin:/bin

user = wwwrun
group = www

listen = /run/php-fpm/php-misp-fpm.sock
;listen.acl_users = apache
listen.allowed_clients = 127.0.0.1

listen.owner = wwwrun
listen.group = www
listen.mode = 0660

pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 10
pm.status_path = /fpm-status

slowlog = /var/log/php_misp_slow-fpm.log

php_admin_value[error_log] = /var/log/php_misp_error-fpm.log
php_admin_flag[log_errors] = no

php_value[session.save_handler] = files
php_value[session.save_path]    = /var/lib/php7/session
php_value[soap.wsdl_cache_dir]  = /var/lib/php7/wsdlcache

access.log = /var/log/php_misp_access-fpm.log
access.format = "%R - %u %t "%m %r%Q%q" %s %{mili}d %{kilo}M %C%%"
EOF

cat << EOF | sudo tee ${PHP_ETC_BASE}/fpm/php-fpm.d/sessions.conf
[misp]
php_value[session.save_handler] = redis
php_value[session.save_path]    = "tcp://127.0.0.1:6379?database=10"
EOF


    # This allows MISP to detect GnuPG, the Python modules' versions and to read the PHP settings.
    sudo sed -i 's/^;\(env\[PATH\]\ =\ \).*/\1\/usr\/local\/bin\:\/usr\/bin\:\/bin/' ${PHP_ETC_BASE}/fpm/php-fpm.d/www.conf
    sudo sed -i 's/^;\(clear_env = no\)/\1/' ${PHP_ETC_BASE}/fpm/php-fpm.d/www.conf
    sudo sed -i 's/^;\(listen\ =\ \).*/\1127\.0\.0\.1\:9000/' ${PHP_ETC_BASE}/fpm/php-fpm.d/www.conf
    sudo sed -i 's/^\(listen\ =\ \).*/\1*\:9000/' ${PHP_ETC_BASE}/fpm/php-fpm.d/www.conf

    sudo sed -i 's/^;\(listen\.owner\ =\ \).*/\1wwwrun/' ${PHP_ETC_BASE}/fpm/php-fpm.d/www.conf
    sudo sed -i 's/^;\(listen\.group\ =\ \).*/\1www/' ${PHP_ETC_BASE}/fpm/php-fpm.d/www.conf
    sudo sed -i 's/^;\(listen\.mode\ =\ \).*/\10660/' ${PHP_ETC_BASE}/fpm/php-fpm.d/www.conf

    sudo systemctl restart php-fpm.service
  fi
}

function configSupervisor () {
  if [[ ${SUPERVISOR_ENABLE} == true ]]; then
    space && loginfo "[CONFIG][SUPERVISOR]" "Configurando: ${COLOR_RED}SUPERVISOR${COLOR_NC}."

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
    sudo systemctl restart supervisord.service
  fi
}

function configCert () {
  if [[ ${ADMIN_CERT_ENABLE} == true ]]; then
    space && loginfo "[CONFIG][BRB]" "Configurando: ${COLOR_RED}CERT BRB${COLOR_NC}."
    [[ ! -z ${ADMIN_CERT_SORCE_CRT} ]] && sudo cp ${ADMIN_CERT_SORCE_CRT} ${ADMIN_CERT_DEST_CRT}
    [[ ! -z ${ADMIN_CERT_SORCE_KEY} ]] && sudo cp ${ADMIN_CERT_SORCE_KEY} ${ADMIN_CERT_DEST_KEY}
    [[ ! -z ${ADMIN_CERT_SORCE_PER} ]] && sudo cp ${ADMIN_CERT_SORCE_PER} ${ADMIN_CERT_DEST_PER}
  fi
}

function configDep () {
  configGpg
  configPyton
  configRedis
  configPhp
  configPhpPecl
  configPhpFmp
  configSupervisor
  configCert
}
###################### FIM CONFIG DEPENDÊNCIAS -------------------------------------------


###################### CONFIG DEP MISP ---------------------------------------------------
function configRepoMISP (){
  space && loginfo "[MISP][REPO]" "Configurando: ${COLOR_RED}REPO MISP${COLOR_NC}."

  if [[ ! -d ${PATH_TO_MISP} ]]; then
    loginfo "[MISP][REPO]" "Criando repositório."

    sudo mkdir ${PATH_TO_MISP}
    sudo chown ${WWW_USER}:${WWW_USER} ${PATH_TO_MISP}
    cd ${PATH_TO_MISP}

    loginfo "[MISP][REPO]" "Baixando: ${COLOR_RED}REPOSITÓTIO e MÓDULOS${COLOR_NC}."

    # Fetch submodules
    if [[ ${MISP_GIT_TAG_CORE_ENABLE} == true  ]] && [[ ! -z ${MISP_GIT_TAG_CORE} ]]; then
      loginfo "[MISP][REPO]" "Criando repositório - TAG: ${COLOR_RED}${GIT_CORE_TAG}${COLOR_NC}."
      ${SUDO_WWW} git clone --branch "${CORE_TAG}" --depth 1 https://github.com/MISP/MISP.git ${PATH_TO_MISP} 
    else
      loginfo "[MISP][REPO]" "Criando repositório MASTER."
      ${SUDO_WWW} git clone https://github.com/MISP/MISP.git ${PATH_TO_MISP}
    fi

    ${SUDO_WWW} git submodule sync
    ${SUDO_WWW} git -C ${PATH_TO_MISP} submodule update --progress --init --recursive
    ${SUDO_WWW} git -C ${PATH_TO_MISP} submodule foreach --recursive git config core.filemode false
    ${SUDO_WWW} git -C ${PATH_TO_MISP} config core.filemode false
  else
    loginfo "[MISP][REPO]" "Repositório: ${COLOR_RED}JÁ EXISTE${COLOR_NC}."
  fi
}

function configRepoMISPDep (){
  space && loginfo "[MISP][REPO][DEP]" "Configurando: ${COLOR_RED}DEPEDÊNCIAS${COLOR_NC}."

  if [[ -d ${PATH_TO_MISP} ]]; then
    cd ${PATH_TO_MISP}

    loginfo "[MISP][REPO][DEP]" "Configurando: ${COLOR_RED}Create a python3 virtualenv${COLOR_NC}."
    # Create a python3 virtualenv
    [[ -e $(which virtualenv 2>/dev/null) ]] && ${SUDO_WWW} virtualenv -p python3 ${PATH_TO_MISP}/venv
    ${SUDO_WWW} python3 -m venv ${PATH_TO_MISP}/venv

    loginfo "[MISP][REPO][DEP]" "Configurando: ${COLOR_RED}make pip happy${COLOR_NC}."

    sudo mkdir /srv/www/.cache
    sudo chown ${WWW_USER}:${WWW_USER} /srv/www/.cache

    loginfo "[MISP][REPO][DEP]" "Configurando: ${COLOR_RED}Install pip setuptools${COLOR_NC}."
    ${SUDO_WWW} ${PATH_TO_MISP}/venv/bin/pip install -U pip setuptools
    #sudo pip3 install -U pip setuptools

    ${SUDO_WWW} ${PATH_TO_MISP}/venv/bin/pip --no-cache-dir install --disable-pip-version-check -r ${PATH_TO_MISP}/requirements.txt
    #sudo pip3 --no-cache-dir install --disable-pip-version-check -r ${PATH_TO_MISP}/requirements.txt

    UMASK=$(umask)
    umask 0022

    loginfo "[MISP][REPO][DEP]" "Configurando: ${COLOR_RED}Installing python-cybox${COLOR_NC}."
    cd ${PATH_TO_MISP}/app/files/scripts/python-cybox
    ${SUDO_WWW} ${PATH_TO_MISP}/venv/bin/pip install .
    #sudo pip3 install

    loginfo "[MISP][REPO][DEP]" "Configurando: ${COLOR_RED}Installing python-stix${COLOR_NC}."
    cd ${PATH_TO_MISP}/app/files/scripts/python-stix
    ${SUDO_WWW} ${PATH_TO_MISP}/venv/bin/pip install .
    #sudo pip3 install

    loginfo "[MISP][REPO][DEP]" "Configurando: ${COLOR_RED}Installing maec${COLOR_NC}."
    cd ${PATH_TO_MISP}/app/files/scripts/python-maec
    ${SUDO_WWW} ${PATH_TO_MISP}/venv/bin/pip install .
    #sudo pip3 install

    # Install misp-stix
    loginfo "[MISP][REPO][DEP]" "Configurando: ${COLOR_RED}Installing misp-stix${COLOR_NC}."
    cd ${PATH_TO_MISP}/app/files/scripts/misp-stix
    ${SUDO_WWW} ${PATH_TO_MISP}/venv/bin/pip install .
    #sudo pip3 install

    loginfo "[MISP][REPO][DEP]" "Configurando: ${COLOR_RED}Installing mixbox${COLOR_NC}."
    cd ${PATH_TO_MISP}/app/files/scripts/mixbox
    ${SUDO_WWW} ${PATH_TO_MISP}/venv/bin/pip install .
    #sudo pip3 install

    # install PyMISP
    loginfo "[MISP][REPO][DEP]" "Configurando: ${COLOR_RED}Installing PyMISP${COLOR_NC}."
    cd ${PATH_TO_MISP}/PyMISP
    ${SUDO_WWW} ${PATH_TO_MISP}/venv/bin/pip install .
    #sudo pip3 install

    # install pydeep
    loginfo "[MISP][REPO][DEP]" "Configurando: ${COLOR_RED}Installing pydeep${COLOR_NC}."
    ${SUDO_WWW} ${PATH_TO_MISP}/venv/bin/pip install git+https://github.com/kbandla/pydeep.git
    #sudo pip3 install git+https://github.com/kbandla/pydeep.git

    # install lief
    loginfo "[MISP][REPO][DEP]" "Configurando: ${COLOR_RED}Installing lief${COLOR_NC}."
    ${SUDO_WWW} ${PATH_TO_MISP}/venv/bin/pip install lief
    #sudo pip3 install lief

    # install python-magic
    loginfo "[MISP][REPO][DEP]" "Configurando: ${COLOR_RED}Installing python-magic${COLOR_NC}."
    ${SUDO_WWW} ${PATH_TO_MISP}/venv/bin/pip install python-magic
    #sudo pip3 install python-magic

    # install plyara
    loginfo "[MISP][REPO][DEP]" "Configurando: ${COLOR_RED}Installing plyara${COLOR_NC}."
    ${SUDO_WWW} ${PATH_TO_MISP}/venv/bin/pip install plyara
    #sudo pip3 install plyara

    # install zmq needed by mispzmq
    loginfo "[MISP][REPO][DEP]" "Configurando: ${COLOR_RED}Installing zmq needed by mispzmq${COLOR_NC}."
    ${SUDO_WWW} ${PATH_TO_MISP}/venv/bin/pip install zmq
    #sudo pip3 install zmq

    umask $UMASK
  else
    loginfo "[MISP][REPO][DEP]" "Diretório: ${COLOR_RED}INEXISTENTE${COLOR_NC}."
  fi
}

function installCake (){
  space && loginfo "[MISP][REPO][CAKE]" "Instalando: ${COLOR_RED}CAKE${COLOR_NC}."

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

  if [[ ${REDIS_ENABLE} == true ]]; then
    sudo sed -i  "/'host' / s/\(=> \).*/\1\'${REDIS_HOST}\',/" ${PATH_TO_MISP}/app/Plugin/CakeResque/Config/config.php
    [[ ! -z ${REDIS_PASS} ]] && sudo sed -i  "/'password' / s/\(=> \).*/\1\'${REDIS_PASS}\'/" ${PATH_TO_MISP}/app/Plugin/CakeResque/Config/config.php
  fi
}

function permissions () {
  space && loginfo "[MISP][REPO][PER]" "Configurando: ${COLOR_RED}PERMISSIONS${COLOR_NC}."

  sudo touch ${PATH_TO_MISP}/.git/ORIG_HEAD

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
  #sudo chown -R ${WWW_USER}:${WWW_USER} ${PATH_TO_MISP}/app/webroot/img/orgs
  sudo chown -R ${WWW_USER}:${WWW_USER} ${PATH_TO_MISP}/app/webroot/img/custom
}

function prepareDB () {
  space && loginfo "[MISP][DB]" "Configurando: ${COLOR_RED}BANCO DE DADOS${COLOR_NC}."

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

  sudo mysql -h ${DB_ADMIN_HOST} -u "${DB_ADMIN_USE}" -p"${DB_ADMIN_PASS}" -e "GRANT ALL PRIVILEGES on ${DB_MISP_DATABASE}.* to '${DB_MISP_USE}'@'localhost';"

  sudo mysql -h ${DB_ADMIN_HOST} -u "${DB_ADMIN_USE}" -p"${DB_ADMIN_PASS}" -e "FLUSH PRIVILEGES;"

  # Import the empty MISP database from MYSQL.sql
  ${SUDO_WWW} cat ${PATH_TO_MISP}/INSTALL/MYSQL.sql | mysql -h ${DB_ADMIN_HOST} -u "${DB_MISP_USE}" -p"${DB_MISP_PASS}" ${DB_MISP_DATABASE}
}

function configMISPFiles () {
  space && loginfo "[MISP][CONFIG][FILES]" "Configurando: ${COLOR_RED}FILES${COLOR_NC}."

  # There are 4 sample configuration files in ${PATH_TO_MISP}/app/Config that need to be copied
  ${SUDO_WWW} cp -a ${PATH_TO_MISP}/app/Config/bootstrap.default.php ${PATH_TO_MISP}/app/Config/bootstrap.php
  ${SUDO_WWW} cp -a ${PATH_TO_MISP}/app/Config/database.default.php ${PATH_TO_MISP}/app/Config/database.php
  ${SUDO_WWW} cp -a ${PATH_TO_MISP}/app/Config/core.default.php ${PATH_TO_MISP}/app/Config/core.php
  ${SUDO_WWW} cp -a ${PATH_TO_MISP}/app/Config/config.default.php ${PATH_TO_MISP}/app/Config/config.php

  echo "<?php
  class DATABASE_CONFIG {
          public \$default = array(
                  'datasource' => 'Database/Mysql',
                  'persistent' => false,
                  'host' => '${DB_ADMIN_HOST}',
                  'login' => '${DB_MISP_USE}',
                  'port' => ${DB_ADMIN_PORT},
                  'password' => '${DB_MISP_PASS}',
                  'database' => '${DB_MISP_DATABASE}',
                  'prefix' => '${DB_MISP_PREFIX}',
                  'encoding' => 'utf8',
          );
  }" | ${SUDO_WWW} tee ${PATH_TO_MISP}/app/Config/database.php

  loginfo "[MISP][CONFIG][USER]" "Configurando: ${COLOR_RED}USER${COLOR_NC}."
  sudo sed -i "/'osuser'/s/\(=>\ \).*/\1\'${WWW_USER}\',/" /srv/www/MISP/app/Config/config.php

  loginfo "[MISP][CONFIG][SALT]" "Configurando: ${COLOR_RED}SALT${COLOR_NC}."
  sudo sed -i "/'salt'/ s/\(=>\ \).*/\1\'${SALT}\',/" /srv/www/MISP/app/Config/config.php

  loginfo "[MISP][CONFIG][TIMEZONE]" "Configurando: ${COLOR_RED}TIMEZONE${COLOR_NC} na página do MISP."
  sudo sed -i "s/^\/\/\(date_default_timezone_set\).*/\1\(\'America\/Sao_Paulo\'\);/g" /srv/www/MISP/app/Config/core.php

  loginfo "[MISP][CONFIG][FORMATO DATA]" "Configurando: ${COLOR_RED}FORMATO DATA${COLOR_NC} na página do MISP."
  sudo sed -i 's/Y-m-d/d\/m\/Y/g' /srv/www/MISP/app/View/Helper/TimeHelper.php

  # and make sure the file permissions are still OK
  sudo chown -R ${WWW_USER}:${WWW_USER} ${PATH_TO_MISP}/app/Config
  sudo chmod -R 750 ${PATH_TO_MISP}/app/Config
}

function logRotation (){
  space && loginfo "[MISP][CONFIG][LOGROTATION]" "Configurando: ${COLOR_RED}LOGROTATION${COLOR_NC}."

  sudo cp ${PATH_TO_MISP}/INSTALL/misp.logrotate /etc/logrotate.d/misp
  sudo chmod 0640 /etc/logrotate.d/misp
}

function configOpenSSL (){
  if [[ ${OPENSSL_ENABLE} == true ]]; then
    space && loginfo "[MISP][CONFIG][OPENSSL]" "Configurando: ${COLOR_RED}OPENSSL${COLOR_NC} - ${ADMIN_CERT_DEST}."

    [[ ! -f "${ADMIN_CERT_DEST}" ]] && sudo mkdir -p ${ADMIN_CERT_DEST}/{private,certs}
    # This will take a rather long time, be ready. (13min on a VM, 8GB Ram, 1 core)
    if [[ ! -e "${ADMIN_CERT_DEST_PER}" ]]; then
      sudo openssl dhparam -out ${ADMIN_CERT_DEST_PER} 4096
    fi

    sudo openssl genrsa \
        -des3 \
        -passout pass:xxxx \
        -out /tmp/${ADMIN_SITE}.key 4096

    sudo openssl rsa \
        -passin pass:xxxx \
        -in /tmp/${ADMIN_SITE}.key \
        -out ${ADMIN_CERT_DEST_KEY}

    sudo rm /tmp/${ADMIN_SITE}.key

    sudo openssl req -new \
        -subj "/C=${OPENSSL_C}/ST=${OPENSSL_ST}/L=${OPENSSL_L}/O=${OPENSSL_O}/OU=${OPENSSL_OU}/CN=${OPENSSL_CN}/emailAddress=${OPENSSL_EMAILADDRESS}" \
        -key ${ADMIN_CERT_DEST_KEY} \
        -out ${ADMIN_CERT_DEST_CSR}

    sudo openssl x509 \
      -req -days 365 \
      -in ${ADMIN_CERT_DEST_CSR} \
      -signkey ${ADMIN_CERT_DEST_KEY} \
      -out ${ADMIN_CERT_DEST_CRT}

    sudo ln -s ${ADMIN_CERT_DEST_CSR} ${ADMIN_CERT_DEST_CRT_CHAIN}

    cat ${ADMIN_CERT_DEST_PER} | sudo tee -a ${ADMIN_CERT_DEST_CRT}   
  fi
}

function setupGnuPG () {
  if [[ ${GPG_ENABLE} == true ]] && [[ ${ADMIN_CERT_ENABLE} == false ]]; then
    loginfo "[MISP][CONFIG][GnuPG]" "Configurando: ${COLOR_RED}GnuPG${COLOR_NC}."

    if [ ! -f "${PATH_TO_MISP}/.gnupg/trustdb.gpg" ]; then
      # Generate a GPG encryption key.
      cat >/tmp/gen-key-script <<GPGEOF
      %echo Generating a default key
      Key-Type: default
      Key-Length: ${GPG_KEY_LENGTH}
      Subkey-Type: default
      Name-Real: ${GPG_REAL_NAME}
      Name-Comment: ${GPG_COMMENT}
      Name-Email: ${GPG_EMAIL}
      Expire-Date: 0
      Passphrase: ${GPG_PASS}
      # Do a commit here, so that we can later print "done"
      %commit
      %echo done
GPGEOF
  
      sudo mkdir -p ${PATH_TO_MISP}/.gnupg
      sudo gpg --homedir ${PATH_TO_MISP}/.gnupg --gen-key --batch /tmp/gen-key-script
      sudo rm -f /tmp/gen-key-script
    else
      loginfo "[MISP][CONFIG][GnuPG]" "... found pre-generated GPG key in ${COLOR_RED}${PATH_TO_MISP}/.gnupg${COLOR_NC}."
    fi


    if [ ! -f ${PATH_TO_MISP}/app/webroot/gpg.asc ]; then
      loginfo "[MISP][CONFIG][GPG.ASC]" "... exporting GPG key"
      sudo gpg --homedir ${PATH_TO_MISP}/.gnupg --export --armor ${GPG_EMAIL} | sudo tee ${PATH_TO_MISP}/app/webroot/gpg.asc
    else
      loginfo "[MISP][CONFIG][GPG.ASC]" "... found exported key ${COLOR_RED}${PATH_TO_MISP}/app/webroot/gpg.asc${COLOR_NC}."
    fi

    # Fix permissions
    sudo chown -R ${WWW_USER}:${WWW_USER} ${PATH_TO_MISP}/.gnupg
    sudo find ${PATH_TO_MISP}/.gnupg -type f -exec chmod 600 {} \;
    sudo find ${PATH_TO_MISP}/.gnupg -type d -exec chmod 700 {} \;
    sudo chown ${WWW_USER}:${WWW_USER} ${PATH_TO_MISP}/app/webroot/gpg.asc
  fi
}

function configProxyMISP () {
  if [[ ${ADMIN_PROXY} == true ]]; then
    loginfo "[MISP][PROXY][CA]" "Configurando: ${COLOR_RED}CA Proxy${COLOR_NC}."

    sudo cp ${MISP_CA_DEFAULT} ${MISP_CA_NEW}

    if [[ ! -z ${AMDIN_PROXY_CA} ]]; then
      sudo echo "" >> ${MISP_CA_NEW}
      sudo echo "Company Proxy CA" >> ${MISP_CA_NEW}
      sudo echo "======================" >> ${MISP_CA_NEW}
      sudo cat ${AMDIN_PROXY_CA} >> ${MISP_CA_NEW}
    fi

    sudo chmod 0400 ${MISP_CA_NEW}
  else
    MISP_CA_NEW=${MISP_CA_DEFAULT}
  fi
}

function configApacheFiles (){
  cat <<EOF | sudo tee /srv/www/htdocs/401.shtml > /dev/null
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="robots" content="noindex">
    <style>
        html, body { width: 100%; margin: 0; padding: 0; }
        body { font-family: 'Calibri', sans-serif; font-size: 16px; color: #ebebeb; background-color: #151515; text-align: center; margin-top: 10% }
        h2 { text-transform: uppercase; font-weight: lighter; font-size: 45px; margin: 5px 0; }
        p { margin: 0; }
        br { margin: 5px; }
        a { color: white }
        .requestId { font-size: 12px; color: gray }
    </style>
    <title>Permission denied</title>
</head>
<body>
    <h2>Permission denied.</h2>
    <br>
    <p>Lamentamos, mas você não tem acesso a esta página.{% if SUPPORT_EMAIL %} Se você acha que deveria conseguir acessar esta página, entre em contato conosco em <a href="mailto:{{ SUPPORT_EMAIL }}">{{ SUPPORT_EMAIL }}</a>{% endif %}.</p>
    <br>
    <p class="requestId">Request ID: <!--#echo encoding="entity" var="HTTP_X_REQUEST_ID" --></p>
</body>
</html>
EOF

  cat <<EOF | sudo tee /srv/www/htdocs/500.shtml > /dev/null
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="robots" content="noindex">
    <style>
        html, body { width: 100%; margin: 0; padding: 0; }
        body { font-family: 'Calibri', sans-serif; font-size: 16px; color: #ebebeb; background-color: #151515; text-align: center; margin-top: 10% }
        h2 { text-transform: uppercase; font-weight: lighter; font-size: 45px; margin: 5px 0; }
        p { margin: 0; }
        br { margin: 5px; }
        a { color: white }
        .requestId { font-size: 12px; color: gray }
    </style>
    <title>Internal Server Error</title>
</head>
<body>
    <h2>Internal Server Error</h2>
    <br>
    <p>O servidor está temporariamente impossibilitado de atender sua solicitação devido a um erro interno do servidor. Por favor, tente novamente mais tarde{% if SUPPORT_EMAIL %} ou entre em contato conosco em <a href="mailto:{{ SUPPORT_EMAIL }}">{{ SUPPORT_EMAIL }}</a>{% endif %}.</p>
    <br>
    <p class="requestId">Request ID: <!--#echo encoding="entity" var="HTTP_X_REQUEST_ID" --></p>
</body>
</html>
EOF

  cat <<EOF | sudo tee /srv/www/htdocs/503.shtml > /dev/null
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="robots" content="noindex">
    <style>
        html, body { width: 100%; margin: 0; padding: 0; }
        body { font-family: 'Calibri', sans-serif; font-size: 16px; color: #ebebeb; background-color: #151515; text-align: center; margin-top: 10% }
        h2 { text-transform: uppercase; font-weight: lighter; font-size: 45px; margin: 5px 0; }
        p { margin: 0; }
        br { margin: 5px; }
        a { color: white }
        .requestId { font-size: 12px; color: gray }
    </style>
    <title>Service Unavailable</title>
</head>
<body>
    <h2>Service Unavailable.</h2>
    <br>
    <p>O servidor está temporariamente impossibilitado de atender sua solicitação devido a tempo de inatividade para manutenção ou problemas de capacidade. Por favor, tente novamente mais tarde{% if SUPPORT_EMAIL %} ou entre em contato conosco em <a href="mailto:{{ SUPPORT_EMAIL }}">{{ SUPPORT_EMAIL }}</a>{% endif %}.</p>
    <br>
    <p class="requestId">Request ID: <!--#echo encoding="entity" var="HTTP_X_REQUEST_ID" --></p>
</body>
</html>
EOF

  cat <<EOF | sudo tee /srv/www/htdocs/504.shtml > /dev/null
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="robots" content="noindex">
    <style>
        html, body { width: 100%; margin: 0; padding: 0; }
        body { font-family: 'Calibri', sans-serif; font-size: 16px; color: #ebebeb; background-color: #151515; text-align: center; margin-top: 10% }
        h2 { text-transform: uppercase; font-weight: lighter; font-size: 45px; margin: 5px 0; }
        p { margin: 0; }
        br { margin: 5px; }
        a { color: white }
        .requestId { font-size: 12px; color: gray }
    </style>
    <title>Service Unavailable</title>
</head>
<body>
    <h2>Service Unavailable.</h2>
    <br>
    <p>O servidor está temporariamente impossibilitado de atender sua solicitação devido a tempo de inatividade para manutenção ou problemas de capacidade. Por favor, tente novamente mais tarde{% if SUPPORT_EMAIL %} ou entre em contato conosco em <a href="mailto:{{ SUPPORT_EMAIL }}">{{ SUPPORT_EMAIL }}</a>{% endif %}.</p>
    <br>
    <p class="requestId">Request ID: <!--#echo encoding="entity" var="HTTP_X_REQUEST_ID" --></p>
</body>
</html>
EOF

  cat <<EOF | sudo tee /srv/www/htdocs/oidc.html > /dev/null
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="robots" content="noindex">
    <style>
        html, body { width: 100%; margin: 0; padding: 0; }
        body { font-family: 'Calibri', sans-serif; font-size: 16px; color: #ebebeb; background-color: #151515; text-align: center; margin-top: 10% }
        h2 { text-transform: uppercase; font-weight: lighter; font-size: 45px; margin: 5px 0; }
        p { margin: 0; }
        br { margin: 5px; }
        a { color: white }
    </style>
    <title>Internal Server Error</title>
</head>
<body>
    <h2>Internal Server Error.</h2>
    <br>
    <p>O servidor está temporariamente impossibilitado de atender sua solicitação devido a um erro interno do servidor. Por favor, tente novamente mais tarde{% if SUPPORT_EMAIL %} ou entre em contato conosco em <a href="mailto:{{ SUPPORT_EMAIL }}">{{ SUPPORT_EMAIL }}</a>{% endif %}.</p>
    <p>%s %s</p>
</body>
</html>
EOF

  cat <<EOF | sudo tee /etc/apache2/vhosts.d/misp.conf.old > /dev/null
ServerAdmin me@me.local 
ServerName ${ADMIN_SITE}

<VirtualHost *:80>    
  DocumentRoot ${PATH_TO_MISP}/app/webroot 

  LogLevel warn 
  ErrorLog /var/log/apache2/${ADMIN_SITE}.http_error.log 
  CustomLog /var/log/apache2/${ADMIN_SITE}.http_access.log combined 

  ErrorDocument 401 /401.html
  ErrorDocument 403 /401.html
  ErrorDocument 500 /500.html
  ErrorDocument 503 /503.html
  ErrorDocument 504 /504.html
  Alias /401.html /srv/www/htdocs/401.shtml
  Alias /500.html /srv/www/htdocs/500.shtml
  Alias /503.html /srv/www/htdocs/503.shtml
  Alias /504.html /srv/www/htdocs/504.shtml

  <Directory /srv/www/htdocs/>
    Options +Includes
  </Directory>

  # Allow access to error page without authentication
  <LocationMatch "/(401|500).html">
      Satisfy any
  </LocationMatch>

  # Disable access to fpm-status
  <Location "/fpm-status">
      Require all denied
  </Location>

  SetEnvIf Authorization "(.*)" HTTP_AUTHORIZATION=\$1
  DirectoryIndex /index.php index.php

  #<FilesMatch \.php$>
  #    SetHandler "unix:/run/php-fpm/php-misp-fpm.sock|fcgi://localhost"
  #    #ProxyPass "unix:/run/php-fpm/php-misp-fpm.sock|fcgi://127.0.0.1:9000"
  #</FilesMatch>

  <Directory ${PATH_TO_MISP}/app/webroot>
      Options -Indexes +FollowSymLinks 
      AllowOverride all 
      Order allow,deny 
      Allow from all 
  </Directory>
</VirtualHost> 
EOF

cat <<EOF | sudo tee /etc/apache2/vhosts.d/misp.conf > /dev/null
ServerTokens Prod

ServerName ${ADMIN_SITE}
ServerAdmin serveradmin@misp.local

<VirtualHost *:80>

  # In theory not needed, left for debug purposes
  # LogLevel warn
  # ErrorLog /var/log/apache2/${ADMIN_SITE}.http_error.log
  # CustomLog /var/log/apache2/${ADMIN_SITE}.http_access.log combined

  Header always unset "X-Powered-By"

  RewriteEngine On
  RewriteCond %{HTTPS}  !=on
  RewriteRule ^/?(.*) https://%{SERVER_NAME}/\$1 [R,L]

  ServerSignature Off
</VirtualHost>
EOF

  cat <<EOF | sudo tee /etc/apache2/vhosts.d/misp.ssl.conf > /dev/null
ServerAdmin serveradmin@misp.local
ServerName ${ADMIN_SITE}

<VirtualHost *:443>
  #ServerAdmin me@me.local 
  #ServerName ${ADMIN_SITE}

  DocumentRoot ${PATH_TO_MISP}/app/webroot

  SSLEngine On
  SSLCertificateFile    ${ADMIN_CERT_DEST_CRT}
  SSLCertificateKeyFile ${ADMIN_CERT_DEST_KEY}

  LogLevel warn 
  ErrorLog /var/log/apache2/${ADMIN_SITE}.ssl_error.log 
  CustomLog /var/log/apache2/${ADMIN_SITE}.ssl_access.log combined 

  ErrorDocument 401 /401.html
  ErrorDocument 403 /401.html
  ErrorDocument 500 /500.html
  ErrorDocument 503 /503.html
  ErrorDocument 504 /504.html
  Alias /401.html /srv/www/htdocs/401.shtml
  Alias /500.html /srv/www/htdocs/500.shtml
  Alias /503.html /srv/www/htdocs/503.shtml
  Alias /504.html /srv/www/htdocs/504.shtml

  <IfModule mod_brotli.c>
    AddOutputFilterByType BROTLI_COMPRESS text/html text/plain text/xml text/css text/javascript application/javascript application/x-javascript application/json application/xml application/x-font-ttf image/svg+xml
    BrotliCompressionQuality 4
  </IfModule>

  <Directory ${PATH_TO_MISP}/app/webroot> 
      Options -Indexes +FollowSymLinks 
      AllowOverride all 
      Order allow,deny 
      Allow from all 
  </Directory>

  <FilesMatch "\.(shtml)$">
    # type only
    ForceType text/html
    # type and character set
    # ForceType 'text/html; charset=UTF-8'
  </FilesMatch>

  TimeOut 310
  ServerSignature Off

  Header always set Strict-Transport-Security "max-age=31536000; includeSubdomains;"
  Header always set X-Content-Type-Options nosniff
  Header always set X-Frame-Options SAMEORIGIN 
  Header always unset "X-Powered-By"
</VirtualHost>
EOF
}

function apacheConfig (){
  space && loginfo "[MISP][CONFIG][APACHE]" "Configurando: ${COLOR_RED}APACHE${COLOR_NC}."
  sudo a2enmod filter

  sudo a2enmod mod_access_compat
  sudo a2enmod ssl
  sudo a2enmod rewrite
  sudo a2enmod headers
  sudo a2enmod brotli
  sudo a2enmod xdebug

  configApacheFiles

  sudo sed -i "s/^#\(Listen 443\).*/\1/" /etc/apache2/listen.conf

  sudo apachectl configtest
  sudo systemctl enable --now apache2.service
  sudo systemctl restart apache2.service
}

function verificaStats (){
  loginfo "[CONFIG][VERIFICA-STATUS]" "Verifica: ${COLOR_RED}STATUS APPs${COLOR_NC}."

  [[ $(sudo systemctl is-active firewalld) == 'active' ]] && sudo systemctl stop firewalld || loginfo "[STATUS][FIREWALLD]" "${COLOR_RED} PARADO${COLOR_NC}."
  [[ $(sudo systemctl is-enabled firewalld) == 'enabled' ]] && sudo sudo systemctl disable firewalld || loginfo "[STATUS][FIREWALLD]" "${COLOR_RED} Desabilitado${COLOR_NC}."

  [[ $(sudo systemctl is-active mariadb.service) != 'active' ]] && sudo systemctl restart mariadb.service || loginfo "[STATUS][MARIADB]" "${COLOR_RED} OK${COLOR_NC}."
  [[ $(sudo systemctl is-enabled mariadb.service) != 'enabled' ]] && sudo systemctl enable mariadb.service || loginfo "[STATUS][MARIADB]" "${COLOR_RED} Habilitado${COLOR_NC}."

  [[ $(sudo systemctl is-active supervisord.service) != 'active' ]] && sudo systemctl restart supervisord.service || loginfo "[STATUS][SUPERVISOR]" "${COLOR_RED} OK${COLOR_NC}."
  [[ $(sudo systemctl is-enabled supervisord.service) != 'enabled' ]] && sudo systemctl enable supervisord.service || loginfo "[STATUS][SUPERVISOR]" "${COLOR_RED} Habilitado${COLOR_NC}."

  [[ $(sudo systemctl is-active redis@default.service) != 'active' ]] && sudo systemctl restart redis@default.service || loginfo "[STATUS][REDIS]" "${COLOR_RED} OK${COLOR_NC}."
  [[ $(sudo systemctl is-enabled redis@default.service) != 'enabled' ]] && sudo systemctl enable redis@default.service || loginfo "[STATUS][REDIS]" "${COLOR_RED} Habilitado${COLOR_NC}."

  [[ $(sudo systemctl is-active apache2.service) != 'active' ]] && sudo systemctl restart apache2.service || loginfo "[STATUS][APACHE2]" "${COLOR_RED} OK${COLOR_NC}."
  [[ $(sudo systemctl is-enabled apache2.service) != 'enabled' ]] && sudo systemctl enable apache2.service || loginfo "[STATUS][APACHE2]" "${COLOR_RED} Habilitado${COLOR_NC}."

}

function preConfigMisp () {
  configRepoMISP
  configRepoMISPDep
  installCake
  permissions
  prepareDB
  configMISPFiles
  logRotation
  configOpenSSL
  setupGnuPG
  configProxyMISP
  apacheConfig
  verificaStats
}
###################### FIM CONFIG DEP MISP -----------------------------------------------




###################### CONFIGURAÇÃO DO SERVIÇO DO MISP -----------------------------------
function backgroundWorkersSupervisor () {
  if [[ ${SUPERVISOR_ENABLE} == true ]]; then
    loginfo "[MISP][CONFIG][backgroundWorkers]" "Configurando: ${COLOR_RED}backgroundWorkers${COLOR_NC}."

    cat <<EOF | sudo tee /etc/supervisord.d/50-workers.conf > /dev/null
# Workers are set to NOT auto start so we have time to enforce permissions on the cache first

[group:misp-workers]
programs=default,email,cache,prio,update

[program:default]
directory=/srv/www/MISP
command=/srv/www/MISP/app/Console/cake start_worker default
process_name=%(program_name)s_%(process_num)02d
numprocs=1
autostart=false
autorestart=true
redirect_stderr=false
stderr_logfile=/srv/www/MISP/app/tmp/logs/misp-workers-errors.log
stdout_logfile=/srv/www/MISP/app/tmp/logs/misp-workers.log
directory=/srv/www/MISP
user=wwwrun

[program:prio]
directory=/srv/www/MISP
command=/srv/www/MISP/app/Console/cake start_worker prio
process_name=%(program_name)s_%(process_num)02d
numprocs=3
autostart=false
autorestart=true
redirect_stderr=false
stderr_logfile=/srv/www/MISP/app/tmp/logs/misp-workers-errors.log
stdout_logfile=/srv/www/MISP/app/tmp/logs/misp-workers.log
directory=/srv/www/MISP
user=wwwrun

[program:email]
directory=/srv/www/MISP
command=/srv/www/MISP/app/Console/cake start_worker email
process_name=%(program_name)s_%(process_num)02d
numprocs=3
autostart=false
autorestart=true
redirect_stderr=false
stderr_logfile=/srv/www/MISP/app/tmp/logs/misp-workers-errors.log
stdout_logfile=/srv/www/MISP/app/tmp/logs/misp-workers.log
directory=/srv/www/MISP
user=wwwrun

[program:update]
directory=/srv/www/MISP
command=/srv/www/MISP/app/Console/cake start_worker update
process_name=%(program_name)s_%(process_num)02d
numprocs=1
autostart=false
autorestart=true
redirect_stderr=false
stderr_logfile=/srv/www/MISP/app/tmp/logs/misp-workers-errors.log
stdout_logfile=/srv/www/MISP/app/tmp/logs/misp-workers.log
directory=/srv/www/MISP
user=wwwrun

[program:cache]
directory=/srv/www/MISP
command=/srv/www/MISP/app/Console/cake start_worker cache
process_name=%(program_name)s_%(process_num)02d
numprocs=1
autostart=false
autorestart=true
redirect_stderr=false
stderr_logfile=/srv/www/MISP/app/tmp/logs/misp-workers-errors.log
stdout_logfile=/srv/www/MISP/app/tmp/logs/misp-workers.log
user=wwwrun
EOF
    sudo supervisorctl reread
    sudo supervisorctl update

    #sudo supervisorctl restart misp-workers:*
  fi
}

function backgroundWorkersNoSupervisor () {
  if [[ ${SUPERVISOR_ENABLE} == false ]]; then
    space && loginfo "[MISP][CONFIG][backgroundWorkers]" "Configurando: ${COLOR_RED}backgroundWorkers${COLOR_NC}."
    
    # To make the background workers start on boot
    sudo chmod +x ${PATH_TO_MISP}/app/Console/worker/start.sh
    if [ ! -e /etc/rc.local ]; then
      echo '#!/bin/sh -e' | sudo tee -a /etc/rc.local
      echo 'exit 0' | sudo tee -a /etc/rc.local
      sudo chmod u+x /etc/rc.local
    fi

    cat <<EOF | sudo tee /etc/systemd/system/misp-workers.service > /dev/null
[Unit]
Description=MISP background workers
After=network.target

[Service]
Type=forking
User=${WWW_USER}
Group=${WWW_USER}
ExecStart=${PATH_TO_MISP}/app/Console/worker/start.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable --now misp-workers

    # Add the following lines before the last line (exit 0). Make sure that you replace www-data with your apache user:
    sudo sed -i -e '$i \echo never > /sys/kernel/mm/transparent_hugepage/enabled\n' /etc/rc.local
    sudo sed -i -e '$i \echo 1024 > /proc/sys/net/core/somaxconn\n' /etc/rc.local
    sudo sed -i -e '$i \sysctl vm.overcommit_memory=1\n' /etc/rc.local
  fi
}


function configuracaoMISP (){
  loginfo "[MISP][ADMIN][USER]" "${COLOR_RED}[PASSO 01]${COLOR_NC} - Configurando: ${COLOR_RED}USER${COLOR_NC}."
  ${SUDO_WWW} -- ${CAKE} user init

  loginfo "[MISP][ADMIN][USER]" "${COLOR_RED}[PASSO 01.1]${COLOR_NC} - Setando e-mail: ${COLOR_RED}${ADMIN_EMAIL}${COLOR_NC}."
  echo "UPDATE misp.users SET email = \"${ADMIN_EMAIL}\" WHERE id = 1;" | mysql -h ${DB_ADMIN_HOST} -u "${DB_MISP_USE}" -p"${DB_MISP_PASS}" ${DB_MISP_DATABASE}
  
  if [ ! -z "$ADMIN_ORG" ]; then
    loginfo "[MISP][ADMIN][USER]" "${COLOR_RED}[PASSO 01.2]${COLOR_NC} - Setando Organização: ${COLOR_RED}${ADMIN_ORG}${COLOR_NC}."
    echo "UPDATE misp.organisations SET name = \"${ADMIN_ORG}\" where id = 1;" | mysql -h ${DB_ADMIN_HOST} -u "${DB_MISP_USE}" -p"${DB_MISP_PASS}" ${DB_MISP_DATABASE}
    echo "UPDATE misp.organisations SET nationality = \"${ADMIN_NAT}\" where id = 1;" | mysql -h ${DB_ADMIN_HOST} -u "${DB_MISP_USE}" -p"${DB_MISP_PASS}" ${DB_MISP_DATABASE}
    echo "UPDATE misp.organisations SET sector = \"${ADMIN_SEC}\" where id = 1;" | mysql -h ${DB_ADMIN_HOST} -u "${DB_MISP_USE}" -p"${DB_MISP_PASS}" ${DB_MISP_DATABASE}
    echo "UPDATE misp.organisations SET description = \"${ADMIN_DES}\" where id = 1;" | mysql -h ${DB_ADMIN_HOST} -u "${DB_MISP_USE}" -p"${DB_MISP_PASS}" ${DB_MISP_DATABASE}
  fi

  loginfo "[MISP][CONFIG]" "${COLOR_RED}[PASSO 02]${COLOR_NC} - Atualizar o ${COLOR_BLUE}BANCO DE DADOS${COLOR_NC}."
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin runUpdates


  loginfo "[MISP][CONFIG]" "${COLOR_RED}[PASSO 03]${COLOR_NC} - Definir o path para o ${COLOR_BLUE}virtualenv${COLOR_NC}."
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.python_bin "${PATH_TO_MISP}/venv/bin/python"

  loginfo "[MISP][CONFIG]" "${COLOR_RED}[PASSO 03.1]${COLOR_NC} - Habilitar a organização padrão e configurar algumas variáveis."
  
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.ca_path "${MISP_CA_NEW}"

  [[ ${ADMIN_PROXY} == true ]] && ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Proxy.host "${AMDIN_PROXY_HOST}"
  [[ ${ADMIN_PROXY} == true ]] && ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Proxy.port "${AMDIN_PROXY_PORT}"
  [[ ${ADMIN_PROXY} == true ]] && ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Proxy.method "Basic"
  [[ ${ADMIN_PROXY} == true ]] && [[ ! -z ${AMDIN_PROXY_USER} ]] && ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Proxy.user "${AMDIN_PROXY_USER}"
  [[ ${ADMIN_PROXY} == true ]] && [[ ! -z ${AMDIN_PROXY_PASS} ]] && ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Proxy.password "${AMDIN_PROXY_PASS}"

  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.tmpdir "${PATH_TO_MISP}/app/tmp"

  loginfo "[MISP][CONFIG]" "${COLOR_RED}[PASSO 03.2]${COLOR_NC} - Definir ${COLOR_BLUE}TIMROUTS${COLOR_NC};"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Session.autoRegenerate 0
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Session.timeout 600
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Session.cookieTimeout 3600

  loginfo "[MISP][CONFIG]" "${COLOR_RED}[PASSO 03.4]${COLOR_NC} - Definir a URL do MISP ${COLOR_BLUE}https://${ADMIN_SITE}${COLOR_NC}."
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.baseurl "https://${ADMIN_SITE}"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.external_baseurl "https://${ADMIN_SITE}"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.org "${ADMIN_ORG}"

  loginfo "[MISP][CONFIG]" "${COLOR_RED}[PASSO 03.5]${COLOR_NC} - Habilitar a organização padrão e configurar algumas variáveis."
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.host_org_id 1
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.email "${ADMIN_CONTATO}"
  # Envio de e-mail
    ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting --force MISP.disable_emailing false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.contact "${ADMIN_CONTATO}"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.disablerestalert true
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.showCorrelationsOnIndex true
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.default_event_tag_collection 0

  loginfo "[MISP][CAKE]" "${COLOR_RED}[PASSO 04]${COLOR_NC} - Enable ${COLOR_BLUE}GnuPG${COLOR_NC}."
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting GnuPG.onlyencrypted false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting GnuPG.email "${GPG_EMAIL}"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting GnuPG.homedir "${PATH_TO_MISP}/.gnupg"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting GnuPG.password "${GPG_PASS}"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting GnuPG.binary "$(which gpg)"
  #${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting GnuPG.bodyonlyencrypted false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting GnuPG.bodyonlyencrypted true
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting GnuPG.sign true
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting GnuPG.obscure_subject true
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting GnuPG.key_fetching_disabled false

  loginfo "[MISP][CAKE]" "${COLOR_RED}[PASSO 05]${COLOR_NC} - Enable ${COLOR_BLUE}SMIME${COLOR_NC}."
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting SMIME.enabled false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting --force SMIME.email "${ADMIN_CONTATO}"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting SMIME.cert_public_sign "/srv/www/MISP/.smime/email@address.com.pem"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting SMIME.cert_public_sign "/srv/www/MISP/.smime/email@address.com.key"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting --force SMIME.password ""

  # Redis block
  loginfo "[MISP][CONFIG]" "${COLOR_RED}[PASSO 06]${COLOR_NC} - Configurando o ${COLOR_BLUE}REDIS${COLOR_NC}."
  [[ ${REDIS_ENABLE} == true ]] && ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.redis_host "${REDIS_HOST}"
  [[ ${REDIS_ENABLE} == true ]] && ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.redis_port ${REDIS_PORT}
  [[ ${REDIS_ENABLE} == true ]] && ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.redis_database ${REDIS_DATA}
  [[ ${REDIS_ENABLE} == true ]] && ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.redis_password "${REDIS_PASS}"

  loginfo "[MISP][CAKE]" "${COLOR_RED}[PASSO 07]${COLOR_NC} - Configurando o ${COLOR_BLUE}SimpleBackgroundJobs block${COLOR_NC}."
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting SimpleBackgroundJobs.enabled true
  [[ ${REDIS_ENABLE} == true ]] && ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting SimpleBackgroundJobs.redis_host  "${REDIS_HOST}"
  [[ ${REDIS_ENABLE} == true ]] && ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting SimpleBackgroundJobs.redis_port ${REDIS_PORT}
  [[ ${REDIS_ENABLE} == true ]] && ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting SimpleBackgroundJobs.redis_database 1
  [[ ${REDIS_ENABLE} == true ]] && ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting SimpleBackgroundJobs.redis_password ${REDIS_PASS}
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting SimpleBackgroundJobs.redis_namespace "background_jobs"
  # ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting SimpleBackgroundJobs.redis_serializer "JSON"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting SimpleBackgroundJobs.max_job_history_ttl 86400
  [[ ${SUPERVISOR_ENABLE} == true ]] && ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting SimpleBackgroundJobs.supervisor_host "${SUPERVISOR_HOST}"
  [[ ${SUPERVISOR_ENABLE} == true ]] && ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting SimpleBackgroundJobs.supervisor_port ${SUPERVISOR_PORT}
  [[ ${SUPERVISOR_ENABLE} == true ]] && ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting SimpleBackgroundJobs.supervisor_user "${SUPERVISOR_USER}"
  [[ ${SUPERVISOR_ENABLE} == true ]] && ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting SimpleBackgroundJobs.supervisor_password "${SUPERVISOR_PASS}"

  loginfo "[MISP][CONFIG]" "${COLOR_RED}[PASSO 08]${COLOR_NC} - Configurando os ${COLOR_BLUE}PLUGINS${COLOR_NC}."
  loginfo "[MISP][CONFIG]" "${COLOR_RED}[PASSO 08.1]${COLOR_NC} - Configurando o ${COLOR_BLUE}CORTEX${COLOR_NC}."
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Cortex_services_enable false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Cortex_services_url "http://127.0.0.1"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Cortex_services_port 9000
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Cortex_timeout 120
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting --force Plugin.Cortex_authkey ""
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Cortex_ssl_verify_peer false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Cortex_ssl_verify_host false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Cortex_ssl_allow_self_signed true

  loginfo "[MISP][CONFIG]" "${COLOR_RED}[PASSO 08.2]${COLOR_NC} - Configurando o ${COLOR_BLUE}SIGHTINGS${COLOR_NC}."
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Sightings_policy 0
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Sightings_anonymise false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Sightings_range 365
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Sightings_sighting_db_enable false

  loginfo "[MISP][CONFIG]" "${COLOR_RED}[PASSO 08.3]${COLOR_NC} - Configurando o ${COLOR_BLUE}CUSTOMAUTH${COLOR_NC}."
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.CustomAuth_disable_logout false

  loginfo "[MISP][CONFIG]" "${COLOR_RED}[PASSO 08.4]${COLOR_NC} - Configurando o ${COLOR_BLUE}RPZ${COLOR_NC}."
  #${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.RPZ_policy "DROP"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.RPZ_walled_garden "127.0.0.1"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.RPZ_serial "\$date00"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.RPZ_refresh "2h"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.RPZ_retry "30m"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.RPZ_expiry "30d"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.RPZ_minimum_ttl "1h"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.RPZ_ttl "1w"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.RPZ_ns "localhost."
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting --force Plugin.RPZ_ns_alt ""
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.RPZ_email "root.localhost"

  loginfo "[MISP][CONFIG]" "${COLOR_RED}[PASSO 08.5]${COLOR_NC} - Configurando o ${COLOR_BLUE}KAFKA${COLOR_NC}."
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Kafka_enable false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Kafka_brokers "kafka:9092"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Kafka_rdkafka_config "/etc/rdkafka.ini"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Kafka_include_attachments false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Kafka_event_notifications_enable false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Kafka_event_notifications_topic "misp_event"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Kafka_event_publish_notifications_enable false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Kafka_event_publish_notifications_topic "misp_event_publish"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Kafka_object_notifications_enable false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Kafka_object_notifications_topic "misp_object"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Kafka_object_reference_notifications_enable false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Kafka_object_reference_notifications_topic "misp_object_reference"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Kafka_attribute_notifications_enable false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Kafka_attribute_notifications_topic "misp_attribute"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Kafka_shadow_attribute_notifications_enable false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Kafka_shadow_attribute_notifications_topic "misp_shadow_attribute"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Kafka_tag_notifications_enable false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Kafka_tag_notifications_topic "misp_tag"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Kafka_sighting_notifications_enable false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Kafka_sighting_notifications_topic "misp_sighting"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Kafka_user_notifications_enable false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Kafka_user_notifications_topic "misp_user"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Kafka_organisation_notifications_enable false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Kafka_organisation_notifications_topic "misp_organisation"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Kafka_audit_notifications_enable false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Kafka_audit_notifications_topic "misp_audit"

  loginfo "[MISP][ADMIN][Plugin][ZeroMQ]" "${COLOR_RED}[PASSO 08.6]${COLOR_NC} - Configurando o ${COLOR_RED}ADMIN - Plugin: ZeroMQ${COLOR_NC}."
  # ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.ZeroMQ_enable 0
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting "Plugin.ZeroMQ_host" "localhost"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting "Plugin.ZeroMQ_port" 50000
  #${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting "Plugin.ZeroMQ_username" ""
  #${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting "Plugin.Plugin.ZeroMQ_password" ""
  [[ ${REDIS_ENABLE} == true ]] && ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.ZeroMQ_redis_host "${REDIS_HOST}"
  [[ ${REDIS_ENABLE} == true ]] && ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.ZeroMQ_redis_port ${REDIS_PORT}
  [[ ${REDIS_ENABLE} == true ]] && ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.ZeroMQ_redis_password "${REDIS_PASS}"
  [[ ${REDIS_ENABLE} == true ]] && ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.ZeroMQ_redis_database 1
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.ZeroMQ_redis_namespace "mispq"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.ZeroMQ_event_notifications_enable false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.ZeroMQ_object_notifications_enable false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.ZeroMQ_object_reference_notifications_enable false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.ZeroMQ_attribute_notifications_enable false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.ZeroMQ_sighting_notifications_enable false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.ZeroMQ_user_notifications_enable false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.ZeroMQ_organisation_notifications_enable false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.ZeroMQ_include_attachments false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.ZeroMQ_tag_notifications_enable false

  #loginfo "[MISP][ADMIN][Plugin][Enrichment]" "Configurando: ${COLOR_RED}ADMIN - Plugin: Enrichment${COLOR_NC}."
  #${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Enrichment_services_enable 0
  #${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Enrichment_hover_enable 0
  #${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Enrichment_hover_popover_only 0
  #${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Enrichment_timeout 10
  #${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Enrichment_hover_timeout 5
  #${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Enrichment_services_url "http://127.0.0.1"
  #${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Plugin.Enrichment_services_port 6666

  loginfo "[MISP][CONFIG]" "${COLOR_RED}[PASSO 09]${COLOR_NC} - Configurando as opções default."
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.language "eng"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.proposals_block_attributes false

  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.ssdeep_correlation_threshold 40
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.extended_alert_subject false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.default_event_threat_level 4
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.newUserText "Dear new MISP user,\\n\\nWe would hereby like to welcome you to the \$org MISP community.\\n\\n Use the credentials below to log into MISP at \$misp, where you will be prompted to manually change your password to something of your own choice.\\n\\nUsername: \$username\\nPassword: \$password\\n\\nIf you have any questions, don't hesitate to contact us at: \$contact.\\n\\nBest regards,\\nYour \$org MISP support team"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.passwordResetText "Dear MISP user,\\n\\nA password reset has been triggered for your account. Use the below provided temporary password to log into MISP at \$misp, where you will be prompted to manually change your password to something of your own choice.\\n\\nUsername: \$username\\nYour temporary password: \$password\\n\\nIf you have any questions, don't hesitate to contact us at: \$contact.\\n\\nBest regards,\\nYour \$org MISP support team"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.disableUserSelfManagement false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.block_event_alert false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.block_event_alert_tag "no-alerts=\"true\""
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.block_old_event_alert false
  #${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.block_old_event_alert_age ""
  #${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.block_old_event_alert_by_date ""
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.incoming_tags_disabled_by_default false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.maintenance_message "O MISP está passando por manutenção, mas retornará em breve."
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.attachments_dir "$PATH_TO_MISP/app/files"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.download_attachments_on_load true
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.title_text "MISP - BRB"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.terms_download false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.showorgalternate false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.event_view_filter_fields "id, uuid, value, comment, type, category, Tag.name"

  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Security.password_policy_length 12
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Security.password_policy_complexity '/^((?=.*\d)|(?=.*\W+))(?![\n])(?=.*[A-Z])(?=.*[a-z]).*$|.{16,}/'

  loginfo "[MISP][CONFIG]" "${COLOR_RED}[PASSO 10]${COLOR_NC} - Hardening do MISP."
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Security.disable_browser_cache true
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Security.check_sec_fetch_site_header true
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Security.csp_enforce true
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Security.advanced_authkeys true
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Security.do_not_log_authkeys true
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Security.username_in_response_header true

  loginfo "[MISP][CONFIG]" "${COLOR_RED}[PASSO 11]${COLOR_NC} - Adicionar endereço IP nos logs."
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.log_client_ip true
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.log_auth true

  loginfo "[MISP][CONFIG]" "${COLOR_RED}[PASSO 12]${COLOR_NC} - Personalizar o MISP."
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting --force MISP.footermidleft ""
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting --force MISP.footermidright "Powered by ${ADMIN_ORG}"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting --force MISP.welcome_text_top ""
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting --force MISP.welcome_text_bottom "" 
  
  loginfo "[MISP][ADMIN][USER]" "${COLOR_RED}[PASSO 13]${COLOR_NC} - Configurando o acesso ${COLOR_RED}${ADMIN_EMAIL}${COLOR_NC}."
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} User change_pw "${ADMIN_EMAIL}" "${ADMIN_PASS}"
  echo 'UPDATE misp.users SET change_pw = 0 WHERE id = 1;' | mysql -h ${DB_ADMIN_HOST} -u "${DB_MISP_USE}" -p"${DB_MISP_PASS}" ${DB_MISP_DATABASE}

  loginfo "[MISP][ADMIN][SECURITY]" "${COLOR_RED}[PASSO 14]${COLOR_NC} - Configurando o ${COLOR_RED}SECURITY${COLOR_NC}."
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Security.alert_on_suspicious_logins true
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Security.log_each_individual_auth_fail true
  #${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting Security.encryption_key ""
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.log_new_audit true
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.log_user_ips true
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.log_user_ips_authkeys true

  #${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting MISP.attachment_scan_module ""



  # Enable Enrichment, set better timeouts
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting "Plugin.Enrichment_services_enable" false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting "Plugin.Enrichment_hover_enable" false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting "Plugin.Enrichment_hover_popover_only" false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting "Plugin.Enrichment_hover_timeout" 150
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting "Plugin.Enrichment_timeout" 300
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting "Plugin.Enrichment_services_url" "http://127.0.0.1"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting "Plugin.Enrichment_services_port" 6666

  # Enable Import modules, set better timeout
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting "Plugin.Import_services_enable" false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting "Plugin.Import_services_url" "http://127.0.0.1"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting "Plugin.Import_services_port" 6666
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting "Plugin.Import_timeout" 300

  # Enable Export modules, set better timeout
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting "Plugin.Export_services_enable" false
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting "Plugin.Export_services_url" "http://127.0.0.1"
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting "Plugin.Export_services_port" 6666
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting "Plugin.Export_timeout" 300

  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin setSetting "Plugin.Action_services_enable" false



  loginfo "[MISP][ADMIN][LIVE]" "${COLOR_RED}[PASSO 15]${COLOR_NC} - Configurando o ${COLOR_RED}LIVE${COLOR_NC}."
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin live 1

  loginfo "[MISP][WORKERS][START]" "${COLOR_RED}[PASSO 16]${COLOR_NC} - Inicando ${COLOR_RED}WORKERS${COLOR_NC}."
  sudo supervisorctl start misp-workers:*
}

function update_components() {
  loginfo "[MISP][GET-AUTH]" "Capturando o ${COLOR_RED}authkey${COLOR_NC}."

  mysql -h ${DB_ADMIN_HOST} -u "${DB_MISP_USE}" -p"${DB_MISP_PASS}" ${DB_MISP_DATABASE} -e "SELECT authkey FROM users;" | tail -1 > /tmp/auth.key
  AUTH_KEY=$(cat /tmp/auth.key)
  rm /tmp/auth.key

  loginfo "[MISP][UPDATE]" "Updating: ${COLOR_RED}Galaxies, ObjectTemplates, Warninglists, Noticelists and Templates${COLOR_NC}."
  # TODO: Fix updateGalaxies
  loginfo "[MISP][UPDATE][Galaxies]" "Updating: ${COLOR_RED}Galaxies${COLOR_NC}."
  #${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin updateJSON
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin updateGalaxies
  # Updating the taxonomies…
  loginfo "[MISP][UPDATE][updateTaxonomies]" "Updating: ${COLOR_RED}updateTaxonomies${COLOR_NC}."
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin updateTaxonomies
  # Updating the warning lists…
  loginfo "[MISP][UPDATE][updateWarningLists]" "Updating: ${COLOR_RED}updateWarningLists${COLOR_NC}."
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin updateWarningLists
  # Updating the notice lists…
  loginfo "[MISP][UPDATE][updateNoticeLists]" "Updating: ${COLOR_RED}updateNoticeLists${COLOR_NC}."
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin updateNoticeLists
  # Updating the object templates…
  loginfo "[MISP][UPDATE][updateObjectTemplates]" "Updating: ${COLOR_RED}updateObjectTemplates${COLOR_NC}."
  ${SUDO_WWW} ${RUN_PHP} -- ${CAKE} Admin updateObjectTemplates 1

}

function runTests () {
  loginfo "[MISP][TESTE]" "Executando os ${COLOR_RED}runTests${COLOR_NC}."

  echo "url = \"${BASE_URL}\"
  key = \"${AUTH_KEY}\"" |sudo tee ${PATH_TO_MISP}/PyMISP/tests/keys.py

  sudo chown -R ${WWW_USER}:${WWW_USER} ${PATH_TO_MISP}/PyMISP/
  ${SUDO_WWW} sh -c "cd $PATH_TO_MISP/PyMISP && git submodule foreach git pull origin main"
  ${SUDO_WWW} ${PATH_TO_MISP}/venv/bin/pip install -e $PATH_TO_MISP/PyMISP/.[fileobjects,neo,openioc,virustotal,pdfexport]
  ${SUDO_WWW} sh -c "cd $PATH_TO_MISP/PyMISP && ${PATH_TO_MISP}/venv/bin/python tests/testlive_comprehensive.py"
}


function configMISP () {
  backgroundWorkersSupervisor
  backgroundWorkersNoSupervisor
  configuracaoMISP

  update_components
  runTests
}


function clenaENV () {
  loginfo "[CLEAN][ENV]" "Linpandos as ${COLOR_BLUE}VARIÁVEIS${COLOR_NC}."
  unset $(sudo egrep -v "^\s*(;|$|\[|#)" /admin/.env | cut -f1 -d'=')
}

###################### INSTALAÇÃO --------------------------------------------------------
function installSupported () {
  space
  loginfo "" "PROCESSO DE INSTALAÇÃO DO ${COLOR_BLUE}MISP Core${COLOR_NC} no ${COLOR_RED}$(. /etc/os-release && echo ${PRETTY_NAME} | tr '[:lower:]' '[:upper:]')${COLOR_NC}"
  space

  ###################### CONFIG SUDO E SUDOERS ------------------------------------------
  checkSudoers

  ###################### CONFIG ADMIN ---------------------------------------------------
  adminConfig

  ###################### CONFIG LOCAL ---------------------------------------------------
  localConfig

  ###################### INSTALL REPO e DEP ---------------------------------------------
  repoDep

  ###################### CONFIG REPO e DEP ----------------------------------------------
  configDep

  ###################### PRE CONFIG MISP ------------------------------------------------
  preConfigMisp

  ###################### PRE CONFIG MISP ------------------------------------------------
  configMISP


  clenaENV
}

colors

installSupported
