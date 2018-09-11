#!/bin/bash
# Script to add a user to Linux system
if [ $(id -u) -eq 0 ]; then
	read -p "Enter username : " username
	egrep "^$username" /etc/passwd >/dev/null
	if [ $? -eq 0 ]; then
		echo "El usuario [$username] existe"
		exit 1
	else
		pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
		useradd -m -p "654321" $username -g www-data
		mkhomedir_helper $username
		[ $? -eq 0 ] && echo "El usuario se ha creado" || echo "Error al crear el usuario"
	fi
else
	echo "Únicamente se puede ejecutar con permisos de root"
	exit 2
fi
