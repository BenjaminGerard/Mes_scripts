### Ne pas oublier de remplacer "BASICAT_CLUSTER" & "PI-SGA-XXX"

#!/bin/bash

BASICAT_CLUSTER_file="BASICAT_CLUSTER"
file_to_copy="PI-SGA-XXX.tar"
remote_dir="/images"

if [ ! -f "$BASICAT_CLUSTER_file" ]; then
    echo "Le fichier $BASICAT_CLUSTER_file n'existe pas. Veuillez vérifier."
    exit 1
fi

if [ ! -f "$file_to_copy" ]; then
    echo "Le fichier $file_to_copy n'existe pas. Veuillez vérifier."
    exit 1
fi

echo "Étape 1 : Copie du fichier sur les machines."
for h in $(cat "$BASICAT_CLUSTER_file"); do
    echo "Copie sur la machine $h..."
    scp -q "$file_to_copy" "$h:$remote_dir" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "Copie réussie sur $h."
    else
        echo "Échec de la copie sur $h."
    fi
done

echo "Étape 2 : Démarrage du service rscd sur les machines."
for h in $(cat "$BASICAT_CLUSTER_file"); do
    echo "Démarrage du service sur $h..."
    ssh -o LogLevel=QUIET "$h" 'systemctl start rscd' 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "Service rscd démarré avec succès sur $h."
    else
        echo "Échec du démarrage sur $h."
    fi
done

echo "Étape 3 : Extraction du fichier tar."
for h in $(cat "$BASICAT_CLUSTER_file"); do
    echo "Extraction sur $h..."
    ssh -o LogLevel=QUIET "$h" "cd $remote_dir && tar -xvf $file_to_copy" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "Extraction réussie sur $h."
    else
        echo "Échec de l'extraction sur $h."
    fi
done

echo "Étape 4 : Exécution du script d'installation."
for h in $(cat "$BASICAT_CLUSTER_file"); do
    echo "Exécution sur $h..."
    ssh -o LogLevel=QUIET "$h" "cd $remote_dir/PI-SGA-XXX && ./Install_BladeLogic_RSCD.sh" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "Script exécuté avec succès sur $h."
    else
        echo "Échec de l'exécution sur $h."
    fi
done

echo "Étape 5 : Rechargement de la configuration systemctl."
for h in $(cat "$BASICAT_CLUSTER_file"); do
    echo "Rechargement de systemctl sur $h..."
    ssh -o LogLevel=QUIET "$h" 'systemctl daemon-reload' 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "Rechargement réussi sur $h."
    else
        echo "Échec du rechargement sur $h."
    fi
done

echo "Toutes les étapes sont terminées."
