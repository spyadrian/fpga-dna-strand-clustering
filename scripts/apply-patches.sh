#!/usr/bin/env bash

set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"

git -C "$repo_root/external/oneoligo" reset --hard
mkdir "$repo_root/external/oneoligo/build"
git -C "$repo_root/external/oneoligo" apply "$repo_root/patches/oneoligo-local.patch"
