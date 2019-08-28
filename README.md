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
To be able to use Guidance Steering you first need to buy the GPS technology for your vehicle. Either buy a new vehicle and add the GPS configuration or drive your current vehicle to the shop and configure it there.

### Toggle Guidance Steering
When you buy the GPS configuration for the first time Guidance Steering is disabled.
In order to turn Guidance Steering on and off hit `alt + c`

### Open the menu
In order to open the menu hit `ctrl + S`. Make sure that you have Guidance Steering enabled first!

### Setting up the guidance line

#### AB Straight line
The AB mode requires two (AB) points in order to calculate the angle to generate the line.
1. Drive to the location where you want to setup your lines.
2. Hit `alt + E` once (or use the menu) in order to reset the AB creation.
3. Hit `alt + E` once more (or use the menu) in order to set point A.
4. Hit `alt + E` once more (or use the menu) in order to set point B which will create the track.

#### A+Heading line
The A+Heading mode requires only an A point and a cardinal angle in order to generate the line.
1. Drive to the location where you want to setup your lines.
2. Hit `alt + E` once (or use the menu) in order to reset the A+Heading creation.
3. Hit `alt + E` once more (or use the menu) in order to set point A.
4. Enter the desired cardinal angle (in degrees).
5. Hit the button 'Set Cardinal' in order to create the line.

### Auto width
Hit `alt + R` (or use the menu) in order to detect the width of your vehicle.
Unfold and lower the vehicle to get the best results.

### Increase/descrease width
Hit `alt + plus` and `alt + minus` in order to change the width manually. In the menu you can set the increment width in order to speed up the process.

> _Please note that this only works after the track creation!_

### Offset line
In the menu you can set the offset line. If the offset is not `0` a red line will show up. Use the increment width select box (the one at the top) to set the increment and click on the button `Increment offset` in order to offset your line. If you set the increment to negative it will flip the offset.

### Shift track
Hit `alt + page up` and `alt + page down` in order to shift the track left and right. If you hold down the key the shifting of the track will speed up.

### Realign track
Hit `alt + home` in order to realign the track with the vehicle.

### Rotate track
Enter the strategy menu and hit the 90 degree button in order to rotate the current track.

### Terrain angle snapping
If you're not able to create straight lines yourself you can enable angle snapping in the menu. This will align the AB lines with the terrain.

### Toggle guidance steering
Once a track is created hit `alt + X` to toggle the steering.

### Headland control
You can set the current headland mode in order to change interaction with the headland.

When you set the mode on `stop` the vehicle will stop at the set interaction distance.
When you set the mode on `off` the vehicle will only warn you at the set interaction distance.

### Store and load tracks
It's also possible to store the tracks and reload them. Open the second page in the menu in order to do it.
This is also an easy way to share track data among other players in multiplayer.

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
