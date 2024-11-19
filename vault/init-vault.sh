#!/usr/bin/env sh
export VAULT_CACERT=/vault/certs/ca.pem
export VAULT_ADDR=https://vault:8200
vault operator init > /vault/config/init.txt

UNSEAL_KEY_1="$(grep 'Unseal Key 1' /vault/config/init.txt | awk '{print $NF}')"
UNSEAL_KEY_2="$(grep 'Unseal Key 2' /vault/config/init.txt | awk '{print $NF}')"
UNSEAL_KEY_3="$(grep 'Unseal Key 3' /vault/config/init.txt | awk '{print $NF}')"
INITIAL_ROOT_TOKEN="$(grep 'Root Token' /vault/config/init.txt | awk '{print $NF}')"

vault operator unseal "$UNSEAL_KEY_1"
vault operator unseal "$UNSEAL_KEY_2"
vault operator unseal "$UNSEAL_KEY_3"
vault login "$INITIAL_ROOT_TOKEN"

vault secrets enable -version=1 -path=concourse kv
vault policy write concourse /vault/config/concourse-policy.hcl
vault auth enable cert
vault write auth/cert/certs/concourse policies=concourse certificate=@/vault/certs/ca.pem ttl=1h

vault write concourse/homelab/ops_manager \
  decryption_passphrase=@/vault/secrets/passphrase.txt \
  fqdn="ops-manager.diggity00.net" \
  password=@/vault/secrets/passphrase.txt \
  user="admin"

vault write concourse/homelab/tile_config \
  pivnet_refresh_token=@/vault/secrets/pivnet.token \
  scp_private_key=@/vault/secrets/ssh_private_key.pem \
  tas_ssl_cert=@/vault/certs/cert.pem \
  tas_ssl_key=@/vault/certs/key.pem

vault write concourse/homelab/vcenter \
  password=@/vault/secrets/passphrase.txt \
  url="https://vc01.diggity00.net" \
  user="administrator@diggity00.net"
