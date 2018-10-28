#!/bin/bash
# Script to add a user to Linux system
if [ $(id -u) -eq 0 ]; then
	read -p "Ingrese el nombre de usuario: " username
	egrep "^$username" /etc/passwd >/dev/null
	if [ $? -eq 0 ]; then
		echo "El usuario [$username] existe"
		exit 1
	else
		pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
		useradd -m -p "$pass" $username -g www-data
		# mkhomedir_helper $username
		mkdir "/vagrant/html/$username"
		mkdir "/vagrant/html/$username/public_html"
		ln -s "/vagrant/html/$username/public_html" "/home/$username"

		cat <<-EOF > /etc/apache2/sites-available/$username.site.conf
		<VirtualHost *:80>        
	        ServerName $username.site
	        ServerAdmin webmaster@localhost
	        DocumentRoot /home/$username/public_html

	        <Directory /home/$username/public_html>
	            Options Indexes FollowSymLinks MultiViews
	            AllowOverride All
	            Require all granted
	        </Directory>
		</VirtualHost>
		EOF

		a2ensite $username.site.conf
		service apache2 restart

		echo "CREATE DATABASE db_$username; GRANT ALL PRIVILEGES ON db_$username.* TO $username@localhost IDENTIFIED BY '$pass'" | mysql -u root -p

		[ $? -eq 0 ] && echo "Se ha creado el entorno para $username, la contraseña es: $pass" || echo "Error al crear el entorno"
	fi
else
	echo "Únicamente se puede ejecutar con permisos de root"
	exit 2
fi
