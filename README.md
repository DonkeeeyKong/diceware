# Diceware Passphrase Generator
Bash script to create passphrases from diceware lists.

## Description
This script can generate random passphrases from [diceware](https://en.wikipedia.org/wiki/Diceware) lists like [this one](https://github.com/dys2p/wordlists-de/blob/main/de-7776-v1-diceware.txt).
It can also be used to simulate rolling five dices simultaneosuly for a set amount of times to get random results to be used with diceware lists.

*Note that from a cryptographic point of view, it's always better to use actual dice instead of a script to generate random numbers.*

## Settings
Two variables can be set in `diceware.conf` (has to be in the same folder as the script):

### Default word list
`defaultdwfile`
The standard word list to be used. This can be a weblink or a local file. Has to be a text file with a list of either 1296 or 7776 words (i.e rolling four resp. five 6-sided dice simultaneosuly).
Default is [this](https://github.com/dys2p/wordlists-de/blob/main/de-7776-v1-diceware.txt) excellent and carefully curated German word list.
List format has to be as follows (see [here](https://theworld.com/~reinhold/diceware.html) for examples in various languages):
```
1111 word1
1112 word2
...
6665 word1295
6666 word1296
```
or
```
11111 word1
11112 word2
...
66665 word7775
66666 word7776
```

### Default passphrase length
`defaultlength`
Amount of words constituting the passphrase / times the dice are thrown together.

## Usage
```
./diceware.sh [passphrase length] [options]
	or
./diceware.sh [options] [passhrase length]
```
Possible command arguments:
* any number without a flag: passphrase length
* `-f` [word list file]: set a custom word list file to use for this run
* `-n`: only simulate dice rolls without using a word list.
* `-h`: show help

### Default mode
If run without any arguments, the script will generate a six-word-passphrase from the word list set in the configuration file `diceware.conf`. If another default passphrase length is set, in the configuration file, it will generate a passphrase containing as many words as the number there.

### Custom passphrase length
```
./diceware.sh [passphrase length]
```
If a number is passed with the command before, after or without another argument, this number overrides the default passphrase length set in `diceware.conf`. The script will generate a passphrase containing as many words as the number passed with the command.

Example:

Command:
```
./diceware.sh 8
```
Output:
```
word1 word2 word3 word4 word5 word6 word7 word8
word1-word2-word3-word4-word5-word6-word7-word8
--
Dice roll results: 11111 22222 33333 444444 55555 66666 12345 23456
```

### Custom word list file
```
./diceware.sh -f [word list file]
```
If the path to a word list file is passed after the flag `-f`, this file is used instead of the default word list set in `diceware.conf`. 
Unlike `diceware.conf` this can only be a local file, not a weblink. It has to contain 1296 or 7776 words with their corresponding numbers from 1111 to 6666 resp. 11111 to 66666 (see [settings](#default-word-list) for more information on the required format).

Examples:

Command: 
```
./diceware.sh -f /homer/user/diceware/diceware-7776.txt
```
Result:
This will generate a passphrase from the words in the file `/homer/user/diceware/diceware-7776.txt`. The passphrase will consist of as many words as set in the configuration file. It will consist of 6 words if nothing is set there.

This option can be used in combination with a custom passphrase length:
Command: 
```
./diceware.sh 8 -f /homer/user/diceware/diceware-7776.txt
```
This will generate an 8-word-passphrase from the words in the file `/homer/user/diceware/diceware-7776.txt`

```
./diceware.sh -f /homer/user/diceware/diceware-7776.txt 8 # this is also possible
./diceware.sh -f 8 /homer/user/diceware/diceware-7776.txt 8 # this is not possible. Default settings will be used instead.
```

### only numbers mode
```
./diceware.sh -n
```
If the flag `-n` is used, random rolls of five dice will be simulated and the results will be printed to screen. 
No word list will be used and no passphrase will be generated.

Examples:

Command: 
```
./diceware.sh -n
```
Result:
This will print blocks of five randomly generated digits between 1 and 6 to the screen. By default the output will be as many blocks as the value of `defaultlength` in `diceware.conf`. If nothing is set there, it will be six 5-digit blocks.

This option can be used in combination with a custom passphrase length:
Command: 
```
./diceware.sh 8 -n
```
This will output 8 randomly generated 5-digit-blocks consisting of numbers between 1 and 6.

```
./diceware.sh -n 8 # this is also possible
```

