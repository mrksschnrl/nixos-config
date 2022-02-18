#!/bin/bash

set -euo pipefail

sudo -E nixos-rebuild switch --impure

COUNT=$(nix profile list | tail -n 1 | grep -o "^[0-9]*")
for i in $(seq 0 "$COUNT"); do
  NIXOS_ALLOW_UNFREE=1 nix profile upgrade "$i" --impure || echo "failed to upgrade $i"
done

