#!/bin/bash
#Fetches the album video's description and parses the titles and timestamps for tracks.
#The album is then downloaded, converted to audio and split into single tracks according to the parsed track information.
#Usage: 
#./ablum_splitter.sh [URL] [location], where
#URL = YouTube URL, location = location to save the tracks to.

#Fetch track list
timestamp_regex="[0-9]*:?[0-5][0-9]:[0-5][0-9]"
if [ -z "$(command -v youtube-dl)" ]; then
	echo "youtube-dl required but not found on the system, please install it first"
	exit $?
fi

description=$(youtube-dl --get-description $1)
#TODO alternatively get timestamps from YT comment if they aren't available in the description?
tracklist=$(echo "$description" | awk -f format_titles.awk | tr '/' '|') #slashes aren't allowed in filenames

echo "Converted to [timestamp] - [title] format"
echo "Tracks:"
echo "$tracklist" | nl -s". "

#Switch to correct location
script_location=$(pwd)
location=${2:-"."}
if [ ! -d "$location" ]; then
	echo "$location isn't a directory, downloading to current directory instead"
	location="."
fi
cd "$location"

#Download audio
album_title=$(youtube-dl --get-title $1 | tr '/' '|')
mkdir "$album_title"
cd "$album_title"
echo "$tracklist" | nl -s". " > tracklist.txt
youtube-dl --id --extract-audio --embed-thumbnail --audio-format mp3 --console-title $1 
filename="$(youtube-dl --get-id $1).mp3" #the --id option above ensures the file is named as expected

#Splitting audio
cat tracklist.txt | awk -v at="$album_title" -v fn="$filename" -f "$script_location"/split_audio.awk 
rm "$filename"

exit 0
