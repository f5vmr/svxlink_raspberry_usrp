#!/bin/bash
# Auto run audio_update.sh
export LANGUAGE=en_GB.UTF-8
GREEN="\033[1;32m"
NORMAL="\033[0;39m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
sudo bash /home/pi/svxlink_raspberry/audio_update.sh
#
# Auto run install.sh
#

CONF="/etc/svxlink/svxlink.conf"
GPIO="/etc/svxlink/gpio.conf"
HOME="/home/pi"
OP="/etc/svxlink"
cd
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

sudo apt update
sudo apt upgrade -yq
VERSIONS="svxlink/src/versions"

	echo -e `date` " ${YELLOW}  *** commence build *** ${NORMAL}"

# Installing other packages
	echo -e `date` " ${YELLOW} Installing required software packages${NORMAL}"
	sudo apt-get -yq install gcc g++ make cmake libgcrypt-dev libgsm1-dev libsigc++-2.0-dev tcl-dev libspeex-dev libasound2-dev libpopt-dev libssl-dev libopus-dev groff libcurl4-openssl-dev git mc libjsoncpp-dev libgpiod-dev gpiod
	echo         
	echo -e "${GREEN} Enter the node callsign: \n ${NORMAL}"
	echo
	read CallVar
	if [ “$CallVar” == “” ]; then
		echo “Sorry - Start this program again with a valid callsign”
		exit 1
	fi
	CALL=${CallVar^^}
	echo
	echo `date` Creating Node $CALL
# Creating Groups and Users
	echo -e `date` "${YELLOW} Creating Groups and Users ${NORMAL}"
	sudo groupadd svxlink
	sudo useradd -g svxlink -G tty,svxlink,audio,plugdev,gpio,dialout -c "SvxLink Master" --shell=/bin/false -m svxlink
 -d /etc/svxlink svxlink
	sudo usermod -aG audio,nogroup,svxlink,plugdev svxlink
	sudo usermod -aG gpio svxlink
	sleep 40
	sudo systemctl stop apache2 && sudo systemctl disable apache2
	sudo wget https://github.com/pjsip/pjproject/archive/refs/tags/2.12.1.tar.gz
	sudo mv 2.12.1.tar.gz pjProject-2.12.1.tar.gz
	sudo tar -zxvf pjProject-2.12.1.tar.gz
	cd pjproject-2.12.1
	sudo ./configure --disable-video --disable-libwebrtc CPPFLAGS=-fPIC CXXFLAGS=-fPIC CFLAGS=-fPIC
	sudo make dep
	sudo make
	sudo make install

# Downloading Source Code for SVXLink
	echo -e `date` "${YELLOW} downloading SVXLink source code … ${NORMAL}"
	cd
	sudo git clone https://github.com/dl1hrc/svxlink.git
	cd svxlink
	sudo git checkout tetra-contrib
	cd src
	sudo mkdir build
	cd build	
	# Compilation
	
	sudo cmake -DUSE_QT=OFF -DCMAKE_INSTALL_PREFIX=/usr -DSYSCONF_INSTALL_DIR=/etc -DLOCAL_STATE_DIR=/var -DCMAKE_BUILD_TYPE=Release -DWITH_CONTRIB_TETRA_LOGIC=ON -DWITH_SYSTEMD=ON -DWITH_CONTRIB_SIP_LOGIC=ON ..
echo -e `date` "${YELLOW} Compiling ${NORMAL}"
	sudo make
	#sudo make doc
	echo `date` "${RED} Installing SVXlink ${NORMAL}"
	sudo make install
	cd /usr/share/svxlink/events.d
	sudo mkdir local
	sudo cp *.tcl ./local
	sudo ldconfig
# Installing United Kingdom Sound files
	cd /usr/share/svxlink/sounds
	sudo wget https://g4nab.co.uk/wp-content/uploads/2023/08/en_GB.tar_.gz
 	
	sudo tar -zxvf en_GB.tar_.gz
	sudo rm en_GB.tar_.gz
	
	
	cd ..	
	sudo chmod 777 *
	echo `date` backing up configuration to : $CONF.bak
	cd $OP
	sudo cp -p $CONF $CONF.bak
#
	cd $HOME
	echo -e `date` "${RED} Downloading prepared configuration files from G4NAB …${NORMAL}"
	sudo mkdir /home/pi/scripts
	sudo cp -r svxlink_raspberry/svxlink.conf $OP
	#sudo cp -r svxlink_raspberry/gpio.conf $OP
	sudo cp -r svxlink_raspberry/node_info.json $OP/node_info.json
	sudo cp -r svxlink_raspberry/resetlog.sh /home/pi/scripts/resetlog.sh
	(crontab -l 2>/dev/null; echo "59 23 * * * /home/pi scripts/resetlog.sh ") | crontab -
#
	echo `date` Setting Callsign to $CALL
	sudo sed -i "s/MYCALL/$CALL/g" $CONF
	sudo sed -i "s/MYCALL/$CALL/g" $OP/node_info.json
#
	echo `date` Setting Squelch Hangtime to 10
	sudo sed -i "s/SQL_HANGTIME=200/SQL_HANGTIME=10/g" $CONF
#	
	echo `date` Disabling audio distortion warning messages
	sudo sed -i "s/PEAK_METER=1/PEAK_METER=0/g" $CONF
#
	echo `date` Updating SplashScreen on startup
	sudo sed -i "s/MYCALL/$CALL/g" /etc/update-motd.d/10-uname
	sudo chmod 0755 /etc/update-motd.d/10-uname
#
	echo `date` Changing Log file
	sudo sed -i "s/log\/svxlink/log\/svxlink.log/g" /etc/default/svxlink
	if [$card=true]
	then
	sudo sed -i "/PTT_TYPE/iHID_DEVICE=\/dev\/hidraw0" $CONF
	sudo sed -i "s/PTT_TYPE=GPIO/PTT_TYPE=Hidraw/g" $CONF
	sudo sed -i "s/PTT_PORT=GPIO/PTT_PORT=\/dev\/hidraw0/g" $CONF
	sudo sed -i "s/PTT_PIN=gpio24/HID_PTT_PIN=GPIO3/g" $CONF
	sudo sed -i "s/\#MUTE/MUTE/g" /etc/svxlink/svxlink.d/ModuleEchoLink.conf
	sudo sed -i "s/\#DEFAULT_LANG=en_US/DEFAULT_LANG=en_GB/g" /etc/svxlink/svxlink.d/ModuleEchoLink.conf
	sudo sed -i "s/\#MUTE/MUTE/g" /etc/svxlink/svxlink.d/ModuleMetarInfo.conf
	sudo sed -i "s/\#DEFAULT_LANG=en_US/DEFAULT_LANG=en_GB/g" /etc/svxlink/svxlink.d/ModuleMetarInfo.conf	

	fi
	sudo chown -R svxlink:svxlink /usr/share/svxlink/events.d
	sudo chown -R svxlink:svxlink /home/pi//svxlink
	sudo chown -R svxlink:svxlink /var/spool/svxlink

	echo `date` "${RED} Authorise GPIO setup service and svxlink service${NORMAL}"
	sudo systemctl enable svxlink_gpio_setup
	sleep 10
	sudo systemctl enable svxlink
	sleep 10
	sudo systemctl start svxlink_gpio_setup.service
	sleep 10
	#sudo systemctl start svxlink.service


echo -e `date` "${RED}Installation of SVXLink is complete\n${NORMAL}"
echo -e `date` "${GREEN} Now for DVSwitch\n\n\n${NORMAL}"
echo
sleep 10
cd 
sudo wget http://dvswitch.org/buster
sudo chmod +x buster
sudo ./buster
sudo apt update -y && sudo apt upgrade
sudo apt install dvswitch-server -y
#sudo systemctl disable lighttpd
#sudo reboot


	
 
