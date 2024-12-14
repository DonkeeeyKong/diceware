#!/bin/bash
# https://github.com/DonkeeeyKong/diceware
source "$(dirname "${0}")/diceware.conf"
if [ -n "$1" ]
then
	wortanzahl="$1"
else
	wortanzahl="${defaultlength:=6}"
fi
dicewaredefault="$(dirname "${0}")/dicewaredefault.txt"
if [ -f "$2" ]
then
	dicewaretemp=$(mktemp)
	cat "$2" > "$dicewaretemp"
	sed -i 's/\r$//' "$dicewaretemp"
	dicewaredatei="$dicewaretemp"
else
	if [[ "$defaultdwfile" =~ ^https?://*|^ftp://*|^file://* ]]
	then
		if [[ "$(curl -sIkL "$defaultdwfile" | sed -r '/content-type:/I!d;s/.*content-type: (.*)$/\1/I')" =~ ^text/plain* ]] &&
			[[ ! "$(curl --head --silent --output /dev/null --write-out '%{http_code}' "$defaultdwfile")" =~ ^404*|^403* ]]
		then
			if [[ $(curl -sIkL "$defaultdwfile" | sed -r '/filename=/!d;s/.*filename=(.*)$/\1/') ]]
			then 
				defaultdwfilename="$(dirname "${0}")/$(curl -skIL "$defaultdwfile" | sed -r '/filename=/!d;s/.*filename=(.*)$/\1/' | sed 's/\r//g' | sed 's/"//g')"
			else
				defaultdwfilename="$(dirname "${0}")/$(basename "$(curl "$defaultdwfile" -s -L -I -o /dev/null -w '%{url_effective}' | sed -e s/?viasf=1//)")"
			fi
			if [[ "$defaultdwfilename" = "$(basename "$(realpath "$dicewaredefault")")" ]]
			then
				curl --no-progress-meter -L -o "$defaultdwfilename" -z "$defaultdwfilename" "$defaultdwfile"
			else
				curl --no-progress-meter -L -o "$defaultdwfilename" "$defaultdwfile"
			fi
			ln -rfs "$defaultdwfilename" "$dicewaredefault"
		elif [ -f "$(realpath "$dicewaredefault")" ]
		then
			echo -e "${defaultdwfile} is not a reachable plain text file.\nProceeding with '${dicewaredefault}'."
		else
			echo -e "${defaultdwfile} is not a reachable plain text file.\n'${dicewaredefault}' doesn't exist or doesn't point to a file.\nAborting."
			exit 1
		fi
	else
		ln -rfs "$defaultdwfile" "$dicewaredefault"
	fi
	sed -i 's/\r$//' "$(realpath "$dicewaredefault")"
	dicewaredatei="$dicewaredefault"
fi
if grep -F "11111" "$dicewaredatei" >> /dev/null
then
	dwfilelength="$(awk '/11111/ {b=NR; next} /66666/ {print NR-b+1; exit}' "$dicewaredatei")"
elif grep -F "1111" "$dicewaredatei" >> /dev/null
then
	dwfilelength="$(awk '/1111/ {b=NR; next} /6666/ {print NR-b+1; exit}' "$dicewaredatei")"
else
	echo "'${dicewaredatei}' does not contain correctly formatted numbers. Aborting."
	exit 1
fi
declare -i i=0
if [[ "$dwfilelength" = "1296" ]]
then
	while [ $i -lt $wortanzahl ]
	do
			woerter[i]="$(echo $(($RANDOM % 6 + 1))$(($RANDOM % 6 + 1))$(($RANDOM % 6 + 1))$(($RANDOM % 6 + 1)) | \
				grep -Ff -  "$dicewaredatei" | awk '{print $2}')"
			i=i+1
	done
elif [[ "$dwfilelength" = "7776" ]]
then
	while [ $i -lt $wortanzahl ]
	do
			woerter[i]="$(echo $(($RANDOM % 6 + 1))$(($RANDOM % 6 + 1))$(($RANDOM % 6 + 1))$(($RANDOM % 6 + 1))$(($RANDOM % 6 + 1)) | \
				grep -Ff -  "$dicewaredatei" | awk '{print $2}')"
			i=i+1
	done
else
	echo "A diceware list has to contain 1296 or 7776 words. '${dicewaredatei}' contains ${dwfilelength:=0} words. Aborting."
	exit 1
fi
echo "${woerter[*]}"
(IFS=$'-'; echo "${woerter[*]}")
rm -f "$dicewaretemp"
exit 0
