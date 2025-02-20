## Ne pas oublier de mettre à jour "chemin/fichier/"

#!/bin/bash

# Générer le nom de fichier avec la date du jour
output_file="OS_FSAinventory_$(date +%d%m%Y)"

echo "Veuillez entrer le nom du fichier contenant la liste des machines :"
read -r filename

# Vérifier si le fichier existe
if [ ! -f "$filename" ]; then
    echo "Le fichier $filename n'existe pas ou n'est pas accessible."
    exit 1
fi

# Copie du fichier InventaireFSA.ksh sur chaque machine de la liste
while read -r line; do
    scp chemin/fichier/InventaireFSA.ksh "$line:/tmp/InventaireFSA.ksh" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "$line copié"
    else
        echo "Échec de la copie vers $line"
    fi
done < "$filename"

# Exécution du script sur chaque machine de la liste
for h in $(cat "$filename"); do
    echo "Exécution de InventaireFSA.ksh sur $h..."
    output=$(ssh "$h" 'chemin/fichier/InventaireFSA.ksh' 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "Sortie de $h :"
        echo "$output" | tee -a "$output_file"
        ssh "$h" 'rm chemin/fichier/InventaireFSA.ksh' 2>/dev/null
        echo "$h script supprimé"
    else
        echo "Échec de l'exécution sur $h"
    fi
    echo "-------------------------------------"
done
