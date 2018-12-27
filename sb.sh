#!/bin/bash

########Secure Boot Signing of lwfinger RTLWifi Drivers########
##########
clear

##############################################################
echo
echo -e "Signing rtlwifi drivers by lwfinger. **\nDon't forget to give feedback on mahsoom.moosa42@gmail.com"
echo



#Logging in as SuperUser
sudo_login()
{
	echo -e "Process running as SuperUser" 2>&1 | tee -a $HOME/bin/Sys_log
	sudo echo
	if [ $? != 0 ]
	then
		echo -e "ERROR: Failed to login";
		exit_code
	fi
}

################################################################

initials()
{
	set -o pipefail
	mkdir $HOME/bin > /dev/null 2>&1
	date -R > $HOME/bin/Sys_log 2>&1
	echo -e "\n\n ---------------------------------------------------------------------\n
------------------------------------------------------\n\n" >> $HOME/bin/Sys_log 2>&1
	echo -e "Checking required programs" 2>&1 | tee -a $HOME/bin/Sys_log
	hash mokutil >> $HOME/bin/Syslog 2>&1
	check1=$?
	if [ $check1 != 0 ]
	then
		echo -e "'mokutil' is not installed. Please install the program 'sudo apt install mokutil'" 2>&1| tee -a $HOME/bin/Sys_log
	exit_code
	fi
}

##Exit Code #########################################33
exit_code()
{
	echo -e "Exiting Script" 2>&1 | tee -a $HOME/bin/Sys_log
	exit
}

##Creating SSL Config File
create_ssl()
{
	read -p "Enter your country name : " country
	country=$(bash country.sh "$country" iso)
	read -p "Enter State or province (1 -128 characters) : " state
	read -p "Enter Locality (1-128 characters) : " locale
	read -p "Do you want to add an organisation name? (y/n) (default will be nan) : " ans1
	if [ $ans1 == 'y' -o $ans1 == 'Y' ]
	then
		read -p "Enter your organisation name : " org 
	else
		org="nan" 
	fi
	export country
	export state
	export locale
	export org
	envsubst < sslinfo.txt > $HOME/bin/openssl.cnf
	unset country
	unset state
	unset locale
	unset org
}

enroll_mok()
{
	openssl req -config $HOME/bin/openssl.cnf \
	-new -x509 -newkey rsa:2048 \
	-nodes -days 36500 -outform DER \
	-keyout "$HOME/bin/RTLMOK.priv" \
	-out "$HOME/bin/RTLMOK.der"

	sudo mokutil --import $HOME/bin/RTLMOK.der
}

sign_modules()
{
	export PRIVK=$HOME/bin/RTLMOK.priv
	export DERK=$HOME/bin/RTLMOK.der
	export DIR=/lib/modules/$(uname -r)/kernel/drivers/net/wireless/realtek/rtlwifi
	find $DIR -name "*.ko" -exec sudo /usr/src/linux-headers-$(uname -r)/scripts/sign-file sha512 $PRIVK $DERK {} \;
	unset PRIVK
	unset DERK
	unset DIR
}


############ Main Script ####################################################################
sudo_login
initials
create_ssl
exit_code
enroll_mok
##############################################################################################

