#Takes a list of tracks formatted as [start time] - [title] as input,
#and splits the audio into separate tracks

BEGIN {
    print "Album title: " at;
    print "Filename: " fn;
    print "Extension: " ext;
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
    print "Processing track No. " trackNo+1 ". " title " " timestamp;
    if (NR!=1)
        splitTrack();
    prev_timestamp = timestamp;
    prev_title = title;
    trackNo++;
}

END {
    #Since end time is needed, each line generates the last line's track.
    #After parsing all lines, only the last track remains to be generated.
    timestamp = "end";     #signals that this is the last track
    splitTrack();
    print "Done splitting";
    #bubble up if there was a error
    exit err;
}

#needed because the variables come from untrusted inputs and will be used on system, see:
#https://unix.stackexchange.com/questions/64212/system-calls-awk-and-bringing-in-external-inputs/64218#64218
#specifically see the comment below since we *are* in awk script
function escape(s) {
    gsub(/'/, "'\\''", s);
    return "'" s "'";
}

function splitTrack(    track_start,track_end)
{
    album = escape(at);
    file  = escape(fn);

    track_start = " -ss " escape(prev_timestamp);
    #last track doesn't need to have its ending specified
    track_end = (timestamp!="end" ? " -to " escape(timestamp) " " : " ");
    output = escape(trackNo ". " prev_title "." ext);
    # -loglevel debug
    aux = system("ffmpeg -y -loglevel warning " \
                " -i "             \
                file               \
                track_start        \
                track_end          \
                " -metadata title="\
                escape(prev_title) \
                " -metadata track="\
                escape(trackNo)    \
                " -metadata album="\
                album              \
                " -acodec copy "   \
                output );
    if (aux!=0)
        err = -1;
    #Adding some basic ID3 tags: title, track number and album (assumed to be the video's title)
}
#TODO: BUG: Album art (/thumbnail) is only added to first track
