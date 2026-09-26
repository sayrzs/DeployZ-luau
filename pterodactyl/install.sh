#!/bin/bash
# DeployZ-luau installer. Runs in the Pterodactyl install container.
set -e
apt-get update -qq && apt-get install -y -qq curl unzip git ca-certificates > /dev/null

mkdir -p /mnt/server && cd /mnt/server

# Lune runtime
ARCH=$(uname -m); [ "$ARCH" = "aarch64" ] || ARCH="x86_64"
LUNE_VERSION=${LUNE_VERSION:-0.10.4}
curl -sSL -o /tmp/lune.zip "https://github.com/lune-org/lune/releases/download/v${LUNE_VERSION}/lune-${LUNE_VERSION}-linux-${ARCH}.zip"
unzip -o -q /tmp/lune.zip -d /tmp/lune && mv -f /tmp/lune/lune ./lune && chmod +x ./lune

# DeployZ code: server code is always updated, user files are only created if missing
rm -rf /tmp/deployz
git clone -q --depth 1 -b "${GIT_BRANCH:-main}" "${GIT_REPO:-https://github.com/sayrzs/DeployZ-luau}" /tmp/deployz
rm -rf ./src && cp -r /tmp/deployz/src /tmp/deployz/deployz.luau /tmp/deployz/README.md ./
[ -f config.json ] || cp /tmp/deployz/config.json ./
[ -d webroot ] || cp -r /tmp/deployz/webroot ./
[ -d sites ] || cp -r /tmp/deployz/sites ./

echo "DeployZ-luau installed (Lune ${LUNE_VERSION}, ${ARCH})"
