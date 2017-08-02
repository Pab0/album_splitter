#Parses the YouTube description provided (or any input, really) 
#and extracts the track list formatted as [start_time] - [title]
BEGIN {
	timestamp_regex="[0-9]*:?[0-5]?[0-9]:[0-5][0-9]"
}

#Split non-timestamp into two (before and after timestamp) parts.
#The title is assumed as being the longer of the two.
#This is done in order to remove track numbers, tildes, 
#and any other characters belonging neither to the timestamp nor to the title.
$0 ~ timestamp_regex {
	arr[1] = $0; arr[2] = $0;
	sub("^.*"timestamp_regex, "", arr[1]);
	sub(timestamp_regex".*", "", arr[2]);
	timestamp = substr($0, match($0, timestamp_regex), RLENGTH);
	arr[1] = chomp(arr[1]);
	arr[2] = chomp(arr[2]);
	title = (length(arr[1])>length(arr[2]) ? arr[1] : arr[2]);
	#Convert to [timestamp] - [title] format
	print timestamp " - " title;
}

#Strip leading/trailing whitespace, tildes, hyphens etc. 
function chomp(str){
	sub(/(^[^a-zA-Z\[('"]*[0-9]+[^a-zA-Z])/, "", str); 
	#Title may start with number only if immediatelly followed by letter, e.g. "9th Symphony"
	sub(/[^a-zA-Z0-9!?\])'"]*$/, "", str);
	return str;
}
