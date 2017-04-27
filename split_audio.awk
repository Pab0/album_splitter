#Takes a list of tracks formatted as [start time] - [title] as input,
#and splits the audio into separate tracks

BEGIN {
	print "Received album title " at;
	print "Received filename " fn
	print "Splitting file";
	timestamp_regex="[0-9]*:?[0-5]?[0-9]:[0-5][0-9]";
}

$0 ~ timestamp_regex {
	print "Processing track No. " trackNo-1 " " title " " timestamp[1];
	#Splitting timestamp and title from entry
	split($0, raw_title, timestamp_regex, timestamp);
	title = substr(raw_title[2], 4); 	#removes the " - ";
	if (NR!=1)
		splitTrack();
	prev_timestamp = timestamp[1];
	prev_title = title
	trackNo++;
}

END {
	#Since end time is needed, each line generates the last line's track.
	#After parsing all lines, only the last track remains to be generated.
	timestamp[1] = "end"; 	#signals that this is the last track
	splitTrack();
	print "Done splitting";
}

function splitTrack()
{
	track_start = " -ss " prev_timestamp;
	#last track doesn't need to have its ending specified
	track_end = (timestamp[1]!="end" ? " -to " timestamp[1] : "");
	#Extra quoting is needed for shell calls
	system("ffmpeg -i \"" fn "\" " track_start track_end \
	" -metadata title=\"" prev_title "\" -metadata track=" trackNo \
	" -metadata album=\"" at "\" " \
	" -acodec copy \"" trackNo ". " prev_title ".mp3\"");
	#Adding some basic ID3 tags: title, track number and album (assumed to be the video's title, to be added)
}
#TODO: BUG: Album art (/thumbnail) is only added to first track
