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
read -p 'Informe a senha adiministrativa do banco de dados Odoo (ex: Pysql-123456): ' DB_ADMINPASS

# Global Variables
ODOO_USER=$ODOO_USER
ODOO_VERSION=$ODOO_VERSION
ODOO_PORT=$ODOO_PORT
ODOO_DATABASE=$ODOO_DATABASE
# Set the superadmin password to postgresql
DB_ADMINPASS=$DB_ADMINPASS

# Fixed variables
ODOO_DIR="/opt/$ODOO_USER"
ODOO_DIR_ADDONS="$ODOO_DIR/${ODOO_USER}-server/addons"
ODOO_DIR_CUSTOM="$ODOO_DIR/custom-addons"
ODOO_DIR_TRUSTCODE="$ODOO_DIR_CUSTOM/odoo-brasil"
ODOO_DIR_OCA="$ODOO_DIR_CUSTOM/oca"

ODOO_DIR_SERVER="$ODOO_DIR/${ODOO_USER}-server"

ODOO_CONFIG_FILE="/etc/${ODOO_USER}-server.conf"
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
        echo "Se alguma informação acima não estiver correta, reinicie o script e informe os valores corretos."
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
Arquivo de Configuração: $ODOO_CONFIG_FILE
Distribuição Linux: $LINUX_DISTRIBUTION
Endereço IP: $ODOO_IP
"

while true; do
        echo "Se alguma informação acima não estiver correta, ajuste os dados no próprio script."
        read -p 'As informações estão corretas? Deseja continuar? (s/n)' sn
        case $sn in
        [Ss]*) break ;;
        [Nn]*) exit ;;
        *) echo "Por favor, responda Sim ou Não." ;;
        esac
done


#--------------------------------------------------
# Backup Banco de Dados Odoo
#--------------------------------------------------
echo -e "\n*** START BACKUP DATABASE ***"

BACKUP_DIR="/var/backups/${ODOO_USER}"

# create a backup directory
mkdir -p ${BACKUP_DIR}

# create a backup
curl -X POST \
    -F "master_pwd=${DB_ADMINPASS}" \
    -F "name=${ODOO_DATABASE}" \
    -F "backup_format=zip" \
    -o ${BACKUP_DIR}/${ODOO_DATABASE}.$(date +%F).zip \
    http://${ODOO_IP}:8069/web/database/backup


# Apagar backup mais antigos que 7 dias
find ${BACKUP_DIR} -type f -mtime +7 -name "${ODOO_DATABASE}.*.zip" -delete

echo -e "\n*** END BACKUP DATABASE ***"

#--------------------------------------------------
# Atualizar Sistema Operacional
#--------------------------------------------------
if [ "$LINUX_DISTRIBUTION" = "Ubuntu" ]; then
        sudo apt update && sudo apt upgrade -y
else
        echo "A distribuição não é Ubuntu"
fi

echo -e "LIMPANDO O CACHE DO APT, AGUARDE... \n"
sudo apt autoclean
sudo apt clean

#--------------------------------------------------
# Update "git pull" from clonnig folders
#--------------------------------------------------

echo -e "\n*** UPDATE ODOO FROM GITHUB ***"

if [ -e "$ODOO_DIR_SERVER" ]; then
        cd $ODOO_DIR_SERVER
        sudo git pull
else
    echo "A pasta ${ODOO_DIR_SERVER} não existe"
        while true; do
                read -p 'Continuar? (s/n)' sn
                case $sn in
                [Ss]*) break ;;
                [Nn]*) exit ;;
                *) echo "Por favor, responda Sim ou Não." ;;
                esac
        done
fi

echo -e "\n*** UPDATE TRUSTCODE MODULES FROM GITHUB ***"

if [ -e "$ODOO_DIR_TRUSTCODE" ]; then
        cd $ODOO_DIR_TRUSTCODE
        sudo git pull
else
    echo "A pasta ${ODOO_DIR_TRUSTCODE} não existe"
        while true; do
                read -p 'Continuar? (s/n)' sn
                case $sn in
                [Ss]*) break ;;
                [Nn]*) exit ;;
                *) echo "Por favor, responda Sim ou Não." ;;
                esac
        done
fi

echo -e "\n*** UPDATE OCA MODULES FROM GITHUB ***"

if [ -e "$ODOO_DIR_OCA/account-financial-tools" ]; then
        cd $ODOO_DIR_OCA/account-financial-tools
        sudo git pull
else
    echo "A pasta ${ODOO_DIR_OCA}/account-financial-tools não existe"
        while true; do
                read -p 'Continuar? (s/n)' sn
                case $sn in
                [Ss]*) break ;;
                [Nn]*) exit ;;
                *) echo "Por favor, responda Sim ou Não." ;;
                esac
        done
fi

if [ -e "$ODOO_DIR_OCA/server-ux" ]; then
        cd $ODOO_DIR_OCA/server-ux
        sudo git pull
else
    echo "A pasta ${ODOO_DIR_OCA}/server-ux não existe"
        while true; do
                read -p 'Continuar? (s/n)' sn
                case $sn in
                [Ss]*) break ;;
                [Nn]*) exit ;;
                *) echo "Por favor, responda Sim ou Não." ;;
                esac
        done
fi

if [ -e "$ODOO_DIR_OCA/mis-builder" ]; then
        cd $ODOO_DIR_OCA/mis-builder
        sudo git pull
else
    echo "A pasta ${ODOO_DIR_OCA}/mis-builder não existe"
        while true; do
                read -p 'Continuar? (s/n)' sn
                case $sn in
                [Ss]*) break ;;
                [Nn]*) exit ;;
                *) echo "Por favor, responda Sim ou Não." ;;
                esac
        done
fi

if [ -e "$ODOO_DIR_OCA/reporting-engine" ]; then
        cd $ODOO_DIR_OCA/reporting-engine
        sudo git pull
else
    echo "A pasta ${ODOO_DIR_OCA}/reporting-engine não existe"
        while true; do
                read -p 'Continuar? (s/n)' sn
                case $sn in
                [Ss]*) break ;;
                [Nn]*) exit ;;
                *) echo "Por favor, responda Sim ou Não." ;;
                esac
        done
fi

if [ -e "$ODOO_DIR_OCA/contract" ]; then
        cd $ODOO_DIR_OCA/contract
        sudo git pull
else
    echo "A pasta ${ODOO_DIR_OCA}/contract não existe"
        while true; do
                read -p 'Continuar? (s/n)' sn
                case $sn in
                [Ss]*) break ;;
                [Nn]*) exit ;;
                *) echo "Por favor, responda Sim ou Não." ;;
                esac
        done
fi

echo -e "\n*** Setting user to entire Odoo directory***"
sudo chown -R $ODOO_USER:$ODOO_USER $ODOO_DIR/*

#--------------------------------------------------
# Update dadabase
#--------------------------------------------------

echo -e "\n*** Stop Odoo service***"
sudo systemctl stop $ODOO_SERVICE

echo -e "\n*** Update database whith Odoo user ***"
sudo -u $ODOO_USER bash -c "$ODOO_DIR_SERVER/odoo-bin --config ${ODOO_CONFIG_FILE} --update=all --database=${ODOO_DATABASE} --stop-after-init"

echo -e "\n*** Start Odoo service***"
sudo systemctl start $ODOO_SERVICE

echo -e "*** STATUS ODOO ***"
sudo systemctl status $ODOO_SERVICE

echo -e "*** COMMANDS TO CHECK ODOO LOGS:  ***"
echo -e "*** 'sudo journalctl -u $ODOO_USER' OR 'sudo tail -f /var/log/${ODOO_USER}/${ODOO_CONFIG_FILE}.log' ***"

echo -e "\n*** OPEN ODOO INSTANCE ON YOUR BROWSER ***\n"
echo -e "*** ************************************************* ***"
echo -e "*** IP ADDRESS: $ODOO_IP - PORT: $ODOO_PORT ***"
echo -e "*** ************************************************* ***"
