NB! This project requires LoopWorkspace dev. You *must* use the workspace to buid this.

## Start with a clean LoopWorkspace based on dev

* Download a fresh copy of LoopWorkspace dev into a subfolder of your choice
```
cd ~
mkdir Code && cd Code
git clone --branch=dev --recurse-submodules https://github.com/LoopKit/LoopWorkspace
cd LoopWorkspace
```

* Add LibreTransmitter submodule
```
git submodule add -b main git@github.com:dabear/LibreTransmitter.git LibreTransmitter
```

* Add Glucose algorithm (GetGlucoseFromRaw.swift)
  * First Download GetGlucoseFromRaw.swift from where ever you want (don't ask, out of scope for this guide) and place it into the Downloads folder on your mac
  * Add GetGlucoseFromRaw.swift into project. For example:
```
cd ~/Downloads
mv GlucoseFromRaw.swift ~/Code/LoopWorkspace/LibreTransmitter/LibreSensor/GlucoseAlgorithm/GlucoseFromRaw.swift
```

## In Xcode, Add LibreTransmitter project into LoopWorkspace
* Open Loop.xcworkspace
* Drag LibreTransmitter.xcodeproj from the Finder (from the LibreTransmitter submodule) into the xcode left menu while having the loop workspace open 
* It should Look like this:
![CGMManager_swift](https://user-images.githubusercontent.com/442324/111884066-63241500-89bf-11eb-9b0c-14a440111cda.jpg "LibreTransmitter as part of workspace")

* Select the "Loop (Workspace)" scheme and then "Edit scheme.."
* In the Build Dialog, make sure to add LibreTransmitterPlugin as a build target, and place it just before "ShareClientPlugin"
* it should look like this: ![CGMManager_swift](https://user-images.githubusercontent.com/442324/111884191-41775d80-89c0-11eb-8f8a-51290e85d9a5.jpg)

## Give Loop Extra background permissions
 The LibreTransmitter plugin will run as a part of Loop. If you want LibreTransmitter to be able to give vibrations for low/high glucose, this is a necessary step
* In Xcode, Open the Loop Project (not the LibreTransmitter project) in the navigator, go to "Signing & Capabilities", then under "background modes", select "Audio, AirPlay, and Picture in picture". This will allow Libretransmitter to use vibration when the phone is locked.
* It should look like this: ![Loop_xcodeproj](https://user-images.githubusercontent.com/442324/111884302-14777a80-89c1-11eb-9171-76ffcef2f345.jpg "Audio/Vibrate capability added into Loop For libretransmitter to work in background")


## Build the LoopWorkspace with LibreTransmitter Plugin
* In xcode, go to Product->"Clean Build Folder"
* Make sure you build "Loop (Workspace)" rather than "Loop"
