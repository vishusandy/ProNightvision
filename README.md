# Pro Nightvision

A custom nightvision plugin for Counter-Strike Source and Sourcemod.  Based off of [GAMMACASE's NightVision](https://github.com/GAMMACASE/NightVision) plugin.  I have only tested this with Counter-Strike Source, but may work with CSGO (if you are willing to help test let me know).

Custom nightvision filters allows adjustments to how nightvision goggles work by applying an adjustment over the player's screen.  Custom nightvision filters (`.raw` files) can be added by adding a database entry for them.  A database is not required if no custom nightvision filters are desired.

## Screenshots

Nightvision menu:

![Nightvision menu](nightvision.png)

## Features

- Reactivates nightvision on respawn
- Support for custom nightvision filters
- Nightvision menu with intensity settings
- Nightvision light for very dark maps (may impact framerate depending on map; defaults to off).  This will add a light only the player can see (must have nightvision on).
- Easy to use - just press `n` (or whatever you use to activate nightvision)
- Natives are provided to control nightvision from other plugins

## Commands

- `!nv` or `!nightvision`: activates the last nightvision filter and brings up the nightvision menu.
- If using the ProEquip plugin the `!setnv` admin command can be used to activate/deactivate a nightvision filter.

## Installation

1. Copy the .SMX file to the `cstrike/addons/sourcemod/plugins` folder
2. For custom filters see [installation](installation.md)

## Credits

Based on GAMMACASE's plugin: https://github.com/GAMMACASE/NightVision
