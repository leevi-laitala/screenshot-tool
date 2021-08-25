#!/usr/bin/sh
path="/home/$USER/Code/screenshot-tool/"
tmp="/tmp/"

iconError="report_problem"
iconSuccess="add_photo_alternate"
iconImgur="cloud_upload"

# Notification functions
errorMessage () {
    # $1 error message string
    dunstify -i $iconError -t 5000 -u critical "Taking screenshot failed" "$1"
    [ -f "$path$file" ] && rm -f "$path$file"

    exit 1
}

notify () {
    # $1 title, $2 message, $3 icon
    dunstify -i "$3" -t 5000 -u low "$1" "$2"
}

geometry="$(slop -q -b 2)" || errorMessage "Cancelled by user"

file="$(date +'%Y-%m-%d_%H-%M-%S').png"

opt1="Keep screenshot"
opt2="Upload to Imgur & Keep screenshot"
opt3="Delete screenshot"

# Take screenshot
shotgun -f png -g $geometry "$path$file" && \
    opt=$(echo -e "$opt1\n$opt2\n$opt3" | dmenu -i -p "What next?" | grep "\<$opt1\>\|\<$opt2\>\|\<$opt3\>")

[ -z "$opt" ] && errorMessage "Cancelled by user"

case $opt in
    $opt1) # Keep screenshot
        notify "Screenshot taken" "Saved to $path\nwith size of $(du -h $path$file | awk '{print $1}')" $iconSuccess
        exit 0
        ;;
    $opt2) # Upload to imgur
        imgurdata="$tmp$(date +'imgurupload-%N')"
        imgurqt --anonymous "$path$file" >> $imgurdata && \
            cat $imgurdata | awk '/Image/ {print $3}' | xclip -selection clipboard && \
            notify "Uploaded to Imgur" "URL copied to clipboard, more details in\n$imgurdata" ‰iconImgur
        exit 0
        ;;
    $opt3) # Delete screenshot
        rm -f "$path$file" && notify "Screenshot deleted" "Screenshot deleted" $iconError
        exit 0
        ;;
esac

errorMessage ""
