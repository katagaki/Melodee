#!/bin/bash
set -euo pipefail

# Xcode Cloud's user script sandbox can prevent the in-build "Generate
# Licenses" phase from writing Melodee/Licenses.plist before the Resources
# phase copies it. Run the same generator here so the file exists in the
# source tree before xcodebuild starts.

cd "$CI_PRIMARY_REPOSITORY_PATH"

xcodebuild -resolvePackageDependencies \
    -project Melodee.xcodeproj \
    -scheme Melodee \
    -derivedDataPath "$CI_DERIVED_DATA_PATH"

# generate_licenses.sh derives the SourcePackages path from
# ${BUILD_DIR%Build/*}SourcePackages/checkouts, so point BUILD_DIR at
# $CI_DERIVED_DATA_PATH/Build/ to land on $CI_DERIVED_DATA_PATH/SourcePackages/checkouts.
export SRCROOT="$CI_PRIMARY_REPOSITORY_PATH"
export BUILD_DIR="$CI_DERIVED_DATA_PATH/Build/"

"$CI_PRIMARY_REPOSITORY_PATH/Scripts/generate_licenses.sh"
