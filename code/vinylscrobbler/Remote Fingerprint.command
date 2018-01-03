#!/bin/sh
#Change our directory to the dejavu directory and then run the dejavu import program
cd /Users/zachwhitten/Documents/Projects/Audio\ Fingerprinting/dejavu
#Get the number of songs in the playlist we are fingerprinting
playlistCount=$(osascript << END
tell application "iTunes"
	set playlist_count to number of tracks in playlist "Vinyl"
	return playlist_count
end tell
END)

#For every song were a fingerprinting...
for ((i = 1; i <= $playlistCount; ++i)); do
#Create a new filename consisting of the song name, artist name, and album name
newFilename=$(osascript -- - "$i" <<'EOF'
  on run(argv)
  	set song_count to item 1 of argv as number
    tell application "iTunes"
		set my_artist to artist of track song_count of playlist "Vinyl"
		set my_album to album of track song_count of playlist "Vinyl"
		set my_song to name of track song_count of playlist "Vinyl"
		set my_type to location of track song_count of playlist "Vinyl" as string
		set AppleScript's text item delimiters to "."
		set my_type to my_type's text items
		set my_filename to my_song & "-delim-" & my_artist & "-delim-" & my_album & "." & item (the count of my_type) in my_type
		return my_filename
	end tell
  end
EOF)
#Get the filepath for the song file
fileLocation=$(osascript -- - "$i" <<'EOF'
  on run(argv)
  	set song_count to item 1 of argv as number
    tell application "iTunes"
		set file_location to location of track song_count of playlist "Vinyl"
		return POSIX path of file_location
	end tell
  end
EOF)
#Escape necessary characters
newFilename="$(echo "$newFilename" | sed -e 's/[/]/:/g')"
#Copy the music file to the mp3 folder in dejavu. Also change the name of the copied file to our new filename
cp "$fileLocation" /Users/zachwhitten/Documents/Projects/Audio\ Fingerprinting/dejavu/mp3/"$newFilename"
echo "file "$i" copied"
done

#Copy files to other machine
scp -i /Users/zachwhitten/.ssh/id_rsa -r /Users/zachwhitten/Documents/Projects/Audio\ Fingerprinting/dejavu/mp3 zachwhitten@10.0.0.66:/Users/zachwhitten/Documents/dejavu
#run fingerprint on other machine 
ssh -tt zachwhitten@10.0.0.66 << EOF
  cd /Users/zachwhitten/Documents/dejavu
  python import.py
  rm -rf mp3/*
  exit
EOF

#ssh zachwhitten@10.0.0.66 cd /Users/zachwhitten/Documents/dejavu; python import.py; rm -rf mp3/*
rm -rf /Users/zachwhitten/Documents/Projects/Audio\ Fingerprinting/dejavu/mp3/*