#!/bin/bash
#
# Ensure all QML modules are pulled in so that the test for valid plugin.qmltypes can be executed

set -o nounset
set -o pipefail

DIR=$(dirname "$0")
SELF=$(basename "$0")
SPEC=$DIR/sdk-harbour-rpmvalidator.spec
CHECK=$DIR/../sdk-tests/check-qml-typeinfo.py
ALLOWED_QMLIMPORTS=$DIR/../allowed_qmlimports.conf
MARK_BEGIN_RE='^# --auto-test-requires-BEGIN--$'
MARK_END_RE='^# --auto-test-requires-END--$'

fatal()
{
    echo "$SELF: $*" >&2
}

list_requires()
{
    "$CHECK" --allowed_qmlimports "$ALLOWED_QMLIMPORTS" list-caps \
             |sed 's/^/Requires: /'
}

if ! grep -e "$MARK_BEGIN_RE" -q "$SPEC"; then
    fatal "No BEGIN-mark in the .spec file"
    exit 1
fi

if ! grep -e "$MARK_END_RE" -q "$SPEC"; then
    fatal "No END-mark in the .spec file"
    exit 1
fi

temp=$(mktemp) || exit
trap 'rm -f "$temp"' EXIT

{
    sed -n "1,/$MARK_BEGIN_RE/p" "$SPEC" || exit
    echo "# Autogenerated by ./$SELF - do not edit manually" || exit
    list_requires || exit
    sed -n "/$MARK_END_RE/,\$p" "$SPEC" || exit
} > "$temp" || exit

mv "$temp" "$SPEC"