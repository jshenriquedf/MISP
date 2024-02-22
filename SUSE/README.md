## INSTALAÇÃO DO MISP - SUSE

# PASSO 1: Configuração do arquivo **SWAP**.

- **1.1**: Criando arquivo e habilitando o seu uso.
```
sudo touch /swapfile
sudo chattr +C /swapfile
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
