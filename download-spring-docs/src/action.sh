#!/bin/bash

__action_usage() {
  echo "usage: action.sh [OPTION]...
    Downloads any zip files that have not been deployed yet and then marks them as deployed.

    --artifactory-host=HOST               the artifactory host to search (default repo.spring.vmware.com)
    --artifactory-username=USERNAME       the username used to artifactory
    --artifactory-password=PASSWORD       the password used to connect to artifactory
    --docs-base-dir=DOCS_BASE_DIR         the base directory to download zip files to. The complete directory is
                                          \$DOCS_BASE_DIR/\$ARTIFACT_NAME/\$ARTIFACT_VERSION which is created if does not exist
"
}


__action_usage_error() {
  echo "Error: $1" >&2
  __action_usage
  exit 1
}

__action() {
  local artifactory_host='repo.spring.vmware.com'
  local artifactory_username artifactory_password docs_base_dir
  valid_args=$(getopt --options '' --long artifactory-host:,artifactory-username:,artifactory-password:,docs-base-dir: -- "$@")
  if [[ $? -ne 0 ]]; then
    __action_usage
    exit 1;
  fi

  eval set -- "$valid_args"

  while [ : ]; do
    case "$1" in
      --artifactory-host)
        artifactory_host="$2"
        shift 2
        ;;
      --artifactory-username)
        artifactory_username="$2"
        shift 2
        ;;
      --artifactory-password)
        artifactory_password="$2"
        shift 2
        ;;
      --docs-base-dir)
        docs_base_dir="$2"
        shift 2
        ;;
      --) shift;
        break
        ;;
      *)
        __action_usage_error "Invalid argument $1 $2"
        ;;
    esac
  done

  if [ -z "$artifactory_host" ]; then
    __action_usage_error "Missing option '--artifactory-host'"
  fi
  if [ -z "$artifactory_username" ]; then
    __action_usage_error "Missing option '--artifactory-username'"
  fi
  if [ -z "$artifactory_password" ]; then
    __action_usage_error "Missing option '--artifactory-password'"
  fi
  if [ -z "$docs_base_dir" ]; then
    __action_usage_error "Missing option '--docs-base-dir'"
  fi
  local download_dir=downloads
  local docs_base_dir=docs
  local get_docs_to_download_uri="https://${artifactory_host}/api/search/prop?zip.type=docs&zip.deployed=false"
  mkdir -p $download_dir
  echo "Getting Downloads from $get_docs_to_download_uri"
  # Use same headers that existed in the original script
  # https://jfrog.com/help/r/jfrog-rest-apis/property-search
  curl -s -H 'Content-type: application/json' -H 'Content-Length: 0' -H 'Accept: application/json' --user "$artifactory_username:$artifactory_password" "$get_docs_to_download_uri" | jq -r '.results | .[].uri' | while read uri; do
    # split by / into uri_parts array
    IFS='/' read -r -a uri_parts <<< "$uri"
    local file_name="${uri_parts[-1]}"
    local project_version="${uri_parts[-2]}"
    local project_name="${uri_parts[-3]}"
    local download_url=$(echo $uri | sed 's#/api/storage##')
    local download_file_path="${download_dir}/${file_name}"
    wget --http-user=$artifactory_username --http-password=$artifactory_password -O "$download_file_path" $download_url
    local unzip_dir="${docs_base_dir}/${project_name}/${project_version}"
    mkdir -p $unzip_dir
    unzip -o $download_file_path -d $unzip_dir
    rm -f $download_file_path
    local mark_deployed_url="${uri}?properties=zip.deployed=true"
    curl -X PUT -H 'Content-type: application/json' -H 'Content-Length: 0' -H 'Accept: application/json' --user "$artifactory_username:$artifactory_password" $mark_deployed_url
  done
  echo "Done getting docs"
}


__action "$@"