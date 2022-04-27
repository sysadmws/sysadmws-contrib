#!/usr/bin/env bash
die() {
        echo "ERROR: $*"; exit 1
}

[[ ! $(pwd) =~ ^/var/www/[^/]+/app ]] && die "Not in \"app\" dir"

set -x

aext="gz"
pma_tar_mask="all-languages.tar.${aext}"        # all-languages.tar.gz
pma_tar_name="pma_${pma_tar_mask}"              # pma_all-languages.tar.gz
pma_tar_abspath="/tmp/${pma_tar_name}"          # /tmp/pma_all-languages.tar.gz
pma_dl_list_url="https://www.phpmyadmin.net/downloads/list.txt"

find "${pma_tar_abspath}" -cmin +59 -exec rm -f {} \;  # delete if file older than 1 hour

if [[ ! -e ${pma_tar_abspath} ]]; then
        URL="$(curl "${pma_dl_list_url}" 2> /dev/null | grep "${pma_tar_mask}")"
        wget --output-document="${pma_tar_abspath}" "${URL}"
fi


pushd ./src || die "Can't pushd to ./src"
  rm -r ./*
  tar xf "${pma_tar_abspath}" -C ./

  pma_dir_name=(phpMyAdmin*)

  [[ "${#pma_dir_name[@]}" -gt 1 ]] && die "There is more than one phpmyadmin dir in src"
  [[ ! -d ${pma_dir_name}        ]] && die "There is no phpmyadmin dir in src"

  mv ./"${pma_dir_name}"/* ./
  rm -r ./"${pma_dir_name}"
  cp config.sample.inc.php config.inc.php
  sed -i '/blowfish_secret/d' config.inc.php
  echo "\$cfg['blowfish_secret'] = '$(openssl rand -base64 48)';" >> config.inc.php
popd
