---
layout: post
title: Vinyl Scrobbling
excerpt_separator: <!--more-->
---

For about 10 years now I’ve used Last.FM to track the music I listen to. I enjoy being able to see what I’ve been listening to over the past week, six months, or several years. I’ve only ever used Last.FM for music I listened to on my computer, as logging (or scrobbling as it’s known) the music I listen to on my iPod / iPhone has never been practical. But a few years ago, a new way to listen to music was introduced into my life. I was given a record player for Christmas in 2014 and became a collector of vinyl. I enjoyed collecting and listening to records for a variety of reasons and it became a regular way for me to listen to music. But it being an analog system, it wasn’t compatible with Last.FM. I didn’t want to see my Last.FM account fall to the wayside and wondered if there was any way to solve this problem. What followed was a system capable of identifying songs being played on my record player and sending the appropriate song metadata to Last.FM. This post documents how I designed and built a vinyl scrobbler.
<!--more-->
First, I needed a way to capture analog audio while simultaneously sending the analog signal to my speakers. No point in identifying what song is being played if you can’t hear it! I used a <a target="_blank" href="https://www.raspberrypi.org/">Raspberry Pi</a> (a <a target="_blank" href="https://www.raspberrypi.org/blog/introducing-raspberry-pi-model-b-plus/">Model B+ v1.2</a>) and an <a target="_blank" href="http://shop.audioinjector.net/detail/sound_card/Stereo+Raspberry+pi+sound+card">Audio Injector Stereo Raspberry Pi Sound Card</a> from Flatmax. The Audio Injector would allow me to pass high quality audio through the pi without a significant loss in audio quality. Before I could worry about audio identification, I needed to get the sound card working with the pi. The procedure is:

<ol>
<li>Install <a target="_blank" href="https://www.raspberrypi.org/downloads/">Raspbian</a> onto the pi and <a target="_blank" href="https://www.raspberrypi.org/documentation/raspbian/updating.md">update it</a> using {% highlight blank%} $ sudo apt-get update 
 $ sudo apt-get dist-upgrade {% endhighlight %}</li>
<li>Connect the Audio Injector to the pi. The Audio Injector card connects using the pi’s general purpose I/O pins.</li> 
<li>Download the Audio Injector <a target="_blank" href="http://www.flatmax.org/phpbb/viewtopic.php?t=3">configuration file</a> onto the pi. (The linked forum post provides instructions for installing the configuration file. While these instructions can provide valuable insight into how the Audio Injector works, we’ll go over all aspects of configuring the Audio Injector here. Consider this more of a mirror than original research.)</li>
<li>Install <a target="_blank" href="http://sox.sourceforge.net/">SoX</a> <code>$ sudo apt-get install sox</code> </li>
<li>Install the downloaded Audio Injector configuration file. Navigate to the directory where the config file is, and use <code>$ sudo dpkg -i audio.injector.scripts_0.1-1_all.deb</code> </li>
<li>Run the now installed config file using <code>$ audioInjector-setup.sh</code> </li>
<li>Reboot the pi <code>$ sudo reboot</code> </li>
<li>Run <code>$ alsactl --file /usr/share/doc/audioInjector/asound.state.RCA.thru.test restore</code> to make the Audio Injector’s RCA connections the audio input and output for the pi. </li>
<li>Run <code>$ alsamixer</code> to open the AlsaMixer application on your pi. This is a GUI application for configuring sound. Pressing F6 will bring up a list of all available sound cards. The Audio Injector card should be enabled by default (on my configuration, it was the only card available). Pressing F3 will bring up audio output settings. Navigate to the “Input Mux” column and use the up and down arrow keys to change its value to “Line In”. (This may be the default setting. If so, take no action). You can modify the master output volume by navigating to the “Master” column and modifying the values using the up and down arrow keys. (for my setup I have Master set to 100). Next, press F4 to bring up audio input settings. Navigate to the “Line” column and press space bar to change the value of the column to “CAPTURE”. Make sure the “Mic” column is set to “- - - - - - -”. You can modify the input volume by navigating to the “Capture” column and modifying the values using the up and down arrow keys. (for my setup I have Capture set to 100). With these values set, press control c to exit the AlsaMixer application. (In short, we configured the pi to use the inputs from the sound card rather than a microphone. We also configured the pi to actually use the sound cards outputs)</li>
</ol>

At this point, the sound card should be working with the pi. You should be able to connect an RCA input and RCA output and audio should pass though the pi without issue. To record audio coming into the pi from the RCA input, use the <a target="_blank" href="https://linux.die.net/man/1/arecord">arecord</a> command. To play audio through the RCA output, use the <a target="_blank" href="https://linux.die.net/man/1/aplay">aplay</a> command. WARNING: The sound card uses ALSA audio and ALSA audio has no audio decompression support. As a result, you cannot play .mp3 files using the aplay command and get any RCA output. Use .wav files with the aplay command to test audio output. 

Once I got the soundcard working with the pi, I needed a way to capture audio clips and identify them. For audio identification (also known as audio fingerprinting) I found an open source project called <a target="_blank" href="https://github.com/worldveil/dejavu">dejavu</a>. Dejavu is an audio fingerprinting and recognition algorithm implemented in Python. From its GitHub page: 

> Dejavu can memorize audio by listening to it once and fingerprinting it. Then by playing a song and recording microphone input, Dejavu attempts to match the audio against the fingerprints held in the database, returning the song being played.

In this case, we won’t be recording microphone input, rather directly capturing the audio signal from the RCA cables! As I settled on using dejavu, I encountered an issue. Dejavu required much more processing power than my old Model B+ could muster. In a small scale testing environment, the Model B+ would take several minutes to identify a given audio file, a performance metric which was only going to get worse in a real world environment. I needed more power for the audio fingerprinting if I wanted it to be completed in a reasonable amount of time. 

Enter my old Early 2011, 15 inch MacBook Pro. With an upgraded 16GB of RAM, a solid state drive, and a 2.2Ghz Intel Core i7 (sitting on a replaced logic board with a working graphics card), this machine would have more than enough power to do audio fingerprinting at a rapid clip. This machine sits powered on under my television for other various reasons, so it was a perfect fit for doing the audio fingerprinting. 

The system would work by:
<ol>
<li>Having the pi constantly capture 15 second audio clips</li>
<li>Checking if those audio clips were silence or contained audio</li>
<li>If they contained audio, it would send the audio file to my MacBook Pro</li>
<li>The MacBook Pro would then run dejavu to identify the given track. </li>
</ol>
Before figuring out how to implement this system, I wanted to get dejavu installed and working on my MacBook Pro. The procedure is:
<ol>

<li>Install <a target="_blank" href="https://brew.sh/">Homebrew</a></li>
<li>Install the necessary dependencies for dejavu as listed on <a target="_blank" href="https://github.com/worldveil/dejavu/blob/master/INSTALLATION.md">dejavu’s github</a>
<ol type="a" style="margin-bottom: 0px;">
<li>Although not explicitly noted in the dependency list for dejavu, you must first install mysql before installing MySQL-python. mysql can be installed using <code>$ brew install mysql</code> </li>
</ol>
</li>
<li>Start the mysql server using <code>$ mysql.server start </code> </li>
<li>Create a new mysql server for dejavu to use:
{% highlight blank%}$ mysql -u root -p
Enter password: ******* 
mysql> CREATE DATABASE IF NOT EXISTS dejavu; {% endhighlight %} </li>
<li>Install dejavu <code>$ git clone https://github.com/worldveil/dejavu.git ./dejavu</code> (You should install this in the directory you want it to permanently reside in)</li>
</ol>


When dejavu is given an audio clip it generates an audio fingerprint of that clip and then compares that fingerprint to a collection of fingerprints in a database. If it matches the clip fingerprint with a fingerprint in the database, dejavu returns the metadata associated with that fingerprint. Before I could pass dejavu audio clips to identify, I needed to populate its database with audio fingerprints so it had something to compare the given audio clips to! So I went about fingerprinting my music library. I had digital audio files of every record I owned, so I would fingerprint those files rather than capturing the audio from the vinyl somehow. I wrote a small python program (<a target="_blank" href="/code/vinylscrobbler/importpy">import.py</a>) which takes .mp3 and .m4a files stored in a specific folder (the mp3 folder in the dejavu source folder) and fingerprints them. This program worked great, but I still needed to manually drag all of the files into the mp3 folder and run the program. Also, I had installed dejavu on my 2011 MacBook Pro, a secondary machine which didn’t have a copy of my music library. On top of this, my record collection wasn’t going to remain stagnant. As new music was released I would be buying new records and would need to add tracks to the dejavu fingerprint database. For these reasons, I wanted to make the process of adding tracks to the dejavu fingerprint database as painless as possible. 

My solution was to develop a bash script (<a target="_blank" href="/code/vinylscrobbler/remoteFingerprintCommand">Remote Fingerprint.command</a>) which would run on my primary machine, a 2013 MacBook Pro. This script:
<ol>
<li>Uses AppleScript to copy the audio files of tracks in a specific iTunes playlist named “Vinyl” to a folder in the filesystem.</li>
<li>Changes the filename of each audio file to contain all necessary metadata.</li>
<li>Uses scp to copy the audio files to the 2011 MacBook Pro with dejavu installed.</li>
<li>Uses ssh to run import.py and delete the copied audio files after they had been fingerprinted.</li>
</ol>
With this script, adding tracks to dejavu is a breeze. On my primary machine, I need to create a playlist named “Vinyl” in iTunes, add all the tracks I want fingerprinted, and run Remote Fingerprint.command. All there is to it. 


A few technical notes about the Remote Fingerprint script. Most of the script is dedicated to pulling track metadata from iTunes and making it the name of the audio file. The reason is dejauv doesn’t specifically store track metadata. It only stores an audio file’s fingerprint and filename. We work around this limitation by adding all the necessary metadata to the filename! I provide this script as it appears on my system, so the filepaths given are non-generic. For the most part, the filepaths in this script can be modified if you’re going to implement this system. The location of the audio files before they are sent to the dejavu machine, for example, is arbitrary and any location on disk will work fine. Lastly, the scp and ssh commands normally require password input. Requesting password input would break the script (and frankly needing to enter a password each time the script is run would be annoying) so an identity file is used for authentication. <a target="_blank" href="https://coolestguidesontheplanet.com/create-a-ssh-private-and-public-key-in-osx-10-11/">Here</a> is a tutorial about creating an identity file for two macOS machines. 

With our Audio Injector sound card working with our Raspberry Pi, dejauv installed, and its database populated, it was time to capture audio from the pi and identify it with dejauv. The first step was to write a bash script (<a target="_blank" href="/code/vinylscrobbler/getFingerprintSh">get-fingerprint.sh</a>) to be executed on the pi. This script:
<ol> 
<li>Records a fifteen second clip of system audio. (Which should be configured to be the RCA input from the Audio Injector)</li>
<li>Runs an audio analysis of the recorded clip and determine if the clip contains more than silence. </li>
<li>If the audio clip is silence, no action is taken and the script concludes. </li>
<li>If the audio clip contains sound, the clip is sent to the dejavu machine and a script is run (fingerprint.bash, which we’ll mention in a moment) to identify the track.</li>
</ol>
We use Raspbian’s Cron tool to schedule this scripts execution time. To schedule a task, we use the command <code>$ crontab -e</code> to modify the cron table. Once open, we add the following line to the cron table:  <code>* * * * * /home/pi/Desktop/dejavu/get-fingerprint.sh >> /home/pi/Desktop/fingerprint.log 2>&1</code> This line does two things. First, it executes the get-fingerprint.sh script once a minute. Second, it places the output of get-fingerprint.sh into a log file on the Desktop. The resulting log file can get quite large, so if you would like to disable this feature, simply place <code>* * * * * /home/pi/Desktop/dejavu/get-fingerprint.sh</code> into the cron table instead. With get-fingerprint.sh running once a minute, there is no need to inform our pi when to listen for audio input, the pi is always listening! If we place a record on the turntable, there are no extra steps to enable audio fingerprinting, the process is completely relegated to the background.


Although get-fingerprint.sh is well commented, I’ll make a few points about the design choices for the script. We use the arecord command to record the audio from RCA in. But the arecord command has no options to specify a recording length. The command is designed to be manually halted by a user when the desired recording time has elapsed. Because our script does not take user input, the default behavior of arecord is to record for an infinite amount of time. So until arecord concludes we cannot execute any later part of the script, preventing the script from terminating. We solve this problem by running the arecord command on a new thread, allowing the scripts execution to continue while arecord runs in the background. To get a fifteen second audio clip, we run arecord on a new thread, pause our script for fifteen seconds using the sleep command, then use the killall command to terminate the arecord process. This results in a fifteen second audio file stored in whatever location we specified. To determine if a recorded audio clip is silent, we use SoX to perform an audio analysis of the recorded clip. From that analysis, we parse out the maximum amplitude of the audio clip. If the max amplitude is less than .001, we assert the file is silent and no action is taken. If the max amplitude is greater than .001, we send the audio file to the dejavu machine and run fingerprint.bash. We determine if a recorded audio clip is silence on the pi to reduce network congestion. We have nothing to gain from constantly sending silent audio files over the network to the dejavu machine, thus the increased network burden is unnecessary and avoided. When we do send an audio clip, it will always have the same filename and if a file with the same filename already exists on the dejavu machine, it will be overwritten. 

The next step was to write a bash script (<a target="_blank" href="/code/vinylscrobbler/fingerprintBash">fingerprint.bash</a>) to be executed on the dejavu machine which would identify a given audio clip and send the information to Last.FM. This script:
<ol>
<li>Uses dejavu to identify the given audio clip. To do this we call the python program dejavu.py, which is provided by dejauv, and pass the program our given audio clip as a parameter.</li>
<li>Captures the output of dejavu.py and parses out the necessary information.</li>
<li>Checks if dejavu was confident in its identification of the given audio clip.</li>
<li>If dejavu was confident, the script checks if the identified track was the last song scrobbled.</li>
<li>If the track the script identified is the same as the last track scrobbled, it doesn’t scrobble.</li>
<li>If the identified track is different than the last track scrobbled, the script scrobbles the identified track.</li>
<li>If the track the script identified is the same as the last track scrobbled but more than 24 hours have passed, the script scrobbles the identified track.</li>
</ol>
To remember the last track scrobbled, fingerprint.bash saves track metadata to a text file after each scrobble. This text file is read into the script to determine if the identified track is the same as the last track scrobbled. We include this check because get-fingerprint.sh is executed once a minute. We don’t want to scrobble the same track four times in a row because it is four minutes long! But if greater than 24 hours have passed, we scrobble the track, regardless If the track we identified are the same as the last track we scrobbled. The assumption is that the song has ended and were just playing it again at a later time.  As with pervious scripts, the filepaths in fingerprint.bash are non-generic. Most of fingerprint.bash is parsing the data from dejavu.py’s output and formatting that data into the format required to scrobble. Bash doesn’t make this process easy, hence the script is rather large. 


Keen observers will note that fingerprint.bash calls an external python program named scrobble.py to do the actual scrobbling. The scrobble.py program is taken from the <a target="_blank" href="https://github.com/hugovk/lastfm-tools">lastfm-tools</a> project, which in turn uses <a target="_blank" href="https://github.com/pylast/pylast">pylast</a>, an open source python interface for last.fm. The procedure for installing scrobble.py and its dependencies are as follows: 
<ol>
<li>Install <a target="_blank" href="https://pypi.python.org/pypi/pip">pip</a>, a package manager for python, using <code>sudo easy_install pip </code> </li>
<li>Install pylast using <code>sudo pip install pylast </code> </li>
<li>Change the directory to wherever you want scrobble.py to reside. This location is permanent because it is referenced in fingerprint.bash. On my system, I saved scrobble.py at /Users/zachwhitten/Documents/pylast</li>
<li>Download the mylast.py program using <code>curl -O https://raw.githubusercontent.com/hugovk/lastfm-tools/master/mylast.py</code> mylast.py is used by scrobble.py to interface with pylast and authenticate with last.fm. Before mylast.py will be able to interface with last.fm, we are going to need to modify the program slightly. In order for a program to interface with last.fm, the program needs an API Key and an API Secret. For the program to interface with a specific user account, it’s going to need that accounts username and password.</li> 
<li>To generate the last.fm API Key and API Secret, head to <a target="_blank" href="last.fm">last.fm</a> and log into your last.fm account. Once logged in, you can create a last.fm API account <a target="_blank" href="https://www.last.fm/api/account/create">here</a>. You don’t need to fill out the Callback URL or Application Homepage fields. Once you hit the submit button on the Create API account page, you will be given both an API key and an API Secret. As last.fm notes, there is no way for you to access the key or secret again, so take a screenshot of the page to make sure you have them permanently stored.</li>
<li>In mylast.py, replace LASTFM_API_KEY on on line 13 with the API Key you received from last.fm. Next, replace LASTFM_API_SECRET on line 14 with the API Secret you received. Place the key and secret inside of the single quotes, do not delete the single quotes.</li>
<li>In mylast.py, replace LASTFM_USERNAME on line 20 with your last.fm username. Again, placing the username inside the single quotes. Also replace the my_username on line 24 with your username. For the LASTFM_PASSWORD_HASH, you need to generate the <a target="_blank" href="https://en.wikipedia.org/wiki/MD5">MD5 hash</a> of your password. You can do so using the mylast.py program, or you can use an <a target="_blank" href="http://www.miraclesalad.com/webtools/md5.php">online MD5 hash generator</a>. Using an online generator is quicker but I understand individuals being trepidatious about entering their password into an online service. Once you’ve generated your password’s hash, replace LASTFM_PASSWORD_HASH on line 21 with it. Also replace pylast.md5(“my_password”) on line 26 with your password’s hash.</li>
<li>Now that mylast.py is correctly configured, install scrobble.py using <code>curl -O https://raw.githubusercontent.com/hugovk/lastfm-tools/master/scrobble.py </code> </li>
</ol>
Now that we’ve installed scrobble.py and all its dependencies, we change the corresponding filepath in fingerprint.bash. 

With the successful instillation of scrobble.py, we have successfully implemented a vinyl scrobbler! All we have left to do is physically install the pi in a suitable location. At this point in the build I realized I didn’t have a case for my pi and that I had no desire to order one and wait for it to arrive. I wanted the project to be finished. So I took the box the Audio Injector came in, cut some holes out of the sides with an xacto bade, placed the pi in the box, and screwed it into the table I keep my record player on. Once mounted, I connected the pi to power and connected the necessary RCA cables. And with that the system was completed! 


<table style="background-color:rgba(0, 0, 0, 0); border:none;">
<tbody style="background-color:rgba(0, 0, 0, 0);">
<tr style="background-color:rgba(0, 0, 0, 0);">
<td style="background-color:rgba(0, 0, 0, 0); border:none;">
<img src="/public/images/audioscrobbler1.jpg" alt="Raspberry Pi case" style="width: 400px; display: block; margin-left: auto; margin-right: auto;"/>
</td>
<td style="background-color:rgba(0, 0, 0, 0); border:none;">
<img src="/public/images/audioscrobbler2.jpg" alt="Like really poorly constructed Raspberry Pi case" style="width: 400px; display: block; margin-left: auto; margin-right: auto;"/>
</td>
</tr>
<tr>
<td style="background-color:rgba(0, 0, 0, 0); border:none;">
<img src="/public/images/audioscrobblerMount1.jpg" alt="Mount shot 1" style="width: 400px; display: block; margin-left: auto; margin-right: auto;"/>
</td>
<td style="background-color:rgba(0, 0, 0, 0); border:none;">
<img src="/public/images/audioscrobblerMount2.jpg" alt="Mount shot 2" style="width: 400px; display: block; margin-left: auto; margin-right: auto;"/>
</td>
</tr>
</tbody>
</table>
<img src="/public/images/audioscrobblerPlayer.jpg" alt="The setup" style="width: 400px; padding-right: 50px; display: block; margin-left: auto; margin-right: auto;"/>



Lastly, a few pieces of miscellaneous information. First, the fingerprint.log file generated on the pi can get large fast. Whenever I need to look through it, I copy the file from the pi to a more powerful machine to make the process less painful. Also, to prevent the fingerprint.log file from getting too large, you can write a script to delete the log file and use cron to execute this delete script every 24 hours or so. Second, when debugging this system, the first thing you should do is run alsamixer on the pi and check to make sure everything is properly configured. I’ve found that alsamixer likes to reset itself back to the default settings on occasion, especially after a restart. Third, another point to debug is the mysql server on the dejavu machine. It doesn’t automatically start after a reboot, so make sure to use <code>$ mysql.server start</code> after rebooting the machine. Forth, I have my dejavu set to never sleep. Although I originally had it set to wake on network access, I found a request to ssh into the machine did not wake it from its sleep state. So if the dejavu machine is asleep, it cannot be accessed the system will fail to work. Fifth, when fingerprinting audio files on the dejavu machine, although the fingerprinting process is rather quick, storing the fingerprints in the mysql database is mind-numbingly slow. I don’t have a good idea why this is and I don’t have a strong enough knowledge of mysql to see an obvious issue. I will keep poking it at and attempt to improve its performance. In the meantime, don’t panic if it takes an extended amout of time to add fingerprinted songs to the mysql database. To confirm that any tracks are being added, you can use the following commands {% highlight blank%}
$ mysql -u root –p
use dejavu
SELECT song_name FROM songs; 
exit{% endhighlight %} to display all of the fingerprinted songs in the mysql database. If after an hour or so you don’t see any of the songs you are attempting to add in the database, you can safely say the program is encountering an error at some point. 

Until next time, <br>
Zach

