# INSTALAÇÃO DO MISP - SUSE

## PASSO 1: Configuração INICIAIS.

### 1.1: Instalando e configurando o sudo.
```
# Logue no servidor e escale privilégio para root.
su -

# Instale o pacote SUDO
zypoer in -y sudo

# Adiciona o usuário padrão ao grupo de superusuário, caso já não esteja.
[[ $(groups cerberus | grep wheen) ]] && usermod -aG wheen cerberus

[[ ! -z ${USER_DEFAULT} ]] && [[ ! -f /etc/sudoers.d/${USER_DEFAULT} ]] && echo "${USER_DEFAULT} ALL=(ALL:ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/${USER_DEFAULT}
[[ ${SUDOERS_LOGFILE} == true ]] && sudo sed -i '/Defaults\ log_output/i Defaults\ logfile=\/var\/log/\sudo.log' /etc/sudoers
[[ ${SUDOERS_TIMEOUT} == true ]] && sudo sed -i "/Defaults\ log_output/i Defaults\ timestamp_timeout=${SUDOERS_TIMEOUT_TIME}" /etc/sudoers
```

### 1.1: Configuração do arquivo **SWAP**.

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
