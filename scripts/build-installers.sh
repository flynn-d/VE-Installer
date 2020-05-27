#!/bin/bash

# This builds (and publishes) the .zip installers - they go straight
# into the www folder

# First the online installer, which will pull the R packages from the
# visioneval installation server

# Must be in "build" folder (parent of "scripts") to start
# Take advantage of shell variable and make variable syntax being identical

# Expecting the RTools version of "zip"

# Must specify whether to build the (time-consuming) SOURCE installer
# or the more modest BINARY installer (for the current platform)
if [[ $# -eq 0 || ( $1 != "BINARY" && $1 != "SOURCE" ) ]]; then
  echo Must specify installer type BINARY or SOURCE as first argument
  exit 1
else
  INSTALLER_TYPE=$1
fi

# Look at second argument for VE_R_VERSION, or use environment if not set
VE_R_VERSION=${2:-${VE_R_VERSION}}
if [ -z "${VE_R_VERSION}" ]; then
  echo "VE_R_VERSION is not available from environment or as second argument to script"
  exit 1
fi

if [ -z "${VE_MAKEVARS}" ]; then
  echo VE_MAKEVARS environment variable should locate ve-output.${VE_R_VERSION}.make
  VE_MAKEVARS="${PWD}/logs/${VE_R_VERSION}/ve-output.make" # use absolute path
  echo Using "${VE_MAKEVARS}"
fi

OLD_R_VERSION=${VE_R_VERSION}
. ${VE_MAKEVARS} # loads VE_OUTPUT, VE_RUNTIME, VE_PLATFORM
if [ "${OLD_R_VERSION}" != "${VE_R_VERSION}" ]; then
  # Technically this should be impossible since the interior VE_R_VERSION in ve-output
  # should be the same as what is encoded in its name; but you never know!
  echo "VE_R_VERSION provided ($OLD_R_VERSION) does not match built R version ($VE_R_VERSION)"
  exit 2
fi

# !!!! Attempt 2020-05-26 to fix /Use/User... problem
#if [ "${VE_PLATFORM}" != "Windows" ]; then
#  # Fix for Macintosh (or less likely, Linux) to get the absolute path if VE_OUTPUT starts with ".."
#  VE_OUTPUT=$(echo $VE_OUTPUT | sed s@../@$(dirname ${PWD})/@)
#fi

VE_BUILD_DATE="(`date +%Y-%m-%d`)"
VE_BASE="${VE_OUTPUT}/${VE_R_VERSION}/VE-Runtime-R${VE_R_VERSION}${VE_BUILD_DATE}.zip"
VE_BINARY="${VE_OUTPUT}/${VE_R_VERSION}/VE-installer-${VE_PLATFORM}-R${VE_R_VERSION}${VE_BUILD_DATE}.zip"
if [ "${VE_PLATFORM}" == "Windows" ]
then
  VE_SOURCE="${VE_OUTPUT}/${VE_R_VERSION}/VE-installer-Source-R${VE_R_VERSION}${VE_BUILD_DATE}.zip"
else
  VE_SOURCE="${VE_BINARY}"
fi
RUNTIME_PATH="${VE_RUNTIME}"

cd "${RUNTIME_PATH}"

if [ "${INSTALLER_TYPE}" == "BINARY" ]
then

  echo "Building Runtime base installer: ${VE_BASE}"
  rm -f "${VE_BASE}"
  zip --recurse-paths "${VE_BASE}" . -x r-paths.bat -x '*.RData' -x '.Renviron' -x '.Rdata' -x '.Rhistory' -x '/.Rproj.user/*'
  echo "Built Runtime base installer: ${VE_BASE}"

  if [ "${VE_PLATFORM}" == "Windows"  ]
  then
    # Binary installer for Windows includes ve-lib
    if [ -d "${VE_LIB}" ]
    then
      echo "Building ${VE_PLATFORM} binary installer: ${VE_BINARY}"
      rm -f "${VE_BINARY}"
      cd ${VE_LIB}/..
      zip --recurse-paths "--output-file=${VE_BINARY}" "${VE_BASE}" "$(basename ${VE_LIB})"
    else
        echo "Missing package library: ${VE_LIB}"
        echo "Failed to build ${VE_SOURCE}"
    fi
    echo "Built ${VE_PLATFORM} ${INSTALLER_TYPE} installer: ${VE_BINARY}"
  fi

fi

if [ "${VE_PLATFORM}" == "MacOSX" -o "${INSTALLER_TYPE}" == "SOURCE" ]
then

  # Add ve-pkgs instead of ve-lib
  if [ -d "${VE_PKGS}" ]
  then
      echo "Building ${VE_PLATFORM} installer: ${VE_SOURCE}"
      echo "Package repository: ${VE_PKGS}"
      rm -f "${VE_SOURCE}"
      cd ${VE_PKGS}/..
      pwd
      zip --recurse-paths "--output-file=${VE_SOURCE}" "${VE_BASE}" "$(basename ${VE_PKGS})"
  else
      echo "Missing package repository: ${VE_PKGS}"
      echo "Failed to build ${VE_SOURCE}"
  fi
  echo "Built ${VE_PLATFORM} ${INSTALLER_TYPE} installer: ${VE_SOURCE}"

fi
echo "Done building installers."
