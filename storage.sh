#!/bin/bash
set -eu
set -o pipefail

# Enviroment variable PROVIDER=['azure'|'openstack']: Selects the storage provider
# Functions provided
# - function uploadBlob(container, file): Uploads from stdin
# - function downloadBlob(container, file, targetFile): Downloads blob to target file
# - function duplicityUrl(container): Echos the url to use for duplicity


if [ "$PROVIDER" == "azure" ]; then
  export ACCOUNT_NAME=`cat /etc/azure/accountName`
  export ACCOUNT_KEY=`cat /etc/azure/accountKey`
  #for duplicity
  export AZURE_ACCOUNT_NAME="$ACCOUNT_NAME"
  export AZURE_ACCOUNT_KEY="$ACCOUNT_KEY"

  # Parameters: <container> <file>
  function uploadBlob {
    cat > "$TMPDIR/upload"
    cat | blobporter -t file-blockblob -c "$1" -n "$2" -f "$TMPDIR/upload"
    rm "$TMPDIR/upload"
  }

  # Parameters: <container> <file> <target file>
  function downloadBlob {
    pushd "$TMPDIR"
    blobporter -e -t blob-file -c "$1" -n "$2" -f "$3"
    mv "$TMPDIR/$2" $3
    popd
  }

  # Parameters: <container>
  function duplicityUrl {
    echo "azure://$1"
  }

#############################################################
elif [ "$PROVIDER" == "openstack" ]; then
  export OS_AUTH_URL=`cat /etc/openstack/authUrl`
  export OS_PROJECT_ID=`cat /etc/openstack/projectId`
  export OS_PROJECT_NAME=`cat /etc/openstack/projectName`
  export OS_REGION_NAME=`cat /etc/openstack/regionName`
  export OS_INTERFACE=`cat /etc/openstack/interface`
  export OS_IDENTITY_API_VERSION=`cat /etc/openstack/identityApiVersion`
  export OS_USERNAME=`cat /etc/openstack-user/user`
  export OS_PASSWORD=`cat /etc/openstack-user/password`
  export SWIFT_USERNAME=${OS_PROJECT_NAME}:${OS_USERNAME}
  export SWIFT_PASSWORD="${OS_PASSWORD}"
  export SWIFT_AUTHURL="${OS_AUTH_URL}"
  export SWIFT_AUTHVERSION="${OS_IDENTITY_API_VERSION}"
  export SWIFT_REGIONNAME="${OS_REGION_NAME}"
  export SWIFT_TENANTID="${OS_PROJECT_ID}"

  # Parameters: <container> <file>
  function uploadBlob {
    swift upload --object-name "$2" "$1" -
  }

  # Parameters: <container> <file> <target file>
  function downloadBlob {
    swift download "$1" "$2" -o "$3"
  }

  # Parameters: <container>
  function duplicityUrl {
    echo "swift://$1"
  }

#############################################################
else
  echo "Unknown storage provider: $PROVIDER"
  exit 1
fi
