#!/bin/bash
# https://github.com/DonkeeeyKong/diceware

# include config-file
source "$(dirname "${0}")/diceware.conf"


# check if first argument is a number. If yes, set to passphrase length and
# shift arguments to next one, in case there is also another argument specified.
if [ -n "$1" ] && [ "$1" -eq "$1" ] 2> /dev/null
then
	wortanzahl="$1"
	shift
fi

# Get options
while getopts f:hn opt
do
	case $opt in
		f)
			# if '-f' is given, set next parameter as diceware list file
	 		dicewareopt="$OPTARG"
	 		# shift arguments in case there is a number after the file
	 		shift "$(($OPTIND -1))"
	 		# check again if the now first argument is a number
	 		# and set to passphrase length if yes
			if [ -n "$1" ] && [ "$1" -eq "$1" ] 2> /dev/null
			then
				wortanzahl="$1"
			fi
	 		;;
		h) 
			# show help and exit
	 		echo "Help"
	 		exit 1
	 		;;
	 	n)
	 		# if 'n' is given, set only numbers to true
	 		onlynumbers="1"
	 		# shift arguments in case there is a number after the file
	 		shift "$(($OPTIND -1))"
	 		# check again if the now first argument is a number
	 		# and set to passphrase length if yes
	 		if [ -n "$1" ] && [ "$1" -eq "$1" ] 2> /dev/null
			then
				wortanzahl="$1"
			fi
	 		;;
		?)
			# abort for all other options
			echo "Invalid option."
			exit 1
			;;
	esac
done

# Check if a passphrase length has been passed. 
if [ -z "$wortanzahl" ]
then
	# set to default length, if no.
	wortanzahl="${defaultlength:=6}"
fi

# Check if onlynumbers option is turned on
if [[ "$onlynumbers" == "1" ]]
then
	# if yes, generate 5 dice rolls per set word, print the numbers and exit
	declare -i i=0
	while [ $i -lt $wortanzahl ]
	do
			zahlen[i]="$(echo $(($RANDOM % 6 + 1))$(($RANDOM % 6 + 1))$(($RANDOM % 6 + 1))$(($RANDOM % 6 + 1))$(($RANDOM % 6 + 1)))"
			i=i+1
	done
	echo "${zahlen[*]}"
	exit 1
fi

# set default text file for diceware lists (is a symlink)
dicewaredefault="$(dirname "${0}")/dicewaredefault.txt"

# check if a custom list to use has been passed and if it's a file
if [ -f "$dicewareopt" ]
then
	# if it's a file, copy its contents to a temp file
	dicewaretemp=$(mktemp)
	cat "$dicewareopt" > "$dicewaretemp"
	# remove possible Carriage Returns, if the file has been edited in Windows
	sed -i 's/\r$//' "$dicewaretemp"
	# set temp file as file to be used
	dicewaredatei="$dicewaretemp"
else
	# check if the default file from the configuration file is a weblink
	if [[ "$defaultdwfile" =~ ^https?://*|^ftp://*|^file://* ]]
	then
		# if it's a weblink, check if it's woking and if it points to a text file
		if [[ "$(curl -sIkL "$defaultdwfile" | sed -r '/content-type:/I!d;s/.*content-type: (.*)$/\1/I')" =~ ^text/plain* ]] &&
			[[ ! "$(curl --head --silent --output /dev/null --write-out '%{http_code}' "$defaultdwfile")" =~ ^404*|^403* ]]
		then
			# get the filename from the link
			if [[ $(curl -sIkL "$defaultdwfile" | sed -r '/filename=/!d;s/.*filename=(.*)$/\1/') ]]
			then 
				defaultdwfilename="$(dirname "${0}")/$(curl -skIL "$defaultdwfile" | sed -r '/filename=/!d;s/.*filename=(.*)$/\1/' | sed 's/\r//g' | sed 's/"//g')"
			else
				defaultdwfilename="$(dirname "${0}")/$(basename "$(curl "$defaultdwfile" -s -L -I -o /dev/null -w '%{url_effective}' | sed -e s/?viasf=1//)")"
			fi
			# check if the filename is already referred by the default text file symlink
			if [[ "$defaultdwfilename" = "$(basename "$(realpath "$dicewaredefault")")" ]]
			then
				# if yes, download the file from the link, if it's newer than the file on disk
				curl --no-progress-meter -L -o "$defaultdwfilename" -z "$defaultdwfilename" "$defaultdwfile"
			else
				# if no, download it in every case
				curl --no-progress-meter -L -o "$defaultdwfilename" "$defaultdwfile"
			fi
			# make the default text file symlink point to the default file we just downloaded or updated
			ln -rfs "$defaultdwfilename" "$dicewaredefault"
		# if the weblink is not working or not a textfile, check if the default text file symlink points to a file on disk
		elif [ -f "$(realpath "$dicewaredefault")" ]
		then
			# if yes, print a message and proceed
			echo -e "${defaultdwfile} is not a reachable plain text file.\nProceeding with '${dicewaredefault}'."
		else
			# if no, print an error and abort, since there is no list to work with
			echo -e "${defaultdwfile} is not a reachable plain text file.\n'${dicewaredefault}' doesn't exist or doesn't point to a file.\nAborting."
			exit 1
		fi
	else
		# if the default file from the configuration is not a weblink, check if it's a file
		if [ -f "${defaultdwfile}" ]
		then
			# if it's a file, make the default text file symlink point to it
			ln -rfs "$defaultdwfile" "$dicewaredefault"
		# if it's not a file, check if the default text file symlink points to a file on disk
		elif [ -f "$(realpath "$dicewaredefault")" ]
		then
			# if yes, print a message and proceed
			echo -e "${defaultdwfile} is not a file.\nProceeding with '${dicewaredefault}'."
		else
			# if no, print an error and abort, since there is no list to work with
			echo -e "${defaultdwfile} is not a file.\n'${dicewaredefault}' doesn't exist or doesn't point to a file.\nAborting."
			exit 1
		fi
	fi
	# remove possible Carriage Returns, if the default file has been edited in Windows
	sed -i 's/\r$//' "$(realpath "$dicewaredefault")"
	# set the default file as the file to work with
	dicewaredatei="$dicewaredefault"
fi
# check if the file contains numbers with 5 digits
if grep -F "11111" "$dicewaredatei" >> /dev/null
then
	# if yes, get the amount of words with numbers
	dwfilelength="$(awk '/11111/ {b=NR; next} /66666/ {print NR-b+1; exit}' "$dicewaredatei")"
# check if the file contains numbers with 5 digits
elif grep -F "1111" "$dicewaredatei" >> /dev/null
then
	# if yes, get the amount of words with numbers
	dwfilelength="$(awk '/1111/ {b=NR; next} /6666/ {print NR-b+1; exit}' "$dicewaredatei")"
else
	# if none of the both is true, abort, since there is no list to work with
	echo "'${dicewaredatei}' does not contain correctly formatted numbers. Aborting."
	exit 1
fi
declare -i i=0
if [[ "$dwfilelength" = "1296" ]]
then
	while [ $i -lt $wortanzahl ]
	do
			zahlen[i]="$(echo $(($RANDOM % 6 + 1))$(($RANDOM % 6 + 1))$(($RANDOM % 6 + 1))$(($RANDOM % 6 + 1)))"
			woerter[i]="$(echo ${zahlen[i]} | grep -Ff - "$dicewaredatei" | awk '{print $2}')"
			i=i+1
	done
elif [[ "$dwfilelength" = "7776" ]]
then
	while [ $i -lt $wortanzahl ]
	do
			zahlen[i]="$(echo $(($RANDOM % 6 + 1))$(($RANDOM % 6 + 1))$(($RANDOM % 6 + 1))$(($RANDOM % 6 + 1))$(($RANDOM % 6 + 1)))"
			woerter[i]="$(echo ${zahlen[i]} | grep -Ff - "$dicewaredatei" | awk '{print $2}')"
			i=i+1
	done
else
	echo "A diceware list has to contain 1296 or 7776 words. '${dicewaredatei}' contains ${dwfilelength:=0} words. Aborting."
	exit 1
fi
echo "${zahlen[*]}" 
echo "${woerter[*]}"
(IFS=$'-'; echo "${woerter[*]}")
rm -f "$dicewaretemp"
exit 0
