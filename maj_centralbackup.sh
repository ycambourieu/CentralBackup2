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
# Création initiale : 13/01/2021
# Script : Mise à joru des configurations CentralBackup2
# Version : 2.0
# Change Log :
#	2.0 - 13/01/2021 : Création du script
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
	echo -e "\033[36m| |________| |\033[0m  Mise à jour des configurations"
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

function UpdateClientConfiguration(){
	AfficherOk "Création de la liste des clients"
	AfficherOk "Mise à jour des configurations client"
	for DOSSIER in $(ls -l $LAUNCH_DIR | egrep "^d" | tr -s " " | cut -d " " -f 9- | sed ':a;N;$!ba;s/\n/ /g'); do
			if [[ "$DOSSIER" != "$NAME_MODEL" ]]; then
				AfficherWaiting "$DOSSIER"
				AfficherInProgressOverwrite "$DOSSIER"
				SUM_BEFORE=$(cksum $LAUNCH_DIR/$DOSSIER/$NAME_SH)
				cp $LAUNCH_DIR/$NAME_MODEL/$NAME_SH $LAUNCH_DIR/$DOSSIER/$NAME_SH
				SUM_AFTER=$(cksum $LAUNCH_DIR/$DOSSIER/$NAME_SH)
			fi
			if [[ $SUM_BEFORE != $SUM_AFTER ]];then
				AfficherDoneOverwrite "$DOSSIER (mis à jour)"
			else
				AfficherDoneOverwrite "$DOSSIER (non mis à jour)"
			fi			
	done
	AfficherOk "Affectation des droits d'exécution à la sauvegarde" 
	chmod +x -R $LAUNCH_DIR/*/$NAME_SH
}

# Programme 
clear
InitVariables
AfficherBanner
AfficherTitre "Début de la mise à jour des configurations CentralBackup2"
UpdateClientConfiguration
AfficherTitre "Fin de la mise à jour des configurations CentralBackup2"