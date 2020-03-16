#!/usr/bin/zsh
TODAY_DATE=$(date --iso-8601)
REPORT_NAME=${TODAY_DATE}.html
mydir=${0:a:h}
cd $mydir
wget https://dph.georgia.gov/covid-19-daily-status-report -O ${REPORT_NAME}
# this is taken from here: https://unix.stackexchange.com/questions/29724/how-to-properly-collect-an-array-of-lines-in-zsh
# I'm not fluent in Zsh yet, but it works
images=("${(@f)$(egrep -o 'https://dph[^?]*Screen[^?]*png' ${REPORT_NAME})}")
# from 3 images in that page we need only the third one with the table
wget $images[3] -O table-${TODAY_DATE}.png
if [[ -v API_KEY ]]; then
	echo "Sending to OCR service..."  
else 
	echo "API_KEY is not set; OCR is cancelled"
	exit 1

fi
curl -H "apikey:${API_KEY}" --form "file=@table-${TODAY_DATE}.png" --form "language=eng" --form "isOverlayRequired=true" https://api.ocr.space/Parse/Image > ocr-${TODAY_DATE}.json
cat ocr-${TODAY_DATE}.json | jq '.ParsedResults[0].ParsedText' | sed 's/"//g' | sed 's/\\r\\n/\n/g' > ${TODAY_DATE}.txt
