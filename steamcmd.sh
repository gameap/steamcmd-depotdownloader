#!/usr/bin/env bash

 shopt -s dotglob

[ "${DEBUG:-}" == 'true' ] && set -x

export DEBIAN_FRONTEND="noninteractive"

trap ctrl_c INT

function ctrl_c() {
    echo
    echo "Exiting..."
    echo
    exit 130
}

EXE_PATH="$(dirname -- "${BASH_SOURCE[0]}")"

optionAppID=""
optionDir=""
optionUsername=""
optionPassword=""
optionValidate="0"

_parse_options ()
{
    while [[ $# -gt 0 ]]; do
      case "$1" in
        +app_update)
          optionAppID=$2
          shift 2
          ;;
        +force_install_dir)
            optionDir=$2
            shift 2
            ;;
        +login)
          optionUsername=$2
          optionPassword=$3
          shift 3
          ;;
        validate)
          optionValidate="1"
          shift
      esac
    done
}

_install_depotdownloader ()
{
  echo "Installing DepotDownloader..."

  if ! curl -SfL https://github.com/SteamRE/DepotDownloader/releases/download/DepotDownloader_2.4.7/depotdownloader-2.4.7.zip \
    --output "${EXE_PATH}/depotdownloader.zip"; then
      echo "Failed to download DepotDownloader" >> /dev/stderr
      exit 1
  fi

  if ! unzip "${EXE_PATH}/depotdownloader.zip" -d "${EXE_PATH}/depotdownloader"; then
    echo "Failed to unpack DepotDownloader" >> /dev/stderr
    exit 1
  fi

  if ! rm "${EXE_PATH}/depotdownloader.zip"; then
    echo "Failed to remove depotdownloader.zip" >> /dev/stderr
  fi

}

_install_dotnet ()
{
  echo "Installing dotnet..."

  if ! curl -SfL https://download.visualstudio.microsoft.com/download/pr/265a56e6-bb98-4b17-948b-bf9884ee3bb3/e2a2587b9a964d155763b706dffaeb8b/dotnet-sdk-6.0.406-linux-x64.tar.gz \
    --output "${EXE_PATH}/dotnet.tar.gz"; then
      echo "Failed to download dotnet" >> /dev/stderr
      exit 1
  fi

  if ! tar -xvf dotnet.tar.gz; then
    echo "Failed to unpack dotnet" >> /dev/stderr
    exit 1
  fi

  if ! rm "${EXE_PATH}/dotnet.tar.gz"; then
    echo "Failed to remove dotnet.tar.gz" >> /dev/stderr
  fi
}

_main ()
{
  if [[ -z ${optionAppID} ]]; then
    echo "Empty APP ID" >> /dev/stderr
    exit 1
  fi

  if [[ -z ${optionDir} ]]; then
    echo "Empty Installation directory" >> /dev/stderr
    exit 1
  fi

  echo "appID: ${optionAppID}"
  echo "dir: ${optionDir}"
  echo "username: ${optionUsername}"
  echo "validate: ${optionValidate}"

  if [[ ! -d "${EXE_PATH}/depotdownloader" ]]; then
    _install_depotdownloader
  fi

  if [[ ! -d "${EXE_PATH}/dotnet" ]]; then
    _install_dotnet
  fi

  declare -a depotdownloaderArgs

  depotdownloaderArgs+=("-app ${optionAppID}")
  depotdownloaderArgs+=("-dir ${optionDir}")

  if [[ ! -z ${optionUsername} ]]; then
    depotdownloaderArgs+=("-username ${optionUsername}")
    depotdownloaderArgs+=("-password ${optionPassword}")
  fi

  if [[ ${optionsValidate} == "1" ]]; then
    depotdownloaderArgs+=("-validate")
  fi

  # echo "${EXE_PATH}/dotnet/dotnet ${EXE_PATH}/depotdownloader/DepotDownloader.dll ${depotdownloaderArgs[*]}"

  if ! "${EXE_PATH}/dotnet/dotnet" "${EXE_PATH}/depotdownloader/DepotDownloader.dll" "${depotdownloaderArgs[@]}"; then
    echo "Failed to execute depotdownloader" >> /dev/stderr
    exit 1
  fi
}

_parse_options "$@"
_main