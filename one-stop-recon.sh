#!/bin/bash

#setting the first argument as variable domain
domain=$1

#color code to make output look a bit cleaner
RED="\033[1;31m"
RESET="\033[0m"

#declare additional directory variables
info_path=$domain/info
subdomain_path=$domain/subdomains
screenshot_path=$domain/screenshots
subdirectory_path=$domain/subdirectories

#if a directory named 'domain' (from argument 1) doesn't exist, make the folder in working dir
if [ ! -d "$domain" ];then
	mkdir $domain
fi

#creates 'domain/info' folder if it doesn't already exist in directory 'domain/'
if [ ! -d "$info_path" ];then
	mkdir $info_path
fi

#creates 'domain/subdomains' folder if it doesn't already exist in directory 'domain/'
if [ ! -d "$subdomain_path" ];then
	mkdir $subdomain_path
fi

#creates 'domain/screenshots' folder if it doesn't already exist in directory 'domain/'
if [ ! -d "$screenshot_path" ];then
	mkdir $screenshot_path
fi

#creates 'domain/subdirectories' folder if it doesn't already exist in directory 'domain/'
if [ ! -d "$subdirectory_path" ];then
	mkdir $subdirectory_path
fi

# adds color and echo to show verbosity on status of script
echo -e "${RED} [+] Running 'whois' check ... ${RESET}"

# run whois statement and output into text file within 'domain/info' directory
# one '>' --> overwrites file
# two '>>' --> appends at end of file (adds on to existing file)
whois $1 > $info_path/whois.txt

echo -e "${RED} [+] Running 'subfinder' check ... ${RESET}"
subfinder -d $domain > $subdomain_path/found.txt

echo -e "${RED} [+] Running 'assetfinder' check ... ${RESET}"
assetfinder $domain | grep $domain >> $subdomain_path/found.txt

echo -e "${RED} [+] Running GoBuster check ... ${RESET}"
gobuster dir -u $domain -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt >> $subdirectory_path/found.txt

# commented out as Amass run-time is rather slow. Can be un-commented as needed
#echo -e "${RED} [+] Running 'Amass' check ... This could take a while... ${RESET}"
#amass enum -d $domain >> $subdomain_path/found.txt

# -- Below will compile ALL found entries from tools above (subfinder, assetfinder, amass) and probe to see what's alive, then output --
echo -e "${RED} [+] Checking what is alive... ${RESET}"
# reads the 'found.txt' file (everything inside)
# grep out the domain so that only our domain exists within the file
# sort the file by unique entries
# run httprobe to see what found entires are alive
# grep out only the https entries that are found alive 
# remove 'https://' at the beginning of each entry with 'sed' tool
# put all remaining wihtin 'alive_hosts.txt'
cat $subdomain_path/found.txt | grep $domain | sort -u | httprobe -prefer-https | grep https | sed 's/https\?:\/\///' | tee -a $subdomain_path/alive.txt

# Takes screenshots of domain/sub-domain pages and saves to 'domain/screenshots' directory
echo -e "${RED} [+] Taking screenshots of domain/sub-domain pages found and alive... ${RESET}"
gowitness file -f $subdomain_path/alive.txt -P $screenshot_path/ --no-http
