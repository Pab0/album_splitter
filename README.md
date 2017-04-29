# album_splitter
Simple awk/bash script to split a (single-video) album from YouTube into separate tracks, based on the tracks listed in its description.

## How to use
Simply copy the album's Youtube URL and pass it as an argument to album_splitter.sh
```
./album_splitter.sh https://www.youtube.com/watch?v=3x4mpl3_1d
```
The script will then download the audio, and create a new directory containing the separate tracks and a tracklist.

The YouTube video should contain the titles/timestamps in its description, which the script uses to determine each track.

## Requirements
-  [youtube-dl](https://github.com/rg3/youtube-dl)
-  ffmpeg (should have been installed with youtube-dl)
-  awk (should be already installed on most systems)
