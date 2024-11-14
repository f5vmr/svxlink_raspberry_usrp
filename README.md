# svxlink_raspberry with Tetra
**<h1> SVXLink and Tetra </h1>**
<h2>Script build for Raspberry Pi - Repeater or Hotspot - British English Version.</h2> 
<p>While there are repositories from which to download and compile SVXLink they do require quite a bit of understanding.
This script takes only a little SSH knowledge to pull the various downloads together to create the basis of a ready-to-configure system.</p>

<p>It has to be done under conditions of research in the original source manuals found on Svxlink.org and the man files http://www.svxlink.org/doc/man/man5/svxlink.conf.</p>
<p>However this script pulls the SVXLink software from Adi DL1HRC's fork, that has the UsrpLogic necessary to drive the DVSwitch components.</p>

<p>It is NOT plug and play when all is said and done however. It does still require a little manipulation of the configuration files, 
but the compilation of the major part of the software is done for you.</p></h2>

<b>First Steps</b>
<p>Requirements: Raspberry Pi of any mark. USB Soundcard, and an interface card (or a modified USB Soundcard and no interface). One or two transceivers (3 or 4 if you are making a double repeater, for which you will need a second USB soundcard.)</p>

There are very very few raspberry images that work successfully for this type of build, where there is a potential for using the eventual application in several directions.

Whilst this in itself is not an image, it will take the hard work out of the physical compilation, although it leaves a little work for the user to place the finishing touches to the final assembly.

There are a number of available interface boards that have a variety of uses, either as a hotspot or a repeater, or even a fill-in receiver/transceiver for an existing SVXLink repeater. The settings in this build are for a modified CM-108 that can use udev and drive the PTT from the modification components, or a homebrew interface with an unmodified CM-108 or similar.

When using the GPIO Pins, an earth pin is also require, so using this combination, pins 14,16 and 18 are all adjacent and ideally placed for these functions.
Pin 14 is the Earth, Pin 16 is GPIO 23 and Pin 18 is GPIO 24.

For a second set of transceivers, you can consider GPIO 17 and 18 as COS & PTT for those.
With the modified CM-108 the transmit is dealt with from the Sound Card settings. 

A copy of a simple design can be found on Facebook Svxlink Amateur Radio Users. There is also a page showing the modification instructions for a CM-108 USB Sound Card on g4nab.co.uk.

<h3>The programming of the SDCard</h3>

Start with a download of <b>Raspberry OS Lite Bullseye - Debian 11 - (because the php used in the Dashboard for DVSwitch is of an older persuasion. Using Bookworm throws up error.)</b> from RaspberryPi.org. Then use a 8/16 GB MicroSD Card and transfer the image to the card using the Raspberry Pi Image builder from the same source.


Once complete, eject the card and install it in the raspberry pi and power it up. Enter the user as 'pi' and password 'raspberry' in lower case. 
<h3>The compilation</h3>
The first step will be the following command: <b>sudo apt update && sudo apt upgrade -y && sudo apt install -y git</b>  

Now the following command: <b>sudo git clone https://github.com/f5vmr/svxlink_raspberry_usrp svxlink_raspberry</b> .

<p>The next commands refer to Raspberry OS Bullseye 32 bit lite (Debian 11). If you wish to use Raspberry OS Buster (Debian 10) such as for the F8ASB Hotspot then you need to edit the svxlink_raspberry/install.sh script by changing php7.4 to php7.3 in the list of software the script will download. Failure to do this will crash the script.</p>

Now type <b>sudo bash svxlink_raspberry/install.sh</b> and return.

<p>The script will now update the software. You will be required to add the callsign of the node prior to the compilation of the software so watch for the prompt.</p>

<p>At the end of the script the running configuration will be compiled with the given callsign. Then the fun begins. Go and have a coffee or even lunch as the compilation will take about an hour possibly longer. A Raspberry Pi 3 or 4 will take less time, and a Raspberry Pi zero possibly longer than 90 minutes. Hopefully there should be no reported error.</p>

<p>At the end of the compilation type <b>sudo reboot</b> to restart the unit if it hasn't already. If all is well the unit will still be only partly functional. You will need to finalise the configuration for SVXLink and DVSwitch. You may continue to leave the rest of the functionality in place, as the configuration of the UsrpLogic is now conducted in /etc/svxlink/svxlink.d/UsrpLogic.conf, that you can edit. The linking of the SimplexLogic and UsrpLogic has been done for you inthe svxlink.conf</p>

<p>For further assistance in relation to setting up SVXLink, UsrpLogic and DVSwitch, I recommend you look closely at groups.io and the Svxlink and Dvswitch groups, as all the answers are there.</p>

<p>You will need to understand the svxlink.conf file and how to make adjustments for Simplex or Repeater operation. In any case you may need to refer to the svxlink.org main page, or svxlink amateur radio users page on facebook, or contact me. For further information also consult the svxlink pages on g4nab.co.uk.</p>

<p>To stop svxlink running type in the terminal <b>sudo systemctl stop svxlink.service</b> and to restart it type <b>sudo systemctl restart svxlink.service</b></p>
<p>The next stage will be to modify the three files <b>node_info.json</b>, <b>svxlink.conf</b>, and <b>ModuleEchoLink.conf</b>.</p>
<p>To obtain information for the node_info.json go to a PC Browser and enter <b>http://svxportal-uk.ddns.net:81</b> where you will find a dashboard.</p>
<p>Click <b>Register</b> at the top, completing the information. This information is held only to enable you to complete the next stage. Log in with the information you have just supplied, and click on <b font=color blue>Generate node_info.json</f></b>. Once complete, save the resulting file in your computer.</p>

<p>Open the terminal of the Raspberry Pi, and type <b>cd /etc/svxlink</b> followed by return. Then type <b>sudo nano node_info.json</b> and edit the information with the content of the file you have just saved on your PC. You can open the file with a text editor or notepad.</p>
<p>When the editing is complete type <b>cntrl-o</b> and return at the keyboard for the terminal followed by <b>cntrl-x</b>.
The next stage is to check and edit where necessary the <b>svxlink.conf</b> file. type <b>sudo nano svxlink.conf</b> followed by return.</p>
<p>Check the content and complete your location information near the bottom of the file. type <b>cntrl-o</b> and return then <b>cntrl-x</b> when finished to save your changes.</p>
<p>To modify the Echolink information type <b>sudo nano svxlink.d/ModuleEchoLink.conf</b> and return. Make your changes to your EchoLink access here. then save the file as you did above with <b>svxlink.conf</b>. If you have not yet enabled svxlink in the <b>svxlink.conf</b> to may need to do this now, and remove the <b>#</b> comment header from the relevant lines.</p>
<p>To incorporated the changes you will need to type <b>sudo systemctl restart svxlink.service</b> and return.</p>
<p>If you need to make changes to the <b>gpio.conf</b> file you will also need to restart the gpio service too.</p>
<p>Everything introduced here is from the original presentation by Tobias SM0SVX, modified slightly with some additional modules from DL1HRC.</p>
<p>This new script will download and compile DVSwitch into the folder /opt/Analog_Bridge and /opt/MMDVM_Bridge. You will need to modify all three .ini files Analog_Bridge, MMDVM_Bridge and DVSwitch. You will also need to download onto an android device DVSwitch_Mobile to control the functions of DVSwitch remotely, as it cannot yet be done from SVXlink.</p>

<p> Il y a un script inclusif pour le téléchargement français</p>


