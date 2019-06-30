# Guidance Steering for Farming Simulator 19 (GPS)

![For Farming Simulator 19](https://img.shields.io/badge/Farming%20Simulator-19-FF7C00.svg) [![Releases](https://img.shields.io/github/release/stijnwop/guidanceSteering.svg)](https://github.com/stijnwop/guidanceSteering/releases)

## Publishing
Only Wopster is allowed to publish any of this code as a mod to any mod site, or file sharing site. The code is open for your own use, but give credit where due. I will not accept support for any 'version' of Guidance Steering that is obtained from a sketchy mod page. Versioning is controlled by me and not by any other page. This confuses people and really holds back the development which results in no fun for me!

## Warning!
Please be aware that this is a ***DEVELOPMENT VERSION***!
* The development version can break the game or your savegame!
* The development version doesn´t support the full feature package yet!

#### Multiplayer
This version should also work in Multiplayer, but keep in mind it might have bugs.

## Installation / Releases
Currently the development version is only available via GitHub. When a official release version is avaiable you can download the latest version from the [release section](https://github.com/stijnwop/guidanceSteering/releases).

> _Please note: if there's no release version available it means there's no official release yet._

All official releases will be avaiable at the offical Farming Simulator ModHub.

For installing the release:

Windows: Copy the `FS19_guidanceSteering_rc_<version>.zip` into your `My Games\FarmingSimulator2019\mods` directory.

## Developers version
To quickly build a zip of the developer version without the needed extra's, use the `zip.bat` which is included in this repository.

> _Please note: the batch file requires an installed version of 7Zip or Winrar_

## Documentation

### Buying GPS
To be able to use the GPS you first need to buy the technology for your vehicle. Either buy a new vehicle and add the GPS or drive your current vehicle to the shop and configure it there.

### Toggle Guidance Steering
In order to turn guidance steering on and off hit `alt + c`

### Open the menu
In order to open the menu hit `ctrl + S`.

### Setting up the line

#### AB line
The AB mode requires two points between which the GPS is aligned.
1. Drive to the location where you want to setup your lines.
2. Hit `alt + E` once (or use the menu) in order to reset the AB creation.
3. Hit `alt + E` once more (or use the menu) in order to set point A.
4. Hit `alt + E` once more (or use the menu) in order to set point B which will create the track.

### Auto width
Hit `alt + R` (or use the menu) in order to detect the width of your vehicle.
Unfold and lower the vehicle to get the best results.

### Increase/descrease width
Hit `alt + plus` and `alt + minus` in order to change the width manually. In the menu you can set the increment width in order to speed up the process.

> _Please note that this only works after the track creation!_

### Offset line
In the menu you can set the offset line. If the offset is not `0` a red line will show up. Use the increment width select box (the one at the top) to set the increment and click on the button `Increment offset` in order to offset your line. If you set the increment to negative it will flip the offset.

### Headline Distance
In the menu you can set the distance to the headline before stop or turn accures. Use the increment width select box to set the increment and click left or right to adjust distance. Headline distance handles all increment as possitive.

### Shift track
Hit `alt + page up` and `alt + page down` in order to shift the track left and right. If you hold down the key the shifting of the track will speed up.

### Realign track
Hit `alt + home` in order to realign the track with the vehicle.

### Terrain angle snapping
If you're not able to create straight lines yourself you can enable angle snapping in the menu. This will align the AB lines with the terrain.

### Toggle guidance steering
Once a track is created hit `alt + X` to toggle the steering.

### Headland control
Currently the automatic steering stops at the headland when cruise control is enabled. Headland turning is still being worked on.

### Store and load tracks
It's also possible to store the tracks and reload them. Open the second page in the menu in order to do it.

### Visuals
On the vanilla John Deere vehicles the starfires visibility is toggled when you choose to buy the GPS system.
If you want the same effect on your mod vehicles you can configure the configuration yourself in the xml:

~~~ xml
<buyableGPSConfigurations>
  <buyableGPSConfiguration name="NO_TEXT" price="0">
          <objectChange node="NODE_NAME" visibilityActive="false" visibilityInactive="true" />
  </buyableGPSConfiguration>
  <buyableGPSConfiguration name="YES_TEXT" price="15000">
          <objectChange node="NODE_NAME" visibilityActive="true" visibilityInactive="false" />
  </buyableGPSConfiguration>
</buyableGPSConfigurations>
~~~

## Copyright
Copyright (c) 2019 [Wopster](https://github.com/stijnwop).
All rights reserved.

Special thanks to workflowsen for creating the icon! 
