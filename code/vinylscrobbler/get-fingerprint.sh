#!/bin/bash
#Use the arecord function to capture audio from the soundcard and save the audio to audioclip.wav
#The & at the end of the arecord function is used to run the arecord function on another thread
arecord -D hw:0,0 -f cd /home/pi/Desktop/dejavu/audioclip.wav &
#Because arecord is being run on another thread, sleeping our script doesn't halt recording
sleep 15
#After recording for 15 seconds, (after a 15 second audio file has been created) kill arecord
#This needs to be done manually because there is no way to have arecord only run for a set amount of time
killall -KILL arecord
#Run an audio analysis of the resulting sound file and save the results to the output variable
output=$(sox /home/pi/Desktop/dejavu/audioclip.wav -n stat 2>&1)
#parse the maximum amplitude from the resulting audio analysis 
IFS=$'\n'; read -rd '' -a TEMP <<< "$output"
IFS=$':'; read -rd '' -a TEMPTWO <<< "${TEMP[4]}"
#Strip whitespace out of our result and store it in the maxAmplitude variable
maxAmplitude="$(echo -e "${TEMPTWO[1]}" | tr -d '[:space:]')"
#Compare our maxAmplitude to 0.001 to see if if's a silent audio file or if music is actually being captured
#We use the awk command because bash can't do floating point math by default
#We store the awk result and check that
echo $maxAmplitude
varResult=$(awk 'BEGIN{ print "'$maxAmplitude'"<"'0.001'" }')
if [ "$varResult" -eq 1 ]; then
	#If the audio file is silence, do nothing
	echo "Audio file most likely silence, not sent for audio fingerprinting"
else
	#If the audio file is actual music, send the audio file to our networked machine to be fingerprinted
	scp -i /home/pi/.ssh/id_rsa /home/pi/Desktop/dejavu/audioclip.wav zachwhitten@10.0.0.66:/Users/zachwhitten/Documents/dejavu
	ssh zachwhitten@10.0.0.66 bash /Users/zachwhitten/Documents/dejavu/fingerprint.bash
        echo -e "-----------------------------------------------\n"
fi
