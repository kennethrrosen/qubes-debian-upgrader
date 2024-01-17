#!/bin/env bash
# A simple script for updating Debian templates in QubesOS
# Debian 12 "Bookworm"
# Debian 13 "Trixie"

PREFIX="$(tput setaf 7)$(tput bold)"
YELLOW="$(tput setaf 3)$(tput bold)"
POSTFIX="$(tput sgr0)"
TAB="$(echo -e '\t')"

message() {
    echo "${PREFIX}${1}${POSTFIX}"
}

upgrade_template() {
    local template=$1
    local proceed=$2
    local clone=$3
    local new_template_name=$4
    local old_name=$5
    local new_name=$6
    
    vm_exists=$(qvm-ls | grep -w "$template")
    if [[ -z $vm_exists ]]; then
        message "Template $template does not exist."
        exit 1
    fi
    
    if [[ $proceed != "y" ]]; then
        message "Skipping $template without changes."
        return 0
    fi
    
    if [[ $clone == "y" ]]; then
        qvm-clone $template $new_template_name
    else
        new_template_name=$template
    fi
    
    message "Upgrading $new_template_name"
    qvm-start $new_template_name
    
    message "Updating APT repositories..."
    qvm-run -p $new_template_name "sudo sed -i 's/$old_name/$new_name/g' /etc/apt/sources.list"
    qvm-run -p $new_template_name "sudo sed -i 's/$old_name/$new_name/g' /etc/apt/sources.list.d/qubes-r4.list"
    
    message "Performing upgrade..."
    qvm-run -p $new_template_name "sudo apt update && sudo apt upgrade && sudo apt dist-upgrade -y"
    qvm-run -p $new_template_name "sudo apt-get autoremove && sudo apt-get clean"
    
    message "Trimming the new template..."
    qvm-run -p $new_template_name "sudo fstrim -av"
    qvm-shutdown $new_template_name
    qvm-start $new_template_name
    qvm-run -p $new_template_name "sudo fstrim -av"
    
    message "Shutting down $new_template_name"
    qvm-shutdown $new_template_name
}

prompt_user() {
    message "Upgrade Debian template in QubesOS"
    read -p "Which template do you want to upgrade? " template
    read -p "Proceed with the upgrade? (y/n): " proceed
    if [[ $proceed != "y" ]]; then
        message "Exiting without changes."
        exit 0
    fi
    read -p "Do you want to clone the template before upgrading? (y/n): " clone
    read -p "What should be the new template name? " new_template_name
    read -p "Enter the old release name (e.g., buster): " old_name
    read -p "Enter the new release name (e.g., bullseye): " new_name
}

if [ $# -eq 0 ]; then
    prompt_user
    upgrade_template $template $proceed $clone $new_template_name $old_name $new_name
else
    message "Usage: $0"
    exit 1
fi


if [ $# -eq 0 ]; then
	cat >&2 <<-EOF
	Usage: ${0##*/} [options] -t 
	...
	EOF
fi
