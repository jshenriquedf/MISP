# INSTALAÇÃO DO MISP - SUSE

## PASSO 1: Configuração INICIAIS.

#### 1.1: Configuração do arquivo **SWAP**.

> Criando arquivo e habilitando o seu uso.
```
# Criando o arquivo que será utilizado como SWAP.
sudo touch /swapfile

# Alterando a permissão do arquivo.
sudo chattr +C /swapfile

# Definindo o tamanho do aquivo de SWAP.
sudo fallocate -l 2G /swapfile
sudo chmod 0600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo /swapfile none swap defaults 0 0" | sudo tee -a /etc/fstab
```

> **Obs.**: Para verificar o espaço ataual apos configuração da **SWAP**.
```
sudo swapon --show
sudo free -th
```
