#!/bin/bash
# ##########################################################################
#    ____           _             _ ____             _               ____  
#   / ___|___ _ __ | |_ _ __ __ _| | __ )  __ _  ___| | ___   _ _ __|___ \ 
#  | |   / _ \ '_ \| __| '__/ _` | |  _ \ / _` |/ __| |/ / | | | '_ \ __) |
#  | |__|  __/ | | | |_| | | (_| | | |_) | (_| | (__|   <| |_| | |_) / __/ 
#   \____\___|_| |_|\__|_|  \__,_|_|____/ \__,_|\___|_|\_\\__,_| .__/_____|
#                                                              |_|         
# -------------------------------------------
# Autheur : Yohan CAMBOURIEU
# Création initiale : 07/01/2021
# Script : Système de sauvegarde pour machines Linux (Debian/RHEL)
# Version : 2.0
# Change Log :
#	2.0 - 07/01/2021 : Création du script
# -------------------------------------------
#
# ##########################################################################

# Fonctions d'affichage

function AfficherBanner(){
	echo ""
	echo -e "\033[36m _.........._\033[0m"
	echo -e "\033[36m| | Central| |\033[0m"
	echo -e "\033[36m| | Backup | |\033[0m"
	echo -e "\033[36m| |   2    | |\033[0m  Machine : $1"
	echo -e "\033[36m| |________| |\033[0m  IP : $2"
	echo -e "\033[36m|   ______   |\033[0m  Date : $3"
	echo -e "\033[36m|  |    | |  |\033[0m"
	echo -e "\033[36m|__|____|_|__|\033[0m"
	echo ""
}

function AfficherTitre(){
	echo -e "\033[1m## $@ ##\033[0m"
}

function AfficherOk(){
	echo -e "	\033[32m►\033[0m $@"
}

function AfficherWarn(){
	echo -e "	\033[33m►\033[0m $@"
}

function AfficherCrit(){
	echo -e "	\033[31m►\033[0m $@"
}

function AfficherWaiting(){
	echo -e "		• $@ : Waiting to start..."
}

function AfficherInProgress(){
	echo -e "		\033[33m• $@ : In Progress...\033[0m"
}

function AfficherInProgressOverwrite(){
	echo -e "\e[1A\e[K		\033[33m• $@ : In Progress...\033[0m"
}

function AfficherDoneOverwrite(){
	echo -e "\e[1A\e[K		\033[32m• $@ : Done.\033[0m"
}

function AfficherErrorOverwrite(){
	echo -e "\e[1A\e[K		\033[31m• $@ : Erreur, des droits root sont peut être requis\033[0m"
}

# Fonctions d'action

function GatherInfos(){
	NAME=$HOSTNAME
	IP=$(ip a | grep "inet " | grep -v "127.0.0.1" | head -n 1 | cut -d "/" -f 1 | rev | cut -d " " -f 1 | rev)
	TIME=$1
}

function InitVariables(){
	t1=$(date +%s)
	DATE_SAVE=$(date +%Y%m%d%H%M%S)
	DATE_MONTH=$(date +%Y_%B)
	DATETIME=$(date "+%Y-%m-%d-%H:%M:%S")
	WORKDIR=$(dirname $0)
	. $WORKDIR/sauvegarde.conf
	REP_SAVE="${NAMEHOST}_${DATE_SAVE}"
	REP_MONTH="$DATE_MONTH"
	SSHCMD="/usr/bin/ssh"
	DUCMD="/usr/bin/du"
	RSYNCCMD="/usr/bin/rsync"
	NBERR="0"
}

function AddErr(){
	NBERR=$(($NBERR+1))
	AfficherCrit "Incrémentaion du compteur d'erreur, nombre actuel d'erreurs = $NBERR"
}

function AppendtoLog(){
	if [ $REMOTE_MODE -ne 0 ];then
		echo "$(date "+%Y-%m-%d-%H:%M:%S") - $NAMEHOST($REMOTE_HOST:$REMOTE_SSH_PORT) - $@" >> $DEST_LOG/$DATE_SAVE.txt
	else
		echo "$(date "+%Y-%m-%d-%H:%M:%S") - $NAMEHOST($IP) - $@" >> $DEST_LOG/$DATE_SAVE.txt
	fi
}

function ControlErr(){
	if [ $1 -ne 0 ];then
		AfficherCrit "Erreur détectée - Arret du programme"
		exit 1
	fi
}

function CreateDir(){
	CODEER="0"
	if [  ! -d "$1" ];then
		mkdir -p $1
		CODEER=$(($CODEER+$?))
		ControlErr $CODEER
		AfficherOk "Répertoire $1 créé"
	else
		AfficherWarn "Le répertoire $1 existe déjà"
	fi
}

function DetectOsFamilly(){

	if  [ $REMOTE_MODE -ne 0 ];then
		OS_FAMILLY=$($SSHCMD -q -p $REMOTE_SSH_PORT ${REMOTE_LOGIN}@${REMOTE_HOST} "cat /etc/os-release | grep -E ^ID= | cut -d \"=\" -f 2 | sed -e 's/\"//g'")
	else
		OS_FAMILLY=$(cat /etc/os-release | grep -E ^ID= | cut -d "=" -f 2 | sed -e 's/"//g')
	fi

	case $OS_FAMILLY in
		debian | raspbian) 
			PKT_TYPE="DPKG"
			TEXT="OS de type Debian, paquets de type $PKT_TYPE"
			AfficherOk $TEXT
			AppendtoLog $TEXT
			;;
		fedora | centos) 
			PKT_TYPE="RPM"
			TEXT="OS de type Fedora/CentOS/RHEL, paquets de type $PKT_TYPE"
			AfficherOk $TEXT
			AppendtoLog $TEXT
			;;
		*) 
			TEXT="Impossible de déterminer le type d'OS et le type de paquets utilisés"
			AfficherCrit $TEXT
			AppendtoLog $TEXT
			ControlErr 1;;
	esac
}

function CheckSshAccess(){
	SSH_ACCESS=$($SSHCMD -q -p $REMOTE_SSH_PORT ${REMOTE_LOGIN}@${REMOTE_HOST} "echo ok")
	if [[ $SSH_ACCESS == "ok" ]];then
			TEXT="Connexion SSH fonctionnelle vers $REMOTE_LOGIN@$REMOTE_HOST:$REMOTE_SSH_PORT"
			AfficherOk $TEXT
			AppendtoLog $TEXT
	else
			TEXT="Impossible d'effectuer la connexion vers $REMOTE_LOGIN@$REMOTE_HOST:$REMOTE_SSH_PORT"
			TEXT2="Une connexion fonctionnelle avec clés SSH est requise pour pouvoir lancer la sauvegarde"
			AfficherCrit $TEXT
			AppendtoLog $TEXT
			AfficherCrit $TEXT2
			AppendtoLog $TEXT2
			ControlErr 1
	fi
}

function CheckInstalledPackages(){
	TEXT="Vérification de la liste des paquets requis"
	AfficherOk $TEXT
	AppendtoLog $TEXT
	LIST_PACKAGE=( bc rsync curl tar )
	case $PKT_TYPE in 
		DPKG)
			for PACKAGE in ${LIST_PACKAGE[*]}; do
				if [ $REMOTE_MODE -ne 0 ];then
					SSH_TEST=$($SSHCMD -q -p $REMOTE_SSH_PORT ${REMOTE_LOGIN}@${REMOTE_HOST} "dpkg -l | grep -E ^ii | tr -s ' ' | cut -d ' ' -f 2 | grep -qE ^${PACKAGE} && echo ok")
					if [[ $SSH_TEST != "ok" ]];then
						TEXT="Identification d'un paquet manquant : $PACKAGE"
						TEXT2="Merci d'installer le paquet manquant avant de lancer la sauvegarde : apt -y install $PACKAGE"
						AfficherCrit $TEXT
						AppendtoLog $TEXT
						AfficherCrit $TEXT2
						AppendtoLog $TEXT2
						ControlErr 1
					else
						TEXT="Paquet requis $PACKAGE installé"
						AfficherOk $TEXT
						AppendtoLog $TEXT
					fi
				else
					dpkg -l | grep -E "^ii" | tr -s " " | cut -d " " -f 2 | grep -qE ^${PACKAGE} 
					if [ $? -ne 0 ];then
						TEXT="Identification d'un paquet manquant : $PACKAGE"
						TEXT2="Merci d'installer le paquet manquant avant de lancer la sauvegarde : apt -y install $PACKAGE"
						AfficherCrit $TEXT
						AppendtoLog $TEXT
						AfficherCrit $TEXT2
						AppendtoLog $TEXT2
						ControlErr 1
					else
						TEXT="Paquet requis $PACKAGE installé"
						AfficherOk $TEXT
						AppendtoLog $TEXT
					fi			
				fi
			done
			;;
		RPM)
			for PACKAGE in ${LIST_PACKAGE[*]}; do
				if [ $REMOTE_MODE -ne 0 ];then
					SSH_TEST=$($SSHCMD -q -p $REMOTE_SSH_PORT ${REMOTE_LOGIN}@${REMOTE_HOST} "rpm -qa | grep -qE ^${PACKAGE} && echo ok")
					if [[ $SSH_TEST != "ok" ]];then
						TEXT="Identification d'un paquet manquant : $PACKAGE"
						TEXT2="Merci d'installer le paquet manquant avant de lancer la sauvegarde : dnf -y install $PACKAGE"
						AfficherCrit $TEXT
						AppendtoLog $TEXT
						AfficherCrit $TEXT2
						AppendtoLog $TEXT2
						ControlErr 1
					else
						TEXT="Paquet requis $PACKAGE installé"
						AfficherOk $TEXT
						AppendtoLog $TEXT
					fi
				else
					rpm -qa | grep -qE ^${PACKAGE}
					if [ $? -ne 0 ];then
						TEXT="Identification d'un paquet manquant : $PACKAGE"
						TEXT2="Merci d'installer le paquet manquant avant de lancer la sauvegarde : dnf -y install $PACKAGE"
						AfficherCrit $TEXT
						AppendtoLog $TEXT
						AfficherCrit $TEXT2
						AppendtoLog $TEXT2
						ControlErr 1
					else
						TEXT="Paquet requis $PACKAGE installé"
						AfficherOk $TEXT
						AppendtoLog $TEXT
					fi			
				fi
			done
			;;
		*)
			TEXT="Mauvais type de paquets détecté"
			AfficherCrit $TEXT
			AppendtoLog $TEXT
			ControlErr 1;;
	esac
}

function CheckUser(){
	if [ $REMOTE_MODE -ne 0 ];then
		TEXT="Vérification de l'utilisateur sur l'hote distant"
		AfficherOk $TEXT
		AppendtoLog $TEXT
		CURRENT_USER=$($SSHCMD -q -p $REMOTE_SSH_PORT ${REMOTE_LOGIN}@${REMOTE_HOST} "whoami")
	else
		TEXT="Vérification de l'utilisateur sur l'hote local"
		AfficherOk $TEXT
		AppendtoLog $TEXT
		CURRENT_USER=$(whoami)
	fi
	if [[ $CURRENT_USER != "root" ]];then
		TEXT="L'utilisateur courrant n'est pas root"
		TEXT2="Certains fichiers peuvent ne pas se sauvegarder par manque de droits"
		AfficherCrit $TEXT
		AppendtoLog $TEXT
		AfficherCrit $TEXT2
		AppendtoLog $TEXT2	
	else
		TEXT="L'utilisateur courrant est root"
		AfficherOk $TEXT
		AppendtoLog $TEXT
	fi
	AppendtoHostInfos "Utilisateur courrant : $CURRENT_USER"
}

function BackupListOfPackages(){
	if [[ $ACTIV_PKG == "1" ]];then
		case $PKT_TYPE in 
			DPKG)
				if [ $REMOTE_MODE -ne 0 ];then
					TEXT="Lancement de la sauvegarde de la liste des paquets sur l'hote distant ($PKT_TYPE)"
					AfficherOk $TEXT
					AppendtoLog $TEXT
					TEXT="Liste des paquets $PKT_TYPE"
					AfficherWaiting $TEXT
					AfficherInProgressOverwrite $TEXT
					$SSHCMD -q -p $REMOTE_SSH_PORT ${REMOTE_LOGIN}@${REMOTE_HOST} "dpkg --get-selections | sort" > $DEST_DIR/$REP_MONTH/$REP_SAVE/PKG_List.txt
					ControlErr $?
					AfficherDoneOverwrite $TEXT
				else
					TEXT="Lancement de la sauvegarde de la liste des paquets sur l'hote local ($PKT_TYPE)"
					AfficherOk $TEXT
					AppendtoLog $TEXT
					TEXT="Liste des paquets $PKT_TYPE"
					AfficherWaiting $TEXT
					AfficherInProgressOverwrite $TEXT
					dpkg --get-selections | sort > $DEST_DIR/$REP_MONTH/$REP_SAVE/PKG_List.txt
					ControlErr $?
					AfficherDoneOverwrite $TEXT
				fi
				;;
			RPM)
				if [ $REMOTE_MODE -ne 0 ];then
					TEXT="Lancement de la sauvegarde de la liste des paquets sur l'hote distant ($PKT_TYPE)"
					AfficherOk $TEXT
					AppendtoLog $TEXT
					TEXT="Liste des paquets $PKT_TYPE"
					AfficherWaiting $TEXT
					AfficherInProgressOverwrite $TEXT
					$SSHCMD -q -p $REMOTE_SSH_PORT ${REMOTE_LOGIN}@${REMOTE_HOST} "rpm -qa | sort" > $DEST_DIR/$REP_MONTH/$REP_SAVE/PKG_List.txt
					ControlErr $?
					AfficherDoneOverwrite $TEXT
				else
					TEXT="Lancement de la sauvegarde de la liste des paquets sur l'hote local ($PKT_TYPE)"
					AfficherOk $TEXT
					AppendtoLog $TEXT
					TEXT="Liste des paquets $PKT_TYPE"
					AfficherWaiting $TEXT
					AfficherInProgressOverwrite $TEXT
					rpm -qa | sort > $DEST_DIR/$REP_MONTH/$REP_SAVE/PKG_List.txt
					ControlErr $?
					AfficherDoneOverwrite $TEXT
				fi
				;;
			*)
				TEXT="Mauvais type de paquets détecté"
				AfficherCrit $TEXT
				AppendtoLog $TEXT
				ControlErr 1;;
		esac
		TEXT="OK - Sauvegarde de la liste des paquets ($PKT_TYPE)"
		AppendtoHostInfos $TEXT
		AppendtoLog $TEXT
	else
		TEXT="Sauvegarde de la liste des paquets désactivée ($PKT_TYPE)"
		AfficherWarn $TEXT
		AppendtoLog $TEXT
	fi
}

function BackupCronTasks(){
	if [[ $ACTIV_CRONTAB == "1" ]];then
		if [ $REMOTE_MODE -ne 0 ];then
			TEXT="Lancement de la sauvegarde des taches Cron sur l'hote distant"
			AfficherOk $TEXT
			AppendtoLog $TEXT
			TEXT="Taches Crontab"
			AfficherWaiting $TEXT
			AfficherInProgressOverwrite $TEXT
			$SSHCMD -q -p $REMOTE_SSH_PORT ${REMOTE_LOGIN}@${REMOTE_HOST} "crontab -l" &> $DEST_DIR/$REP_MONTH/$REP_SAVE/CRONTAB.txt
			AfficherDoneOverwrite $TEXT
		else
			TEXT="Lancement de la sauvegarde des taches Cron sur l'hote local"
			AfficherOk $TEXT
			AppendtoLog $TEXT
			TEXT="Taches Crontab"
			AfficherWaiting $TEXT
			AfficherInProgressOverwrite $TEXT
			crontab -l &> $DEST_DIR/$REP_MONTH/$REP_SAVE/CRONTAB.txt
			AfficherDoneOverwrite $TEXT
		fi
		TEXT="OK - Sauvegarde des taches Cron"
		AppendtoHostInfos $TEXT
		AppendtoLog $TEXT
	else
		TEXT="Sauvegarde des taches Cron désactivée"
		AfficherWarn $TEXT
		AppendtoLog $TEXT
	fi
}

function BackupDatabases(){
	if [[ $ACTIV_BDD == "1" ]];then
		TEXT="Lancement de la sauvegarde des BDD"
		AfficherOk $TEXT
		AppendtoLog $TEXT
		AfficherWaiting "superviser"

		AfficherInProgressOverwrite "superviser"

		AfficherDoneOverwrite "superviser"
		AfficherWaiting "nexclouddb"

		AfficherInProgressOverwrite "nexclouddb"

		AfficherDoneOverwrite "nexclouddb"
	else
		TEXT="Sauvegarde des BDD désactivée"
		AfficherWarn $TEXT
		AppendtoLog $TEXT
	fi
}

function BackupDir (){
	if [[ $ACTIV_FICH == "1" ]];then
		if [ $REMOTE_MODE -ne 0 ];then
			TEXT="Lancement de la sauvegarde des répertoires sur l'hote distant"
			AfficherOk $TEXT
			AppendtoLog $TEXT
			for DIR in ${SOURCE_DIR[*]}; do
				CODEER="0"
				AfficherWaiting "${DIR}"
				mkdir -p /$DIR/ $DEST_DIR/$REP_MONTH/$REP_SAVE/$DIR/
				AfficherInProgressOverwrite "/${DIR}"		
				$RSYNCCMD -a -q --no-links --ignore-errors --force --include ".*" --filter "- *.tmp" --filter "- lost+found/" --filter "- .cache/" -e "ssh -p $REMOTE_SSH_PORT" ${REMOTE_LOGIN}@${REMOTE_HOST}:/$DIR/ $DEST_DIR/$REP_MONTH/$REP_SAVE/$DIR/ &> /dev/null
				CODEER=$(($CODEER+$?))
				TAILLEDIR=$($DUCMD -hsc $DEST_DIR/$REP_MONTH/$REP_SAVE/$DIR/ | tail -n 1 | tr -s "	" | cut -d "	" -f 1 )
				TAILLEDIR="${TAILLEDIR}o"
				if [ $CODEER -ne 0 ]; then
					AfficherErrorOverwrite "/${DIR} (${TAILLEDIR})"
					TEXT="ERR- Sauvegarde du répertoire /${DIR}"
					AppendtoHostInfos $TEXT
					AppendtoLog $TEXT
				else
					AfficherDoneOverwrite "/${DIR} (${TAILLEDIR})"
					TEXT="OK - Sauvegarde du répertoire /${DIR}"
					AppendtoHostInfos $TEXT
					AppendtoLog $TEXT
				fi
			done
		else
			TEXT="Lancement de la sauvegarde des répertoires sur l'hote local"
			AfficherOk $TEXT
			AppendtoLog $TEXT
			for DIR in ${SOURCE_DIR[*]}; do
				CODEER="0"
				AfficherWaiting "${DIR}"
				mkdir -p /$DIR/ $DEST_DIR/$REP_MONTH/$REP_SAVE/$DIR/
				AfficherInProgressOverwrite "/${DIR}"		
				$RSYNCCMD -a -q --no-links --ignore-errors --force --include ".*"  --filter "- *.tmp" --filter "- lost+found/" --filter "- .cache/" /$DIR/ $DEST_DIR/$REP_MONTH/$REP_SAVE/$DIR/ &> /dev/null
				CODEER=$(($CODEER+$?))
				TAILLEDIR=$($DUCMD -hsc $DEST_DIR/$REP_MONTH/$REP_SAVE/$DIR/ | tail -n 1 | tr -s "	" | cut -d "	" -f 1 )
				TAILLEDIR="${TAILLEDIR}o"
				if [ $CODEER -ne 0 ]; then
					AfficherErrorOverwrite "/${DIR} (${TAILLEDIR})"
					TEXT="ERR- Sauvegarde du répertoire /${DIR}"
					AppendtoHostInfos $TEXT
					AppendtoLog $TEXT
				else
					AfficherDoneOverwrite "/${DIR} (${TAILLEDIR})"
					TEXT="OK - Sauvegarde du répertoire /${DIR}"
					AppendtoHostInfos $TEXT
					AppendtoLog $TEXT
				fi
			done
		fi
		
	else
		TEXT="Sauvegarde des répertoires désactivée"
		AfficherWarn $TEXT
		AppendtoLog $TEXT
	fi
}

function CompressArchiv(){
	ORIGIN_DIR=$(pwd)
	TEXT="Lancement de la compression des données sauvegardées"
	AfficherOk $TEXT
	AppendtoLog $TEXT

	cd  $DEST_DIR/$REP_MONTH
	AfficherWaiting "Démarrage de la compression de $REP_SAVE"
	AfficherInProgressOverwrite "Compression de $REP_SAVE"
	tar -czf $REP_SAVE.tar.gz $REP_SAVE
	if [ $? -ne 0 ]; then
		AfficherErrorOverwrite "Compression de $REP_SAVE"
		TEXT="ERR- Compression du répertoire $REP_SAVE "
		AppendtoHostInfos $TEXT
		AppendtoLog $TEXT
		ControlErr 1
	else
		TAILLE_ARCHIVE=$(ls -lh | grep $REP_SAVE.tar.gz | tr -s ' ' | cut -d ' ' -f 5)
		TAILLE_ARCHIVE="${TAILLE_ARCHIVE}o"
		AfficherDoneOverwrite "Compression de $REP_SAVE ($TAILLE_ARCHIVE)"
		TEXT="OK - Compression de $REP_SAVE"
		AppendtoHostInfos $TEXT
		AppendtoLog $TEXT
	fi
	if [[ $(echo "$REP_SAVE" | grep -E "^${NAMEHOST}_") ]];then
		rm -rf $DEST_DIR/$REP_MONTH/$REP_SAVE &> /dev/null
		if [ $? -ne 0 ]; then
			AfficherErrorOverwrite "Suppression du répertoire non compressé $REP_SAVE"
			TEXT="ERR- Suppression du répertoire non compressé $REP_SAVE "
			AppendtoHostInfos $TEXT
			AppendtoLog $TEXT
			cd $ORIGIN_DIR
			ControlErr 1
		else
			AfficherDoneOverwrite "Suppression du répertoire non compressé $REP_SAVE"
			TEXT="OK - Suppression du répertoire non compressé $REP_SAVE"
			AppendtoLog $TEXT
			cd $ORIGIN_DIR
		fi

	else
		AfficherErrorOverwrite "Suppression du répertoire non compressé $REP_SAVE"
		TEXT="ERR- Suppression du répertoire non compressé $REP_SAVE"
		AppendtoHostInfos $TEXT
		AppendtoLog $TEXT
		cd $ORIGIN_DIR
		ControlErr 1
	fi
}

function AddHostInfos(){
	TEXT="Ajout des informations sur l'hote dans le répertoire de sauvegarde"
	AfficherOk $TEXT
	AppendtoLog $TEXT
	HOST_INFO_FILE="$DEST_DIR/$REP_MONTH/$REP_SAVE/Host_Info.txt"
	echo "CENTRALBACKUP2 ------------------" > $HOST_INFO_FILE
	echo "Machine de sauvegarde : $NAME" >> $HOST_INFO_FILE
	echo "Adresse IP : $IP" >> $HOST_INFO_FILE
	echo "Heure de sauvegarde : $TIME" >> $HOST_INFO_FILE
	echo "---------------------------------" >> $HOST_INFO_FILE
	echo "Configuration de la sauvegarde :" >> $HOST_INFO_FILE
	echo "	Sauvegarde distante = $REMOTE_MODE" >> $HOST_INFO_FILE
	if [ $REMOTE_MODE -ne 0 ];then
		echo "	Cible à sauvegarder = $NAMEHOST - $REMOTE_LOGIN@$REMOTE_HOST:$REMOTE_SSH_PORT" >> $HOST_INFO_FILE
	fi
	echo "	Sauvegarde répertoires = $ACTIV_FICH" >> $HOST_INFO_FILE
	echo "	Sauvegarde base de données = $ACTIV_BDD" >> $HOST_INFO_FILE
	echo "	Sauvegarde de la liste des paquets = $ACTIV_PKG" >> $HOST_INFO_FILE
	echo "	auvegarde des tâches Cron = $ACTIV_CRONTAB" >> $HOST_INFO_FILE
	echo "	Destination = $DEST_DIR" >> $HOST_INFO_FILE
	echo "	Fichier de log dans = $DEST_LOG" >> $HOST_INFO_FILE
	echo "---------------------------------" >> $HOST_INFO_FILE
}

function AppendtoHostInfos(){
	echo "$(date "+%Y-%m-%d-%H:%M:%S") - $@" >> $HOST_INFO_FILE
}

function BackupReport(){
	t2=`date +%s`
	total=$(($t2-$t1))
	nbh=$(($total/3600))
	nbm=$((($total-(3600*nbh))/60))
	nbs=$((($total-(3600*nbh))%60))
	TEXT="Durée de la sauvegarde :  ${nbh}h ${nbm}m ${nbs}s - ${TAILLE_ARCHIVE} (compressée)"
	AfficherOk $TEXT
	AppendtoLog $TEXT
}

function CheckCron(){
	crontab -l &> cron.tmp 
	cat cron.tmp | grep $0 &> /dev/null
	if [ $? -ne 0 ]; then
		AfficherCrit "La sauvegarde n'est pas planifée dans la CRONTAB"
	else
		AfficherOk "La sauvegarde est planifiée dans la CRONTAB"
	fi
	rm cron.tmp
}

function Archiv(){
	if [[ $ACTIV_CLEANUP == "1" ]];then
		TEXT="L'archivage de sauvegarade activée avec une rétention de $NB_ARCHIV"
		AfficherOk $TEXT
		AppendtoLog $TEXT
		#TODO
		ls -1 $ROOT > liste_host.tmp
		while read REP; do
			REP="$ROOT/$REP"
			echo "NOTE : Affichage de la liste des dossiers de sauvegarde dans $REP"
			ls -rt $REP | egrep "^2[0-9][0-9][0-9]" | head -n-1 > liste_rep.tmp
			echo ""
			echo "NOTE : Affichage du nombre de sauvegarde dans chaque dossier"
			while read SELECT_REP; do
					ls -1 $REP/$SELECT_REP | grep "tar.gz" > liste_sauve.tmp
					NB_SAUVE=`cat liste_sauve.tmp | wc -l`
					echo "NOTE : $SELECT_REP contient $NB_SAUVE sauvegardes"
					LAST_SAUVE=`ls -t $REP/$SELECT_REP | grep "tar.gz" | head -n 1`
					echo "NOTE : La sauvegarde la plus récente à sauvegarde est : $LAST_SAUVE"
					while read SELECT_SAUVE; do
							if [ $SELECT_SAUVE != $LAST_SAUVE ];then
									echo -e "\t Fichier à supprimer : $REP/$SELECT_REP/$SELECT_SAUVE"
									rm "$REP/$SELECT_REP/$SELECT_SAUVE"
									CODEER=$(($CODEER+$?))
									if [ $CODEER -ne 0 ]; then
											if [ $DEBUG -eq "1" ];then
													echo -e "\033[31mERR\033[0m : Probleme lors de la suppression de $REP/$SELECT_REP/$SELECT_SAUVE"
											fi
											echo "ERR : Probleme lors de la suppression de $REP/$SELECT_REP/$SELECT_SAUVE" >> archivage.log
									fi
							fi
					done < liste_sauve.tmp
			done < liste_rep.tmp
			echo ""
			CURRENT_REP=`ls -t $REP | head -n 1`
			echo "NOTE : Le répertoire courant dans $REP est : $CURRENT_REP "
		done < liste_host.tmp

		# Nettoyage des fichiers temporaires du programme
		rm liste_host.tmp
		rm liste_rep.tmp
		rm liste_sauve.tmp	
	fi
}

# Programme
clear
InitVariables
GatherInfos $DATETIME
if  [ $REMOTE_MODE -ne 0 ];then
	AfficherBanner $NAMEHOST $REMOTE_HOST $TIME
else
	AfficherBanner $NAME $IP $TIME
fi
AfficherTitre "Début de la sauvegarde"
CreateDir $DEST_LOG
CreateDir $DEST_DIR
CreateDir $DEST_DIR/$REP_MONTH
CreateDir $DEST_DIR/$REP_MONTH/$REP_SAVE
AppendtoLog "Démarrage de la sauvegarde"
AddHostInfos
if  [ $REMOTE_MODE -ne 0 ];then
	TEXT="Utilisation du mode de sauvegarde déporté (SSH $REMOTE_LOGIN@$REMOTE_HOST:$REMOTE_SSH_PORT)"
	AfficherOk $TEXT
	AppendtoLog $TEXT
	CheckSshAccess $REMOTE_HOST $REMOTE_SSH_PORT $REMOTE_LOGIN
else
	TEXT="Utilisation du mode de sauvegarde local"
	AfficherOk $TEXT
	AppendtoLog $TEXT
fi
DetectOsFamilly
CheckInstalledPackages
CheckUser
#Archiv
BackupDir
BackupDatabases
BackupCronTasks
BackupListOfPackages
CompressArchiv
BackupReport
CheckCron
AfficherTitre "Fin de la sauvegarde"
AppendtoLog "Fin de la sauvegarde"