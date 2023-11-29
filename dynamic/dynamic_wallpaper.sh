#!/bin/bash

sleep 5

success=false
counter=0

while  [ "$success" != "true" ]
do
    if [ $counter -gt 4 ]; then
	notify-send "Wallpaper update failed"
        exit 1
    fi
    nslookup google.com 2>&1 >/dev/null

    if [ $? -eq 0 ]; then
        success=true
    fi
    counter=$((counter + 1))
    sleep $counter
done

# get current location
location=$(curl -s https://ipinfo.io/loc)

# get timezone
timezone=$(curl -s https://ipinfo.io/timezone)

# calculate sunrise and sunset times
sunrise=$(curl -s "https://api.sunrise-sunset.org/json?lat=${location%,*}&lng=${location#*,}&formatted=0" | jq -r '.results.sunrise')
sunset=$(curl -s "https://api.sunrise-sunset.org/json?lat=${location%,*}&lng=${location#*,}&formatted=0" | jq -r '.results.sunset')
sunrise_unix=$(TZ=$timezone date -d "$sunrise" +%s)
sunset_unix=$(TZ=$timezone date -d "$sunset" +%s)

# calculate one hour before and after sunrise and sunset
one_hour=3600
sunrise_before_unix=$((sunrise_unix-one_hour))
sunrise_after_unix=$((sunrise_unix+one_hour))
sunset_before_unix=$((sunset_unix-one_hour))
sunset_after_unix=$((sunset_unix+one_hour))

# update XML file
xmlstarlet edit --inplace \
  --update '/background/starttime/year' --value "$(TZ=$timezone date -d @$sunrise_unix +'%Y')" \
  --update '/background/starttime/month' --value "$(TZ=$timezone date -d @$sunrise_unix +'%-m')" \
  --update '/background/starttime/day' --value "$(TZ=$timezone date -d @$sunrise_unix +'%-d')" \
  --update '/background/starttime/hour' --value "$(TZ=$timezone date -d @$sunrise_after_unix +'%-H')" \
  --update '/background/starttime/minute' --value "$(TZ=$timezone date -d @$sunrise_after_unix +'%-M')" \
  --update '/background/starttime/second' --value "$(TZ=$timezone date -d @$sunrise_after_unix +'%-S')" \
  --update '/background/static[1]/duration' --value "$((sunset_before_unix-sunrise_after_unix))" \
  --update '/background/static[2]/duration' --value "$((sunrise_before_unix+86400-sunset_after_unix))" \
  /path/to/La-Saline.xml
