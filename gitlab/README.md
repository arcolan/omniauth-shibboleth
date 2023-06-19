# Installation sur une instance Gitlab

Le script `o2s_install.sh` permet l'installation de la stratégie OmniAuth Shibboleth dans différentes versions, ainsi que la désactivation de cette fonctionnalité le temps d'une mise à jour de l'instance Gitlab, par exemple.

## Modification du fichier gitlab.rb

Le fichier de configuration de Gitlab doit être modifié afin de fonctionner avec le script `o2s_install.sh`. Chaque ligne concernant les paramètres d'OmniAuth doit se terminer par le commentaire ***#o2s_comment***.

Voici un exemple de fichier `gitlab.rb` fonctionnaant avec le script d'installation :

```ruby
### Shibboleth OmniAuth Provider
gitlab_rails['omniauth_allow_single_sign_on'] = ['shibboleth']      # o2s_comment
gitlab_rails['omniauth_block_auto_created_users'] = false           # o2s_comment
gitlab_rails['omniauth_enabled'] = true                             # o2s_comment
gitlab_rails['omniauth_providers'] = [                              # o2s_comment
  {                                                                 # o2s_comment
    "name" => "shibboleth",                                         # o2s_comment
    "label" => "SSO Connexion", # Text for Login Button             # o2s_comment
    "args" => {                                                     # o2s_comment
        "shib_session_id_field" => "HTTP_SHIB_SESSION_ID",          # o2s_comment
        "shib_application_id_field" => "HTTP_SHIB_APPLICATION_ID",  # o2s_comment
        "uid_field" => 'HTTP_EPPN',                                 # o2s_comment
        "name_field" => 'HTTP_CN',                                  # o2s_comment
        "info_fields" => { "email" => 'HTTP_MAIL'}                  # o2s_comment
     }                                                              # o2s_comment
  }                                                                 # o2s_comment
]                                                                   # o2s_comment
```

## Installation du script

```bash
wget https://raw.githubusercontent.com/arcolan/omniauth2-shibboleth/master/gitlab/o2s-install.sh
wget https://raw.githubusercontent.com/arcolan/omniauth2-shibboleth/master/gitlab/shibboleth_64.png
chmod +x o2s_install.sh
```

## Utilisation du script

Installation d'[omniauth2-shibboleth](https://github.com/arcolan/omniauth2-shibboleth/) sur l'instance Gitlab :

```bash
/o2s-install.sh
```

Installation d'[omniauth-shibboleth](https://github.com/toyokazu/omniauth-shibboleth) en version 1.3 sur l'instance Gitlab :

```bash
/o2s-install.sh -o
```

Désactivation de la stratégie OmniAuth Shibboleth sur l'instance Gitlab :

```bash
/o2s-install.sh -d
```
