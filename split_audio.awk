#Takes a list of tracks formatted as [start time] - [title] as input,
#and splits the audio into separate tracks

BEGIN {
	print "Album title: " at;
	print "Filename: " fn
	print "Splitting file";
	timestamp_regex="[0-9]*:?[0-5]?[0-9]:[0-5][0-9]";
}

$0 ~ timestamp_regex {
	#Removing track number from format [TrackNumber]. [Timestamp] - [TrackTitle]
	sub(" *[0-9]*\. *", "");
	#Splitting timestamp and title from entry
	timestamp = $0; title =$0;
	sub(" - .*", "", timestamp);
	sub(timestamp_regex" - ", "", title);
	print "Processing track No. " trackNo+1 " " title " " timestamp;
	if (NR!=1)
		splitTrack();
	prev_timestamp = timestamp;
	prev_title = title;
	trackNo++;
}

END {
	#Since end time is needed, each line generates the last line's track.
	#After parsing all lines, only the last track remains to be generated.
	timestamp = "end"; 	#signals that this is the last track
	splitTrack();
	print "Done splitting";
}

function splitTrack()
{
	track_start = " -ss " prev_timestamp;
	#last track doesn't need to have its ending specified
	track_end = (timestamp!="end" ? " -to " timestamp : "");
	#Extra quoting is needed for shell calls
	system("ffmpeg -i \"" fn "\" " track_start track_end \
	" -metadata title=\"" prev_title "\" -metadata track=" trackNo \
	" -metadata album=\"" at "\" " \
	" -acodec copy \"" trackNo ". " prev_title ".mp3\"");
	print "ffmpeg -i \"" fn "\" " track_start track_end \
	" -metadata title=\"" prev_title "\" -metadata track=" trackNo \
	" -metadata album=\"" at "\" " \
	" -acodec copy \"" trackNo ". " prev_title ".mp3\"";
	#Adding some basic ID3 tags: title, track number and album (assumed to be the video's title)
}
#TODO: BUG: Album art (/thumbnail) is only added to first track
