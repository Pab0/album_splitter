#!/bin/bash
#Fetches the album video's description and parses the titles and timestamps for tracks.
#The album is then downloaded, converted to audio and split into single tracks according to the parsed track information.
if [ -z $(command -v youtube-dl) ]; then
	echo "youtube-dl required but not found on the system, please install it first"
	exit $?
fi

edit_pl=0
single=0
keep_video=0
location='.'
#for the option to always it in playlist
while getopts ":hkesd:" opt; do
  case ${opt} in
    h )
        echo -e "\
Youtube-dl album download and splitter helper.\n\
given a supported url, downloads and tries to get\n\
from the description a playlist to segment the audio.\n\
The -e option always allows edits, not only when this\n\
info is missing.\n\
The -s option considers each link as a single and is\n\
incompatible with -e.\n\
The -k option keeps the video, for if you're not sure of\n\
the split ofsets and want to experiment without redownload.\n\
\n\
album_splitter.sh [-e edit playlist | -s treat as single] [-k keep video] [-d output dir] [url]\n"
      ;;
    e )
        edit_pl=1
      ;;
    d )
        location="$OPTARG"
      ;;
    s )
        single=1
      ;;
    k )
        keep_video=1
      ;;
    \? )
        echo -e "Usage: album_splitter.sh [-h] [-e | -s] [-k] [-d output dir] [url]"
      ;;
  esac
done

if ([ $(( $# - $OPTIND )) -ne 0 ]) || ([ $edit_pl -eq 1 ] && [ $single -eq 1 ]); then
    echo -e "Usage: album_splitter.sh [-h] [-e | -s] [-k] [-d output dir] [url]"
    exit 1
fi

yt_link=${@:$OPTIND:1}

#Switch to correct location
location="${location:-"."}"
if [ ! -d "$location" ]; then
	echo "$location isn't a directory"
	exit 1
fi
cd "$location"

#this is needed because the script might be invoked from another dir
#and expecting parts of the program to be in current dir breaks
script_location="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

album_title=$(youtube-dl -s --get-title "$yt_link" | tr '/' '|')

if [ $single -eq 1 ]; then
    tracklist="00:00 - $album_title"
else
    description=$(youtube-dl --get-description "$yt_link")
    tracklist=$(echo "$description" | awk -f "$script_location/format_titles.awk" | tr '/' '|') #slashes aren't allowed in filenames

    if ([ "$tracklist" = "" ]) || ([ $edit_pl -eq 1 ]); then
        TMPFILE=`mktemp -t album_splitter_playlist.XXXXXXXXXX` || exit 1

        if [ "$tracklist" = "" ]; then
            echo "#$yt_link has no playlist, write it in, or skip" > "$TMPFILE"
        else
            echo -e "#$yt_link\n$tracklist" > "$TMPFILE"
        fi
        nano --restricted "$TMPFILE"
        description=$(<"$TMPFILE")
        tracklist=$(echo "$description" | awk -f "$script_location/format_titles.awk" | tr '/' '|')
        if [ "$tracklist" = "" ]; then
            exit 1
        fi
    fi
    echo "Converted to [timestamp] - [title] format"
    echo "Tracks:"
    echo "$tracklist" | nl -s". "
fi

mkdir "$album_title" 2> /dev/null
cd "$album_title"
echo "$tracklist" | nl -s". " > tracklist.txt

yt_video=$(youtube-dl -s --get-id "$yt_link" ) #the --id option above ensures the file is named as expected

#if it already exists, find the file, that is not the original video or parts of it, print and quit after the first
#note: since find -name doesn't use regex but wildcards, the '.' is part of the name, not the 'any character' regex
filename=$(find . -type f -name "$yt_video.*" ! -name "$yt_video.webm*" -print -quit)
#youtube downloader is smart enough that the 'in progress' download is named different from a complete one
if [ ! -e "$filename" ]; then
    youtube-dl -k -f bestaudio/best --id --extract-audio --audio-format best --console-title "$yt_link"
    if [ $? -ne 0 ]; then
        exit 1
    fi
    filename=$(find . -type f -name "$yt_video.*" ! -name "$yt_video.webm*" -print -quit)
fi

if [ ! -e "$filename" ]; then
    echo "Something is wrong with the downloaded audio, did you delete it?"
    exit 1
fi

extension="${filename##*.}"

if [ $single -eq 1 ]; then
    mv -f "./$filename" "./$album_title.$extension"
    #youtube-dl can automatically choose another container if required
    if [ $keep_video -ne 1 ]; then
        rm -f ./*.webm ./*.mp4 ./*.mkv
    fi
    rm -f "./tracklist.txt"  ./*.part
    exit 0 #nothing to do, conversion would only lower quality
fi

cat tracklist.txt | awk -v at="$album_title" -v fn="$filename" -v ext="$extension" -f "$script_location/split_audio.awk"

if [ $? -eq 0 ]; then
    if [ $keep_video -ne 1 ]; then
        rm -f ./*.webm ./*.mp4 ./*.mkv
    fi
    rm -f "./tracklist.txt" ./*.part "./$filename"
else
    echo "finished with errors, not deleting tmp files for reuse after input or script fix".
    exit 1
fi

exit 0
