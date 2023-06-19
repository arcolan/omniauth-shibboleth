#!/bin/bash

# Fonction d'aide
afficher_aide() {
    echo "Utilisation :"
    echo "  ./o2s-install.sh [-o]"
    echo
    echo "Installe omniauth2-shibboleth sur une instance Gitlab."
    echo
    echo "Options :"
    echo "  -o : installe omniauth-shibboleth version 1.3.0."
    echo "  -d : désactivation d'omniauth2-shibboleth."
    echo "  -h : affiche ce message d'aide." 
    exit 1
}

# Fonction de suppression d'une ligne dans un fichier
delete_line() {
    local file="$1"
    local line_to_delete="$2"

    if ! grep -Fq "$line_to_delete" "$file"; then
        echo 0
    else
        awk '!/'"$line_to_delete"'/' "$file" > temp && mv temp "$file"
        echo 1
    fi
}

# Fonction d'insertion d'une ligne dans un fichier
insert_line() {
    local file="$1"
    local line_to_insert="$2"
    local existing_line="$3"

    if grep -Fq "$line_to_insert" "$file"; then
        echo 0
    else
        awk -v line="$line_to_insert" -v existing="$existing_line" '1; $0 ~ existing {print line}' "$file" > temp && mv temp "$file"
        echo 1
    fi
}

# Fonction d'affichage de l'état d'un fichier
display_state() {
    local file="$1"
    local state="$2"

    if [ "$state" -gt "0" ]; then
        echo -e "${GREEN}$(basename $file) mis à jour.${NOCOLOR}"
    else
        echo -e "${ORANGE}$(basename $file) non modifié.${NOCOLOR}"
    fi
}

# Fonction de vérification de présence d'une chaine
check_comment() {
    local filename="$1"
    local search_string="$2"

    if grep -q "$search_string" "$filename"; then
        return 0
    else
        echo "Le fichier $CONF n'est pas correctement paramétré."
        echo "Consultez la documentation pour plus de détails :"
        echo "https://github.com/arcolan/omniauth2-shibboleth/tree/master/gitlab"
        exit 1
    fi
}

# Fonction pour commenter les lignes correspondantes
comment_lines() {
    local filename="$1"
    local search_string="$2"

    rm -f temp
    while IFS= read -r line; do
        if [[ "$line" =~ "$search_string" ]] && [[ "$line" != \#* ]]; then
            echo "#$line" >> temp
        else
            echo "$line" >> temp
        fi
    done < "$filename"
    mv temp "$filename"
}

# Fonction pour décommenter les lignes correspondantes
uncomment_lines() {
    local filename="$1"
    local search_string="$2"

    awk -v search="$search_string" -v comment="#" '{ if ($0 ~ search) gsub("^" comment, "", $0); print }' "$filename" > temp
    mv temp "$filename"
}

# Fonction de fin du script
exit_script() {
    /opt/gitlab/embedded/bin/bundle config unset frozen
    echo "Reconfigure Gitlab..."
    gitlab-ctl reconfigure > /dev/null 2>&1
    gitlab-ctl restart puma
    gitlab-ctl restart sidekiq

    # URL à vérifier
    URL=$(echo $(cat /etc/gitlab/gitlab.rb | grep "^external_url") | cut -d'"' -f2)
    # Durée maximale en secondes
    max_duration=180

    # Début du compte à rebours
    start_time=$(date +%s)

    # Exécution de la commande "curl" pour récupérer le code HTTP
    http_code=0
    while [ "$http_code" -ne 200 ]; do
        # Calcul de la durée écoulée
        current_time=$(date +%s)
        duration=$((current_time - start_time))

        # Vérification si la durée maximale est dépassée
        if [ "$duration" -gt "$max_duration" ]; then
            echo -e "${RED}Timeout: la durée maximale de $max_duration secondes est dépassée.${NOCOLOR}"
            gitlab-ctl status | grep "^down"
            exit 1
        fi

        # Récupération du code HTTP
        sleep 10
        http_code=$(curl -sL -w "%{http_code}\\n" "$URL" -o /dev/null)

        # Arrêt de la temporisation lorsque le code HTTP est 200
        if [ "$http_code" -eq 200 ]; then
            echo -e "\r${GREEN}$URL : $http_code${NOCOLOR}"
            break
        else
            echo -ne "\r${RED}$URL : $http_code${NOCOLOR}"
        fi
    done

    exit 0
}

# Colorisation des sorties
NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'

# Paramètres du script
DIR="/opt/gitlab/embedded/service/gitlab-rails"
CONF="/etc/gitlab/gitlab.rb"
CONF_COMMENT="o2s_comment"
OMNIAUTH_VERSION="2.1.0"

# Vérification de présence du fichier de configuration
if [ ! -f "$CONF" ]; then
    echo "Le fichier $CONF n'existe pas."
    exit 1
fi

# Traitement des options de ligne de commande
while getopts "odh" opt; do
    case $opt in
        o)
            OMNIAUTH_SHIBBOLETH_VERSION="1.3.0"
            OMNIAUTH_SHIBBOLETH_CHECKSUM="b0bb725ced5cb76fbfc187ddbb8ad6864d0cd5df714cab36a528df8ee4b1d113"
            OLD_GEM="omniauth2-shibboleth"
            NEW_GEM="omniauth-shibboleth"
            ;;
        d)  
            if check_comment "$CONF" "$CONF_COMMENT" ; then
                comment_lines "$CONF" "o2s_comment"
            fi
            i=$(delete_line "$DIR/app/helpers/auth_helper.rb" "    shibboleth")
            display_state "$DIR/app/helpers/auth_helper.rb" "$i"
            exit_script
            ;;
        h)
            afficher_aide
            ;;
        *)
            echo "Option invalide: -$OPTARG"
            afficher_aide
            ;;
    esac
done
if [ -z "$OMNIAUTH_SHIBBOLETH_VERSION" ] || [ -z "$OMNIAUTH_SHIBBOLETH_CHECKSUM" ] || [ -z "$OLD_GEM" ] || [ -z "$OLD_GEM" ]; then
    OMNIAUTH_SHIBBOLETH_VERSION="2.0.1.alpha"
    OMNIAUTH_SHIBBOLETH_CHECKSUM="dccea8a94d79f23a41d980e128cc4260b7e7dd7c1684dbd796469dfe31b5c459"
    OLD_GEM="omniauth-shibboleth"
    NEW_GEM="omniauth2-shibboleth"
fi

# Modification de gitlab.rb
if check_comment "$CONF" "$CONF_COMMENT" ; then
    uncomment_lines "$CONF" "$CONF_COMMENT"
fi

# Installation d'Omniauth Shibboleth
if /opt/gitlab/embedded/bin/gem list |grep -Fq "$OLD_GEM"
then
    /opt/gitlab/embedded/bin/gem uninstall $OLD_GEM
fi
if ! /opt/gitlab/embedded/bin/gem list |grep "$NEW_GEM"
then
    /opt/gitlab/embedded/bin/gem install "$NEW_GEM" --pre
fi

# Copie du logo Shibboleth
if [ -f ./shibboleth_64.png ]; then
    mkdir -p $DIR/public/images/auth_buttons/
    cp ./shibboleth_64.png $DIR/public/images/auth_buttons/
fi

# Modification des fichiers de configuration de Gitlab
i=$(insert_line "$DIR/app/helpers/auth_helper.rb" "    shibboleth" "    salesforce")
display_state "$DIR/app/helpers/auth_helper.rb" "$i"

i=$(delete_line "$DIR/Gemfile" $OLD_GEM)
j=$(insert_line "$DIR/Gemfile" "gem '$NEW_GEM', '~> $OMNIAUTH_SHIBBOLETH_VERSION'" "gem 'omniauth-saml', *")
display_state "$DIR/Gemfile" "$((i+j))"

i=$(delete_line "$DIR/Gemfile.checksum" $OLD_GEM) 
j=$(insert_line "$DIR/Gemfile.checksum" "{\"name\":\"$NEW_GEM\",\"version\":\"$OMNIAUTH_SHIBBOLETH_VERSION\",\"platform\":\"ruby\",\"checksum\":\"$OMNIAUTH_SHIBBOLETH_CHECKSUM\"}," '{"name":"omniauth-saml","version":*')
display_state "$DIR/Gemfile.checksum" "$((i+j))"

i=$(delete_line "$DIR/Gemfile.lock" $OLD_GEM)
j=$(insert_line "$DIR/Gemfile.lock" "  $NEW_GEM (~> $OMNIAUTH_SHIBBOLETH_VERSION)" "  omniauth-saml \(~> *")
k=$(insert_line "$DIR/Gemfile.lock" "      omniauth (>= $OMNIAUTH_VERSION)" "      ruby-saml *")
l=$(insert_line "$DIR/Gemfile.lock" "    $NEW_GEM ($OMNIAUTH_SHIBBOLETH_VERSION)" "      ruby-saml *")
display_state "$DIR/Gemfile.lock" "$((i+j+k+l))"

exit_script
