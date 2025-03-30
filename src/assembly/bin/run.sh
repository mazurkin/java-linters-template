#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
set -o monitor
set -o noglob

# calculate current directory
SCRIPT_DIR=$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")
declare -r SCRIPT_DIR

# include common options and settings
# shellcheck source=src/assembly/bin/env.sh
source "${SCRIPT_DIR}/env.sh"

# declare local JVM options
declare -a JAVA_OPTIONS_LOCAL
JAVA_OPTIONS_LOCAL+=("-Xms1G")
JAVA_OPTIONS_LOCAL+=("-Xmx1G")
JAVA_OPTIONS_LOCAL+=("-XX:+UseG1GC")
JAVA_OPTIONS_LOCAL+=("-XX:MaxGCPauseMillis=5")
declare -r JAVA_OPTIONS_LOCAL

# declare external JVM options ($JAVA_OPTIONS is a space-delimited set of JVM options)
read -r -a JAVA_OPTIONS_EXTERNAL <<< "${JAVA_OPTIONS}"
declare -r JAVA_OPTIONS_EXTERNAL

# run JVM process
exec "${JAVA_HOME}/bin/java" \
    "${JAVA_OPTIONS_COMMON[@]}" \
    "${JAVA_OPTIONS_LOCAL[@]}" \
    "${JAVA_OPTIONS_EXTERNAL[@]}" \
    -cp "${JAVA_CLASSPATH}" \
    com.github.mazurkin.Application \
    "$@"
