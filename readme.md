# LibreTransmitter for Loop
This is a https://github.com/loopkit/loop plugin for connecting to libresensors via miaomiao and bubble transmitters
For all supported sensors you need such a transmitter, even for the libre 2 which has builtin bluetooth. 

# Supported sensors
* US Libre 1 10 day sensors (tested)
* US Libre 1 14 day sensors (untested)
* International Libre 1 sensors (tested)
* European Libre 2 sensors (untested, should work, but requires transmitter as well)

# Unsupported sensors
* US libre 2 sensors
* Libre Pro sensors
* Libre H sensors

# Features
* Auto calibration, similar - but not identical - to the official algorithm
* Glucose values can be uploaded to nightscout automatically by Loop
* Optional: Backfill the last 16 minutes of data (recommend to turn off)
* Optional: Backfill the last 8 hours of data (15 minute cadence)
* Glucose data is smoothed to avoid noise, using a 5 point moving average filter
* Official algorithm implements glucose prediction, to align cgm values with blood values; this feature is deliberately removed from this implementation
* Glucose readout interval: 5 minutes
* Glucose alarms
* Glucose notifications on lockscreen
* Manual calibration for expert users (warnings apply here, this feature can be extremly dangerous)

# How it looks

<img src="IMG_0888.png" width="25%"> <img src="IMG_0889.png" width="25%"> <img src="IMG_0890.png" width="25%">


# How to build
It's a dynamic loop plugin. I usually build a modified loopworkspace to get this working. See the [build.md](./build.md) file for futher instructions

## Glucose Algorithm
The GetGlucoseFromRaw.swift file is not included in this repo. You need to explicitly download this file from other sources and add it before you build

