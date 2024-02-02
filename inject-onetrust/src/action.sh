#!/bin/bash

__action_usage() {
  echo "usage: action.sh [OPTION]...

   --docs-base-dir=DIR              the directory to search for html files and inject the onetrust code above </head>
"
}


__action_usage_error() {
  echo "Error: $1" >&2
  __action_usage
  exit 1
}

__action() {
    local script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
    local onetrust_include_path="${script_dir}/onetrust.include"
    local docs_directory
    valid_args=$(getopt --options '' --long docs-dir: -- "$@")
    if [[ $? -ne 0 ]]; then
      __action_usage
      exit 1;
    fi

    eval set -- "$valid_args"

    while [ : ]; do
    case "$1" in
      --docs-dir)
          docs_directory="$2"
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

    if [ -z "$docs_directory" ]; then
      __action_usage_error "Missing option '--docs-dir'"
    fi
    find $docs_directory -name "*.html" | while read html_filename; do
        echo $html_filename
        # https://learnbyexample.github.io/learn_gnused/adding-content-from-file.html#insert-file-using-e-and-cat
        sed -i -e '/<\/head>/e cat '$onetrust_include_path $html_filename
    done
}


__action "$@"