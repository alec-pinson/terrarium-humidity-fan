#!/bin/bash

# runs via crontab
# * * * * * /home/pi/fan_control/humidity_check.sh >>/home/pi/fan_control/humidity_check.log 2>&1

# get current humidity level
HUMIDITY=`curl -s -X GET http://localhost:8090/api/areas/70a97617-5456-4f39-bbf1-c08414f5c5dd/ | jq .state.sensors.current`

if [[ -n $HUMIDITY ]]; then
  HUMIDITY=`echo $HUMIDITY | awk -F"." '{print $1}'`
  if [[ $HUMIDITY -gt 80 ]]; then
    if [[ ! -f /tmp/fanon ]]; then
      rm -f /tmp/fanoff && touch /tmp/fanon
      # turn fan on to lower humidity
      echo "`date`: humidity is $HUMIDITY, turning fan on"
      sudo python3 /home/pi/fan_control/fan.py 100
    fi
  else
    if [[ ! -f /tmp/fanoff ]]; then
      # turn fan off as humidity is low enough
      rm -f /tmp/fanon && touch /tmp/fanoff
      echo "`date`: humidity is $HUMIDITY, turning fan off"
      sudo python3 /home/pi/fan_control/fan.py 0
    fi  
  fi
fi

# cycle log each day, keep 7 days
if [[ `date +"%H:%M"` == "00:00" ]]; then
  mv /home/pi/fan_control/humidity_check.log /home/pi/fan_control/humidity_check_%u.log 
fi
