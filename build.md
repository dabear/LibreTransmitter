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
* In Xcode 13 this can be accessed from the top menu `Product -> Scheme -> Edit Scheme`
* it should look like this: ![CGMManager_swift](https://user-images.githubusercontent.com/442324/111884191-41775d80-89c0-11eb-8f8a-51290e85d9a5.jpg)

## Give Loop Extra background permissions
 The LibreTransmitter plugin will run as a part of Loop. If you want LibreTransmitter to be able to give vibrations for low/high glucose, this is a necessary step
* In Xcode, Open the Loop Project (not the LibreTransmitter project) in the navigator, go to "Signing & Capabilities", then under "background modes", select "Audio, AirPlay, and Picture in picture". This will allow Libretransmitter to use vibration when the phone is locked.
* It should look like this: ![Loop_xcodeproj](https://user-images.githubusercontent.com/442324/111884302-14777a80-89c1-11eb-9171-76ffcef2f345.jpg "Audio/Vibrate capability added into Loop For libretransmitter to work in background")

## Give Loop NFC permissions for libre2 direct bluetooth support
This plugin now supports libre2 direct bluetooth connections.
To utilize libre2direct you need to pair your sensor via NFC first, and therefore Loop needs NFC permissions
* In Xcode, Open the Loop Project (not the LibreTransmitter project) in the navigator, go to "Signing & Capabilities",  then "+ Capability" and add the "NFC" or "Near field communication Tag Reading" capability.
* In Loop's Info.plist, add the tag NFCReaderUsageDescription and set description to something similar to: "Loop will use NFC on the phone to pair libre2 sensors"

## Give Libretransmitter Critical Alerts permissions
Libretransmitter will by default send alarms as "timesensitve", appearing immediately on the lock screen.
If you mute or set your phone to do not disturb, you can potentially miss out on such alarms.
To remedy this, LibreTransmitter will dynamically try to upgrade any glucose alarms to "critical". 
Critical alarms will sound even if your phone is set to to mute or "do not disturb" mode.

For this to be possible, you will have to request special permissions from apple.
This process is documented at https://stackoverflow.com/questions/66057840/ios-how-do-you-implement-critical-alerts-for-your-app-when-you-dont-have-an-en . 
The linked article describes some necessary code changes, but that can be ignored; only the entitlements have to be added to Loop for LibreTransmitter to automatically use them.
It's worth mentioning again that those permissions must be given to Loop itself, not to the LibreTransmitter package.

## Build the LoopWorkspace with LibreTransmitter Plugin
* In xcode, go to Product->"Clean Build Folder"
* Make sure you build "Loop (Workspace)" rather than "Loop"
