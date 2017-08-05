#!/bin/bash

# Assumption: You have followed the instructions at http://bit.ly/2ub5Vq0

# Adjust the following variables as necessary
TEMP="/var/www/html/TechnicSolder/public/temp"
MODS="/var/www/html/TechnicSolder/public/mods"
WWWUSER="www-data"

function isYn {
  if [ ${#1} -gt 1 ]; then
    echo "I only need one character!"
    echo "y or n"
    echo "Exiting ..."
    echo
    exit
  fi
}

function exitIfNull {
  if [ "${1}" == "" ]; then
    echo "Null response detected."
    echo "Exiting ..."
    echo
    exit
  fi
}

re='^[0-9]+$'
if [[ "${1}" -gt 0 ]]; then
  if ! [[ ${1} =~ $re ]] ; then
    clear
    echo "error: first argument is not a valid menu choice" >&2; exit 1
    echo
  fi
fi
if [[ "${1}" -lt 1 || "${1}" -gt 5 ]]; then
  echo "Pack Type:"
  echo
  echo "1. Standard Mod"
  echo "2. Lite Mod"
  echo "3. Config Pack"
  echo " - You must have uploaded all configs in"
  echo " the structure required by the mod to"
  echo " the TEMP path"
  echo "4. Forge Jar"
  echo "5. Minecraft Root"
  echo " - servers.dat, options.txt etc. ..."
  echo
  read -rp "CHOICE: " CHOICE
  if [[ $CHOICE -lt 1 || $CHOICE -gt 5 ]]; then
    echo "Invalid Choice!"
    echo "Please choose a number from 1-5"
    echo "Exiting ..."
    echo
    exit
  fi
else
  # we received the menu entry at the command line
  CHOICE="${1}"
fi
case $CHOICE in
  1) STRUCTURE="mods"
    TARGET="mods"
  ;;
  2) STRUCTURE="mods/1.8"
    TARGET="mods"
  ;;
  3) STRUCTURE="config"
    TARGET="config"
  ;;
  4) STRUCTURE="bin"
    TARGET="bin"
    FILENAM="modpack.jar"
  ;;
  5) STRUCTURE=""
    TARGET="*"
  ;;
esac

if [ "${2}" == "" ]; then
  # modslug not given at command line, let's get it now
  read -rp "MODSLUG=" MODSLUG
  exitIfNull "${MODSLUG}"
else
  #THE %/ is what removes the trailing slash
  MODSLUG="${2%/}"
fi

if [ "${3}" == "" ]; then
  read -rp "VERSION=" VERSION
  exitIfNull "${VERSION}"
else
  VERSION="${3}"
fi

if [ "${4}" == "" ]; then
  read -rp "Is mod in temp? (y/n) " LOCATION
  exitIfNull "${LOCATION}"
  isYn "${LOCATION}"
  if [ "${LOCATION}" = "n" ]; then
    read -rp "MODLINK=" MODLINK
    exitIfNull "${MODLINK}"

    if [ "${FILENAM}" == "" ]; then
      read -rp "Generate filename? (y/n)" GENFILE
      exitIfNull "${GENFILE}"
      isYn "${GENFILE}"
      if [[ "${GENFILE}" =~ ^(y|Y)$ ]]; then
        FILENAM="${MODSLUG}-${VERSION}.jar"
      fi
    fi
  else
    LOCATION="TEMP"
    read -rp "Is there more than one part in Temp for ${MODSLUG}? (y/n) " CHOICE
    exitIfNull "${CHOICE}"
    isYn "${CHOICE}"
    if [[ "${CHOICE}" =~ ^(y|Y)$ ]]; then
      PAT="*"
    fi
  fi
else
  MODLINK="${4}"
  if [ "${FILENAM}" == "" ]; then
    if [ "${5}" == "" ]; then
      # no filename on command line so gen one now
      # because if we are doing this many options via
      # cli then why not!?
      FILENAM="${MODSLUG}-${VERSION}.jar"
    fi
  fi
fi

if [ "${FILENAM}" = "" ]; then
  if [ "${5}" != "" ]; then
    FILENAM="${5}"
  fi
fi

if [ "${PAT}" == "" ]; then
  if [ "${FILENAM}" == "" ]; then
    read -rp "FILENAM=" FILENAM
    exitIfNull "${FILENAM}"
  fi
fi

MODPATH="${MODSLUG}/${STRUCTURE}"
mkdir -p "${MODPATH}" # creates the entire directory path as needed; supresses standard errors

cd "${MODPATH}" || exit $?
#the mods directory should actually be empty
rm -f "*"
if [ "${LOCATION}" = "TEMP" ]; then
  if [ "${STRUCTURE}" != "" ]; then #root archive if true, leave it in temp
    if [ "${PAT}" = "*" ]; then
      mv "${TEMP}/${PAT}" .
    else
      if [ -e "${TEMP}/${FILENAM}" ]; then
        mv "${TEMP}/${FILENAM}" .
      else
        echo "Error locating ..."
        echo "${TEMP}/${FILENAM}"
        echo "Exiting ..."
        exit
      fi
    fi
  fi
else
  wget "${MODLINK}" -O "${FILENAM}"
fi

cd "${MODS}/${MODSLUG}" || exit $?

ZIPFILE="${MODSLUG}-${VERSION}.zip"
if [ -e "${ZIPFILE}" ]; then
  # prevent multiple copies of a same or similar mod
  # based on the mod you are zipping for in the event
  # you are remaking the mod archive with the same
  # ZIPFILE name
  clear
  echo "You are duplicating your efforts, ${ZIPFILE} already exists!!!"
  echo "I'm not doing this, if you insist on doing this, change the version number!"
  echo "Conversely you should probably take a break!"
  exit
fi

# Zip options:
# -r recurse into directories
# -m move file into zipfile
if [ "${TARGET}" == "*" ]; then
  # this is a root archive operation
  # we'll be working from the master temp folder
  # and move the completed zipfile to its proper
  # home afterwords
  if [ "${STRUCTURE}" = "" ]; then # root archive
    cd "${TEMP}" || exit $?
    zip -rm "${ZIPFILE}" "*"
    mv "${ZIPFILE}" "${MODS}/${MODSLUG}/"
  else
    zip -rm "${ZIPFILE}" "*"
  fi
else
  zip -rm "${ZIPFILE}" "${TARGET}"
fi

cd "${MODS}" || exit $?
chown -R "${WWWUSER}:${WWWUSER}" "${MODSLUG}"

clear
echo "Modslug=${MODSLUG}"
echo "Filename=${FILENAM}"
echo "Version=${VERSION}"
if [ "${MODLINK}" != "" ]; then
  echo "Modlink=${MODLINK}"
  echo
  echo "./newMod.sh ${MODLINK} ${FILENAM}"
  echo
fi
