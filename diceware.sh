#!/bin/bash
# Diceware Passphrase Generator Script
# https://github.com/DonkeeeyKong/diceware
version="0.1"
configfile="$(dirname "${0}")/diceware.conf"
# include config-file
source "$configfile"


# check if first argument is a number. If yes, set to passphrase length and
# shift arguments to next one, in case there is another argument given.
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
			# if '-f' is passed, set next parameter as diceware list file
	 		dicewareopt="$OPTARG"
	 		# check if passed argument is a file. Unset variable, if not.
	 		if [ ! -f "${dicewareopt}" ]
	 		then
	 			echo "'${dicewareopt}' is not a file. Proceeding with word list '${defaultdwfile}'."
	 			echo
	 			unset dicewareopt
	 		fi
	 		# shift arguments in case there is a number after the filename
	 		shift "$((OPTIND -1))"
	 		# check again if the now first argument is a number and set to passphrase 
	 		# length if yes
			if [ -n "$1" ] && [ "$1" -eq "$1" ] 2> /dev/null
			then
				wortanzahl="$1"
			fi
	 		;;
		h) 
			# show help and exit
			echo "Diceware Passphrase Generator Script ${version}"
			echo "configuration file: $(realpath "${configfile}")"
			echo
	 		echo "Usage:"
	 		echo "command [passphrase length] [options]"
	 		echo "	or"
	 		echo "command [options] [passhrase length]"
	 		echo
	 		echo "No options set:"
	 		echo "	generate a passphrase from the word list set in the config file."
	 		echo "	Use the default passphrase length (6 words, if not set otherwise"
	 		echo "	in the config file)."
	 		echo
	 		echo "passphrase length"
	 		echo "	Optional. Can be any number, passed before or after other options."
	 		echo "	Sets the amount of words constituting the passphrase. E.g.:"
	 		echo "		command 2"
	 		echo "	will generate"
	 		echo "		'word1 word2' and 'word1-word2'"
	 		echo "	while"
	 		echo "		command 8 -f [path to optional word list file]"
	 		echo "	will generate"
	 		echo "		'word1 word2 word3 word4 word5 word6 word7 word8' and"
	 		echo "		'word1-word2-word3-word4-word5-word6-word7-word8'"
	 		echo "		from 'word list file' (see below)"
	 		echo
	 		echo "optional flags:"
	 		echo "-f [word list file]"
	 		echo "	use [word list file] instead of the word list set in the config"
	 		echo "	file. Has to be a text file with 7776 or 1296 words and contain a"
	 		echo "	list with dice roll results and their corresponding words."
	 		echo "	(1296 words: 4 dice thrown simultaneously, 7776 words: 5 dice"
	 		echo "	thrown simultaneously)."
	 		echo "		list format: [dice roll result] [word]"
	 		echo "		e.g.:"
	 		echo "		11111 example"
	 		echo "-h"
	 		echo "	print this help and exit"
	 		echo "-n "
	 		echo "	print only numbers, don't use a word list, i.e. only simulate dice"
	 		echo "	rolls without generating a passphrase." 
	 		echo "	Prints the results of 5 dice thrown simultaneously for as many"
	 		echo "	times as set with [passphrase length] or in the config file."
	 		echo "	If nothing is set, default is 6 times."
	 		echo " 	"
	 		exit 0
	 		;;
	 	n)
	 		# if 'n' is passed, set only numbers to true
	 		onlynumbers="1"
	 		# shift arguments in case there is a number after the flag
	 		shift "$((OPTIND -1))"
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
	while [ $i -lt "$wortanzahl" ]
	do
		zahlen[i]="$((RANDOM % 6 + 1))$((RANDOM % 6 + 1))$((RANDOM % 6 + 1))$((RANDOM % 6 + 1))$((RANDOM % 6 + 1))"
		i=i+1
	done
	echo "${zahlen[*]}"
	exit 0
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
			# make the default text file symlink point to the default file we just 
			# downloaded or updated
			ln -rfs "$defaultdwfilename" "$dicewaredefault"
		# if the weblink is not working or not a textfile, check if the default text
		# file symlink points to a file on disk
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
	while [ $i -lt "$wortanzahl" ]
	do
			zahlen[i]="$((RANDOM % 6 + 1))$((RANDOM % 6 + 1))$((RANDOM % 6 + 1))$((RANDOM % 6 + 1))"
			woerter[i]="$(echo "${zahlen[i]}" | grep -Ff - "$dicewaredatei" | awk '{print $2}')"
			i=i+1
	done
elif [[ "$dwfilelength" = "7776" ]]
then
	while [ $i -lt "$wortanzahl" ]
	do
			zahlen[i]="$((RANDOM % 6 + 1))$((RANDOM % 6 + 1))$((RANDOM % 6 + 1))$((RANDOM % 6 + 1))$((RANDOM % 6 + 1))"
			woerter[i]="$(echo "${zahlen[i]}" | grep -Ff - "$dicewaredatei" | awk '{print $2}')"
			i=i+1
	done
else
	echo "A diceware list has to contain 1296 or 7776 words. '${dicewaredatei}' contains ${dwfilelength:=0} words. Aborting."
	exit 1
fi
echo "${woerter[*]}"
(IFS=$'-'; echo "${woerter[*]}")
echo "--"
echo "Dice roll results: ${zahlen[*]}"
rm -f "$dicewaretemp"
exit 0
