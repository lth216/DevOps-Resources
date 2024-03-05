#!/bin/bash

set -eou pipefail
[[ -n ${DEBUG:-} ]] && set -x

WORK_DIR=$(cd $(dirname $0) && pwd)

# Get the release version from user input. If not, use the latest one from MySQL server
while [[ $# -gt 0 ]]; do
	case $1 in
	--version | -v)
		VERSION=$2
		shift 2
		break
		;;
	--help | -h)
		usage
		exit 0
		;;
	*)
		echo "Unknown argument $1"
		;;
	esac
	shift $(($# > 0 ? 1 : 0))
done

# Check whether a command exists or not
command_exists() {
	command -v "$@" >/dev/null 2>&1
}

# Install the tool
do_install() {
	# Check whether MySQL is installed or not
	if command_exists mysql; then
		cat >&2 <<-'EOF'
			Warning: the command "mysql" appears to already exist on this system.

			If you already install MySQL server on this machine, this script can cause trouble, which is
			why we're displaying this warning and provide the opportunity to cancel the installation.
		EOF
		(sleep 20)
	fi

	user=$(whoami)
	bash_c="bash -c"
	# Check whether non-root user has sudo privilege or not
	if [[ $user != "root" ]]; then
		if command_exists sudo; then
			bash_c="sudo -E bash -c"
		elif command_exists su; then
			bash_c='su -c'
		else
			cat >&2 <<-'EOF'
				Error: This installer needs the ability to run command as root.
				Unable to find either "sudo" or "su" command available to make this happen.
			EOF
			exit 1
		fi
	fi

	# mysql-apt-config binary file requires lsb_release tool to be able to install
	if ! command_exists lsb_release; then
		$bash_c "apt-get update -qq > /dev/null"
		$bash_c "apt-get install -y -qq lsb > /dev/null"
	fi

	lsb_dist=$(cat /etc/lsb-release | grep "DISTRIB_ID" | cut -d'=' -f2 | tr [:upper:] [:lower:])
	# Run setup for each distro version accordingly
	case $lsb_dist in
	ubuntu)
		dist_version=$(cat /etc/lsb-release | grep "DISTRIB_CODENAME" | cut -d'=' -f2 | tr [:upper:] [:lower:])
		DOWNLOAD_MIRROR="https://repo.mysql.com/apt/ubuntu/dists"
		# Format when curling from website: "Version: 0.8.29-1" --> Remove "version" string and whitespace to get version value
		latest_version=$(curl -fs "$DOWNLOAD_MIRROR/$dist_version/mysql-apt-config/binary-amd64/Packages" | grep "Version" | cut -d' ' -f2)
		installed_version=${VERSION:-$latest_version}
		if [[ -z $installed_version ]]; then
			echo "Missing installation version"
			exit 1
		fi
		curl -fsO "https://repo.mysql.com/apt/ubuntu/pool/mysql-apt-config/m/mysql-apt-config/mysql-apt-config_${installed_version}_all.deb"
		if [[ ! -f "mysql-apt-config_${installed_version}_all.deb" ]]; then
			echo "Cannot download binary file from MySQL website. Check Internet connection"
			exit 1
		fi
		mysql_binary="mysql-apt-config_${installed_version}_all.deb"
		$bash_c "dpkg -i $mysql_binary"
		$bash_c "apt-get update -qq > /dev/null"
		$bash_c "apt-get install -y mysql-server"
		wait
		if command_exists mysql; then
			echo "Successfully install MySQL Server on machine"
		else
			echo "Failed to install MySQL Server on machine"
		fi
		rm $WORK_DIR/$mysql_binary || True
		;;
	*)
		echo "This machine architecture is unsupported at the moment"
		exit 0
		;;
	esac
}

do_install
