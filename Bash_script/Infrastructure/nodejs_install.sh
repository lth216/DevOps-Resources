#!/bin/bash

set -eou pipefail
[[ -n ${DEBUG:-} ]] && set -x

function usage(){
    echo "Usage: ./nodejs.sh <VERSION> (17, 18, 19)"
    echo "If <VERSION> is not specified, nodejs version 18 will be used"
    echo -e "\nStop this script and rerun with a specific version"
    echo -e "\n\nWaiting for 5s and install Nodejs version 18..."
    sleep 5
}

function command_exist(){
    command -v $@ > /dev/null 2>&1
}

user=$(whoami)
bash_c="bash -c"
function do_install(){
    if command_exist nodejs; then
        cat <<-EOF
        Warning: Nodejs already exists on this machine.
        Re-install it can cause unpredictable problems. Please remove the old one first
EOF
        exit 1
    fi
    
    if [[ $user != root ]]; then
        if command_exist sudo; then
            bash_c="sudo -E bash -c"
        elif command_exist su; then
            bash_c="su $user -c"
        else
            cat <<-EOF
            Error: This installer needs the ability to run command as root.
            Unable to find either "sudo" or "su" available to make this happen
EOF
            exit 1
        fi
    fi
    
    NODE_VERSION=${1:-18}
    $bash_c "apt-get -qq update > /dev/null 2>&1"
    $bash_c "apt-get install -y -qq ca-certificates curl gnupg > /dev/null 2>&1"
    $bash_c "curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg"
    $bash_c "echo \"deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_VERSION.x nodistro main\" | tee /etc/apt/sources.list.d/nodesource.list"
    $bash_c "apt-get update -qq > /dev/null 2>&1"
    $bash_c "apt-get install -y -qq nodejs > /dev/null 2>&1"
    
    if [[ $? -eq 0 ]]; then
        echo "Installing Nodejs version $NODE_VERSION:...OK"
    else
        echo "Installing Nodejs version $NODE_VERSION:...FAILED"
    fi
}

#----MAIN----
usage
do_install
