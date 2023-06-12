#!/bin/bash

# Paramètres du script
DIR="/opt/gitlab/embedded/service/gitlab-rails"
OMNIAUTH_VERSION="2.1.0"
OMNIAUTH_SHIBBOLETH_VERSION="2.0.1.alpha"
OMNIAUTH_SHIBBOLETH_CHECKSUM="dccea8a94d79f23a41d980e128cc4260b7e7dd7c1684dbd796469dfe31b5c459"

# Colorisation des sorties
NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'

# Fonction d'insertion d'une ligne dans un fichier
insert_line() {
    local file="$1"
    local line_to_insert="$2"
    local existing_line="$3"

    # Vérifier si la ligne existe déjà dans le fichier
    if grep -Fxq "$line_to_insert" "$file"; then
        echo -e "${ORANGE}$file non modifié.${NOCOLOR}"
    else
        # Utiliser awk pour insérer la nouvelle ligne après la ligne existante
        awk -v line="$line_to_insert" -v existing="$existing_line" '1; $0 ~ existing {print line}' "$file" > temp && mv temp "$file"
        echo -e "${GREEN}$file mis à jour.${NOCOLOR}"
    fi
}

# Installation d'Omniauth Shibboleth
if ! /opt/gitlab/embedded/bin/gem list |grep "omniauth2-shibboleth" |grep -Fq "2.0.1.alpha"
then
    /opt/gitlab/embedded/bin/gem install omniauth2-shibboleth --pre
fi

# Copie du logo Shibboleth
mkdir -p $DIR/public/images/auth_buttons/
cp ./shibboleth_64.png $DIR/public/images/auth_buttons/

# Modification des fichiers de configuration de Gitlab
insert_line "$DIR/app/helpers/auth_helper.rb" "    shibboleth" "    salesforce"
insert_line "$DIR/Gemfile" "gem 'omniauth-shibboleth', '~> $OMNIAUTH_SHIBBOLETH_VERSION'" "gem 'omniauth-saml', *"
insert_line "$DIR/Gemfile.checksum" "{\"name\":\"omniauth-shibboleth\",\"version\":\"$OMNIAUTH_SHIBBOLETH_VERSION\",\"platform\":\"ruby\",\"checksum\":\"$OMNIAUTH_SHIBBOLETH_CHECKSUM\"}," '{"name":"omniauth-saml","version":*'
insert_line "$DIR/Gemfile.lock" "  omniauth-shibboleth (~> $OMNIAUTH_SHIBBOLETH_VERSION)" "  omniauth-saml \(~> *"
insert_line "$DIR/Gemfile.lock" "      omniauth (>= $OMNIAUTH_VERSION)" "      ruby-saml *"
insert_line "$DIR/Gemfile.lock" "    omniauth-shibboleth ($OMNIAUTH_SHIBBOLETH_VERSION)" "      ruby-saml *"

# Reconfiguration
/opt/gitlab/embedded/bin/bundle config unset frozen
gitlab-ctl reconfigure
