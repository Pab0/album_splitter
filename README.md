# album_splitter
Simple awk/bash script to split a (single-video) album from YouTube into separate tracks, based on the tracks listed in its description.

## Syntax
```bash
./album_splitter.sh URL [download location]
```
## How to use
Simply copy the album's YouTube URL and pass it as an argument to album_splitter.sh
```bash
./album_splitter.sh https://www.youtube.com/watch?v=3x4mpl3_1d
```
The script will then download the audio, and create a new directory containing the separate tracks and a tracklist.

By default, the album will be downloaded to the current directory. Another directory may be specified as an argument after the URL , such as
```bash
./album_splitter.sh https://www.youtube.com/watch?v=3x4mpl13_1d ~/Music
```

The YouTube video should contain the titles/timestamps in its description, which the script uses to determine each track.

## Requirements
-  [youtube-dl](https://github.com/rg3/youtube-dl)
-  ffmpeg (should have been installed with youtube-dl)
-  awk (should already be installed on most systems)
