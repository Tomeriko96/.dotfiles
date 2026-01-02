#!/bin/bash
set -euo pipefail

# Install R and related development libraries (Debian/Ubuntu)
R_PACKAGES=(
  r-base
  libfreetype6-dev
  libpng-dev
  libtiff5-dev
  libjpeg-dev
  libwebp-dev
  libxml2-dev
  libssl-dev
  libcurl4-openssl-dev
  libfontconfig1-dev
  libharfbuzz-dev
  libfribidi-dev
)

sudo apt update
sudo apt install -y "${R_PACKAGES[@]}"

echo "R and related libraries installed."
