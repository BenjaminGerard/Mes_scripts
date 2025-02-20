### Il faut remplacer "Mettre le nom du repo à ACTIVER" & "Mettre le nom du repo à DESACTIVER"


# Supprimer SysMon pour chaque élément dans la liste
for i in $(cat liste); do 
    echo "Removing SysMon for item: $i"
    sudo yum remove SysMon -y
    if [ $? -ne 0 ]; then
        echo "Failed to remove SysMon for item: $i"
        exit 1  # Quitte le script avec un code d'erreur
    fi
done

# Activer le dépôt Mettre le nom du repo à ACTIVER pour chaque élément dans la liste
for i in $(cat liste); do 
    echo "Enabling repository for item: $i"
    if subscription-manager repos --enable="Mettre le nom du repo à ACTIVER"; then
        echo "Repository enabled for item: $i"
    else
        echo "Error: Repository 'Mettre le nom du repo à ACTIVER' does not match a valid repository ID."
        exit 1  # Quitte le script avec un code d'erreur
    fi
done


# Installer SysMon pour chaque élément dans la liste
for i in $(cat liste); do 
    echo "Installing SysMon for item: $i"
    sudo yum install SysMon -y
    if [ $? -ne 0 ]; then
        echo "Failed to install SysMon for item: $i"
        exit 1  # Quitte le script avec un code d'erreur
    fi
done

# Désactiver le dépôt Mettre le nom du repo à DESACTIVER pour chaque élément dans la liste
for i in $(cat liste); do 
    echo "Disabling repository for item: $i"
    subscription-manager repos --disable="Mettre le nom du repo à DESACTIVER"
    if [ $? -ne 0 ]; then
        echo "Failed to disable repository for item: $i"
        exit 1  # Quitte le script avec un code d'erreur
    fi
done

# Arrêter SysMon pour chaque élément dans la liste
for i in $(cat liste); do 
    echo "Stopping SysMon for item: $i"
    sudo systemctl stop SysMon
    if [ $? -ne 0 ]; then
        echo "Failed to stop SysMon for item: $i"
        exit 1  # Quitte le script avec un code d'erreur
    fi
done

# Démarrer SysMon pour chaque élément dans la liste
for i in $(cat liste); do 
    echo "Starting SysMon for item: $i"
    sudo systemctl start SysMon
    if [ $? -ne 0 ]; then
        echo "Failed to start SysMon for item: $i"
        exit 1  # Quitte le script avec un code d'erreur
    fi
done

echo "All operations completed successfully."
exit 0  # Quitte le script avec succès

sudo yum remove SysMon
subscription-manager repos --enable="Mettre le nom du repo à ACTIVER"
sudo yum install SysMon
subscription-manager repos --disable="Mettre le nom du repo à DESACTIVER"
sudo systemctl stop SysMon
sudo systemctl start SysMon
sudo systemctl status SysMon
