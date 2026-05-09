#!/usr/bin/env bash


function ctrl_c(){
    echo -e "\n\n${redColour}[+] Exiting...${endColour}\n"
    exit 1
}

# Ctrl+C
trap ctrl_c SIGINT


# Colors 
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
cyanColour="\e[0;36m\033[1m"
whiteColour="\e[0;37m\033[1m"

# This script will attempt to mitigate the copy_fail attack. CVE-2026-31431 
# echo "install algif_aead /bin/false" | sudo tee /etc/modprobe.d/manual-disable-algif_aead.conf
# sudo rmmod algif_aead 2>/dev/null
# grep -qE '^algif_aead ' /proc/modules && echo "Affected module is loaded" || echo "Affected module is NOT loaded"

NOTLOADED=$(grep -qE '^algif_aead ' /proc/modules && echo "Affected module is loaded" || echo "Affected module is NOT loaded")
RESULT=$(grep -qE '^algif_aead ' /proc/modules && echo "Affected module is loaded" || echo "Affected module is NOT loaded")

if [[ $EUID -ne 0 ]]; then
   echo -e "\n${redColour}[-] It is recommended to run this script as root...${endColour}\n"
fi

if [[ -f /etc/modprobe.d/manual-disable-algif_aead.conf ]]; then
	echo -e "\n${greenColour}[+] Mitigation file is already present... No further action needed.${endColour}\n"
	sudo tree /etc/modprobe.d
	wait
	echo -e "\n${blueColour}[*] Contents of the mitigation file:${endColour}\n"
	sudo cat /etc/modprobe.d/manual-disable-algif_aead.conf
	echo -e "\n${yellowColour}[*] Verifying if the affected module is loaded...${endColour}\n"
	if [[ $NOTLOADED == "Affected module is NOT loaded" ]]; then
		echo -e "\n${greenColour}[+] The affected module is not loaded. Mitigation is effective...${endColour}\n"
	else
		echo -e "\n${redColour}[-] The affected module is still loaded. Mitigation is not effective...${endColour}\n"
	fi
	exit 0
else
	echo -e "\n${redColour}ERROR: [-] Mitigation file is not present. Check path.${endColour}\n"
	echo -e "\n${yellowColour}[*] Attempting to create the mitigation file...${endColour}\n"
fi
wait
sleep 1

if ! [[ -f /etc/modprobe.d/manual-disable-algif_aead.conf ]]; then
	echo -e "\n${redColour}[-] The mitigation file does not exist. This script will create it...${endColour}\n"
	echo -e "\n${yellowColour}[*] Mitigating copy_fail attack...${endColour}\n"
	#### The following line is the important one. It creates a file in /etc/modprobe.d that prevents the affected module from loading on boot.
	echo "install algif_aead /bin/false" | sudo tee /etc/modprobe.d/manual-disable-algif_aead.conf
	wait
	echo "blacklist algif_aead" | sudo tee -a /etc/modprobe.d/manual-disable-algif_aead.conf
	echo -e "\n${blueColour}[*] Mitigation file created successfully...${endColour}\n"
	tree /etc/modprobe.d
	wait
	echo -e "\n${blueColour}[*] Contents of the mitigation file:${endColour}\n"
	sudo cat /etc/modprobe.d/manual-disable-algif_aead.conf

	echo -e "\n${greenColour}[+] Unloading the algif_aead module...${endColour}\n"
	sudo rmmod algif_aead 2>/dev/null
	wait
	if [[ $RESULT == "Affected module is NOT loaded" ]]; then
		echo -e "\n${greenColour}[+] Mitigation successful. The affected module is not loaded...${endColour}\n"
	else
		echo -e "\n${redColour}[-] Mitigation failed. The affected module is still loaded...${endColour}\n"
	fi
else
	echo -e "\n${yellowColour}[*] Mitigation file already exists...${endColour}\n"
	if [[ $NOTLOADED == "Affected module is NOT loaded" ]]; then
		echo -e "\n${greenColour}[+] The affected module is not loaded. Mitigation is effective...${endColour}\n"
	else
		echo -e "\n${redColour}[-] The affected module is still loaded. Mitigation is not effective...${endColour}\n"
	fi
fi