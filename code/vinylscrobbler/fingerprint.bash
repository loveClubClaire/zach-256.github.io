#!/bin/bash

cd /Users/zachwhitten/Documents/dejavu
#Run the fingerprinting program and save the result in a variable
output=$(python  dejavu.py --recognize file audioclip.wav)
#Parse the output of the fingerprinting program (get the song metadata)
#Check if dejavu identified the song. If it failed to, it returns nothing. Thus we check if the array "TEMP" is defined and if its not we exit the script. This prevents an infinate loop later in the scripts execution. Also, dejavu almost always identifies a given song, just with a very low confidence. When it returns nothing we can expect the audio file is empty. 
IFS=$','; read -rd '' -a TEMP <<< "$output"
if [ "${#TEMP[@]}" -eq 1 ]; then
echo "Song is not identified. Probably silent audio file. Exiting script."
exit 1
fi
#If the song name, artist, or album has commas in it anywhere it makes a mess because commas are the delimiter for parsing the metadata. So instead of the expected seven elements of metadata, we get nine or whatever, which will crash the script. We can fix this by adding array element 2 to array element 1 until the last char of  array element 1 is a " char. 
tempLength=${#TEMP[@]}
str="${TEMP[1]}"
echo "$str"
lastChar="${str: -1}"
echo "$lastChar"
while [ "$lastChar" != "'" ]
do
fixedTrack="${TEMP[1]},${TEMP[2]}"
unset TEMP[1]
TEMP[1]="$fixedTrack"
unset TEMP[2]
TEMP=( "${TEMP[@]}" )
str="${TEMP[1]}"
lastChar="${str: -1}"
done
IFS=$':'; read -rd '' -a TEMPTWO <<< "${TEMP[1]}"
IFS=$','; read -rd '' -a TEMPTHREE <<< "${TEMP[3]}"
IFS=$':'; read -rd '' -a TEMPFOUR <<< "$TEMPTHREE"
confidence="${TEMPFOUR[1]}"
#If we're confident about the song we've fingerprinted, then we scrobble 
if (( confidence > 5 )); then 
echo "Good confidence"
#Break the metadata up into song, artist, and album
metadata="${TEMPTWO[1]}"
#remove leading and trailing ' chars from metadata
metadata=$(echo "$metadata" | tr -d \')
#Set the delimiter to '-delim-'
sep='-delim-'
#Generates a variable with the individual components separated by line 
result="${metadata//$sep/$'\n'}"
#Convert our single variable with values separated by line to an array of values 
IFS=$'\n'; read -rd '' -a metadata <<< "$result"
#Place the value of the array elements into individual variables and strip away any whitespace from the metadata variables
song="$(echo -e "${metadata[0]}" | sed -e 's/^[[:space:]]*//')"
artist="$(echo -e "${metadata[1]}" | sed -e 's/^[[:space:]]*//')"
album="$(echo -e "${metadata[2]}" | sed -e 's/^[[:space:]]*//')"
#strip away any trailing and leading quotes
song=$(echo "${song}" | tr -d '"')
artist=$(echo "${artist}" | tr -d '"')
album=$(echo "${album}" | tr -d '"')
# strip away any trailing and leading quotes
#song=$(echo "${metadata[0]}" | tr -d '"')
#artist=$(echo "${metadata[1]}" | tr -d '"')
#album=$(echo "${metadata[2]}" | tr -d '"')
#Parse the contents of the last scrobbled file
i=0
sList=''
while read -r line
do
	name="$line"
	sList[i]=$(echo "$name")
	i=$((i+1))
done < "lastplayed.txt"
#Get the current date and subtract the date of our last scrobble 
now=$(date +%s)
past="${sList[3]}"
difference=$((now-past))
#If the song and artist we identified are the same as the last track we scrobbled, we don't scrobble 
#We assume the song hasn't ended since we've last scrobbled 
#But if greater than 24 hours have passed, we scrobble it anyway, regardless if the song and artist are the same
#Assumption here is that the song has ended and were just playing it again 
if [ "${sList[0]}" = "$song" ] && [ "${sList[1]}" = "$artist" ] && (( difference < 86400 )); then 
	echo -e "Don't scrobble, already captrued song\n"
else
	echo -e "Do scrobble\n"
	#When we scrobble, we call the scrobble.py program and pass it an input of the artist and song
	cd /Users/zachwhitten/Documents/pylast
	input=$artist" - "$song
	python scrobble.py $input
	#We then update the lastplayed.txt file to reflect the last song that was scrobbled 
	#We add the expletive at the end to make sure bash reads in all the important information in the file
	#(The last line of the file wasn't being read in. This is a cheep fix to that) 
	cd /Users/zachwhitten/Documents/dejavu
	toFile=$song'\n'$artist'\n'$album'\n'$now'\n'"shit"
	echo -e $toFile > "lastplayed.txt"
fi
fi 
exit 0
