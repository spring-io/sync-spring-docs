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
    echo "----"
    echo "$output"
    echo "----"

    assert [ "$status" -eq 1 ]
    assert [ "${output}" = "Error: Missing option '--artifactory-username'
usage: action.sh [OPTION]...
    Downloads any zip files that have not been deployed yet and then marks them as deployed.

    --artifactory-host=HOST               the artifactory host to search (default repo.spring.vmware.com)
    --artifactory-username=USERNAME       the username used to artifactory
    --artifactory-password=PASSWORD       the password used to connect to artifactory
    --docs-base-dir=DOCS_BASE_DIR         the base directory to download zip files to. The complete directory is
                                          \$DOCS_BASE_DIR/\$ARTIFACT_NAME/\$ARTIFACT_VERSION which is created if does not exist" ]
}

@test "invalid long option" {
    run action.sh --invalid
    assert [ "$status" -eq 1 ]
    assert [ "${lines[0]}" = "getopt: unrecognized option '--invalid'" ]
    assert [ "${lines[1]}" = 'usage: action.sh [OPTION]...' ]
}

@test "missing artifactory-username" {
    run action.sh --artifactory-password password --docs-base-dir /tmp/docs-base-dir
    assert [ "$status" -eq 1 ]
    assert [ "${lines[0]}" = "Error: Missing option '--artifactory-username'" ]
    assert [ "${lines[1]}" = 'usage: action.sh [OPTION]...' ]
}

@test "missing artifactory-password" {
    run action.sh --artifactory-username username --docs-base-dir /tmp/docs-base-dir
    assert [ "$status" -eq 1 ]
    assert [ "${lines[0]}" = "Error: Missing option '--artifactory-password'" ]
    assert [ "${lines[1]}" = 'usage: action.sh [OPTION]...' ]
}

@test "missing docs-base-dir" {
    run action.sh --artifactory-username username --artifactory-password password
    assert [ "$status" -eq 1 ]
    assert [ "${lines[0]}" = "Error: Missing option '--docs-base-dir'" ]
    assert [ "${lines[1]}" = 'usage: action.sh [OPTION]...' ]
}

@test "artifactory-host defaults" {
    stub curl "$(capture_program_args "curl");echo '{ \"results\": [ { \"uri\": \"https://repo.spring.vmware.com/artifactory/api/storage/libs-milestone-local/com/rabbitmq/http-client/1.0.0.M1/http-client-1.0.0.M1-docs.zip\" } ] }'"
    stub curl "$(capture_program_args "curl")"
    stub mkdir "$(capture_program_args "mkdir")"
    stub mkdir "$(capture_program_args "mkdir")"
    stub wget "$(capture_program_args "wget")"
    stub unzip "$(capture_program_args "unzip")"
    stub rm "$(capture_program_args "rm")"

    run action.sh --artifactory-username username --artifactory-password password --docs-base-dir /tmp/docs-base-dir

    unstub curl
    unstub mkdir
    unstub wget
    unstub unzip
    unstub rm

    assert_success
    assert_program_args "curl" "-s -H Content-type: application/json -H Content-Length: 0 -H Accept: application/json --user username:password https://repo.spring.vmware.com/api/search/prop?zip.type=docs&zip.deployed=false
-X PUT -H Content-type: application/json -H Content-Length: 0 -H Accept: application/json --user username:password https://repo.spring.vmware.com/artifactory/api/storage/libs-milestone-local/com/rabbitmq/http-client/1.0.0.M1/http-client-1.0.0.M1-docs.zip?properties=zip.deployed=true"
    assert_program_args "mkdir" "-p downloads
-p docs/http-client/1.0.0.M1"
    assert_program_args "wget" "--http-user=username --http-password=password --quiet -O downloads/http-client-1.0.0.M1-docs.zip https://repo.spring.vmware.com/artifactory/libs-milestone-local/com/rabbitmq/http-client/1.0.0.M1/http-client-1.0.0.M1-docs.zip"
    assert_program_args "unzip" "-q -o downloads/http-client-1.0.0.M1-docs.zip -d docs/http-client/1.0.0.M1"
    assert_program_args "rm" "-f downloads/http-client-1.0.0.M1-docs.zip"
}

@test "artifactory-host repo.spring.io" {
    stub curl "$(capture_program_args "curl");echo '{ \"results\": [ { \"uri\": \"https://repo.spring.io/artifactory/api/storage/libs-milestone-local/com/rabbitmq/http-client/1.0.0.M1/http-client-1.0.0.M1-docs.zip\" } ] }'"
    stub curl "$(capture_program_args "curl")"
    stub mkdir "$(capture_program_args "mkdir")"
    stub mkdir "$(capture_program_args "mkdir")"
    stub wget "$(capture_program_args "wget")"
    stub unzip "$(capture_program_args "unzip")"
    stub rm "$(capture_program_args "rm")"

    run action.sh --artifactory-username username --artifactory-password password --docs-base-dir /tmp/docs-base-dir --artifactory-host repo.spring.io

    unstub curl
    unstub mkdir
    unstub wget
    unstub unzip
    unstub rm

    assert_success
    assert_program_args "curl" "-s -H Content-type: application/json -H Content-Length: 0 -H Accept: application/json --user username:password https://repo.spring.io/api/search/prop?zip.type=docs&zip.deployed=false
-X PUT -H Content-type: application/json -H Content-Length: 0 -H Accept: application/json --user username:password https://repo.spring.io/artifactory/api/storage/libs-milestone-local/com/rabbitmq/http-client/1.0.0.M1/http-client-1.0.0.M1-docs.zip?properties=zip.deployed=true"
    assert_program_args "wget" "--http-user=username --http-password=password --quiet -O downloads/http-client-1.0.0.M1-docs.zip https://repo.spring.io/artifactory/libs-milestone-local/com/rabbitmq/http-client/1.0.0.M1/http-client-1.0.0.M1-docs.zip"
}