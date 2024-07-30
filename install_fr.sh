#!/bin/bash
# Auto run audio_update.sh
export LANGUAGE=fr_FR.UTF-8
VERT="\033[1;32m"
NORMAL="\033[1;39m"
ROUGE="\033[1;31m"
JAUNE="\033[1;33m"
sudo bash /home/pi/svxlink_raspberry/audio_update.sh
#
# Auto run install.sh
#

CONF=/etc/svxlink/svxlink.conf
GPIO=/etc/svxlink/gpio.conf
HOME=/home/pi
OP=/etc/svxlink
cd
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
NODE_MAJOR=20
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list

sudo apt update
sudo apt upgrade -y
VERSIONS=svxlink/src/versions

	echo -e `date` " ${YELLOW}  *** commence build *** ${NORMAL}"

# Installing other packages
	echo -e `date` " ${YELLOW} Installing required software packages${NORMAL}"
	sudo apt install build-essential g++ make cmake libsigc++-2.0-dev php8.0 nodejs libgsm1-dev libudev-dev libpopt-dev tcl-dev libgpiod-dev gpiod libgcrypt20-dev libspeex-dev libasound2-dev alsa-utils libjsoncpp-dev libopus-dev rtl-sdr libcurl4-openssl-dev libogg-dev librtlsdr-dev groff doxygen graphviz python3-serial toilet -y
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
	sudo useradd -g svxlink -d /etc/svxlink svxlink
	sudo usermod -aG audio,nogroup,svxlink,plugdev svxlink
	sudo usermod -aG gpio svxlink


# Downloading Source Code for SVXLink
	echo -e `date` "${YELLOW} downloading SVXLink source code … ${NORMAL}"
	cd
	sudo git clone https://github.com/dl1hrc/svxlink.git
	cd svxlink
	sudo git checkout svxlink-usrp
	cd src
	sudo mkdir build
	cd build	
	# Compilation
	
	sudo cmake -DUSE_QT=OFF -DCMAKE_INSTALL_PREFIX=/usr -DSYSCONF_INSTALL_DIR=/etc \ -DLOCAL_STATE_DIR=/var -DWITH_CONTRIB_USRP_LOGIC -DWITH_SYSTEMD=ON  ..
	echo -e `date` "${YELLOW} Compiling ${NORMAL}"
	sudo make
	sudo make doc
	echo `date` "${RED} Installing SVXlink ${NORMAL}"
	sudo make install
	cd /usr/share/svxlink/events.d
	sudo mkdir local
	sudo cp *.tcl ./local
	sudo ldconfig
# Installing United Kingdom Sound files
	cd /usr/share/svxlink/sounds
	sudo wget https://g4nab.co.uk/wp-content/uploads/2023/08/fr_FR.tar_.gz
	sudo mv fr_FR_.tar_.gz fr_FR.tar.gz
	sudo tar -zxvf fr_FR.tar.gz
	sudo rm fr_FR.tar.gz
	sudo chmod 777 *
	echo `date` backing up configuration to : $CONF.bak
	cd $OP
	sudo cp -p $CONF $CONF.bak
#
	cd $HOME
	echo -e `date` "${RED} Downloading prepared configuration files from G4NAB …${NORMAL}"
	sudo mkdir /home/pi/scripts
	#sudo cp -r svxlink_raspberry/svxlink.conf $OP
	#sudo cp -r svxlink_raspberry/gpio.conf $OP
	#sudo cp -r svxlink_raspberry/node_info.json $OP/node_info.json
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
sudo systemctl disable lighttpd
sudo reboot
