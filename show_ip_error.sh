#!/bin/bash

# Liste des interfaces à vérifier
interfaces=("eth0" "eth1" "eth2" "eth3")

# Variable pour garder trace des erreurs
errors_found=false

# Boucle sur chaque interface et vérifie le nombre d'erreurs de réception
for iface in "${interfaces[@]}"; do
    # Vérifie si l'interface existe avant de collecter les stats
    if ethtool -i "$iface" &> /dev/null; then
        rx_errors=$(ethtool -S "$iface" | grep rx_errors | awk '{print $2}')
        
        # Affichage pour vérification (facultatif)
        echo "Interface $iface: $rx_errors rx_errors"

        # Vérifie si rx_errors est supérieur à zéro
        if [ "$rx_errors" -gt 0 ]; then
            errors_found=true
        fi
    else
        echo "Interface $iface non disponible"
    fi
done

# Vérifie s'il y a des erreurs
if $errors_found; then
    echo "Des erreurs de réception ont été détectées."
    exit 1
else
    echo "Aucune erreur de réception détectée."
    exit 0
fi
