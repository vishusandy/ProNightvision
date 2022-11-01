# Pro Nightvision

Allows setting nightvision that is reactivated on respawn. Different custom filter types are supported, as well as the default nightvision.  A set of natives are also provided for interacting with this plugin.

Pressing `n` (or whatever key your nightvision is bound to) will turn on nightvision, reactivating the last filter you used (does not persist after leaving the server), and also displaying the nightvision menu.

## Nightvision Menu

In the nightvision menu you can:

- change the nightvision filter (defaults to standard nightvision filter)
- change filter intensity (only for custom filters), 
- Toggle nightvision light (only seen by you; especially useful for very dark maps).  This is probably slightly more realistic since nightvision goggles do actually emit light.  This may impact framerates depending on the map.


## Commands

- `!nv` or `!nightvision`: activates the last nightvision filter and brings up the nightvision menu.
- If using the ProEquip plugin the `!setnv` admin command can be used to activate/deactivate a nightvision filter.


## Installation

Download nightivision templates and put them in the `materials` folder.

For example, download GAMMACASE's nightvision templates, [https://github.com/GAMMACASE/NightVision/tree/master/materials/gammacase/nightvision], and put them somehwere like `materials/gammecase/nightvision/`.

Create a new database named `pro_nightvision`.  Code for MySQL:

``` 
CREATE TABLE `pro_nightvision` (
  `id` int(11) NOT NULL,
  `ordering` int(11) NOT NULL,
  `name` varchar(64) NOT NULL,
  `file` varchar(128) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
```

Insert a record into the database for each filter (menu order determined by `ordering` field).  For example, when using GAMMACASE's filters you can use something like:

```
INSERT INTO `pro_nightvision` (`id`, `ordering`, `name`, `file`) VALUES
(1, 0, 'Balanced', 'materials/gammacase/nightvision/nv1.raw'),
(2, 2, 'Stronger', 'materials/gammacase/nightvision/nv2.raw'),
(3, 1, 'Strong', 'materials/gammacase/nightvision/nv3.raw'),
(4, 3, 'Strongest', 'materials/gammacase/nightvision/nv4.raw');
```

Add the following to your `cstrike/addons/sourcemod/configs/databases.cfg`, substituting your database information and credentials:

```
  "pro_nightvision"
	{
		"driver"			"default"
		"host"				"<hostname>"
		"database"		"<database>"
		"user"				"<username>"
		"pass"				"<password>"
	}
```

Copy the .smx file to the plugins folder (e.g. `cstrike/addons/sourcemod/plugins`) and load the file using `sm plugins load`.

Based on GAMMACASE's plugin: [https://github.com/GAMMACASE/NightVision]

Custom nightvision templates: [https://github.com/GAMMACASE/NightVision#creating-custom-templates]

