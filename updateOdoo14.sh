#!/bin/bash
##############################################################################################################
# Script for update Odoo on Ubuntu 20.04 64Bits
# Author: Marcelo Costa from SOULinux (www.soulinux.com)
#-------------------------------------------------------------------------------------------------------------
# # Place this content in it and then make the file executable:
# sudo chmod +x updateOdoo14.sh
# Execute the script to install Odoo: ./updateOdoo14.sh
#
##############################################################################################################

echo -e "\n*** INFORME OS PARÂMETROS BÁSICOS DO ODOO ***\n"

read -p 'Informe o nome do seu usuário Odoo (ex: odoo): ' ODOO_USER
read -p 'Informe a versão do seu Odoo (ex: 14.0): ' ODOO_VERSION
read -p 'Informe a porta do seu Odoo (ex: 8069): ' ODOO_PORT
read -p 'Informe o nome do  banco de dados Odoo (ex: empresa_xyz): ' ODOO_DATABASE

# Global Variables
ODOO_USER=$ODOO_USER
ODOO_VERSION=$ODOO_VERSION
ODOO_PORT=$ODOO_PORT
ODOO_DATABASE=$ODOO_DATABASE

# Fixed variables
ODOO_DIR="/opt/$ODOO_USER"
ODOO_DIR_ADDONS="$ODOO_DIR/${ODOO_USER}-server/addons"
ODOO_DIR_CUSTOM="$ODOO_DIR/custom-addons"
ODOO_DIR_TRUSTCODE="$ODOO_DIR_CUSTOM/odoo-brasil"
ODOO_DIR_OCA="$ODOO_DIR_CUSTOM/oca"

ODOO_DIR_SERVER="$ODOO_DIR/${ODOO_USER}-server"

ODOO_CONFIG_FILE="${ODOO_USER}-server"
ODOO_SERVICE="${ODOO_USER}.service"

ODOO_IP="$(hostname -I)"
LINUX_DISTRIBUTION=$(awk '{ print $1 }' /etc/issue)

# Generic Conf
TIMESTAMP=$(/bin/date +%d-%m-%Y_%T)

echo "
INFORMAÇÕES BÁSICAS DO SEU ODOO:
Usuário Odoo: $ODOO_USER
Versão Odoo: $ODOO_VERSION
Porta Odoo: $ODOO_PORT
Banco de dados Odoo: $ODOO_DATABASE
"
while true; do
        echo "\nSe alguma informação acima não estiver correta, reinicie o script e informe os valores corretos.\n"
        read -p 'As informações estão corretas? Deseja continuar? (s/n)' sn
        case $sn in
        [Ss]*) break ;;
        [Nn]*) exit ;;
        *) echo "Por favor, responda Sim ou Não." ;;
        esac
done

echo "
INFORMAÇÕES DE PASTAS DO ODOO:
Pasta padrão de instalação do Odoo: $ODOO_DIR
Pasta padrão dos módulos TrustCODE: $ODOO_DIR_TRUSTCODE
Pasta padrão dos módulos OCA: $ODOO_DIR_OCA
Pasta padrão de instalação do servidor Odoo: $ODOO_DIR_SERVER
Distribuição Linux: $LINUX_DISTRIBUTION
Endereço IP: $ODOO_IP
"

while true; do
        echo "\nSe alguma informação acima não estiver correta, ajuste os dados no próprio script.\n"
        read -p 'As informações estão corretas? Deseja continuar? (s/n)' sn
        case $sn in
        [Ss]*) break ;;
        [Nn]*) exit ;;
        *) echo "Por favor, responda Sim ou Não." ;;
        esac
done

#--------------------------------------------------
# Atualizar Sistema Operacional
#--------------------------------------------------
if [ "$LINUX_DISTRIBUTION" = "Ubuntu" ]; then
        sudo apt update && sudo apt upgrade -y
else
        echo "continuar"
fi

if [ "$?" != "0" ]; then
        EXIT_STATUS=1
        echo "${TIMESTAMP} $0: Erro ao atualizar o sistema operacional"
        exit
else
        echo "continuar"
fi

echo -e "LIMPANDO O CACHE DO APT, AGUARDE... \n"
sudo apt autoclean
sudo apt clean

#--------------------------------------------------
# Update "git pull" from clonnig folders
#--------------------------------------------------

echo -e "\n*** UPDATE ODOO FROM GITHUB ***"
cd $ODOO_DIR_SERVER
git pull

if [ "$?" != "0" ]; then
        EXIT_STATUS=1
        echo "${TIMESTAMP} $0: \nErro ao atualizar o Odoo! Saindo do script."
        exit
fi

echo -e "\n*** UPDATE TRUSTCODE MODULES FROM GITHUB ***"
cd $ODOO_DIR_TRUSTCODE
git pull

if [ "$?" != "0" ]; then
        EXIT_STATUS=1
        echo "${TIMESTAMP} $0: \nErro ao atualizar o fork da TrustCode! Saindo do script."
        exit
fi

echo -e "\n*** UPDATE OCA MODULES FROM GITHUB ***"
cd $ODOO_DIR_OCA/account-financial-tools
sudo git pull

cd $ODOO_DIR_OCA/server-ux
sudo git pull

cd $ODOO_DIR_OCA/mis-builder
sudo git pull

cd $ODOO_DIR_OCA/reporting-engine
sudo git pull

cd $ODOO_DIR_OCA/contracts
sudo git pull

if [ "$?" != "0" ]; then
        EXIT_STATUS=1
        echo "${TIMESTAMP} $0: \nErro ao atualizar os módulos OCA! Saindo do script."
        exit
fi

#--------------------------------------------------
# Update dadabase
#--------------------------------------------------

echo -e "\n*** Stop Odoo service***"
sudo systemctl stop $ODOO_SERVICE

echo -e "\n*** Change to user Odoo ***"
sudo su - $ODOO_USER -s /bin/bash

echo -e "\n*** Update database ***"
sudo $ODOO_DIR_SERVER/odoo-bin --config /etc/${ODOO_CONFIG_FILE} --update=all --database=${ODOO_DATABASE} --stop-after-init

echo -e "\n*** Exit Odoo user ***"
sudo exit

echo -e "\n*** Start Odoo service***"
sudo systemctl start $ODOO_SERVICE

echo -e "*** STATUS ODOO ***"
sudo systemctl status $ODOO_SERVICE

echo -e "*** COMMANDS TO CHECK ODOO LOGS:  ***"
echo -e "*** 'sudo journalctl -u $ODOO_USER' OR 'sudo tail -f /var/log/${ODOO_USER}/${ODOO_CONFIG_FILE}.log' ***"

echo -e "*** OPEN ODOO INSTANCE ON YOUR BROWSER ***"
echo -e "*** ************************************************* ***"
echo -e "*** IP ADDRESS: $ODOO_IP - PORT: $ODOO_PORT ***"
echo -e "*** ************************************************* ***"
