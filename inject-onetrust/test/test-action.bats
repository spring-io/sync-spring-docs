setup () {
  load 'test_helper/common-setup'
  _common_setup
}

# executed after each test
teardown() {
    _common_teardown
}

@test "no arguments" {
    run action.sh
    assert [ "$status" -eq 1 ]
    assert_regex "${lines[0]}" 'Error: Missing option .*'
    assert [ "${lines[1]}" = 'usage: action.sh [OPTION]...' ]
}

@test "usage" {
    run action.sh
    assert [ "$status" -eq 1 ]
    assert [ "${output}" = "Error: Missing option '--docs-dir'
usage: action.sh [OPTION]...

   --docs-dir=DIR              the directory to search for html files and inject the onetrust code above </head>" ]
}

@test "invalid long option" {
    run action.sh --invalid
    assert [ "$status" -eq 1 ]
    assert [ "${lines[0]}" = "getopt: unrecognized option '--invalid'" ]
    assert [ "${lines[1]}" = 'usage: action.sh [OPTION]...' ]
}

@test "injects into html files only" {
    local docs_dir="${BATS_RESOURCE_TEMP_DIR}/docs"
    local expected_dir="${BATS_RESOURCE_TEMP_DIR}/expected-docs"
    local tmp_actual_filename=/tmp/actual.txt
    local tmp_expected_filename=/tmp/expected.txt
    run action.sh --docs-dir $docs_dir
    assert_success
    find $expected_dir -type f | while read expected_file; do
        local actual_file=$(echo $expected_file | sed "s#$expected_dir#$docs_dir#")
        echo "$expected_file vs $actual_file (diff $tmp_expected_filename and $tmp_actual_filename )"
        cat $expected_file > $tmp_expected_filename
        cat $actual_file > $tmp_actual_filename
        assert_equal "$(cat $expected_file)" "$(cat $actual_file)"
    done
}