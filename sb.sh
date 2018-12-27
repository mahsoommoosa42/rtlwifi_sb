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
	echo "Enter your Name : "
	read name;
	echo \
	"# This definition stops the following lines choking if HOME isn't
	# defined.
	HOME                    = .
	RANDFILE                = $ENV::HOME/.rnd 
	[ req ]
	distinguished_name      = req_distinguished_name
	x509_extensions         = v3
	string_mask             = utf8only
	prompt                  = no

	[ req_distinguished_name ]
	countryName             = CA
	stateOrProvinceName     = Quebec
	localityName            = Montreal
	0.organizationName      = cyphermox
	commonName              = Secure Boot Signing
	emailAddress            = example@example.com

	[ v3 ]
	subjectKeyIdentifier    = hash
	authorityKeyIdentifier  = keyid:always,issuer
	basicConstraints        = critical,CA:FALSE
	extendedKeyUsage        = codeSigning,1.3.6.1.4.1.311.10.3.6,1.3.6.1.4.1.2312.16.1.2
	nsComment               = \"OpenSSL Generated Certificate\"" | tee -a openssl.cnf
}


############ Main Script ####################################################################
sudo_login
initials
create_ssl
exit_code
##############################################################################################

