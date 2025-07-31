#!/bin/bash

clear 

# === STATIC PARAMETERS ===
COMMAND="setup-server"
RUDDER_VERSION="8.3"
SERVER="$(hostname -f)"
PLUGINS="all"
SERVER_IP=$(hostname -I | awk '{print $1}')

# === PROMPT ===

# Ask for username
read -p "Enter a username to be used as Rudder admin: " RUDDER_ROOT_USER

# Ask for password
while true; do
  read -s -p "Enter '$RUDDER_ROOT_USER' password (leave empty to auto-generate): " RUDDER_ROOT_PASS
  echo
  read -s -p "Re-enter password (leave empty to confirm auto-generation): " RUDDER_ROOT_PASS_CONFIRM
  echo

  if [ "$RUDDER_ROOT_PASS" != "$RUDDER_ROOT_PASS_CONFIRM" ]; then
    echo "Passwords do not match. Try again."
  else
    break
  fi
done

# Auto-generate password if empty
if [ -z "$RUDDER_ROOT_PASS" ]; then
  RUDDER_ROOT_PASS=$(openssl rand -base64 12)
  echo "Auto-generated password for '$RUDDER_ROOT_USER': $RUDDER_ROOT_PASS"
fi





# === ORIGINAL SCRIPT ===

set -e

# Documentation !
usage() {
  echo "Usage $0 (add-repository|setup-agent|setup-relay|setup-server|upgrade-agent|upgrade-relay|upgrade-server) <rudder_version> [<policy_server>] ['<plugins>']"
  echo "  Adds a repository and setup rudder on your OS"
  echo "  Should work on as many OS as possible"
  echo "  Currently supported : Debian, Ubuntu, RHEL, Fedora, Centos, Amazon, Oracle, SLES, Slackware"
  echo ""
  echo "  rudder_version : x.y or x.y.z or x.y-nightly or ci/x.y or lts or latest"
  echo "       x.y:            the latest x.y release (ex: 3.2)"
  echo "       x.y.z:          the exact x.y.z release (ex: 3.2.1)"
  echo "       x.y.z~a:        the latest x.y.z pre-release where a can be alpha1, beta1, rc1... (ex: 4.0.0~rc1) "
  echo "       x.y-nightly:    the latest public x.y nightly build (ex: 3.2-nightly)"
  echo "       ci/x.y.z:       the latest development x.y.z release build (ex: ci/3.2.16)"
  echo "       ci/x.y.z~a:     the latest development x.y.z pre-release build (ex: ci/4.0.0~rc1)"
  echo "       ci/x.y-nightly: the latest development x.y nightly build (ex: ci/5.1-nightly)"
  echo "       latest:         the latest stable version"
  echo ""
  echo "  plugins: 'all' or a list of plugin names between ''"
  echo "  plugin_version: '', 'nightly', 'ci', 'ci/nightly' (see below)"
  echo ""
  echo "  Environment variables"
  echo "    USE_HTTPS=true          use https in repository source (default true)"
  echo "    PLUGINS_VERSION=...     download nightly or ci version of plugins"
  echo "    DOWNLOAD_USER=...       download from private repository with this user"
  echo "    DOWNLOAD_PASSWORD=...   use this password for private repository"
  echo "    FORGET_CREDENTIALS=true remove credentials after installing plugins and licenses"
  echo "    DEV_MODE=true           permit external access to server and databases (default false)"
  echo "    ADMIN_PASSWORD=...      create an administrator user 'admin' with the given password"
  echo "    ADMIN_USER=...          change administrator user name"
  exit 1
}
# GOTO bottom for main()

ISRG_ROOT_X1="-----BEGIN CERTIFICATE-----
MIIFazCCA1OgAwIBAgIRAIIQz7DSQONZRGPgu2OCiwAwDQYJKoZIhvcNAQELBQAw
TzELMAkGA1UEBhMCVVMxKTAnBgNVBAoTIEludGVybmV0IFNlY3VyaXR5IFJlc2Vh
cmNoIEdyb3VwMRUwEwYDVQQDEwxJU1JHIFJvb3QgWDEwHhcNMTUwNjA0MTEwNDM4
WhcNMzUwNjA0MTEwNDM4WjBPMQswCQYDVQQGEwJVUzEpMCcGA1UEChMgSW50ZXJu
ZXQgU2VjdXJpdHkgUmVzZWFyY2ggR3JvdXAxFTATBgNVBAMTDElTUkcgUm9vdCBY
MTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAK3oJHP0FDfzm54rVygc
h77ct984kIxuPOZXoHj3dcKi/vVqbvYATyjb3miGbESTtrFj/RQSa78f0uoxmyF+
0TM8ukj13Xnfs7j/EvEhmkvBioZxaUpmZmyPfjxwv60pIgbz5MDmgK7iS4+3mX6U
A5/TR5d8mUgjU+g4rk8Kb4Mu0UlXjIB0ttov0DiNewNwIRt18jA8+o+u3dpjq+sW
T8KOEUt+zwvo/7V3LvSye0rgTBIlDHCNAymg4VMk7BPZ7hm/ELNKjD+Jo2FR3qyH
B5T0Y3HsLuJvW5iB4YlcNHlsdu87kGJ55tukmi8mxdAQ4Q7e2RCOFvu396j3x+UC
B5iPNgiV5+I3lg02dZ77DnKxHZu8A/lJBdiB3QW0KtZB6awBdpUKD9jf1b0SHzUv
KBds0pjBqAlkd25HN7rOrFleaJ1/ctaJxQZBKT5ZPt0m9STJEadao0xAH0ahmbWn
OlFuhjuefXKnEgV4We0+UXgVCwOPjdAvBbI+e0ocS3MFEvzG6uBQE3xDk3SzynTn
jh8BCNAw1FtxNrQHusEwMFxIt4I7mKZ9YIqioymCzLq9gwQbooMDQaHWBfEbwrbw
qHyGO0aoSCqI3Haadr8faqU9GY/rOPNk3sgrDQoo//fb4hVC1CLQJ13hef4Y53CI
rU7m2Ys6xt0nUW7/vGT1M0NPAgMBAAGjQjBAMA4GA1UdDwEB/wQEAwIBBjAPBgNV
HRMBAf8EBTADAQH/MB0GA1UdDgQWBBR5tFnme7bl5AFzgAiIyBpY9umbbjANBgkq
hkiG9w0BAQsFAAOCAgEAVR9YqbyyqFDQDLHYGmkgJykIrGF1XIpu+ILlaS/V9lZL
ubhzEFnTIZd+50xx+7LSYK05qAvqFyFWhfFQDlnrzuBZ6brJFe+GnY+EgPbk6ZGQ
3BebYhtF8GaV0nxvwuo77x/Py9auJ/GpsMiu/X1+mvoiBOv/2X/qkSsisRcOj/KK
NFtY2PwByVS5uCbMiogziUwthDyC3+6WVwW6LLv3xLfHTjuCvjHIInNzktHCgKQ5
ORAzI4JMPJ+GslWYHb4phowim57iaztXOoJwTdwJx4nLCgdNbOhdjsnvzqvHu7Ur
TkXWStAmzOVyyghqpZXjFaH3pO3JLF+l+/+sKAIuvtd7u+Nxe5AW0wdeRlN8NwdC
jNPElpzVmbUq4JUagEiuTDkHzsxHpFKVK7q4+63SM1N95R1NbdWhscdCb+ZAJzVc
oyi3B43njTOQ5yOf+1CceWxG1bQVs5ZufpsMljq4Ui0/1lvh+wjChP4kqKOJ2qxq
4RgqsahDYVvTH9w7jXbyLeiNdd8XM2w9U/t7y0Ff/9yi0GE44Za4rF2LN9d11TPA
mRGunUHBcnWEvgJBQl9nJEiU0Zsnvgc/ubhPgXRR4Xq37Z0j4r7g1SgEEzwxA57d
emyPxgcYxn/eR44/KJ4EBs+lVDR3veyJm+kXQ99b21/+jh5Xos1AnX5iItreGCc=
-----END CERTIFICATE-----
"

# use local or typeset to define a local variable
setlocal() {
  if eval typeset x=1 2>/dev/null
  then
    local="typeset"
  elif eval local x=1 2>/dev/null
  then
    local="local"
  else
    # unsupported
    return 1
  fi
}

# reexcute current script with another shellif we can find one
re_exec()
{
  for shell in bash /opt/csw/bin/bash
  do
    if exists "$shell"
    then
      exec "$shell" "$0" "$@"
    fi
  done
  # no supported shell stop here
  print "I need a fully posix shell please find me one"
  exit 255
}

# return true if the command exists
exists() {
  if type  "$1" >/dev/null 2>/dev/null
  then
    return 0
  else
    return 1
  fi
}

# Reimplement which (taken from 10_ncf_internals/list-compatible-inputs)
which() {
  $local name="$1"
  $local IFS_SAVE="$IFS"
  IFS=:
  for directory in $PATH
  do
    if [ -x "${directory}/${name}" ]
    then
      echo "${directory}/${name}"
      IFS="$IFS_SAVE"
      return 0
    fi
  done
  IFS="$IFS_SAVE"
  return 1
}

# get a remote url content using the first available method
get() {
  WGET="wget -q -O"
  CURL="curl -s -f -o"
  if type curl >/dev/null 2>/dev/null
  then
    ${CURL} "$@"
  elif type wget >/dev/null 2>/dev/null
  then
    ${WGET} "$@"
  elif [ "$1" = "-" ]
  then
    perl -MLWP::UserAgent -e '$r=LWP::UserAgent->new()->get(shift);if($r->is_success()){print $r->content()}else{exit 1}' "$2"
  else
    perl -MLWP::UserAgent -e '$r=LWP::UserAgent->new()->get(shift);if($r->is_success()){print $r->content()}else{exit 1}' "$2" > "$1"
  fi
}

has_ssl() {
  URL="https://www.rudder-project.org/release-info/"
  WGET="wget -O /dev/null"
  CURL="curl -s -f -o /dev/null"
  if type apt-cache >/dev/null 2>/dev/null
  then
    # libgnutls <=26 is known to fail
    if apt-cache pkgnames libgnutls2 | grep -q 'libgnutls2[0-6]'
    then
      return 1
    fi
  fi
  if type curl >/dev/null 2>/dev/null
  then
    curl -s -f -o /dev/null "${URL}" || ret=$?
    if [ -n "${ret}" ] && [ ${ret} -eq 35 ]; then
      return 1
    elif [ -n "${ret}" ] && [ ${ret} -eq 60 ]; then
      echo "${ISRG_ROOT_X1}" > /usr/local/share/ca-certificates/isrg_root_x1.crt
      update-ca-certificates
      return 0
    else
      return 0
    fi
  fi
  if type wget >/dev/null 2>/dev/null
  then
    if wget -O /dev/null "${URL}" 2>&1 | grep -q "SSL23_GET_SERVER_HELLO:tlsv1 alert protocol version"; then
      return 1
    elif wget -O /dev/null "${URL}" 2>&1 | grep -q "GnuTLS: A TLS fatal alert has been received."; then
      return 1
    else
      return 0
    fi
  fi
  return 1
}

# run a service using the first available method
service_cmd() {
  if [ -x "/etc/init.d/$1" ]
  then
    name="$1"
    shift
    "/etc/init.d/${name}" "$@"
  elif exists systemctl
  then
    name="$1"
    cmd="$2"
    shift 2
    systemctl "${cmd}" "${name}" "$@"
  elif exists service
  then
    service "$@"
  elif exists startsrc
  then
    name="$1"
    cmd="$2"
    shift 2
    if [ "${cmd}" = "start" ]; then
      startsrc -s "${name}"
    elif [ "${cmd}" = "stop" ];then
      stopsrc -s "${name}"
    else
      echo "Don't know how to manage service $@"
    fi
  else
    echo "Don't know how to manage service $@"
  fi
}

release_file() {
  $local rf_distro="$1"
  $local rf_release_file="$2"
  $local rf_regex="$3"
  if [ ! -f "${rf_release_file}" ]; then return 1; fi
  OS_NAME="${rf_distro}"
  OS_VERSION=`sed -n "/${rf_regex}/s/${rf_regex}/\\1/p" ${rf_release_file}`
}

os_release_file() {
  $local os_release="$1"
  if [ ! -f "${os_release}" ]; then return 1; fi
  OS_NAME=`grep "^NAME=" ${os_release} | sed s/NAME=//g | sed s/\"//g | cut -d' ' -f1`
  OS_VERSION=`grep "^VERSION=" ${os_release} | sed s/VERSION=//g | sed s/\"//g | cut -d' ' -f1`
}

# output example
#
#OS_NAME=Centos
#OS_COMPATIBLE=RHEL
#OS_VERSION=7.2014_sp3
#OS_COMPATIBLE_VERSION=7.0
#OS_MAJOR_VERSION=7
#
#PM=apt
#PM_INSTALL="DEBIAN_FRONTEND=noninteractive apt-get -y install"

detect_os() {
  # defaults values
  OS_NAME="unknown"
  OS_COMPATIBLE=""
  OS_VERSION=""
  OS_COMPATIBLE_VERSION=""
  PM=""
  PM_INSTALL="echo Your package manager is not yet supported"
  PM_UPGRADE="echo Your package manager is not yet supported"
  PM_LOCAL_INSTALL="echo Your package manager is not yet supported for local install"

  # detect package manager
  ########################
  # TODO macports, homebrew, portage
  if exists apt-get
  then
    PM="apt"
    export DEBIAN_FRONTEND=noninteractive
    release_opt=$(apt-get --version | head -n1 | perl -ne '/apt ([0-9]+\.[0-9]+)\..*/; if($1 > 1.5) { print "--allow-releaseinfo-change" }')
    PM_INSTALL="apt-get -y install"
    PM_UPDATE="apt-get -y update ${release_opt}"
    PM_UPGRADE="apt-get -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold -y install"
    PM_LOCAL_INSTALL="dpkg -i"
  elif exists yum
  then
    PM="yum"
    PM_INSTALL="yum -y install"
    PM_UPDATE="yum -y makecache"
    PM_UPGRADE="yum -y update"
    PM_LOCAL_INSTALL="rpm -i"
  elif exists zypper
  then
    PM="zypper"
    PM_INSTALL="zypper --non-interactive install"
    PM_UPDATE="zypper --non-interactive refresh"
    PM_UPGRADE="zypper --non-interactive update"
    PM_LOCAL_INSTALL="rpm -i"
  elif exists pkgadd
  then # solaris
    PM="pkg"
    PM_INSTALL="pkg install --accept"
    PM_UPDATE="true"
    PM_UPGRADE="pkg update --accept"
    PM_LOCAL_INSTALL="yes | pkgadd -d"
  elif exists slackpkg
  then
    PM="slackpkg"
    PM_INSTALL="slackpkg install"
    PM_UPDATE="slackpkg update"
    PM_UPGRADE="slackpkg install"
    PM_LOCAL_INSTALL="installpkg"
  fi

  # install lsb_release if required
  #################################

  if [ -e /etc/debian_version ]; then
    if ! dpkg -l lsb-release > /dev/null 2>/dev/null
    then
      echo "lsb-release is needed to detect debian derivative, installing it."
      ${PM_INSTALL} lsb-release
    fi
  fi

  # detect os and version
  #######################

  if [ "$(uname -s)" = "AIX" ]; then
    OS_NAME="AIX"
    # Format: Major.Minor (Ex: 5.3)
    OS_VERSION="$(uname -v).$(uname -r)"
    PM="rpm"
    PM_INSTALL="rpm -i"
    PM_UPGRADE="rpm -u"
  elif [ "$(uname -s)" = "SunOS" ] ; then
    . /etc/os-release
    OS_NAME="${ID}"
    OS_VERSION="${VERSION}"

  # try with lsb_release
  elif exists lsb_release; then
    OS_NAME=`lsb_release -is`
    OS_VERSION=`lsb_release -rs`
    OS_CODENAME=`lsb_release -cs`

  # manual detection adapted from FusionInventory lib/FusionInventory/Agent/Task/Inventory/Linux/Distro/NonLSB.pm
  elif release_file  'VMWare' '/etc/vmware-release' '.*\([0-9.]\+\).*'; then true
  elif release_file  'ArchLinux' '/etc/arch-release' '\(.*\)'; then true
  elif release_file  'Debian' '/etc/debian_version' '\(.*\)'; then
    if [  "${OS_VERSION}" = "jessie/sid" ]; then OS_VERSION=7; fi
  elif release_file  'Fedora' '/etc/fedora-release' '.*release \([0-9.]\+\)'; then true
  elif release_file  'Gentoo' '/etc/gentoo-release' '\(.*\)'; then true
  elif release_file  'Knoppix' '/etc/knoppix_version' '\(.*\)'; then true
  elif release_file  'Mandriva' '/etc/mandriva-release' '.*release \([0-9.]\+\).*'; then true
  elif release_file  'Mandrake' '/etc/mandrake-release' '.*release \([0-9.]\+\).*'; then true
  elif release_file  'Oracle' '/etc/oracle-release' '.*release \([0-9.]\+\).*'; then true
  elif release_file  'CentOS' '/etc/centos-release' '.*release \([0-9.]\+\).*'; then true
  elif release_file  'RedHat' '/etc/redhat-release' '.*release \([0-9.]\+\).*'; then true
  elif release_file  'Slackware' '/etc/slackware-version' '.*Slackware \(.*\).*'; then true
  elif release_file  'Trustix' '/etc/trustix-release' '.*release \([0-9.]\+\).*'; then true
  elif release_file  'SuSE' '/etc/SuSE-release' 'VERSION *= *\([0-9.]\+\).*'; then
    OS_VERSION="${OS_VERSION}-`sed -n '/PATCHLEVEL/s/PATCHLEVEL *= *\([0-9.]\+\).*/\1/p' /etc/SuSE-release`"
  elif release_file  'Amazon' '/etc/system-release-cpe' '[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:\([^:]*\).*'; then true

  elif os_release_file '/etc/os-release'; then true
  fi

  # Detect compatibility
  ######################
  OS_COMPATIBLE=`echo "${OS_NAME}" | tr '[a-z]' '[A-Z]'`
  OS_COMPATIBLE_VERSION="${OS_VERSION}"
  case "${OS_NAME}" in
    AIX)      OS_COMPATIBLE_VERSION=5;;
    RedHat)   OS_COMPATIBLE="RHEL" ;;
    RedHatEnterprise*) OS_COMPATIBLE="RHEL" ;;
    Oracle)   OS_COMPATIBLE="RHEL" ;;
    CentOS)   OS_COMPATIBLE="RHEL" ;;
    Amazon)   OS_COMPATIBLE="RHEL"
          if [ "${OS_VERSION}" = "2" ]; then
              OS_COMPATIBLE_VERSION=7
          elif [ "${OS_VERSION}" = "2023" ]; then
              OS_COMPATIBLE="AL"
              OS_COMPATIBLE_VERSION="2023"
          else
              OS_COMPATIBLE_VERSION=6
          fi;;
    SuSE)     OS_COMPATIBLE="SLES" ;;
    SUSE)     OS_COMPATIBLE="SLES" ;;
    "SLES")   OS_COMPATIBLE="SLES" ;;
    "SUSE LINUX")   OS_COMPATIBLE="SLES" ;;
    Raspbian) OS_COMPATIBLE="DEBIAN" ;;
  esac
  OS_MAJOR_VERSION=`echo "${OS_COMPATIBLE_VERSION}" | sed 's/[^0-9].*//'`

  # Package manager fixup
  #######################
  # Debian 6 gpg key has expired will not be updated anymore
  if [ "${OS_CODENAME}" = "squeeze" ]
  then
    PM_INSTALL="${PM_INSTALL} --allow-unauthenticated"
    PM_UPGRADE="${PM_UPGRADE} --allow-unauthenticated"
  fi

  export OS_NAME OS_COMPATIBLE OS_VERSION OS_COMPATIBLE_VERSION OS_MAJOR_VERSION PM PM_INSTALL
}



# version-spec = 5 / 5.1 / 5.1.5 / 5.1-rc3 / [5 7] / [5.1 7] / [5.1 *] / ... # [A B] means between A and B (A and B included)
#

# A component is a version element, components are separated by '.'
# echo the version component number $id (Nth component)
get_component() {
  $local version="$1"
  $local id="$2"
  echo "${version}" |
    sed -e 's/[^0-9a-zA-Z ]/ /g' | # use ' ' as a separator
    sed -e 's/\([0-9]\)\([^0-9]\)/\1 \2/g' | # separate after a number (23rc1 -> 23 rc1)
    sed -e 's/\([^0-9]\)\([0-9]\)/\1 \2/g' | # separate before a number (rc2 -> rc 2)
    sed -e 's/  */ /g' | # remove duplicate ' '
    cut -d' ' -f${id} # keep the one we want
}

# Return if a version component matches a specification component
# Operator can be "-le" "-eq" or "-ge"
# Return codes:
#  "no"  -> component doesn't match specification
#  "yes" -> component matches specification and is different from it
#  "continue" -> component is equal to specification (so you must check the next component)
component_cmp() {
  $local version_component="$1"
  $local operator="$2"
  $local spec_component="$3"
  $local alpha_version="`echo -n "${version_component}" | grep "[^0-9]" || true`"
  $local alpha_spec="`echo -n "${spec_component}" | grep "[^0-9]" || true`"
  if [ -z "${spec_component}" ] # no spec -> match
  then
    echo "yes"
  elif [ -z "${version_component}" ] # no version -> doesn't match
  then
    echo "no"
  elif [ -z "${alpha_spec}" ] && [ -z "${alpha_version}" ] # both are numeric
  then
    if [ "${version_component}" -eq "${spec_component}" ]  # go to next component if this one is equal
    then
      echo "continue"
    elif [ "${version_component}" "${operator}" "${spec_component}" ] # match
    then
      echo "yes"
    else # doesn't match
      echo "no"
    fi
  elif [ -z "${alpha_spec}" ] # numeric spec, alpha version -> version is strictly inferior to spec
  then
    if [ "${operator}" = "-le" ] # true only for "less than"
    then
      echo "yes"
    else
      echo "no"
    fi
  else # alpha spec (beta, rc, ...)
    if [ "${version_component}" = "${spec_component}" ] # same value -> continue
    then
      echo "continue"
    else
      # hack (alpha < beta < rc) but I see no better way for now
      [ "${operator}" = "-le" ] && op="<="
      [ "${operator}" = "-eq" ] && op="=="
      [ "${operator}" = "-ge" ] && op=">="
      echo "${version_component} ${spec_component}" | awk "{ if(\$1 ${op} \$2) print \"yes\"; else print \"no\" }"
    fi
  fi
}

# Return true if a version matches a specification
# Operator can be "-le" "-eq" or "-ge"
version_cmp() {
  $local version="$1"
  $local operator="$2"
  $local spec="$3"

  # comparison with * laways matches
  [ "${spec}" = "*" ] && return 0

  # Iterate over components and stop on first component not matching
  for i in 1 2 3 4 5 6 7 8 9 # maximum 9 components
  do
    $local version_component="`get_component "${version}" "${i}"`"
    $local spec_component="`get_component "${spec}" "${i}"`"

    # if we have a spec component, test against the matching one in version
    if [ -n "${spec_component}" ]
    then
      cmp="`component_cmp "${version_component}" "${operator}" "${spec_component}"`"
      if [ "${cmp}" = "yes" ]
      then
        return 0 # match
      elif [ "${cmp}" = "no" ]
      then
        return 1 # doesn't match
      else
        :        # go to next component
      fi
    else # given version is more precise than spec -> match
      return 0
    fi

  done
  # given version precisely equals spec or has more than 9 components -> match
  return 0
}

# Return true if the version is compatible with the version specification
# Parameters (version, version specification)
# Version spec is of the form [A B] : between A and B (A and B included)
is_version_valid() {
  $local version_isok="$1"
  $local specification="$2"
  $local v1="`echo "${specification}" | sed 's/[][]//g' | cut -d' ' -f1`"
  $local v2="`echo "${specification}" | sed 's/[][]//g' | cut -d' ' -f2`"
  if [ -z "${v2}" ]
  then
    version_cmp "${version_isok}" "-eq" "${v1}"
  else
    version_cmp "${version_isok}" "-ge" "${v1}" && version_cmp "${version_isok}" "-le" "${v2}"
  fi
}

# test function for component specification
test_component() {
  $local retval="$1"
  $local ret="`component_cmp "$2" "$3" "$4"`"
  if [ "${ret}" = "${retval}" ]
  then
    echo "$2 $3 $4 = $1 -> PASS"
  else
    echo "$2 $3 $4 = $1 -> ERROR"
  fi
}

# test function for version specification
test_spec() {
  $local retval=1
  if [ "$1" = "ok" ]
  then
    retval=0
  fi
  is_version_valid "$2" "$3"
  if [ $? -eq ${retval} ]
  then
    echo "$2 ~ $3 = $1 -> PASS"
  else
    echo "$2 ~ $3 = $1 -> ERROR"
  fi
}

# This is the test for version comparison
# This test acts as a definition of version specification
version_spec() {
  test_component continue 2 -le 2
  test_component yes 11 -le 12
  test_component no 12 -le 11
  test_component continue rc -le rc
  test_component yes beta -le rc
  test_component no beta -le alpha
  test_component continue 2 -eq 2
  test_component no 11 -eq 12
  test_component continue rc -eq rc
  test_component no beta -eq rc
  test_component continue 2 -ge 2
  test_component yes 12 -ge 11
  test_component no 11 -ge 12
  test_component continue rc -ge rc
  test_component no beta -ge rc
  test_component yes beta -ge alpha


  test_spec ok "2.11" "2.11"
  test_spec ok "2.11.2" "2.11"
  test_spec ok "2.11" "[2.11 2.12]"
  test_spec ok "2.12" "[2.11 2.12]"
  test_spec ok "2.12" "[2.11 3.1]"
  test_spec ok "2.11.2" "[2.11.1 2.11.3]"
  test_spec ok "2.11-rc1" "2.11"
  test_spec ok "2.11-rc1" "2.11-rc"
  test_spec ok "2.11" "[2.10 *]"
  test_spec ok "2.11" "[* 2.11]"
  test_spec ok "2.11.3" "[* 2.11]"
  test_spec ok "2.10-rc1" "[2.10-beta1 2.11]"
  test_spec ko "2.11" "2.11.2"
  test_spec ko "2.11-rc1" "2.11.1"
  test_spec ko "2.11" "[2.11.1 2.11.3]"
  test_spec ko "2.11-rc1" "[2.11.1 2.11.3]"
  test_spec ko "2.10" "2.11"
  test_spec ko "2.10-rc1" "[2.11.1 2.11.3]"
  test_spec ko "2.11" "[2.12 *]"
  test_spec ok "3.1" "[3.0 4.0]"
}


rudder_is_compatible() {
  $local ROLE="$1"
  # Remove the -suffix and only keep major version
  $local MAJOR_VERSION=$(echo "$2"| cut -d '-' -f 1 | cut -f 1-2 -d .)
  $local OS=$(echo "$3"|tr 'A-Z' 'a-z')
  if [ "${OS}" = "ubuntu" ] || [ "${OS}" = "slackware" ] ; then
    # Keep the part after the first dot for ubuntu and slackware versions, e.g. 14.04
    $local OS_VERSION=$(echo "$4"| cut -d '-' -f 1)
  else
    $local OS_VERSION=$(echo "$4"| cut -f 1 -d . | cut -d '-' -f 1)
  fi

  [ "${USE_HTTPS}" != "false" ] && S="s"
  if get - "http${S}://www.rudder-project.org/release-info/rudder/versions/${MAJOR_VERSION}/os/${OS}-${OS_VERSION}/roles" | grep "${ROLE}" >/dev/null
  then
    return 0
  else
    return 1
  fi
}

rudder_compatibility_check() {
  $local ROLE="$1"
  if [ "${UNSUPPORTED}" = "y" ] || [ "${USE_CI}" = "yes" ]  || [ "${PROTOTYPE}" = "yes" ]
  then
    return
  fi
  if ! rudder_is_compatible "${ROLE}" "${RUDDER_VERSION}" "${OS_COMPATIBLE}" "${OS_COMPATIBLE_VERSION}"
  then
    echo "Your installation: Rudder ${RUDDER_VERSION} ${ROLE} for ${OS_COMPATIBLE} - ${OS_COMPATIBLE_VERSION} is not supported."
    echo "Aborting."
    echo "export UNSUPPORTED=y to remove this check"
    exit 1
  fi
}

rudder_real_version() {
  $local version="`echo "$1" | tr '[A-Z]' '[a-z]'`"
  if [ "${version}" = "lts" ] || [ "${version}" = "latest" ]
  then
    [ "${USE_HTTPS}" != "false" ] && S="s"
    get - "http${S}://www.rudder-project.org/release-info/rudder/versions/${version}"
  else
    echo "${version}"
  fi
}

############################################
# Add rudder repository to package manager #
############################################
add_repo() {
  # if the version is a file or a URL stop here
  if [ -f "${RUDDER_VERSION}" ] || echo "${RUDDER_VERSION}" | grep "^http" > /dev/null
  then
    return
  fi

  # Make Repository URL
  [ "${PM}" = "apt" ] && REPO_TYPE="apt"
  [ "${PM}" = "yum" ] && REPO_TYPE="rpm"
  [ "${PM}" = "zypper" ] && REPO_TYPE="rpm"
  [ "${PM}" = "rpm" ] && REPO_TYPE="rpm"
  [ "${PM}" = "pkg" ] && REPO_TYPE="misc/solaris"
  [ "${PM}" = "slackpkg" ] && REPO_TYPE="misc/slackware"

  # old os that do not support TLS 1.2
  if [ "${OS_COMPATIBLE}" = "RHEL" -a $(echo "${OS_COMPATIBLE_VERSION}"|cut -d. -f1) -lt 6 ] ||
     [ "${OS_COMPATIBLE}" = "SLES" -a $(echo "${OS_COMPATIBLE_VERSION}"|cut -d. -f1) -lt 12 ]
  then
    USE_HTTPS="false"
  fi
  if [ "${USE_HTTPS}" != "false" ]; then
    S="s"
    if [ "${OS_COMPATIBLE}" = "UBUNTU" -a $(echo ${OS_COMPATIBLE_VERSION}|cut -d. -f1) -lt 20 ] ||
       [ "${OS_COMPATIBLE}" = "DEBIAN" -a $(echo ${OS_COMPATIBLE_VERSION}|cut -d. -f1) -lt 10 ]
    then
       ${PM_INSTALL} apt-transport-https
    fi
  else
    S=""
  fi

  # Add jdk repo on AL2
  if [ "${OS_NAME}" = "Amazon" ] && [ "${OS_VERSION}" = "2" ]; then
    amazon-linux-extras enable java-openjdk11
  fi

  # On sles we need to urlencode the password or if it contains special chars it won't be able to
  # add the repo

  if [ "${DOWNLOAD_USER}" = "" ]; then
    USER=""
  elif [ "${PM}" = "zypper" ]; then
    URLENCODED_PASSWORD=$(echo "${DOWNLOAD_PASSWORD}" | xxd -plain | tr -d '\n' | sed 's/\(..\)/%\1/g')
    USER="${DOWNLOAD_USER}:${URLENCODED_PASSWORD}@"
  elif [ "${OS_COMPATIBLE}" = "UBUNTU" -o "${OS_COMPATIBLE}" = "DEBIAN" ]; then
    USER=""
  else
    USER="${DOWNLOAD_USER}:${DOWNLOAD_PASSWORD}@"
  fi

  if [ "${USE_CI}" = "yes" ]
  then
    HOST="publisher.normation.com"
  else
    if [ "${DOWNLOAD_USER}" = "" ]; then
      HOST="repository.rudder.io"
    else
      HOST="${USER}download.rudder.io"
    fi
  fi
  URL_BASE="http${S}://${HOST}/${REPO_PREFIX}${REPO_TYPE}/${RUDDER_VERSION}"

  if [ "${PM}" = "yum" ] || [ "${PM}" = "rpm" ] || [ "${PM}" = "zypper" ]
  then
    URL_BASE="${URL_BASE}/${OS_COMPATIBLE}_${OS_MAJOR_VERSION}"
  elif [ "${PM}" = "pkg" ]
  then
    URL_BASE="${URL_BASE}/$(echo ${OS_COMPATIBLE} | tr '[:upper:]' '[:lower:]')-${OS_COMPATIBLE_VERSION}"
  fi

  RELEASE_GPG_KEY="http${S}://repository.rudder.io/rudder_release_key"
  APT_GPG_KEY="http${S}://repository.rudder.io/apt/rudder_apt_key"
  # RPM may use an old gpg key on old versions
  if is_version_valid "${RUDDER_VERSION}" "[8.3 *]"
  then
    RPM_GPG_KEY="${RELEASE_GPG_KEY}.pub"
  else
    RPM_GPG_KEY="http${S}://repository.rudder.io/rpm/rudder_rpm_key.pub"
  fi

  # add repository
  if [ "${PM}" = "apt" ]
  then
    if [ "${OS_COMPATIBLE}" = "UBUNTU" -a $(echo ${OS_COMPATIBLE_VERSION}|cut -d. -f1) -le 10 ] ||
       [ "${OS_COMPATIBLE}" = "DEBIAN" -a $(echo ${OS_COMPATIBLE_VERSION}|cut -d. -f1) -le 7 ]
    then
      # old Debian / Ubuntu like
      ${PM_INSTALL} -y --force-yes gnupg
      get - "${APT_GPG_KEY}.pub" | apt-key add -
    else
      # Debian / Ubuntu like
      get /etc/apt/trusted.gpg.d/rudder_release_key.gpg "${APT_GPG_KEY}.gpg"
    fi

    # force the default architecture
    dpkg_arch=$(dpkg --print-architecture)

    # the source configuration
    cat > /etc/apt/sources.list.d/rudder.list << EOF
deb [arch=${dpkg_arch}] ${URL_BASE}/ ${OS_CODENAME} main
EOF

    # source password
    if [ "${DOWNLOAD_USER}" != "" ]; then
      if [ "${OS_COMPATIBLE}" = "UBUNTU" -a $(echo ${OS_COMPATIBLE_VERSION}|cut -d. -f1) -lt 20 ] ||
         [ "${OS_COMPATIBLE}" = "DEBIAN" -a $(echo ${OS_COMPATIBLE_VERSION}|cut -d. -f1) -lt 10 ]
      then
        # old distro don't have an apt/auth.conf.d
        AUTH_CONF="/etc/apt/auth.conf"
      else
        AUTH_CONF="/etc/apt/auth.conf.d/rudder.conf"
      fi

      echo "machine download.rudder.io login ${DOWNLOAD_USER} password ${DOWNLOAD_PASSWORD}" >> "${AUTH_CONF}"
      chmod 640 ${AUTH_CONF}
    fi

    ${PM_UPDATE}
    return 0

  elif [ "${PM}" = "yum" ]
  then
    # Add RHEL like rpm repo
    cat > /etc/yum.repos.d/rudder.repo << EOF
[Rudder]
name=Rudder ${RUDDER_VERSION} Repository
baseurl=${URL_BASE}/
gpgcheck=1
gpgkey=${RPM_GPG_KEY}
EOF
    # CentOS 5 only supports importing keys from files
    get "/tmp/rudder_rpm_key.pub" "${RPM_GPG_KEY}"
    rpm --import "/tmp/rudder_rpm_key.pub"
    rm "/tmp/rudder_rpm_key.pub"
    return 0

  elif [ "${PM}" = "zypper" ]
  then
    cat > /tmp/rudder.repo << EOF
[Rudder]
enable=1
autorefresh=0
baseurl=${URL_BASE}/
type=rpm-md
EOF
    # Add SuSE repo
    # SLES11 only supports importing keys from files
    get "/tmp/rudder_rpm_key.pub" "${RPM_GPG_KEY}"
    rpm --import "/tmp/rudder_rpm_key.pub"
    rm "/tmp/rudder_rpm_key.pub"
    zypper removerepo Rudder || true
    zypper --non-interactive addrepo /tmp/rudder.repo || true
    ${PM_UPDATE}
    return 0
  elif [ "${PM}" = "rpm" ]
  then
    # No repo management, install directly
    return 0
  elif [ "${PM}" = "pkg" ]
  then
    pkg set-publisher -g "${URL_BASE}/" normation
    return 0
  elif [ "${PM}" = "slackpkg" ]
  then
    LOCALINSTALL_URL="${URL_BASE}/slackware-${OS_COMPATIBLE_VERSION}"
    return 0
  fi

  # TODO pkgng emerge pacman smartos
  echo "Sorry your Package Manager is not *yet* supported !"
  return 1
}

update_repo() {
  # nothing to update
  if [ "${RUDDER_VERSION}" = "" ]
  then
    return
  fi

  # if the version is a file or a URL stop here
  if [ -f "${RUDDER_VERSION}" ] || echo "${RUDDER_VERSION}" | grep "^http" > /dev/null
  then
    return
  fi

  if [ "${PM}" = "apt" ]
  then
    file=/etc/apt/sources.list.d/rudder.list
    REPO_TYPE="apt"
  elif [ "${PM}" = "yum" ]
  then
    file=/etc/yum.repos.d/rudder.repo
    REPO_TYPE="rpm"
    if is_version_valid "${RUDDER_VERSION}" "[8.3 *]"
    then
      NEW_GPG_KEY="http${S}://repository.rudder.io/rudder_release_key.pub"
      get "/tmp/rudder_rpm_key.pub" "${NEW_GPG_KEY}"
      rpm --import "/tmp/rudder_rpm_key.pub"
      sed -i "s%gpgkey=.*%gpgkey=${NEW_GPG_KEY}" "${file}"
    fi
  elif [ "${PM}" = "zypper" ]
  then
    file=/etc/zypp/repos.d/Rudder.repo
    REPO_TYPE="rpm"
    if is_version_valid "${RUDDER_VERSION}" "[8.3 *]"
    then
      NEW_GPG_KEY="http${S}://repository.rudder.io/rudder_release_key.pub"
      get "/tmp/rudder_rpm_key.pub" "${NEW_GPG_KEY}"
      rpm --import "/tmp/rudder_rpm_key.pub"
    fi
  elif [ "${PM}" = "pkg" ]
  then
    URL_BASE=$(LANG=C pkg publisher | grep ^normation | awk '{print $5}' | sed "s%misc/solaris/\(latest\|nightly\|[0-9.]\+\(-nightly\|~beta[0-9]\+\|~rc[0-9]\+\)\?\)/%misc/solaris/${RUDDER_VERSION}/%")
    pkg set-publisher -g "${URL_BASE}/" normation
    return
  elif [ "${PM}" = "slackpkg" ]
  then
    # slack repository are only used for Slackware distro itself
    # but we need the call to compute package URL
    add_repo
  else
    echo "Sorry your Package Manager is not *yet* supported !"
    return 1
  fi

  # The real edit
  sed -i "s%${REPO_TYPE}/\(latest\|nightly\|[0-9.]\+\(-nightly\|~beta[0-9]\+\|~rc[0-9]\+\)\?\)/%${REPO_TYPE}/${RUDDER_VERSION}/%" "${file}"

  if [ "${PM}" = "apt" ] || [ "${PM}" = "zypper" ]
  then
    ${PM_UPDATE}
  fi
}

remove_repo() {
  # if the version is a file or a URL stop here
  if [ -f "${RUDDER_VERSION}" ] || echo "${RUDDER_VERSION}" | grep "^http" > /dev/null
  then
    return
  fi

  if [ "${PM}" = "apt" ]
  then
    rm -f /etc/apt/sources.list.d/rudder.list
  elif [ "${PM}" = "yum" ]
  then
    rm -f /etc/yum.repos.d/rudder.repo
  elif [ "${PM}" = "zypper" ]
  then
    zypper removerepo Rudder || true
  elif [ "${PM}" = "pkg" ]
  then
    pkg unset-publisher normation
  fi
}

can_remove_repo() {
  if [ "${FORGET_CREDENTIALS}" = "true" ]
  then
    remove_repo
  fi
}

######################
# Setup rudder agent #
######################
setup_agent() {
  package="$1"
  [ -z "${package}" ] && package="rudder-agent"
  [ -z "${SERVER}" ] && SERVER="rudder"

  # Install via package manager only
  if [ -z "${PM}" ]
  then
    echo "Sorry your System is not *yet* supported !"
    exit 4
  fi

  if [ -n "${SERVER}" ]
  then
    mkdir -p /var/rudder/cfengine-community/
    echo "${SERVER}" > /var/rudder/cfengine-community/policy_server.dat
  fi

  # The version given is a file or a URL
  if [ -f "${RUDDER_VERSION}" ] || echo "${RUDDER_VERSION}" | grep "^http" > /dev/null || echo "${RUDDER_VERSION}" | grep "^ftp" > /dev/null
  then
    # localinstall
    if [ "${PM}" = "pkg" ] && LANG=C file "${RUDDER_VERSION}" | grep "gzip compressed data" > /dev/null
    then
      cd /tmp
      gzip -d -c "${RUDDER_VERSION}" | tar xf -
      ${PM_LOCAL_INSTALL} /tmp RudderAgent
    elif [ "${PM}" = "pkg" ]
    then
      ${PM_LOCAL_INSTALL} "${RUDDER_VERSION}" RudderAgent
    else
      ${PM_LOCAL_INSTALL} "${RUDDER_VERSION}"
    fi
  # remote install without repository manager
  elif [ "${PM}" = "rpm" ] && [ "${OS_COMPATIBLE}" = "AIX" ]
  then
    $local fields="`echo "${RUDDER_VERSION}" | tr . ' ' | wc -w`"
    if [ "${fields}" -eq 2 ]
    then
      if echo "${RUDDER_VERSION}" | grep nightly > /dev/null
      then
        file=`get - "${URL_BASE}/ppc/" | sed -n '/href="rudder-agent/s/.*href="\(.*\)">rudder.*/\1/p' | tail -n 1`
      else
        RUDDER_VERSION=`get - "https://www.rudder-project.org/release-info/rudder/versions/${RUDDER_VERSION}/next"`
        file="rudder-agent-${RUDDER_VERSION}.release-1.AIX.5.3.aix5.3.ppc.rpm"
      fi
    fi
    ${PM_INSTALL} "${URL_BASE}/ppc/${file}"
  # special get + localinstall for slackware
  elif [ "${PM}" = "slackpkg" ]
  then
    $local file=$(mktemp).tgz
    wget -O "${file}" "${LOCALINSTALL_URL}/latest"
    ${PM_LOCAL_INSTALL} "${file}"
    rm "${file}"
  else
    # Install
    ${PM_INSTALL} "${package}"
  fi

  # System specific behavior
  #######

  # TODO rhel5 only
  #${PM_INSTALL} pcre openssl db4-devel

  rudder agent inventory

  # No start needed anymore in 6.0
  if is_version_valid "${RUDDER_VERSION}" "[* 5.0]"
  then
    if is_version_valid "${RUDDER_VERSION}" "[4.1 *]"
    then
      rudder agent start
    else
      service_cmd rudder-agent start
    fi
  fi

  if is_version_valid "${RUDDER_VERSION}" "[4.0 *]"; then
    rudder agent health
  fi
}

upgrade_agent() {
  package="$1"
  [ -z "${package}" ] && package="rudder-agent"

  # Upgrade via package manager only
  if [ -z "${PM}" ]
  then
    echo "Sorry your System is not *yet* supported !"
    exit 4
  fi
  ${PM_UPGRADE} "${package}"
}

#######################
# Setup rudder server #
#######################
setup_server() {
  # Install via package manager only
  if [ -z "${PM}" ]
  then
    echo "Sorry your System is not *yet* supported !"
    exit 4
  fi

  # TODO detect supported OS
  # echo "Sorry your System is not supported by Rudder Server !"
  # exit 5

  $local LDAPRESET="yes"

  # 4.0 has autodetect support, older releases don't
  if [ -z "${ALLOWEDNETWORK}" ]
  then
    if is_version_valid "${RUDDER_VERSION}" "[4.0 *]"
    then
      $local ALLOWEDNETWORK='auto'
    else
      $local ALLOWEDNETWORK='127.0.0.1/24'
    fi
  elif [ "${DEV_MODE}" = "true" ]
  then
    $local ALLOWEDNETWORK='192.168.0.0/16'
  fi

  # guess package name
  if is_version_valid "${RUDDER_VERSION}" "[7.2 *]"
  then
    PACKAGE="rudder-server"
  else
    PACKAGE="rudder-server-root"
  fi

  # Install rudder server package
  ${PM_INSTALL} "${PACKAGE}"

  # System specific behavior
  #######

  # Setup the Java TZ on SLES
  # On SLES, the Oracle JRE is often unable to get the system
  # timezone, resulting in broken reporting timings.
  if [ "${PM}" = "zypper" ]
  then
    grep -q JAVA_OPTIONS /opt/rudder/etc/rudder-jetty.conf || echo "JAVA_OPTIONS='-Duser.timezone=Europe/Paris'" >> /opt/rudder/etc/rudder-jetty.conf
  fi

  if is_version_valid "${RUDDER_VERSION}" "[* 5.0]"; then
    # Initialize Rudder
    echo -n "Running rudder-init..."
    /opt/rudder/bin/rudder-init ${LDAPRESET} ${ALLOWEDNETWORK} < /dev/null > /dev/null 2>&1
    echo "Done."
  fi

  [ "${DEV_MODE}" = "true" ] && setup_dev_mode

  # install plugins
  if is_version_valid "${RUDDER_VERSION}" "[6.0 *]" && [ "${PLUGINS}" != "" ]
  then
    # Configure plugins
    if  [ "$(echo ${PLUGINS_VERSION} | sed  's|.*/||')" = "nightly" ]; then
      nightly_plugins="--nighty"
    fi
    if [ "$(echo ${PLUGINS_VERSION} | sed  's|/.*||')" = "ci" ]; then
      url="https://publisher.normation.com/plugins/"
    elif [ "${DOWNLOAD_USER}" = "" ]; then
      url="https://repository.rudder.io/plugins/"
    else
      url="https://download.rudder.io/plugins"
    fi
    cat > /opt/rudder/etc/rudder-pkg/rudder-pkg.conf <<EOF
[Rudder]
url = ${url}
username = ${DOWNLOAD_USER}
password = ${DOWNLOAD_PASSWORD}
EOF

    # list available packages
    rudder package --quiet update
    if [ "${PLUGINS}" = "all" ]; then
      PLUGINS=$(rudder package list --all | grep rudder-plugin | awk '{print $2}')
    fi

    # install plugins
    if [ "${PLUGINS_VERSION}" = "nightly" ] || echo "${RUDDER_VERSION}" | grep -q nightly ; then
      nightly_plugins="--nightly"
    fi
    for p in ${PLUGINS}
    do
      rudder package --quiet install "${p}" ${nightly_plugins} || true # accept plugin install to fail
    done

    # remove credentials if needed
    if [ "${FORGET_CREDENTIALS}" = "true" ]; then
      rm -f /opt/rudder/etc/rudder-pkg/rudder-pkg.conf
    fi
  fi

  set_admin

  if is_version_valid "${RUDDER_VERSION}" "[5.0.14 *]"; then
    rudder server health -w
  fi
}

set_admin() {
  if is_version_valid "${RUDDER_VERSION}" "[7.1 *]"; then
    if [ "${ADMIN_PASSWORD}" != "" ]; then
      if [ "${ADMIN_USER}" != "" ]; then
        user_opt="-u ${ADMIN_USER}"
      fi
      rudder server create-user ${user_opt} -p "${ADMIN_PASSWORD}"
    fi
  elif is_version_valid "${RUDDER_VERSION}" "[6.1 *]"; then
    if [ "${ADMIN_PASSWORD}" != "" ]; then
      hash=$(htpasswd -nbBC 12 "" "${ADMIN_PASSWORD}" | tr -d ':\n')
      details="<user name=\"admin\" password=\"${hash}\" role=\"administrator\" />"
      sed -i "/^[[:space:]]*<\/authentication>/i ${details}" "/opt/rudder/etc/rudder-users.xml"
      systemctl restart rudder-jetty
      # force an inventory, because this restart often happens while inventory is being processed
      rudder agent inventory
    fi
  fi
}

upgrade_server() {
  # Upgrade via package manager only
  if [ -z "${PM}" ]
  then
    echo "Sorry your System is not *yet* supported !"
    exit 4
  fi

  # guess package name
  if is_version_valid "${RUDDER_VERSION}" "[7.2 *]"
  then
    PACKAGE="rudder-server"
  else
    PACKAGE="rudder-server-root"
  fi

  # Upgrade
  ${PM_UPGRADE} "${PACKAGE}"

  if is_version_valid "${RUDDER_VERSION}" "[6.0 *]" && [ "${PLUGINS}" != "" ]
  then
    if [ "${PLUGINS_VERSION}" = "nightly" ]; then
      nightly_plugins="--nightly"
    fi
    if is_version_valid "${RUDDER_VERSION}" "[6.1 *]"; then
      quiet_arg="--quiet"
    fi
    rudder package update ${quiet_arg}
    rudder package upgrade-all ${nightly_plugins} ${quiet_arg}
  fi

  if is_version_valid "${RUDDER_VERSION}" "[5.0.14 *]"; then
    rudder server health -w
  fi
}

upgrade_techniques() {
  cd /var/rudder/configuration-repository && cp -a /opt/rudder/share/techniques/* techniques/

  git add -u techniques
  git add techniques
  git commit -m "Technique upgrade to version ${RUDDER_VERSION}"

  curl --silent --fail --insecure "https://localhost/rudder/api/techniqueLibrary/reload"
  echo ""
}

setup_dev_mode() {
  # Permit LDAP access from outside
  [ -f /opt/rudder/etc/rudder-slapd.conf ] && sed -i "s/^IP=.*$/IP=*/" /opt/rudder/etc/rudder-slapd.conf
  [ -f /opt/rudder/etc/rudder-slapd.conf ] && sed -i "s/^#IP=.*$/IP=*/" /etc/default/rudder-slapd
  if [ -f /usr/lib/systemd/system/rudder-slapd.service ]; then
    mkdir -p /etc/systemd/system/rudder-slapd.service.d
    cat > /etc/systemd/system/rudder-slapd.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=/opt/rudder/libexec/slapd -n rudder-slapd -u rudder-slapd -f /opt/rudder/etc/openldap/slapd.conf -h "ldap://0.0.0.0:389/"
EOF
  fi
  systemctl daemon-reload
  service_cmd rudder-slapd restart

  # Permit PostgreSQL access from outside
  PG_HBA_FILE=$(su - postgres -c "psql -t -P format=unaligned -c 'show hba_file';")
  if [ $? -ne 0 ]; then
    echo "Postgresql failed to start! Halting"
    exit 1
  fi

  PG_CONF_FILE=$(su - postgres -c "psql -t -P format=unaligned -c 'show config_file';")
  if [ $? -ne 0 ]; then
    echo "Postgresql failed to start! Halting"
    exit 1
  fi

  echo "listen_addresses = '*'" >> ${PG_CONF_FILE}
  echo "host    all         all         192.168.0.0/16    trust" >> ${PG_HBA_FILE}
  echo "host    all         all         10.0.0.0/16       trust" >> ${PG_HBA_FILE}

  POSTGRESQL_SERVICE_NAME=$(systemctl list-unit-files --type service | awk -F'.' '{print $1}' | grep -E "^postgresql-?[0-9]*$" | tail -n 1)
  if [ -z "${POSTGRESQL_SERVICE_NAME}" ]; then
    POSTGRESQL_SERVICE_NAME="postgresql"
  fi
  service_cmd ${POSTGRESQL_SERVICE_NAME} restart

  # Replace passwords with easy ones
  if [ -e /opt/rudder/etc/rudder-passwords.conf ] ; then
    sed -i "s/\(RUDDER_WEBDAV_PASSWORD:\).*/\1rudder/" /opt/rudder/etc/rudder-passwords.conf
    sed -i "s/\(RUDDER_PSQL_PASSWORD:\).*/\1Normation/" /opt/rudder/etc/rudder-passwords.conf
    sed -i "s/\(RUDDER_OPENLDAP_BIND_PASSWORD:\).*/\1secret/" /opt/rudder/etc/rudder-passwords.conf
  fi

  # -E option is available from 6.1.2
  if is_version_valid "${RUDDER_VERSION}" "[6.1.2 *]"; then
    rudder agent run -E
  else
    rudder agent run
  fi

  # insert sample inventories
  $local MAJOR_VERSION=$(echo "${RUDDER_VERSION}"| cut -d '-' -f 1 | cut -f 1-2 -d .)
  cd /tmp
  git clone --depth=1 --single-branch --branch=branches/rudder/${MAJOR_VERSION} https://github.com/Normation/rudder.git
  cd rudder/webapp/sources/ldap-inventory/inventory-fusion/src/test/resources/fusion-report
  for dir in $(find .  -maxdepth 1 -type d -name '[0-9]*')
  do
    cp ${dir}/* /var/rudder/inventories/incoming/
  done
  cd
  rm -rf /tmp/rudder
}

########
# MAIN #
########

preinst_check() {
  $local ROLE="$1"
  if [ "${ROLE}" = "server" ]
  then
    if ! getent hosts `hostname` > /dev/null
    then
      echo "Your hostname cannot be resolved, this is mandatory for Rudder server to work !"
      exit 1
    fi
  fi
}

setlocal || re_exec "$@"

#COMMAND="$1"
#RUDDER_VERSION=`rudder_real_version "$2"`
#RUDDER_VERSION=${RUDDER_VERSION}
#SERVER="$3"
#PLUGINS="$3"

PREFIX=$(echo "${RUDDER_VERSION}" | cut -f 1 -d "/")
if [ "${PREFIX}" = "ci" ]
then
  USE_CI=yes
  RUDDER_VERSION=$(echo "${RUDDER_VERSION}" | cut -f 2- -d "/")
fi

PREFIX=$(echo "${RUDDER_VERSION}" | cut -f 1 -d "/")
if [ "${PREFIX}" = "prototype" ]
then
  PROTOTYPE=yes
  RUDDER_VERSION=$(echo "${RUDDER_VERSION}" | cut -f 2- -d "/")
fi


if [ $(whoami) != "root" ]
then
  echo "You need to be root to run rudder-setup"
  usage
  exit 1
fi

if [ "${USE_HTTPS}" = "" ] && ! has_ssl
then
  USE_HTTPS=false
fi
detect_os

case "${COMMAND}" in
  "add-repository")
    add_repo
    ;;
  "setup-agent")
    rudder_compatibility_check "agent-allinone"
    preinst_check "agent-allinone"
    add_repo
    setup_agent "rudder-agent"
    can_remove_repo
    ;;
  "setup-relay")
    rudder_compatibility_check "relay"
    preinst_check "relay"
    add_repo
    if is_version_valid "${RUDDER_VERSION}" "[7.2 *]"
    then
      PACKAGE="rudder-relay"
    else
      PACKAGE="rudder-server-relay"
    fi
    setup_agent "${PACKAGE}"
    can_remove_repo
    ;;
  "setup-server")
    rudder_compatibility_check "server"
    preinst_check "server"
    add_repo
    setup_server
    can_remove_repo
    ;;
  "upgrade-agent")
    rudder_compatibility_check "agent-allinone"
    update_repo
    upgrade_agent "rudder-agent"
    can_remove_repo
    ;;
  "upgrade-relay")
    rudder_compatibility_check "relay"
    update_repo
    if is_version_valid "${RUDDER_VERSION}" "[7.2 *]"
    then
      PACKAGE="rudder-relay"
    else
      PACKAGE="rudder-server-relay"
    fi
    upgrade_agent "${PACKAGE}"
    can_remove_repo
    ;;
  "upgrade-server")
    rudder_compatibility_check "server"
    update_repo
    upgrade_server
    can_remove_repo
    ;;
  "upgrade-techniques")
    upgrade_techniques
    ;;
  *)
    usage
    ;;
esac


# === FIREWALL ===
echo "Configuring firewall..."
sudo firewall-cmd --add-service=https --permanent
sudo systemctl restart firewalld



# === CREATE A USER ===
sudo rudder server create-user -u ${RUDDER_ROOT_USER} -p ${RUDDER_ROOT_PASS}

# === SAVE THIS INFORMATION ===
echo
echo "# === Save this information for future reference ==="
echo "Rudder Web UI:                  https://${SERVER_IP}/"
echo "Rudder admin user:              ${RUDDER_ROOT_USER}"
echo "Rudder admin password:          ${RUDDER_ROOT_PASS}"
echo "Log file:                       ${LOG_FILE:-/var/log/rudder/webapp/webapp.log}"
echo "Main configuration:             /opt/rudder/etc/"
echo
echo "# === Common commands ==="
echo "To check logs:                  journalctl -u rudder-server"
echo "To check service status:        sudo systemctl status rudder-server"
echo "To start service:               sudo systemctl start rudder-server"
echo "To stop service:                sudo systemctl stop rudder-server"
echo "To restart service:             sudo systemctl restart rudder-server"
echo "To enable at boot:              sudo systemctl enable rudder-server"
echo "To disable at boot:             sudo systemctl disable rudder-server"
