#!/bin/bash

KEY=$(cat secrets.key 2> /dev/null || echo "")
ENC_FILE="secrets.enc"
UNENC_FILE="/tmp/imjacinta_deploy_secrets.unenc"
INSECURE="false"

POSITIONAL=()
while [[ $# -gt 0 ]]
do
  case $1 in
    --key)
      KEY=$2
      shift
      shift
      ;;
    --keyfile)
      KEY=$(cat $2)
      shift
      shift
      ;;
    --debug)
      set -x
      shift
      ;;
    --development)
      INSECURE="true"
      shift
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done
set -- "${POSITIONAL[@]}"

encrypt_file() {
  openssl enc -aes-256-cbc -salt -pbkdf2 -a -k "$KEY" -in "$1"
}

decrypt_file() {
  openssl enc -aes-256-cbc -pbkdf2 -d -a -k "$KEY" -in "$1"
}

if [ -z "$KEY" ]; then
  echo "No key supplied! (secrets.key, --key, --keyfile)"
  exit 1
fi

DEFAULT_SECRETS=(
  '# Secrets used for k8s deployment'
  'secret_key_base="YOUR SECRET KEY HERE"'
  'imjacinta_master_key="YOUR MASTER KEY HERE"'
  'curtincourses_master_key="YOUR MASTER KEY HERE"'
  'imjacinta_gcs="YOUR GCS JSON HERE (base64 encoded)"'
  'postgresql_password="YOUR PASSWORD HERE"'
  'traefik_htpasswd="YOUR PASSWORD HERE"'
)

case $1 in
  edit-secrets)
    decrypt_file $ENC_FILE > $UNENC_FILE
    ${EDITOR:-vi} $UNENC_FILE
    encrypt_file $UNENC_FILE > $ENC_FILE
    rm $UNENC_FILE
    echo "Secrets saved!"
    ;;
  show-secrets)
    decrypt_file $ENC_FILE
    ;;
  seed-secrets)
    printf '%s\n' "${DEFAULT_SECRETS[@]}" > $UNENC_FILE
    encrypt_file $UNENC_FILE > $ENC_FILE
    rm $UNENC_FILE
    ;;
  install)
    eval $(decrypt_file $ENC_FILE | grep -v '^#' | xargs)
    helm upgrade --install imjacinta imjacinta \
      --set secret_key_base="$secret_key_base" \
      --set imjacinta.master_key="$imjacinta_master_key" \
      --set curtincourses.master_key="$curtincourses_master_key" \
      --set postgresql.postgresqlPassword="$postgresql_password" \
      --set imjacinta.gcs="$imjacinta_gcs" \
      --set insecure="$INSECURE" \
      --set traefik.htpasswd="$traefik_htpasswd"
    ;;
  uninstall)
    helm uninstall imjacinta
    ;;
  *)
    echo "Usage: ./deploy (edit-secrets|show-secrets|seed-secrets|install)"
    exit 1
    ;;
esac

# helm upgrade --install imjacinta imjacinta --set \
#     secret_key_base="`rake secret`",\
#     imjacinta.master_key="$1",\
#     curtincourses.master_key="$2",\
#     postgresql.postgresqlPassword="test123"