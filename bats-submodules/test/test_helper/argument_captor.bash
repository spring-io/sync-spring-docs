__get_program_path() {
  if [ -z "$BATS_TEMP_DIR" ]; then
    echo "Ensure to set \$BATS_TEMP_DIR"
    exit 1
  fi
  local program="$1"
  if [ -z "$program" ]; then
    echo "Missing argument: program"
    exit 1
  fi
  echo "${BATS_TEMP_DIR}/${program}"
}

__get_capture_path() {
  echo "$(__get_program_path $1)-args"
}

__get_stdin_capture_path() {
  echo "$(__get_program_path $1)-sdin"
}

capture_program() {
  echo "$(capture_program_args $1); $(capture_program_stdin $1)"
}

capture_program_args() {
  local path=$(__get_capture_path "$1")
  echo "echo \${@} >> $path"
}

capture_program_stdin() {
  local path=$(__get_stdin_capture_path "$1")
  echo "while read -r l; do echo \$l >> $path; done"
}

get_program_args() {
  local path="$(__get_capture_path "$1")"
  echo "$(cat ${path})"
}

assert_program_args() {
  local args="$(get_program_args $1)"
  assert [ "$args" = "$2" ]
}

get_program_stdin() {
  local path=$(__get_stdin_capture_path "$1")
  echo "$(cat ${path})"
}