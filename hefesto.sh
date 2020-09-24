#!/bin/bash
# Script to add a user to Linux system
if [ $(id -u) -eq 0 ]; then
	read -p "Tipo de entorno: [1] Local [2] Produccion " enviroment
	read -p "El entorno usa Laravel [S]í [No]: " using_laravel
	read -p "Habilitar la conexión HTTPS: [S]í [No]: " using_https
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
		public_html="content"
		apache_log_dir="/home/$username/logs"

		if [ $using_laravel = "S" ] || [ $using_laravel = "s" ];
		then
			public_html="public"
		fi

		case $enviroment in
			1)
				mkdir $apache_log_dir
				mkdir "/vagrant/html/$username"
				mkdir "/vagrant/html/$username/$public_html"
				ln -s "/vagrant/html/$username/$public_html" "/home/$username"
				username="$username"
				domain="site"
			;;

			2)
				read -p "Ingrese el dominio: " domain
				apache_log_dir="/var/logs/apache2/"
			;;

			*)
				echo "Opción no encontrada"
			;;
		esac

		if [ $using_https = "S" ] || [$using_https = "s"];
                then
			certs_dir="/home/$username/certs"
			mkdir $certs_dir

			openssl genrsa -out $certs_dir/$username.$domain.key 2048
			openssl req -new -x509 -key $certs_dir/$username.$domain.key -out /home/$username/certs/$username.$domain.cert -days 3650 -subj /CN=$username.$domain

			cat <<-EOF > /etc/apache2/sites-available/$username.$domain.conf
                       	<VirtualHost *:80>
				 ServerName $username.$domain
				 DocumentRoot /home/$username/$public_html
				 Redirect permanent / https://$username.$domain/
			</VirtualHost>
		   	<VirtualHost *:443>
				ServerName $username.$domain
				ServerAdmin webmaster@localhost
				DocumentRoot /home/$username/$public_html

				SSLEngine on
				SSLCertificateFile $certs_dir/$username.$domain.cert
				SSLCertificateKeyFile $certs_dir/$username.$domain.key

				ErrorLog $apache_log_dir/$username.$domain.error.log
				CustomLog $apache_log_dir/$username.$domain.access.log combined

				<Directory /home/$username/$public_html>
					Options Indexes FollowSymLinks MultiViews
					AllowOverride All
					Require all granted
				</Directory>
			</VirtualHost>
EOF
		else
			 cat <<-EOF > /etc/apache2/sites-available/$username.$domain.conf
                        <VirtualHost *:80>
                                ServerName $username.$domain
                                ServerAdmin webmaster@localhost
                                DocumentRoot /home/$username/$public_html

                                ErrorLog $apache_log_dir/$username.$domain.error.log
                                CustomLog $apache_log_dir/$username.$domain.access.log combined

                                <Directory /home/$username/$public_html>
                                    Options Indexes FollowSymLinks MultiViews
                                    AllowOverride All
                                    Require all granted
                                </Directory>
                        </VirtualHost>
EOF
		fi

		a2ensite $username.$domain.conf
		service apache2 restart

		echo "CREATE DATABASE db_$namedb; GRANT ALL PRIVILEGES ON db_$namedb.* TO $namedb@localhost IDENTIFIED BY '$password'" | mysql -u root -p

		[ $? -eq 0 ] && echo "Se ha creado el entorno para $username" || echo "Error al crear el entorno"
	fi
else
	echo "Únicamente se puede ejecutar con permisos de root"
	exit 2
fi
