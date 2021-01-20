#!/bin/bash
# ##########################################################################
#    ____           _             _ ____             _               ____  
#   / ___|___ _ __ | |_ _ __ __ _| | __ )  __ _  ___| | ___   _ _ __|___ \ 
#  | |   / _ \ '_ \| __| '__/ _` | |  _ \ / _` |/ __| |/ / | | | '_ \ __) |
#  | |__|  __/ | | | |_| | | (_| | | |_) | (_| | (__|   <| |_| | |_) / __/ 
#   \____\___|_| |_|\__|_|  \__,_|_|____/ \__,_|\___|_|\_\\__,_| .__/_____|
#                                                              |_|         
# Ajout de client
# -------------------------------------------
# Autheur : Yohan CAMBOURIEU
# Création initiale : 11/01/2021
# Script : Ajout d'un client CentralBackup2
# Version : 2.0
# Change Log :
#	2.0 - 11/01/2021 : Création du script
# -------------------------------------------
#
# ##########################################################################

# Fonctions d'affichage

function AfficherBanner(){
	echo ""
	echo -e "\033[36m _.........._\033[0m"
	echo -e "\033[36m| | Central| |\033[0m"
	echo -e "\033[36m| | Backup | |\033[0m"
	echo -e "\033[36m| |   2    | |\033[0m"
	echo -e "\033[36m| |________| |\033[0m  Ajout d'un client"
	echo -e "\033[36m|   ______   |\033[0m"
	echo -e "\033[36m|  |    | |  |\033[0m"
	echo -e "\033[36m|__|____|_|__|\033[0m"
	echo ""
}

function AfficherTitre(){
	echo -e "\033[1m## $@ ##\033[0m"
}

function AfficherSautLigne(){
	echo ""
}

function AfficherCode(){
	AfficherSautLigne
	echo -e "	\033[35m$@\033[0m"
	AfficherSautLigne
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

function AfficherDone(){
	echo -e "		\033[32m• $@ : Done.\033[0m"
}

function AfficherErrorOverwrite(){
	echo -e "\e[1A\e[K		\033[31m• $@ : Erreur, des droits root sont peut être requis\033[0m"
}

function ColorTextComment(){
	ESC=$(printf '\033')
	echo "$@" | sed "s,.*,\t${ESC}[36m&${ESC}[0m,"

}

function ColorTextHost(){
	ESC=$(printf '\033')
	echo -e "\t\t$@" | sed "s,${CLIENT},${ESC}[33m&${ESC}[0m,"

}

function ColorTextEnabled(){
	ESC=$(printf '\033')
	echo -e "\t\t$@" | sed "s,1,${ESC}[32m&${ESC}[0m,"

}

function ColorTextDisabled(){
	ESC=$(printf '\033')
	echo -e "\t\t$@" | sed "s,0,${ESC}[31m&${ESC}[0m,"

}

# Fonctions d'action

function InitVariables(){
	WORKDIR=`dirname $0`
	. $WORKDIR/centralbackup.conf
}

function ControlErr(){
	if [ $1 -ne 0 ];then
		AfficherCrit "Erreur détectée - Arret du programme"
		exit 1
	fi
}

function AddClient(){
	AfficherOk "Saisir le nom de la machine cliente :"
	echo -ne "\t\t\033[33m"
	read CLIENT
	echo -e "\033[0m"
	AfficherOk "Ajout de la machine $CLIENT : "
	if [ ! -d $LAUNCH_DIR/$CLIENT ];then
		TEXT="Création du répertoire de configuration pour $CLIENT"
		cp -R $LAUNCH_DIR/$NAME_MODEL/ $LAUNCH_DIR/$CLIENT
		ControlErr $?
		AfficherDone $TEXT
		TEXT="Modification des permissions d'exécution"
		AfficherWaiting $TEXT
		AfficherInProgressOverwrite $TEXT
		chmod +x $LAUNCH_DIR/$CLIENT/*.sh
		ControlErr $?
		AfficherDoneOverwrite $TEXT
		TEXT="Modification des permissions d'exécution"
		AfficherWaiting $TEXT
		AfficherInProgressOverwrite $TEXT
		sed -i "s/	NAMEHOST=.*$/	NAMEHOST=\"$CLIENT\"/" $LAUNCH_DIR/$CLIENT/sauvegarde.conf
		ControlErr $?
		AfficherDoneOverwrite $TEXT
	else
		AfficherCrit "Le répertoire existe déjà pour la machine $CLIENT"
		ControlErr 1
	fi
}

function ConfigureClient(){
	AfficherTitre "Fichier de configuration actuel"
	AfficherSautLigne
	while read LIGNE; do
		echo "$LIGNE "| grep -E "^#.*" &> /dev/null
 		if [ $? -eq 0 ];then
			# La ligne est un commentaire
			ColorTextComment "$LIGNE"
		else
			# La ligne n'est pas un commentaire
			echo "$LIGNE" | grep -Ei "$CLIENT" &> /dev/null
			if [ $? -eq 0 ];then
				# La ligne contient le nom du client
				ColorTextHost "$LIGNE"
			else
				echo "$LIGNE" | grep -Ei "=\"1\"" &> /dev/null
				if [ $? -eq 0 ];then
					ColorTextEnabled "$LIGNE"
				else
					echo "$LIGNE" | grep -Ei "=\"0\"" &> /dev/null
					if [ $? -eq 0 ];then
						ColorTextDisabled "$LIGNE"
					else
						echo -e "\t\t$LIGNE"
					fi
				fi
			fi
		fi
	done < $LAUNCH_DIR/$CLIENT/sauvegarde.conf
	AfficherSautLigne
	AfficherTitre "Fin de la configuration"
	AfficherOk "Pour modifier la configuration :"
	AfficherCode "vim $LAUNCH_DIR/$CLIENT/sauvegarde.conf"
}

# Programme 
clear
InitVariables
AfficherBanner
AfficherTitre "Début d'ajout d'un client CentralBackup2"
AddClient
ConfigureClient
AfficherTitre "Fin d'ajout d'un client CentralBackup2"