# Ne pas oublier de remplacer "curl --url 'smtp://url.fr:25' \" ainsi que les adresses mail, "base_url="https://url.com, "auth_user="admin"" & "auth_pass="mdp""

#!/bin/bash

# Base URL de l'API Elasticsearch
base_url="https://url.com"

# Identifiants
auth_user="admin"
auth_pass="mdp"

# Fichier de log des indices détectés
output_file="rollover_failed_log"
temp_file="rollover_temp_log"

# Effacer les fichiers de log temporaires
> "$temp_file"
trap 'rm -f "$temp_file" "$existing_failed.txt" "$new_failed_indices.txt"' EXIT

# Récupération des indices correspondants à z_*
response=$(curl -s -u "$auth_user:$auth_pass" -X GET "$base_url/_plugins/_ism/explain/z_*" -H 'Content-Type: application/json')

# Vérification de la réponse
if [ $? -ne 0 ] || [ -z "$response" ]; then
    echo "Erreur lors de la récupération des informations pour z_*."
    exit 1
fi

# Analyse de la réponse pour détecter les messages indiquant un rollover failed
failed_indices=$(echo "$response" | grep -oP '"message"\s*:\s*"Failed to evaluate conditions for rollover \[index=([^]]+)\]' | sed -E 's/.*\[index=([^]]+)\]/\1/')

if [ -n "$failed_indices" ]; then
    echo "$failed_indices" > "$temp_file"

    # Vérification des index déjà présents dans le fichier output_file
    existing_failed=()
    if [ -f "$output_file" ]; then
        while IFS= read -r line; do
            existing_failed+=("$line")
        done < "$output_file"
    fi

    # Gestion des index encore en erreur
    if [ ${#existing_failed[@]} -gt 0 ]; then
        current_time=$(date '+%Y-%m-%d %H:%M:%S')
        one_hour_ago=$(date -d '1 hour ago' '+%Y-%m-%d %H:%M:%S')

        # Création du fichier contenant les index échoués
        > existing_failed.txt
        for index in "${existing_failed[@]}"; do
            echo "$index" >> existing_failed.txt
        done

        # Vérification de la présence du fichier avant d'envoyer le mail
        if [ -f "existing_failed.txt" ]; then
            # Corps du mail
            email_body="Bonjour,\n\nLe rollover sur l'index a échoué malgré le retry policy.\nL'index était en status failed à $one_hour_ago, il est toujours non fonctionnel à $current_time.\nLe script de retry est présent sur ophdb2914 dans /opt/operating/bin.\nVeuillez regarder de votre côté ce qui pose problème sur cet index via : https://hd-hdb-dashboard:8443/app/login?."

            # Envoi de l'email avec pièce jointe
            curl --url 'smtp://url.fr:25' \
                --mail-from 'mail1@mail.com' \
                --mail-rcpt 'mail3@mail.com' \
                --mail-rcpt 'mail2@mail.com' \
                --mail-rcpt 'mail1@mail.com' \
                --upload-file <(cat <<EOF
From: mail1@mail.com
To: mail3@mail.com, mail2@mail.com, mail1@mail.com
Subject: [HDB] Failed rollover sur certains index
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary=boundary123

--boundary123
Content-Type: text/plain; charset=UTF-8

$email_body

--boundary123
Content-Type: application/octet-stream
Content-Disposition: attachment; filename="existing_failed.txt"
Content-Transfer-Encoding: base64

$(base64 existing_failed.txt)

--boundary123--
EOF
)
        fi
    fi

    # Filtrer les nouveaux indices échoués
    new_failed_indices=$(grep -vFxf "$output_file" "$temp_file")

    if [ -n "$new_failed_indices" ]; then
        # Tentative de réessai pour les nouveaux indices échoués
        retry_failed=()
        while IFS= read -r index; do
            retry_response=$(curl -s -u "$auth_user:$auth_pass" -X POST "$base_url/_plugins/_ism/retry/$index" -H 'Content-Type: application/json')

            if [ $? -eq 0 ]; then
                echo "Réessai effectué pour l'index : $index"
            else
                echo "Échec du réessai pour l'index : $index"
                retry_failed+=("$index")
            fi
        done <<< "$new_failed_indices"

        # Notification pour les nouveaux index échoués après réessai
        if [ ${#retry_failed[@]} -gt 0 ]; then
            echo "$new_failed_indices" > new_failed_indices.txt

            # Corps de l'email
            email_body="Bonjour,\n\nUn retry policy a été effectué sur les index suivants :\n${retry_failed[*]}\n\nLe script de retry est présent sur ophdb2914 dans /opt/operating/bin."

            # Envoi de l'email avec pièce jointe
            curl --url 'smtp://opbdfprx2.rouen.francetelecom.fr:25' \
                --mail-from 'mail1@mail.com' \
                --mail-rcpt 'mail2@mail.com' \
                --mail-rcpt 'mail1@mail.com' \
                --mail-rcpt 'mail3@mail.com' \
                --upload-file <(cat <<EOF
From: mail1@mail.com
To: mail2@mail.com, mail3@mail.com, mail1@mail.com
Subject: Retry Policy Effectué
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary=boundary123

--boundary123
Content-Type: text/plain; charset=UTF-8

$email_body

--boundary123
Content-Type: application/octet-stream
Content-Disposition: attachment; filename="new_failed_indices.txt"
Content-Transfer-Encoding: base64

$(base64 new_failed_indices.txt)

--boundary123--
EOF
)
        fi
    fi
fi

# Résumé final
if [ -f "$output_file" ] && [ -s "$output_file" ]; then
    echo "Tous les indices échoués ont été enregistrés dans $output_file."
else
    echo "Aucun indice échoué détecté. Fichier de log non généré."
    rm "$output_file" 2>/dev/null
fi

exit 0
