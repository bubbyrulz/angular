#!/usr/bin/env bash

set -u -e -o pipefail

# Setup environment
readonly thisDir=$(cd $(dirname $0); pwd)
source ${thisDir}/_travis-fold.sh


# If the previous commands in the `script` section of .travis.yaml failed, then abort.
# The variable is not set in early stages of the build, so we default to 0 there.
# https://docs.travis-ci.com/user/environment-variables/
if [[ ${TRAVIS_TEST_RESULT=0} == 1 ]]; then
  exit 1;
fi

# No build needed for bazel or aio docs tests
if [[ ${CI_MODE:-} == "bazel" || ${CI_MODE:-} == "docs_test" ]]; then
  exit 0;
fi

# Build the Angular packages
if [[ ${CI_MODE:-} == "aio_local" || ${CI_MODE:-} == "aio_e2e" || ${CI_MODE:-} == "aio_tools_test" ]]; then
  travisFoldStart "build.packages.$CI_MODE"
  (
    ./build.sh --examples=false
  )
  travisFoldEnd "build.packages.$CI_MODE"

  # Exit if no further build required
  if [[ ${CI_MODE:-} == "aio_e2e" || ${CI_MODE:-} == "aio_tools_test" ]]; then
    exit 0;
  fi
fi

# Build angular.io, then exit (no further build required)
if [[ ${CI_MODE:-} == "aio" || ${CI_MODE:-} == "aio_local" ]]; then
  travisFoldStart "build.aio"
  (
    cd "`dirname $0`/../../aio"
    yarn $([[ ${CI_MODE} == "aio" ]] && echo "build" || echo "build-local")
  )
  travisFoldEnd "build.aio"
  exit 0;
fi

travisFoldStart "tsc tools"
  $(npm bin)/tsc -p tools
  $(npm bin)/tsc -p packages/compiler/tsconfig-tools.json
  $(npm bin)/tsc -p packages/compiler-cli/tsconfig-tools.json
travisFoldEnd "tsc tools"


travisFoldStart "tsc all"
  node dist/tools/@angular/compiler-cli/src/main -p packages/tsconfig-metadata.json
  $(npm bin)/tsc -p packages
  $(npm bin)/tsc -p packages/examples
  $(npm bin)/tsc -p modules
travisFoldEnd "tsc all"
