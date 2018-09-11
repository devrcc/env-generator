#!/bin/bash
# Script to add a user to Linux system
if [ $(id -u) -eq 0 ]; then
	read -p "Ingrese el nombre de usuario: " username
	egrep "^$username" /etc/passwd >/dev/null
	if [ $? -eq 0 ]; then
		sudo a2dissite $username.site.conf
		service apache2 restart
		userdel -r $username
		chmod 0777 -R "/vagrant/html/$username"
		rm -R "/vagrant/html/$username"
		rm "/etc/apache2/sites-available/$username.site.conf"

		[ $? -eq 0 ] && echo "Se ha eliminado el entorno $username.site" || echo "Error al eliminar el entorno"
	else
		echo "El usuario [$username] no existe"
		exit 1
	fi
else
	echo "Únicamente se puede ejecutar con permisos de root"
	exit 2
fi
