#!/bin/bash

# runs via crontab
# * * * * * /home/pi/fan_control/humidity_check.sh >>/home/pi/fan_control/humidity_check.log 2>&1

#
# config
#

# how long in seconds to wait before turning the fan back on or off again
FAN_SLEEP_TIME=600 # 10 minutes

#
# functions
#

# fan_on <force> [echo humidity info]
fan_on () {
  if [[ $1 != true ]]; then
    # check if fan is off
    if [[ -f /tmp/fanoff ]]; then
      # check if fan turned off recently
      AGE=`date -d "now - $( stat -c "%Y" /tmp/fanon ) seconds" +%s`
      if [[ $AGE -lt $FAN_SLEEP_TIME ]]; then
        # don't turn fan back on yet
        exit 0
      fi
    fi
  fi

  # check if fan already on
  if [[ ! -f /tmp/fanon ]]; then
    rm -f /tmp/fanoff && touch /tmp/fanon
    if [[ -n $2 ]]; then echo "`date`: humidity is $HUMIDITY, turning fan on"; fi
    sudo python3 /home/pi/fan_control/fan.py 100
  fi
}

# fan_off <force> [echo humidity info]
fan_off () {
  if [[ $1 != true ]]; then
    # check if fan is on
      if [[ -f /tmp/fanon ]]; then
      # check if fan turned on recently
      AGE=`date -d "now - $( stat -c "%Y" /tmp/fanon ) seconds" +%s`
      if [[ $AGE -lt $FAN_SLEEP_TIME ]]; then
        # don't turn fan back on yet
        exit 0
      fi
    fi
  fi

  # check if fan already off
  if [[ ! -f /tmp/fanoff ]]; then
    rm -f /tmp/fanon && touch /tmp/fanoff
    if [[ -n $2 ]]; then echo "`date`: humidity is $HUMIDITY, turning fan off"; fi
    sudo python3 /home/pi/fan_control/fan.py 0
  fi
}

#
# script begin
#

# automatic misting at 9am and 8pm so need to add an ignore for an hour
if [[ `date +"%H"` == "09" ]] || [[ `date +"%H"` == "20" ]] ; then
  fan_off true
  exit 0
fi

# get current humidity level
HUMIDITY=`curl -s -X GET http://localhost:8090/api/areas/70a97617-5456-4f39-bbf1-c08414f5c5dd/ | jq .state.sensors.current`

if [[ -n $HUMIDITY ]]; then
  HUMIDITY=`echo $HUMIDITY | awk -F"." '{print $1}'`
  if [[ $HUMIDITY -gt 80 ]]; then
    # turn fan on to lower humidity
    fan_on false true
  else
    # turn fan off as humidity is low enough
    fan_off false true
  fi
fi

# cycle log each day, keep 7 days
if [[ `date +"%H:%M"` == "00:00" ]]; then
  mv /home/pi/fan_control/humidity_check.log /home/pi/fan_control/humidity_check_`date +"%u"`.log 
fi
