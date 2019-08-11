#!/bin/bash

#Companion code for the blog https://cloudywindows.com
#call this code direction from the web with:
#bash <(wget -O - https://raw.githubusercontent.com/PowerShell/PowerShell/master/tools/installpsh-osx.sh) ARGUMENTS
#bash <(curl -s https://raw.githubusercontent.com/PowerShell/PowerShell/master/tools/installpsh-osx.sh) <ARGUMENTS>

#Usage - if you do not have the ability to run scripts directly from the web,
#        pull all files in this repo folder and execute, this script
#        automatically prefers local copies of sub-scripts

#Completely automated install requires a root account or sudo with a password requirement

#Switches
# -includeide         - installs vscode and vscode PowerShell extension (only relevant to machines with desktop environment)
# -interactivetesting - do a quick launch test of vscode (only relevant when used with -includeide)
# -preview            - installs the latest preview release of PowerShell side-by-side with any existing production releases

#gitrepo paths are overrideable to run from your own fork or branch for testing or private distribution


VERSION="0.1" # script based on Version 1.1.2
gitreposubpath="PowerShell/PowerShell/master"
gitreposcriptroot="https://raw.githubusercontent.com/$gitreposubpath/tools"
thisinstallerdistro=ios
repobased=true
gitscriptname="installpsh-ios.sh"
powershellpackageid=powershell

echo "*** PowerShell Development Environment Installer $VERSION for $thisinstallerdistro"
echo "***    Original script is at: $gitreposcriptroot/$gitscriptname"
echo "*** Arguments used: $*"

# Let's quit on interrupt of subcommands
trap '
  trap - INT # restore default INT handler
  echo "Interrupted"
  kill -s INT "$$"
' INT

#Verify The Installer Choice (for direct runs of this script)
lowercase(){
    echo "$1" | tr "[:upper:]" "[:lower:]"
}

OS=$(lowercase "$(uname)")
MACH=$(lowercase "$(uname -m)")
if [ "${OS}" == "windowsnt" ]; then
    OS=windows
    DistroBasedOn=windows
elif [ "${OS}" == "darwin" ]; then
    OS=osx
    DistroBasedOn=osx
    
    if [ ${MACH} =~ "iPhone.*" ]; then
        OS=ios
        DistroBasedOn=ios
    fi
else
    OS=$(uname)
    if [ "${OS}" == "SunOS" ] ; then
        OS=solaris
        DistroBasedOn=sunos
    elif [ "${OS}" == "AIX" ] ; then
        DistroBasedOn=aix
    elif [ "${OS}" == "Linux" ] ; then
        if [ -f /etc/redhat-release ] ; then
            DistroBasedOn='redhat'
        elif [ -f /etc/system-release ] ; then
            DIST=$(sed s/\ release.*// < /etc/system-release)
            if [[ $DIST == *"Amazon Linux"* ]] ; then
                DistroBasedOn='amazonlinux'
            else
                DistroBasedOn='redhat'
            fi
        elif [ -f /etc/SuSE-release ] ; then
            DistroBasedOn='suse'
        elif [ -f /etc/mandrake-release ] ; then
            DistroBasedOn='mandrake'
        elif [ -f /etc/debian_version ] ; then
            DistroBasedOn='debian'
        fi
        if [ -f /etc/UnitedLinux-release ] ; then
            DIST="${DIST}[$( (tr "\n" ' ' | sed s/VERSION.*//) < /etc/UnitedLinux-release )]"
            DistroBasedOn=unitedlinux
        fi
        OS=$(lowercase "$OS")
        DistroBasedOn=$(lowercase "$DistroBasedOn")
    fi
fi

if [ "$DistroBasedOn" != "$thisinstallerdistro" ]; then
  echo "*** This installer is only for $thisinstallerdistro and you are running $DistroBasedOn, please run \"$gitreposcriptroot\install-powershell.sh\" to see if your distro is supported AND to auto-select the appropriate installer if it is."
  exit 1
fi

## Check requirements and prerequisites

echo "*** Installing PowerShell for $DistroBasedOn..."

#Check for sudo if not root
if [[ "${CI}" == "true" ]]; then
    echo "Running on CI (as determined by env var CI set to true), skipping SUDO check."
    set -- "$@" '-skip-sudo-check'
fi

SUDO=''
if (( $EUID != 0 )); then
    #Check that sudo is available
    if [[ ("'$*'" =~ skip-sudo-check) && ("$(whereis sudo)" == *'/'* && "$(sudo -nv 2>&1)" != 'Sorry, user'*) ]]; then
        SUDO='sudo'
    else
        echo "ERROR: You must either be root or be able to use sudo" >&2
        #exit 5
    fi
fi

#Collect any variation details if required for this iOS version
. /etc/lsb-release
DISTRIB_ID=`lowercase $DISTRIB_ID`
#END Collect any variation details if required for this iOS version

#If there are known incompatible versions of this distro, put the test, message and script exit here:

#END Verify The Installer Choice

##END Check requirements and prerequisites

echo
echo "*** Installing PowerShell Core for $DistroBasedOn..."
if ! hash curl 2>/dev/null; then
    echo "curl not found, installing..."
    $SUDO apt-get install -y curl
fi


echo
echo "*** Installing PowerShell Core for $DistroBasedOn..."
if ! hash curl 2>/dev/null; then
    echo "curl not found, installing..."
    $SUDO apt-get install -y curl
fi

if [[ "'$*'" =~ preview ]] ; then
    echo
    echo "-preview was used, the latest preview release will be installed (side-by-side with your production release)"
    powershellpackageid=powershell-preview
fi


curl https://packages.microsoft.com/config/debian/$DISTRIB_RELEASE/prod.list | $SUDO tee /etc/apt/sources.list.d/microsoft.list

# Update apt-get
$SUDO apt-get update
# Install PowerShell
$SUDO apt-get install -y ${powershellpackageid}

pwsh -noprofile -c '"Congratulations! PowerShell is installed at $PSHOME.
Run `"pwsh`" to start a PowerShell session."'

success=$?


if [[ "$success" != 0 ]]; then
    echo "ERROR: PowerShell failed to install!" >&2
    exit "$success"
fi

if [[ "$repobased" == true ]] ; then
  echo "*** NOTE: Run your regular package manager update cycle to update PowerShell"
fi
echo "*** Install Complete"
