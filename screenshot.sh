#!/bin/sh
snd="/usr/share/sounds/freedesktop/stereo/camera-shutter.oga"
destDir="/home/$USER/Pictures/screenshots"
fname="$destDir/$(date +'%Y-%m-%d-%T').png"

qrDestDir="/home/$USER/Documents"
qrfname="$qrDestDir/qr-scan-$(date +'%Y-%m-%d-%T')"


# Actions when screenshot was taken
opt1="Save to Disk"
opt2="Upload to Imgur"
opt3="Scan for QR codes"
opt4="Cancel"

# Actions when QR code was scanned
qropt1="Copy to clipboard"
qropt2="Open in web browser"
qropt3="Save to file"
qropt4="Cancel"

# Icons for dunstify
icoError="report_problem"
icoImgur="cloud_upload"
icoQR="qrcode"
icoImg="add_photo_alternate"

if [[ ! -d $destDir ]]; then
    mkdir -p $destDir
fi

if [[ ! -d $qrDestDir ]]; then
    mkdir -p $qrDestDir
fi

area=$(slop -c 1,1,1,1)

if [ $? -eq 0 ]; then
   shotgun -g $area -f png "$fname"
else
   dunstify -i $icoError -t 5000 -u critical "Screenshot failed" "Taking screenshot cancelled by user"
   exit 1
fi

paplay --volume=40000 $snd &

if [[ -e $fname ]]; then
  opt=$(echo -e "$opt1\n$opt2\n$opt3\n$opt4" | dmenu -p "Screenshot taken, what next?")

  case $opt in
  $opt1)
    dunstify -i "$icoImg" -t 5000 "Screenshot taken" "Screenshot saved to $fname\n Size: $(du -h $fname | awk '{print $1}')"
    exit 0
    ;;
  $opt2)
    url=$(imgurqt --anonymous $fname | grep Image | awk '{print $3}')
    size=$(du -h $fname | awk '{print $1}')
    rm -f $fname
    echo "$url" | xclip -selection clipboard
    dunstify -i $icoImgur -t 5000 "Screenshot taken" "Screenshot uploaded to imgur with address $url\n \nURL copied to clipboard\n Size: $size"
    exit 0
    ;;
  $opt3)
    qr="$(zbarimg --oneshot -q $fname | sed 's/QR-Code://g')"

    if ! [ -z $qr ]; then
      input=$qr
      limit=16

      if [ ${#input} -gt $(($limit + 3)) ]; then
        out=$(echo "${input:0:$limit}...")
      else
        out=$qr
      fi

      qropt=$(echo -e "$qropt1\n$qropt2\n$qropt3\n$qropt4" | dmenu -p "QR : $out")

      case $qropt in
      $qropt1)
        echo -e "$qr" | xclip -selection clipboard
        rm -f $fname
        dunstify -i $icoQR -t 5000 "QR code was found" "QR code found in screenshot, contents copied to clipboard\nContents: $qr"
        exit 0
        ;;
      $qropt2)
        xdg-open $qr
        rm -f $fname
        dunstify -i $icoQR -t 5000 "QR code was found" "QR code found in screenshot, contents opened in web browser\nContents: $qr"
        exit 0
        ;;
      $qropt3)
        echo -e "$qr" >> $qrfname 
        rm -f $fname
        dunstify -i $icoQR -t 5000 "QR code was found" "QR code found in screenshot, contents saved to $qrfname\nContents: $qr"
        exit 0
        ;;
      $qropt4)
        rm -f $fname
        dunstify -i $icoError -t 5000 -u critical "QR code scan failed" "Scanning QR code was cancelled by user"
        exit 0
        ;;
      esac


      rm -f $fname
      dunstify -i $icoError -t 5000 -u critical "QR code scan failed" "Scanning QR code was cancelled by user"
      exit 1
    fi

    rm -f $fname
    dunstify -i $icoError -t 5000 -u critical "QR code scan failed" "No QR code was found in the image"
    exit 1
    ;;
  esac

  rm -f $fname
  dunstify -i $icoError -t 5000 -u critical "Screenshot failed" "Taking screenshot cancelled by user"
else
  dunstify -i $icoError -t 5000 -u critical "Screenshot failed" "Saving or taking screenshot failed"
fi
