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


###################### CONFIG FIREWALLD ---------------------------------------------------
function enableSSH () {
  # Verificando se o serviço SSH está habilitado.
  firewall-cmd --list-all

  # Adicionando o serviço SSH na Zona PUBLIC de forma permanente.
  firewall-cmd --zone=public --add-service=ssh --permanent

  # Reiniciando o servico para aplicar as configurações.
  systemctl restart firewalld.service
}

###################### CONFIG SUDO E SUDOERS ---------------------------------------------------
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

###################### CONFIG ADMIN ---------------------------------------------------
function adminDirectory () {
  if [[ ! -d "/admin"  ]]; then  
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
  [[ -f "/admin/.env"  ]] && sudo rm -f /admin/.env

  # Criando o arquivo /admin/.env
  sudo touch /admin/.env

  # Alterando a permissão do arqui para READ e WRITE apenas para o dono do arquivo.
  sudo chmod 0600 /admin/.env
}


function adminFileEnvConfig () {
  # Abra o arquivo .env com o coimando abaixo e cole as configurações abaixo.
  space && loginfo "[ADMIN][.ENV]" "Populando o arquivo ${COLOR_RED}.ENV${COLOR_NC}."
  cat <<EOF | sudo tee  /admin/.env > /dev/null
[O.S.]
SUSE_SP=$(. /etc/os-release && echo "$VERSION_ID")
FLAVOUR=$(. /etc/os-release && echo "$ID"| tr '[:upper:]' '[:lower:]')
#PRETTY="$(. /etc/os-release && echo "$PRETTY_NAME"| tr '[:upper:]' '[:lower:]')"

[ADMIN]
ADMIN_HOSTNAME=misp
ADMIN_SITE=misp.local

[MISP]



[PYTHON]
VERSION_PYTHON=310

[PHP]
PHP_FPM=false
PHP_PECL=true
PHP_ETC_BASE=/etc/php7

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

EOF
}

function adminGeneratingPass () {
  space && loginfo "[ADMIN][.ENV][PASS]" "Gerando as senhas do arquivo ${COLOR_RED}.ENV${COLOR_NC}."
  sudo sed -i "s/^\(.*_PASS=\).*/\1$(openssl rand -hex 32)/" /admin/.env
}

function adminGeneratingExport () {
  space && loginfo "[ADMIN][EXPORT][GENERATING]" "Gerando as variáveis temporárias pelo ${COLOR_RED}EXPORT${COLOR_NC}."
  #export $(sudo egrep -v "^\s*(;|$|\[)" /admin/.env | cut -f1 -d$'\t' | cut -f1 -d' ' | xargs)
  export $(sudo egrep -v "^\s*(;|$|\[|#)" /admin/.env | xargs)
  #eval $(sudo grep -v -e "^\s*(;|$|\[|#)" /admin/.env | xargs -I {} echo export \'{}\')
  # unset $(sudo egrep -v "^\s*(;|$|\[|#)" /admin/.env | cut -f1 -d'=')
}

function adminConfig () {
  adminDirectory
  adminFileEnv
  adminFileEnvConfig
  adminGeneratingPass
  adminGeneratingExport
}


###################### CONFIGURAÇÕES LOCAIS ---------------------------------------------------
function localTimeZone () {
  space && loginfo "[LOCAL][TIMEZONE]" "Definindo o ${COLOR_RED}TIMEZONE - America/Sao_Paulo${COLOR_NC} e aplicando."
  sudo timedatectl set-timezone America/Sao_Paulo
  sudo sed -i "s/^#\(NTP=\).*/\1a.ntp.br/g" /etc/systemd/timesyncd.conf
  sudo sed -i "s/^#\(FallbackNTP=\).*/\1a.ntp.br/g" /etc/systemd/timesyncd.conf
  sudo timedatectl set-ntp true
  sudo sudo hwclock --systohc --localtime
  sudo service systemd-timesyncd restart

  sudo localectl set-locale LC_TIME=pt_BR.UTF-8
  export LC_TIME=pt_BR.UTF-8
}

function localSetHostname () {
  if  [[ ! -z ${ADMIN_HOSTNAME} ]]; then  
    space && loginfo "[LOCAL][HOSTNAME]" "Configurando o HOSTNAME para ${COLOR_RED}${ADMIN_HOSTNAME}${COLOR_NC}."
    sudo hostnamectl set-hostname ${ADMIN_HOSTNAME}
  fi  
}


function localHosts () {
  space && loginfo "[LOCAL][HOSTS]" "Configurando o HOSTS ${COLOR_RED}${FQDN}${COLOR_NC}."
  echo "127.0.0.1       ${ADMIN_SITE} ${ADMIN_HOSTNAME}" | sudo tee -a /etc/hosts
}

function localRcLocal () {
  space && loginfo "[LOCAL][RC.LOCAL]" "Criando o arquivo RC.LOCAL, caso não exista."
  # Criação do arquivo /etc/rc.local.
  echo '#!/bin/sh -e' | sudo tee /etc/rc.local
  echo 'exit 0' | sudo tee -a /etc/rc.local
  # Aplicando as permissões de execução do arquivo /etc/rc.local.
  sudo chmod u+x /etc/rc.local
}

function localSwap () {
  if [[ ${SWAP_ENABLE} == true  ]]; then
    if [[ ! $(sudo swapon -v) ]]; then
      space && loginfo "[LOCAL][SWAP]" "Configurnado ${COLOR_YELLOW}SWAP${COLOR_NC}."

      sudo touch ${SWAP_FILE}
      # sudo chattr +C ${SWAP_FILE}
      sudo fallocate -l ${SWAP_SIZE}G ${SWAP_FILE}
      sudo chmod 0600 ${SWAP_FILE}
      sudo mkswap ${SWAP_FILE}
      sudo swapon ${SWAP_FILE}
      echo "${SWAP_FILE} none swap defaults 0 0" | sudo tee -a /etc/fstab

      sudo swapon --show
      sudo free -th
    else
      space && loginfo "[LOCAL][SWAP]" "FALHA: ${COLOR_YELLOW}SWAP${COLOR_NC} existente"

      sudo swapon --show
      sudo free -th
    fi
  fi
}

# Instalação de Respositório
function localRepo () {
  space && loginfo "[LOCAL][REPO]" "Configurnado ${COLOR_RED}REPOSITÓRIOS${COLOR_NC}."

  REPO=(sle-module-desktop-applications/${SUSE_SP}/x86_64
    sle-module-development-tools/${SUSE_SP}/x86_64
    PackageHub/${SUSE_SP}/x86_64
    sle-module-python3/${SUSE_SP}/x86_64
    sle-module-legacy/${SUSE_SP}/x86_64
    sle-module-web-scripting/${SUSE_SP}/x86_64
  )
  for REP in "${REPO[@]}"; do loginfo "[REPO]" "${COLOR_BLUE}${REP}${COLOR_NC}." && sudo SUSEConnect -p ${REP}; done
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

  if [[ "${VERSION_PYTHON}" == "310" ]]; then
    loginfo "[DEPE][PYTHON]" "Instalando ${COLOR_RED}PYTHON 310${COLOR_NC}."
    sudo zypper in -y \
      python310 \
      python310-devel \
      python310-pip \
      python310-setuptools
  fi

  if [[ "${VERSION_PYTHON}" == "311" ]]; then
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

  loginfo "[DEPE][MSQL]" "Instalando ${COLOR_RED}MARIADB${COLOR_NC}."
  sudo zypper in -y \
        mariadb \
        mariadb-server

  [[ ${SUPERVISOR_ENABLE} == true  ]] && loginfo "[DEPE][SUPERVISOR]" "Instalando ${COLOR_RED}SUPERVISOR${COLOR_NC}." && sudo zypper in -y supervisor
  [[ ${SUPERVISOR_ENABLE} == true  ]] && loginfo "[DEPE][SUPERVISOR]" "Instalando PIP ${COLOR_RED}SUPERVISOR${COLOR_NC}." && sudo pip3 install supervisor

  [[ ${PHP_FPM} == true  ]] && loginfo "[DEPE][PHP_FPM]" "Instalando ${COLOR_RED}PHP_FPM${COLOR_NC}." && sudo zypper in -y php7-fpm
}

function localConfig () {
  localTimeZone
  localSetHostname
  localHosts
  localRcLocal
  localSwap
  localRepo
  localInstallDep
}








###################### INSTALAÇÃO ---------------------------------------------------
function installSupported () {
  space
  loginfo "" "PROCESSO DE INSTALAÇÃO DO ${COLOR_BLUE}MISP Core${COLOR_NC} no ${COLOR_RED}${PRETTY}${COLOR_NC}"
  space

  ###################### CONFIG SUDO E SUDOERS ---------------------------------------------------
  checkSudoers

  ###################### CONFIG ADMIN ---------------------------------------------------
  adminConfig

  ###################### CONFIG LOCAL ---------------------------------------------------
  localConfig
  
  unset $(sudo egrep -v "^\s*(;|$|\[|#)" /admin/.env | cut -f1 -d'=')
}


colors

installSupported
