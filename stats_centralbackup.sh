#!/bin/bash
	WORKDIR=`dirname $0`
	. $WORKDIR/centralbackup.conf

	LISTE_DOSSIER=`ls -l /mnt/backup/ | egrep "^d" | tr -s " " | cut -d " " -f 9-`
	TAILLETOTAL=`du -hc /mnt/backup/ | tail -n 1 | cut -d "t" -f 1`
	NBTOTAL=0

# Rendre les $NAME_SH executables

	echo -e "NOTE : \033[1m------------ Statistiques de sauvegardes ------------\033[0m" 
	echo "NOTE : Création de la liste des clients" 
	for DOSSIER in "$LISTE_DOSSIER"; do
		echo "${DOSSIER}" > liste_rep.tmp
	done 
	
	echo "NOTE : Affichage des statistiques" 
	while read REP
	do
		REPUPPER=${REP^^}
		NBSAVE=`tree /mnt/backup/$REPUPPER/ | grep tar.gz | wc -l`
		NBTOTAL=$(($NBTOTAL+$NBSAVE))
		if [ $NBSAVE -lt 10 ];then
			echo -e "[\033[31m$NBSAVE\033[0m] \t $REPUPPER"

		else
			echo -e "[\033[32m$NBSAVE\033[0m] \t $REPUPPER"
		fi

	done < liste_rep.tmp
	echo "NOTE : Nombre total de sauvegardes : $NBTOTAL"
	echo "NOTE : Taille totale des sauvegardes : ${TAILLETOTAL}"
	echo "NOTE : Suppression des fichiers temporaires" 
	rm liste_rep.tmp
	
	echo -e "NOTE : \033[1m------------ Fin de la récupération des statistiques------------\033[0m" 
