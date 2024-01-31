#!/usr/bin/env bash

BATS_TEMP_DIR="/tmp/bats-$(uuidgen)"
BATS_RESOURCE_TEMP_DIR=''

_test_resource_dir() {
  echo "${BATS_TEST_DIRNAME}/resources/$(basename $BATS_TEST_FILENAME)"
}

_common_setup() {
  mkdir -p $BATS_TEMP_DIR
#  export BATS_MOCK_BINDIR="${BATS_TEMP_DIR}/bin"
#  export BATS_MOCK_TMPDIR="${BATS_TEMP_DIR}/mock"
  # get the containing directory of this file
  # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
  # as those will point to the bats executable's location or the preprocessed file respectively
  DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
  # make executables in src/ visible to PATH
  PATH="$DIR/../src:$PATH"
  load 'test_helper/bats-support/load' # this is required by bats-assert!
  load 'test_helper/bats-assert/load'
  load 'helpers/mocks/stub'
  load 'test_helper/argument_captor'
  # Remove this to prevent failing based on past failures and not cleaning the mocks
#  rm -rf "${BATS_MOCK_BINDIR}"
#  mkdir -p "${BATS_MOCK_BINDIR}"
  local test_resource_dir=$(_test_resource_dir)
  if [ -d $test_resource_dir ]; then
    cp -r $test_resource_dir $BATS_TEMP_DIR
    BATS_RESOURCE_TEMP_DIR="${BATS_TEMP_DIR}/$(basename $test_resource_dir)"
    ls $BATS_RESOURCE_TEMP_DIR
    # gets removed because it is in $BATS_TEMP_DIR
  fi
}

_common_teardown() {
  echo "Cleanup...."
   rm -rf $BATS_TEMP_DIR
}
