# Light Extension Specialisation for Farming Simulator 22

 `Farming Simulator  22`   `Revision:  FS22-02`

## Usage
This specialisation is free for use in any Farming Simulator vehicle mod for both ***Private*** and ***Public*** release.

## Publishing
The publishing of this specialisation when not included as part of a vehicle mod is not permitted.

## Modification / Converting
Only GtX | Andy is permitted to make modifications to this code including but not limited to bug fixes, enhancements or the addition of new features.

Converting this specialisation or parts of it to other version of the Farming Simulator series is not permitted without written approval from GtX | Andy.

## Versioning
All versioning is controlled by GtX | Andy and not by any other page, individual or company.

## Documentation

#### Running Lights (DRL):
These lights are activated whenever the vehicle is started. This is possible in the base game as of FS22 and remains for conversion compatibility mainly.

#### Strobe Lights:
These lights are activated with the `Beacon Light` key. In FS22 there is the ability to use 'multiBlink' for similar results however this spec allows more complex patterns.

> Method 1: Uses a string of X and - characters to define the sequence times, X represents ON state and - represents OFF state for the given 'blinkStepLength' in seconds. This is a similar method to that used in `ETS2 and ATS` and will be more familiar to some mod makers.

```xml
<strobeLight blinkStepLength="0.06" blinkPattern="X-X-X-X------X--"/>
```

> Method 2: A string of millisecond values each separated with a space are used to create an alternating light sequence. When `invert="true"` the first ms value will represent OFF.

```xml
<strobeLight sequence="600 600 200 200" invert="false"/>
```

> Method 3: Allow the randomiser to create the sequence using the given values or default values.

```xml
<strobeLight minOn="100" maxOn="100" minOff="100" maxOff="400"/>
```

#### Beacon Sound:
Plays a sample when beacon or strobe lights are active. Useful if you wish to include a siren or beacon rotor sound.

#### Auto Combine Beacon Lights
Activates the Beacon and  Strobe lights when the grain hopper reaches the set percentage.

> Default value is 80 % if not specified in the XML

```xml
<autoCombineBeaconLights percent="80"/>
```

## Example Mod
An example mod is available [HERE](https://workupload.com/file/ETzyCN9PLdV) that demonstrates the available features. This mods is not for release and is provided to assist with adding this specialisation to your own vehicles.

#### XML Info
Please also see the [lightExtension_exampleXML](https://github.com/GtX-Andy/lightExtension/blob/master/lightExtension_exampleXML.html) for more information.

## Thanks
#### [Sven777b](http://ls-landtechnik.com)
Allowing me to use parts of his original strobe light code as found in `Beleuchtung v3.1.1`.

#### Inerti and Nicolina
Testing of original concept from Farming Simulator 2017 in both single and multiplayer.

## Copyright
Copyright (c) 2018 [GtX (Andy)](https://github.com/GtX-Andy)