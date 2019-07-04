#Parses the YouTube description provided (or any input, really) 
#and extracts the track list formatted as [start_time] - [title]
BEGIN {
	timestamp_regex="[0-9]*:?[0-5]?[0-9]:[0-5][0-9]"
    start = 0
    possible_unmarked_start = ""
}

#some videos playlists start with the 'first' without a 00:00 timestamp
#record to detect
$0 !~ timestamp_regex {
    possible_unmarked_start = $0
}

$0 ~ timestamp_regex {
    doit($0);
}

#Split non-timestamp into two (before and after timestamp) parts.
#The title is assumed as being the longer of the two.
#This is done in order to remove track numbers, tildes, 
#and any other characters belonging neither to the timestamp nor to the title.
function doit(str,      title, timestamp){
	arr[1] = str; arr[2] = str;
	sub("^.*"timestamp_regex, "", arr[1]);
	sub(timestamp_regex".*", "", arr[2]);
	timestamp = substr(str, match(str, timestamp_regex), RLENGTH);
	arr[1] = chomp(arr[1]);
	arr[2] = chomp(arr[2]);
	title = (length(arr[1])>length(arr[2]) ? arr[1] : arr[2]);
	#Convert to [timestamp] - [title] format
    if(start==0){
        start = start + 1;
        #if the offset from zero is not < 10 seconds
        if(timestamp !~ "[0]*:?[0]?[0]:[0][0-9]")
            doit( "0:00" possible_unmarked_start);
    }
	print timestamp " - " title;
}

#Strip leading 'nonwords'. The first word can have weird characters/delimiters.
#ex: "9-12th Symp." is ok, "[~12th Symp.]" is ok but "~ 123. [12th Symp.]" is not ok
function chomp(str,      WORD){
	#greedy match, mawk 1.3.3 (default in ubuntu and debian) doesn't support character classes
	if (match(str, /^[^a-zA-Z\[('"]*/ )) {
		#backtrack if needed
		WORD = RLENGTH + 1;
		if(match(substr(str,1,RLENGTH), /[^ \t\f]*$/ )){
			WORD = RSTART;
		}
		str = substr(str, WORD);
	}
	return str;
}
