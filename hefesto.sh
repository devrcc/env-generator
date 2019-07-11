#!/bin/bash
# Script to add a user to Linux system
if [ $(id -u) -eq 0 ]; then
	read -p "Tipo de entorno: [1] Local [2] Produccion " enviroment
	read -p "Ingrese el nombre de usuario: " username
	read -p "Ingrese la contraseña: " password
	egrep "^$username" /etc/passwd >/dev/null
	if [ $? -eq 0 ]; then
		echo "El usuario [$username] existe"
		exit 1
	else
		pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
		useradd -m -p "$pass" $username -g www-data

		namedb="$username"
		case $enviroment in
			1)			
				mkdir "/vagrant/html/$username"
				mkdir "/vagrant/html/$username/content"
				ln -s "/vagrant/html/$username/content" "/home/$username"
				username="$username"
				domain="site"
			;;

			2)
				read -p "Ingrese el dominio: " domain
			;;

			*)
				echo "Opción no encontrada"
			;;
		esac

		apache_log_dir="/var/log/apache2"

		cat <<-EOF > /etc/apache2/sites-available/$username.$domain.conf
		<VirtualHost *:80>        
	        ServerName $username.$domain
	        ServerAdmin webmaster@localhost
	        DocumentRoot /home/$username/content

	        ErrorLog $apache_log_dir/$username.$domain.error.log
        	CustomLog $apache_log_dir/$username.$domain.access.log combined

	        <Directory /home/$username/content>
	            Options Indexes FollowSymLinks MultiViews
	            AllowOverride All
	            Require all granted
	        </Directory>
		</VirtualHost>
		EOF

		a2ensite $username.$domain.conf
		service apache2 restart

		echo "CREATE DATABASE db_$namedb; GRANT ALL PRIVILEGES ON db_$namedb.* TO $namedb@localhost IDENTIFIED BY '$password'" | mysql -u root -p

		[ $? -eq 0 ] && echo "Se ha creado el entorno para $username" || echo "Error al crear el entorno"
	fi
else
	echo "Únicamente se puede ejecutar con permisos de root"
	exit 2
fi
