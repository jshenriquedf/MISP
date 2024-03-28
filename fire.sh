#!/bin/bash

# Este script é chamado por /etc/network/interfaces
# v2015012 by Henrique

#PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# For debugging use iptables -v.
IPTABLES="/sbin/iptables"
IP6TABLES="/sbin/ip6tables"

#### SSH PORT
SSH_PORT="20000"

ETH1="eth0"

#### Liberação SSH IP LOCAL
WHITE_IPV4_LOCAL_SSH="192.168.100.0/24"
WHITE_IPV6_LOCAL_SSH="192.168.100.0/24"

#### Liberação HTTP e HTTPS IP LOCAL
WHITE_IPV4_LOCAL_WEB="192.168.100.0/24"
WHITE_IPV6_LOCAL_WEB="192.168.100.0/24"

#### Liberação HTTP e HTTPS IP LOCAL
WHITE_IPV4_PARCEIROS_WEB="192.168.100.0/24"
WHITE_IPV6_PARCEIROS_WEB="192.168.100.0/24"


##########################
### Limpeza das Regras ###
##########################

##--------------------
# Dropando todos os acessos
$IPTABLES -P INPUT DROP
$IPTABLES -P FORWARD DROP
$IPTABLES -P OUTPUT DROP

# Removendo todas as regras
$IPTABLES -F
$IPTABLES -t filter -F
$IPTABLES -t nat -F
$IPTABLES -t mangle -F

# Deletando CHAINS
$IPTABLES -X
$IPTABLES -t filter -X
$IPTABLES -t nat -X
$IPTABLES -t mangle -X
##--------------------


#### Allow Self
$IPTABLES -A INPUT -i lo -j ACCEPT

#### Allow State NEW and Flags FIN,SYN,RST,ACK SYN in tcp
$IPTABLES -A INPUT -p tcp -m tcp ! --tcp-flags FIN,SYN,RST,ACK SYN -m state --state NEW -j DROP

$IPTABLES -A INPUT -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP
$IPTABLES -A INPUT -p tcp -m tcp --tcp-flags FIN,SYN FIN,SYN -j DROP
$IPTABLES -A INPUT -p tcp -m tcp --tcp-flags SYN,RST SYN,RST -j DROP
$IPTABLES -A INPUT -p tcp -m tcp --tcp-flags FIN,RST FIN,RST -j DROP
$IPTABLES -A INPUT -p tcp -m tcp --tcp-flags FIN,ACK FIN -j DROP
$IPTABLES -A INPUT -p tcp -m tcp --tcp-flags ACK,URG URG -j DROP
$IPTABLES -A INPUT -m state --state INVALID -j DROP

$IPTABLES -A INPUT -p tcp -m state --state ESTABLISHED -j ACCEPT
$IPTABLES -A INPUT -p udp -m state --state ESTABLISHED -j ACCEPT

$IPTABLES -A INPUT -m state --state NEW -j IN-NEW

# Gravando em Log um ip e em seguida bloqueando.
$IPTABLES -A INPUT -j LOG --log-prefix "IPT_INPUT: " --log-level 6
$IPTABLES -A INPUT -j DROP

# Gravando em Log um ip e em seguida bloqueando.
$IPTABLES -A FORWARD -j LOG --log-prefix "IPT_FORWARD: " --log-level 6
$IPTABLES -A FORWARD -j DROP

$IPTABLES -A OUTPUT -o lo -j ACCEPT
$IPTABLES -A OUTPUT -p tcp -m state --state NEW,ESTABLISHED -j ACCEPT
$IPTABLES -A OUTPUT -p udp -m state --state NEW,ESTABLISHED -j ACCEPT
$IPTABLES -A OUTPUT -p icmp -m state --state NEW,ESTABLISHED -j ACCEPT
$IPTABLES -A OUTPUT -j LOG --log-prefix "IPT_OUTPUT: " --log-level 6
$IPTABLES -A OUTPUT -j DROP



########################
### Segurança básica ###
########################

# ICMP.
$IPTABLES -A INPUT -d 224.0.0.0/32 -j REJECT --reject-with icmp-port-unreachable
$IPTABLES -A INPUT -p icmp -m state --state NEW,ESTABLISHED -m icmp --icmp-type 8 -m limit --limit 10/s -j ACCEPT

# SSH com log
iptables -t nat -A PREROUTING -p tcp --dport $SSH_PORT -i $ETH1 -j LOG --log-prefix "BRB-IN-SSH: "

#### Liberando acesso SSH LOCAL
for ip in $WHITE_IPV4_LOCAL_SSH; do
    iptables -A IN-NEW -s $ip -p tcp -m tcp --dport $SSH_PORT -i $ETH1 --tcp-flags FIN,SYN,RST,ACK SYN -j ACCEPT
done
iptables -A FORWARD -p tcp --dport $SSH_PORT -j DROP





#### Liberando acesso WEB LOCAL
for ip in $WHITE_IPV4_LOCAL_WEB; do
    $IPTABLES -A IN-NEW -s $ip -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -m multiport --dports 80,443 -j ACCEPT
done

#### Liberando acesso WEB PARCEIROS
for ip in $WHITE_IPV4_PARCEIROS_WEB; do
    $IPTABLES -A IN-NEW -s $ip -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -m multiport --dports 80,443 -j ACCEPT
done

# IPs let's encrypt (opcional)
$IPTABLES -A IN-NEW -s 66.133.109.36/32 -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN --dport 80 -j ACCEPT

# IPs ssllabs (opcional)
$IPTABLES -A IN-NEW -s 64.41.200.0/24 -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN --dport 443 -j ACCEPT


iptables -A FORWARD -p tcp -m multiport --dports 80,443 -j DROP

## Drop everything else!
##--------------------
$IPTABLES -A INPUT -j DROP
$IPTABLES -A FORWARD -j DROP
$IPTABLES -A OUTPUT -j ACCEPT
##--------------------



##############################
### TTL = 62 para Internet ###
##############################

TEST=$(iptables -t mangle -L -n | grep "TTL set to 62")
[ ! "$TEST" ] && iptables -t mangle -A FORWARD -o eth1 -j TTL --ttl-set 62




# Completely disable IPv6.
#------------------------------------------------------------------------------

# Block all IPv6 traffic
# If the ip6tables command is available, try to block all IPv6 traffic.
if test -x $IP6TABLES; then
    # Set the default policies
    # drop everything
    $IP6TABLES -P INPUT DROP 2>/dev/null
    $IP6TABLES -P FORWARD DROP 2>/dev/null
    $IP6TABLES -P OUTPUT DROP 2>/dev/null

    # The mangle table can pass everything
    $IP6TABLES -t mangle -P PREROUTING ACCEPT 2>/dev/null
    $IP6TABLES -t mangle -P INPUT ACCEPT 2>/dev/null
    $IP6TABLES -t mangle -P FORWARD ACCEPT 2>/dev/null
    $IP6TABLES -t mangle -P OUTPUT ACCEPT 2>/dev/null
    $IP6TABLES -t mangle -P POSTROUTING ACCEPT 2>/dev/null

    # Delete all rules.
    $IP6TABLES -F 2>/dev/null
    $IP6TABLES -t mangle -F 2>/dev/null

    # Delete all chains.
    $IP6TABLES -X 2>/dev/null
    $IP6TABLES -t mangle -X 2>/dev/null

    # Zero all packets and counters.
    $IP6TABLES -Z 2>/dev/null
    $IP6TABLES -t mangle -Z 2>/dev/null
fi




# Completely disable IPv6.
#------------------------------------------------------------------------------

# Block all IPv6 traffic
# If the ip6tables command is available, try to block all IPv6 traffic.
if test -x $IP6TABLES; then
# Set the default policies
# drop everything
$IP6TABLES -P INPUT DROP 2>/dev/null
$IP6TABLES -P FORWARD DROP 2>/dev/null
$IP6TABLES -P OUTPUT DROP 2>/dev/null

# The mangle table can pass everything
$IP6TABLES -t mangle -P PREROUTING ACCEPT 2>/dev/null
$IP6TABLES -t mangle -P INPUT ACCEPT 2>/dev/null
$IP6TABLES -t mangle -P FORWARD ACCEPT 2>/dev/null
$IP6TABLES -t mangle -P OUTPUT ACCEPT 2>/dev/null
$IP6TABLES -t mangle -P POSTROUTING ACCEPT 2>/dev/null

# Delete all rules.
$IP6TABLES -F 2>/dev/null
$IP6TABLES -t mangle -F 2>/dev/null

# Delete all chains.
$IP6TABLES -X 2>/dev/null
$IP6TABLES -t mangle -X 2>/dev/null

# Zero all packets and counters.
$IP6TABLES -Z 2>/dev/null
$IP6TABLES -t mangle -Z 2>/dev/null
fi




##########################
### Limpeza das Regras ###
##########################

## Cleanup Rules First!
##--------------------
$IP6TABLES -P INPUT ACCEPT
$IP6TABLES -P FORWARD ACCEPT
$IP6TABLES -P OUTPUT ACCEPT
$IP6TABLES -F
$IP6TABLES -X
$IP6TABLES -t filter -F
$IP6TABLES -t filter -X
$IP6TABLES -t nat -F
$IP6TABLES -t nat -X
$IP6TABLES -t mangle -F
$IP6TABLES -t mangle -X
##--------------------

## Policies
##--------------------
$IP6TABLES -P INPUT DROP
$IP6TABLES -P FORWARD DROP
$IP6TABLES -P OUTPUT ACCEPT
#$IP6TABLES -P OUTPUT DROP
##--------------------


$IP6TABLES -A INPUT -i lo -j ACCEPT

$IP6TABLES -A INPUT -m rt --rt-type 0 -j DROP
$IP6TABLES -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
$IP6TABLES -A INPUT -m conntrack --ctstate INVALID -j DROP
$IP6TABLES -A INPUT -p ipv6-icmp -m icmp6 --icmpv6-type 1 -j ACCEPT
$IP6TABLES -A INPUT -p ipv6-icmp -m icmp6 --icmpv6-type 2 -j ACCEPT
$IP6TABLES -A INPUT -p ipv6-icmp -m icmp6 --icmpv6-type 3 -j ACCEPT
$IP6TABLES -A INPUT -p ipv6-icmp -m icmp6 --icmpv6-type 4 -j ACCEPT
$IP6TABLES -A INPUT -p ipv6-icmp -m icmp6 --icmpv6-type 128 -j ACCEPT
$IP6TABLES -A INPUT -p ipv6-icmp -m icmp6 --icmpv6-type 129 -j ACCEPT
$IP6TABLES -A INPUT -p ipv6-icmp -m icmp6 --icmpv6-type 133 -j ACCEPT
$IP6TABLES -A INPUT -p ipv6-icmp -m icmp6 --icmpv6-type 134 -j ACCEPT
$IP6TABLES -A INPUT -p ipv6-icmp -m icmp6 --icmpv6-type 135 -j ACCEPT
$IP6TABLES -A INPUT -p ipv6-icmp -m icmp6 --icmpv6-type 136 -j ACCEPT
$IP6TABLES -A INPUT -p ipv6-icmp -m icmp6 --icmpv6-type 141 -j ACCEPT
$IP6TABLES -A INPUT -p ipv6-icmp -m icmp6 --icmpv6-type 142 -j ACCEPT
$IP6TABLES -A INPUT -p ipv6-icmp -m icmp6 --icmpv6-type 148 -j ACCEPT
$IP6TABLES -A INPUT -p ipv6-icmp -m icmp6 --icmpv6-type 149 -j ACCEPT


#### Liberando acesso SSH LOCAL
for ip in $WHITE_IPV6_LOCAL_SSH; do
    $IP6TABLES -A IN-NEW -s $ip -p tcp -m tcp --dport $SSH_PORT --tcp-flags FIN,SYN,RST,ACK SYN -j ACCEPT
done

#### Liberando acesso WEB LOCAL
for ip in $WHITE_IPV6_LOCAL_WEB; do
    $IP6TABLES -A IN-NEW -s $ip -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -m multiport --dports 80,443 -j ACCEPT
done

#### Liberando acesso WEB PARCEIROS
for ip in $WHITE_IPV6_PARCEIROS_WEB; do
    $IP6TABLES -A IN-NEW -s $ip -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -m multiport --dports 80,443 -j ACCEPT
done






# liberar acesso SSH para a organização
#$IP6TABLES -A INPUT -s <SEU-IPv6-OU-REDE> -p tcp -m tcp --dport 22 -j ACCEPT

# liberar acesso ao MISP para a organização
#$IP6TABLES -A INPUT -s <SEU-IPv6-OU-REDE> -p tcp -m tcp -m multiport --dports 80,443 -j ACCEPT

# liberar acesso ao MISP para parceiros
#$IP6TABLES -A INPUT -s <IPv6-MISP-PARCEIRO> -p tcp -m tcp -m multiport --dports 80,443 -j ACCEPT

# IPs let's encrypt (opcional)
$IP6TABLES -A INPUT -s 2600:3000::/29 -p tcp -m tcp --dport 80 --tcp-flags FIN,SYN,RST,ACK SYN -j ACCEPT
$IP6TABLES -A INPUT -s 2600:1f00::/24 -p tcp -m tcp --dport 80 --tcp-flags FIN,SYN,RST,ACK SYN -j ACCEPT
$IP6TABLES -A INPUT -s 2a05:d000::/25 -p tcp -m tcp --dport 80 --tcp-flags FIN,SYN,RST,ACK SYN -j ACCEPT

# IPs ssllabs (opcional)
$IP6TABLES -A INPUT -s 2600:C02:1020:4202::/64 -p tcp -m tcp --dport 443 -j ACCEPT

$IP6TABLES -A INPUT -j LOG --log-prefix "IPT_INPUT6: " --log-level 6
$IP6TABLES -A INPUT -j REJECT --reject-with icmp6-port-unreachable
$IP6TABLES -A FORWARD -j REJECT --reject-with icmp6-port-unreachable
$IP6TABLES -A OUTPUT -j ACCEPT

## Drop everything else!
##--------------------
$IP6TABLES -A INPUT -j DROP
$IP6TABLES -A FORWARD -j DROP
$IP6TABLES -A OUTPUT -j ACCEPT
##--------------------




exit 0