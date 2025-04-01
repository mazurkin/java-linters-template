#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
set -o monitor
set -o noglob

# print banner
echo "Using additional JAVA options: ${JAVA_OPTIONS}"
echo "Using JMX host and port: ${JMX_HOST}:${JMX_PORT}"

# calculate current directory
ENV_DIR=$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")
declare -r ENV_DIR

# search for all JAR libraries and compose an array of paths
readarray -d '' JAR_LIB_PATHS < <(find "${ENV_DIR}/../lib" -maxdepth 1 -type f -name "*.jar" -print0)
declare -r JAR_LIB_PATHS

# compose classpath library list
for JAR_LIB_PATH in "${JAR_LIB_PATHS[@]}"
do
    JAVA_CLASSPATH="${JAVA_CLASSPATH}:${JAR_LIB_PATH}"
done
declare -r JAVA_CLASSPATH

# application name
APP_NAME="linters"
declare -r APP_NAME

# stamp
APP_STAMP=$(date '+%Y%m%d-%H%M%S')
declare -r APP_STAMP

# directories
DIR_APP_CONF="/etc/${APP_NAME}"
declare -r DIR_APP_CONF
test -d "${DIR_APP_CONF}"

DIR_APP_ROOT="/opt/${APP_NAME}"
declare -r DIR_APP_ROOT
test -d "${DIR_APP_ROOT}"

DIR_APP_LIB="/var/lib/${APP_NAME}"
declare -r DIR_APP_LIB
mkdir -p "${DIR_APP_LIB}"

DIR_APP_LOG="/var/log/${APP_NAME}"
declare -r DIR_APP_LOG
mkdir -p "${DIR_APP_LOG}"

DIR_APP_TMP="/tmp/${APP_NAME}"
declare -r DIR_APP_TMP
mkdir -p "${DIR_APP_TMP}"

DIR_JVM_LOG="${DIR_APP_LOG}/jvm"
declare -r DIR_JVM_LOG
mkdir -p "${DIR_JVM_LOG}"

DIR_JVM_DUMP="${DIR_APP_LOG}/dump"
declare -r DIR_JVM_DUMP
mkdir -p "${DIR_JVM_DUMP}"

# temporary directory for this script (default `/tmp` might be read-only)
export TMPDIR="${DIR_APP_TMP}"

# common JVM options
# https://docs.oracle.com/en/java/javase/11/tools/java.html#GUID-3B1CE181-CD30-4178-9602-230B800D4FAE
declare -a JAVA_OPTIONS_COMMON

# Option control
JAVA_OPTIONS_COMMON+=("-XX:+UnlockDiagnosticVMOptions")
JAVA_OPTIONS_COMMON+=("-XX:+UnlockExperimentalVMOptions")
JAVA_OPTIONS_COMMON+=("-XX:+UseContainerSupport")

# Print JVM configuration
JAVA_OPTIONS_COMMON+=("-XshowSettings:all")
JAVA_OPTIONS_COMMON+=("-XX:+PrintFlagsFinal")

# VM reporting
JAVA_OPTIONS_COMMON+=("-XX:+LogVMOutput")
JAVA_OPTIONS_COMMON+=("-XX:LogFile=${DIR_JVM_LOG}/vm.log")
JAVA_OPTIONS_COMMON+=("-XX:ErrorFile=${DIR_JVM_LOG}/error%p.log")

# VM heap dump
JAVA_OPTIONS_COMMON+=("-XX:+ExitOnOutOfMemoryError")
JAVA_OPTIONS_COMMON+=("-XX:-HeapDumpOnOutOfMemoryError")
JAVA_OPTIONS_COMMON+=("-XX:HeapDumpPath=${DIR_JVM_DUMP}/${APP_STAMP}.hprof")

# Memory settings
JAVA_OPTIONS_COMMON+=("-XX:MaxDirectMemorySize=4G")
JAVA_OPTIONS_COMMON+=("-XX:+AlwaysPreTouch")
JAVA_OPTIONS_COMMON+=("-XX:+UseCompressedOops")

# GC logging
# https://blog.jayan.kandathil.ca/gc_logging_in_java11.html
# https://blog.codefx.org/java/unified-logging-with-the-xlog-option/
JAVA_OPTIONS_COMMON+=("-Xlog:gc:file=${DIR_JVM_LOG}/gc.log:time,uptime:filecount=3,filesize=1m")
JAVA_OPTIONS_COMMON+=("-Xlog:safepoint:file=${DIR_JVM_LOG}/safepoint.log:time,uptime:filecount=3,filesize=1m")

# Exceptions
JAVA_OPTIONS_COMMON+=("-XX:+OmitStackTraceInFastThrow")

# Hacks
JAVA_OPTIONS_COMMON+=("-Djava.security.egd=file:/dev/./urandom")

# Network
JAVA_OPTIONS_COMMON+=("-Djava.net.preferIPv4Stack=true")
JAVA_OPTIONS_COMMON+=("-Dnetworkaddress.cache.ttl=600")
JAVA_OPTIONS_COMMON+=("-Dnetworkaddress.cache.negative.ttl=600")

# SUN network internals
JAVA_OPTIONS_COMMON+=("-Dsun.net.client.defaultConnectTimeout=30000")
JAVA_OPTIONS_COMMON+=("-Dsun.net.client.defaultReadTimeout=30000")
JAVA_OPTIONS_COMMON+=("-Dsun.net.http.retryPost=false")

# JMX & RMI
JAVA_OPTIONS_COMMON+=("-Djava.rmi.server.hostname=${JMX_HOST}")
JAVA_OPTIONS_COMMON+=("-Dcom.sun.management.jmxremote")
JAVA_OPTIONS_COMMON+=("-Dcom.sun.management.jmxremote.port=${JMX_PORT}")
JAVA_OPTIONS_COMMON+=("-Dcom.sun.management.jmxremote.rmi.port=${JMX_PORT}")
JAVA_OPTIONS_COMMON+=("-Dcom.sun.management.jmxremote.authenticate=false")
JAVA_OPTIONS_COMMON+=("-Dcom.sun.management.jmxremote.ssl=false")
JAVA_OPTIONS_COMMON+=("-Dcom.sun.management.jmxremote.local.only=false")

# Logging
JAVA_OPTIONS_COMMON+=("-Dlog4j2.configurationFile=${DIR_APP_CONF}/log4j2.xml")
JAVA_OPTIONS_COMMON+=("-Dlog4j2.formatMsgNoLookups=true")

# JVM paths
JAVA_OPTIONS_COMMON+=("-Djava.io.tmpdir=${DIR_APP_TMP}")

# JVM timezone & locale & country
JAVA_OPTIONS_COMMON+=("-Duser.timezone=America/New_York")
JAVA_OPTIONS_COMMON+=("-Duser.country=US")
JAVA_OPTIONS_COMMON+=("-Duser.language=en")

declare -r JAVA_OPTIONS_COMMON
