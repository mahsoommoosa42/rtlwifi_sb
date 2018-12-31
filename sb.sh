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
	if [ $country == "N" ]
	then
		$country == X1
	fi
	echo -e "\n\n------------------------------------------------------------------------------\n\nCountry : $country\n" >> $HOME/bin/Sys_log 2>&1
	read -p "Enter State or province (1 -128 characters) : " state
	echo -e "State : $state" >> $HOME/bin/Sys_log 2>&1
	read -p "Enter Locality (1-128 characters) : " locale
	echo -e "Locality : $locale" >> $HOME/bin/Sys_log 2>&1
	read -p "Do you want to add an organisation name? (y/n) (default will be nan) : " ans1
	if [ $ans1 == 'y' -o $ans1 == 'Y' ]
	then
		read -p "Enter your organisation name : " org 
	else
		org="nan" 
	fi
	echo "Organisation Name : $org" >> $HOME/bin/Sys_log 2>&1
	read -p "Enter your email address : " email
	echo "Email : $email" >> $HOME/bin/Sys_log 2>&1
	export country
	export state
	export locale
	export org
	export email
	envsubst < sslinfo.txt > $HOME/bin/openssl.cnf 2>&1 | tee -a $HOME/bin/Sys_log
	if [ $? != 0 ]
	then
		echo -e "ERROR : Failed to create file. \n$HOME/bin/Sys_log for detailed log";
		exit_code
	fi
	echo -e "OpenSSL Config file created at $HOME/bin" 2>&1 | tee -a $HOME/bin/Sys_log
	unset country
	unset state
	unset locale
	unset org
	unset email

	openssl req -config $HOME/bin/openssl.cnf \
	-new -x509 -newkey rsa:2048 \
	-nodes -days 36500 -outform DER \
	-keyout "$HOME/bin/RTLMOK.priv" \
	-out "$HOME/bin/RTLMOK.der" 2>&1 | tee -a $HOME/bin/Sys_log
	if [ $? != 0 ]
	then
		echo -e "Error : Failed to create private key and signature file. Check $HOME/bin/Sys_log for detailed log";
		exit_code
	fi
	echo -e "Private Key and Signature File created at $HOME/bin"
}


#######################Enrolling Key into MOK#################################################

enroll_mok()
{
	sudo mokutil --import $HOME/bin/RTLMOK.der 2>&1 | tee -a $HOME/bin/Sys_log
	if [ $? != 0 ]
	then
		echo -e "Failed to import key to MOK. Check $HOME/bin/Sys_log for detailed log\n"
		exit_code
	fi
	echo -e "Key Succesfully enrolled into MOK" 2>&1 | tee -a $HOME/bin/Sys_log
}


########################## Signing Modules with necessary key ##################################

sign_modules()
{
	export PRIVK=$HOME/bin/RTLMOK.priv
	export DERK=$HOME/bin/RTLMOK.der
	#export DIR=/lib/modules/$(uname -r)/kernel/drivers/net/wireless/realtek/rtlwifi
	export DIR=$(dirname $(dirname $(modinfo -n rtl8723be)))
	find $DIR -name "*.ko" -exec sudo /usr/src/linux-headers-$(uname -r)/scripts/sign-file sha512 $PRIVK $DERK {} \; >> $HOME/bin/Sys_log 2>&1
	if [ $? != 0]
	then
		echo -e "\n\n Unable to sign modules. Check $HOMe/bin/Sys_log for detailed log"
		exit_code
	fi
	echo -e "\n\n Modules successfully signed. Do you want to reboot? (y/n)"
	unset PRIVK
	unset DERK
	unset DIR
	read ans
	if [ $ans == 'y' -o $ans == 'Y' ]
	then
		reboot
	else
		echo -e "Don't forget to reboot manually"
	fi
	echo -e "\n Upon reboot, you will enter a blue screen (MokManager). \nUse the screen to select 'Enroll MOK' and follow the menus to finish the enrolling process"	
	exit_code
}


############ Main Script ####################################################################
sudo_login
initials
create_ssl
enroll_mok
sign_modules
exit_code
##############################################################################################

