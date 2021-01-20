#!/bin/bash
ROOT="/backup"
CODEER=0
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

