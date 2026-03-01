#!/bin/bash

set -e

source dev-container-features-test-lib

extract_single_checksum() {
    local checksums_file="$1"
    local binary_name="$2"
    local target_entry="./${binary_name}"
    local expected_matches
    local match_count

    expected_matches=$(awk -v target="$target_entry" '$2 == target { print $1 }' "$checksums_file")
    match_count=$(printf '%s\n' "$expected_matches" | awk 'NF { c++ } END { print c+0 }')

    if [ "$match_count" -eq 0 ]; then
        return 2
    fi

    if [ "$match_count" -gt 1 ]; then
        return 3
    fi

    if ! [[ "$expected_matches" =~ ^[a-f0-9]{64}$ ]]; then
        return 4
    fi

    printf '%s\n' "$expected_matches"
}

normalize_version_tag() {
    local requested_version="$1"

    if [[ "$requested_version" =~ ^[0-9] ]]; then
        printf 'v%s\n' "$requested_version"
    else
        printf '%s\n' "$requested_version"
    fi
}

is_valid_version_tag() {
    local version_tag="$1"
    [[ "$version_tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

TMP_DIR=$(mktemp -d /tmp/mise-negative-cases-XXXXXXXX)
trap 'rm -rf "$TMP_DIR"' EXIT

BINARY_NAME="mise-v2026.2.23-linux-arm64"
CHECKSUM_A="82de2280004a50714112ed21c20ef430b3d004a044a7bce5abd4e0860605ccd9"
CHECKSUM_B="b67d6a0a4f0a373638a194a213e4f2f659a6ef22c155749f881d98a67f071582"

export -f extract_single_checksum normalize_version_tag is_valid_version_tag
export TMP_DIR BINARY_NAME CHECKSUM_A CHECKSUM_B

check "invalid version format is rejected" bash -c '
  version_tag=$(normalize_version_tag "invalid-version")
  ! is_valid_version_tag "$version_tag"
'

check "numeric version is normalized and valid" bash -c '
  version_tag=$(normalize_version_tag "2026.2.23")
  [ "$version_tag" = "v2026.2.23" ]
  is_valid_version_tag "$version_tag"
'

check "missing checksum entry is rejected" bash -c '
  cat > "$TMP_DIR/missing.asc" <<EOF
${CHECKSUM_A}  ./mise-v2026.2.23-linux-x64
EOF
  set +e
  extract_single_checksum "$TMP_DIR/missing.asc" "$BINARY_NAME" >/dev/null 2>&1
  code=$?
  set -e
  [ "$code" -eq 2 ]
'

check "duplicate checksum entries are rejected" bash -c '
  cat > "$TMP_DIR/duplicate.asc" <<EOF
${CHECKSUM_A}  ./${BINARY_NAME}
${CHECKSUM_B}  ./${BINARY_NAME}
EOF
  set +e
  extract_single_checksum "$TMP_DIR/duplicate.asc" "$BINARY_NAME" >/dev/null 2>&1
  code=$?
  set -e
  [ "$code" -eq 3 ]
'

check "single checksum entry is accepted" bash -c '
  cat > "$TMP_DIR/valid.asc" <<EOF
${CHECKSUM_A}  ./${BINARY_NAME}
EOF
  output=$(extract_single_checksum "$TMP_DIR/valid.asc" "$BINARY_NAME")
  [ "$output" = "${CHECKSUM_A}" ]
'

reportResults
