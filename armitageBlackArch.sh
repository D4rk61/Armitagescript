#!/bin/bash 
#
#
# script para la instalacion correcta de armitage dentro de blackarch

if [ "$(whoami)" != "root" ]; then 
	echo "Debes de ser root para ejecutar este script"
	exit 1 
fi 

distro=$(cat /etc/*-release | grep PRETTY_NAME | cut -d= -f2- | tr -d ' "') 
if [ "$distro" == "BlackArchLinux" ]; then 
	sudo pacman -S armitage --needed --noconfirm

else 
	sudo pacman -S metasploit postgresql jdk10-openjdk --needed --noconfirm
	wget "www.fastandeasyhacking.com/`curl -s http://www.fastandeasyhacking.com/download/ | grep -E -o 'download/armitage[0-9]+.tgz'`" -O armitage.tgz
	tar xvzf armitage.tgz
	rm armitage.tgz
fi 

clear 
echo -e "\n\tConfigurando Metasploit & PostgreSQL\n" 

read -p "Presione ENTER para continuar"
sudo chown -R postgres:postgres /var/lib/postgres/
sudo -i -u postgres <<EOF
initdb --locale $LANG -E UTF8 -D '/var/lib/postgres/data'
EOF

sudo systemctl start postgresql.service
sudo -u postgres createuser user -W
sudo -u postgres createdb -O user metasploit4
msfconsole -x "db_connect user@metasploit4" -x "msfdb reinit" 

cat <<EOF > ~/.msf4/database.yml
production:
 adapter: postgresql
 database: metasploit4
 username: user
 password: 1
 host: localhost
 port: 5432
 pool: 5
 timeout: 5
EOF


# Iniciando el "msffrpcd service" 
#
sudo msfrpcd -U msf -P 1234 -S

# Ejecutando armitage
#
export MSF_DATABASE_CONFIG="`ls ~/.msf4/database.yml`"

alias1='alias armitage="sudo msfrpcd -U msf -P 1234 -S && export MSF_DATABASE_CONFIG="`ls ~/.msf4/database.yml`" && armitage"'

alias1 >> ~/.zshrc 

echo -e "\n\n\tArmitage esta correctamente instalado ejecutalo con \"armitage\"!"

