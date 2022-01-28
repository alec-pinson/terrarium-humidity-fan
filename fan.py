#!/usr/bin/python
# -*- coding: utf-8 -*-

import RPi.GPIO as GPIO
import time
import sys

FAN_PIN = 21
WAIT_TIME = 1
PWM_FREQ = 25

GPIO.setwarnings(False)
GPIO.setmode(GPIO.BCM)
GPIO.setup(FAN_PIN, GPIO.OUT, initial=GPIO.LOW)

fan=GPIO.PWM(FAN_PIN,PWM_FREQ)
fan.start(0);

try:
    fanSpeed=float(sys.argv[1])
    fan.ChangeDutyCycle(fanSpeed)

except:
    GPIO.cleanup()
    sys.exit()
