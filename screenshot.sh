#!/bin/sh
snd="/usr/share/sounds/freedesktop/stereo/camera-shutter.oga"
fname="/home/$USER/Pictures/screenshots/$(date +"%Y-%m-%d-%T").png"

area=$(slop -c 1,1,1,1)

if [ $? -eq 0 ]; then
   shotgun -g $area -f png "$fname"
else
   dunstify -i report_problem -t 5000 -u critical "Screenshot failed" "Taking screenshot cancelled by user"
   exit 1
fi

paplay --volume=40000 $snd &


opt1="Save to Disk"
opt2="Upload to Imgur"
opt3="Scan for QR codes"
opt4="Cancel"

if [[ -e $fname ]]; then
  opt=$(echo -e "$opt1\n$opt2\n$opt3\n$opt4" | /home/leevi/scripts/dmenu_center.sh 2048 3 "What do you want to do?")
  case $opt in
  $opt1)
    dunstify -i add_photo_alternate -t 5000 "Screenshot taken" "Screenshot saved to $fname\n Size: $(du -h $fname | awk '{print $1}')"
    exit 0
    ;;
  $opt2)
    url=$(imgurqt --anonymous $fname | grep Image | awk '{print $3}')
    size=$(du -h $fname | awk '{print $1}')
    rm -f $fname
    echo $url | clipster -c
    dunstify -i cloud_upload -t 5000 "Screenshot taken" "Screenshot uploaded to imgur with address $url\n \nURL copied to clipboard\n Size: $size"
    exit 0
    ;;
  $opt3)
    qr="$(zbarimg -q $fname | sed 's/QR-Code://g')"

    qropt1="Copy to clipboard"
    qropt2="Open in Firefox"
    qropt3="Save to file"
    qropt4="Cancel"

    if ! [ -z $qr ]; then
      input=$qr
      limit=16

      if [ ${#input} -gt $(($limit + 3)) ]; then
        out=$(echo "${input:0:$limit}...")
      else
        out=$qr
      fi

      qropt=$(echo -e "$qropt1\n$qropt2\n$qropt3\n$qropt4" | /home/leevi/scripts/dmenu_center.sh 2048 4 "QR : $out")

      case $qropt in
      $qropt1)
        echo -e "$qr" | clipster -c
        rm -f $fname
        dunstify -i qrcode -t 5000 "QR code was found" "QR code found in screenshot, contents copied to clipboard\nContents: $qr"
        exit 0
        ;;
      $qropt2)
        firefox $qr
        rm -f $fname
        dunstify -i qrcode -t 5000 "QR code was found" "QR code found in screenshot, contents opened in Firefox\nContents: $qr"
        exit 0
        ;;
      $qropt3)
        qrfname="/home/$USER/Documents/qr-scan-$(date +"%Y-%m-%d-%T")"
        echo -e "$qr" >> $qrfname 
        rm -f $fname
        dunstify -i qrcode -t 5000 "QR code was found" "QR code found in screenshot, contents saved to $qrfname\nContents: $qr"
        exit 0
        ;;
      $qropt4)
        rm -f $fname
        dunstify -i report_problem -t 5000 -u critical "QR code scan failed" "Scanning QR code was cancelled by user and temporary screenshot file deleted"
        exit 0
        ;;
      esac


      rm -f $fname
      dunstify -i report_problem -t 5000 -u critical "QR code scan failed" "Scanning QR code was cancelled by user and temporary screenshot file deleted"
      exit 1
    fi

    rm -f $fname
    dunstify -i report_problem -t 5000 -u critical "QR code scan failed" "No QR code was found in the image"
    exit 1
    ;;
  esac

  rm -f $fname
  dunstify -i report_problem -t 5000 -u critical "Screenshot failed" "Taking screenshot cancelled by user and temporary screenshot file deleted"
else
  dunstify -i report_problem -t 5000 -u critical "Screenshot failed" "Saving or taking screenshot failed"
fi
