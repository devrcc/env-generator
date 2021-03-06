#!/bin/bash
# Script to add a user to Linux system
if [ $(id -u) -eq 0 ]; then
	read -p "Tipo de entorno: [1] Local [2] Produccion " enviroment
	read -p "Ingrese el nombre de usuario: " username
	egrep "^$username" /etc/passwd >/dev/null
	if [ $? -eq 0 ]; then
		namedb="${username//./_}";
		echo "DROP DATABASE db_$namedb; DROP USER '$namedb'@'localhost';" | mysql -u root -p
		userdel -r $username
		case $enviroment in
			1)
				username="$username"
				domain="dev"
			;;

			2)
				read -p "Ingrese el dominio: " domain
			;;

			*)
				echo "Opción no encontrada"
			;;
		esac

		# rm "$apache_log_dir/$username.$domain.error.log"
		# rm "$apache_log_dir/$username.$domain.access.log"
		sudo a2dissite $username.$domain.conf
		rm "/etc/apache2/sites-available/$username.$domain.conf"
		service apache2 restart
		# chmod 0777 -R "/vagrant/html/$username"
		rm -R "/vagrant/html/$username"

		[ $? -eq 0 ] && echo "Se ha eliminado el entorno $username.$domain" || echo "Error al eliminar el entorno"
	else
		echo "El usuario [$username] no existe"
		exit 1
	fi
else
	echo "Únicamente se puede ejecutar con permisos de root"
	exit 2
fi
