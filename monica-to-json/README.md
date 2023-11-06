# monica-to-json.pl
This is a Perl script that can communicate with MoniCA to extract information about the state of the telescope
and create the standard type of JSON that the telescope-monitoring tools require.

## Usage
A configuration file needs to be created that maps the required parameters in the JSON to the data source
in MoniCA. An example configuration file is given here, for the ATCA telescope. Then, the script is run
with the configuration file as its argument, and it produces JSON to the standard output.

```
computer-name-goes-here% ./monica-to-json.pl configuration_file_atca
{"weather":{"temperature":25.9,"windSpeed":8.05,"windSpeedError":"false"},
 "configuration":{"receiver":["6/3cm","6/3cm","6/3cm","6/3cm","6/3cm"],
                  "frequencies":[8425,8489],"tickPhase":0.69},
 "stateError":["false","false","false","false","false"],
 "declinationICRF":["57:12:53.3","57:12:53.1","57:12:52.6","57:12:53.7","57:12:53.4"],
 "azimuth":[216.021916666667,216.021972222222,216.021777777778,216.0215,216.021611111111],
 "elevation":[48.1669166666667,48.1654722222222,48.1662222222222,48.1665277777778,48.1666666666667],
 "antennaName":"ATCA",
 "rightAscensionICRF":["14:08:26.2","14:08:26.2","14:08:26.4","14:08:26.2","14:08:26.1"],
 "state":["TRACKING","TRACKING","TRACKING","TRACKING","TRACKING"]}
```
## Configuration file
The configuration file is simple ASCII, with one configuration listed per line. The format of each line is:
```
parameter=value[,value,type]
```

The `parameter` can either be an internal-use variable, like `monicaServer` (which does not appear in the
output JSON, but is rather simply used to configure the script's actions), or the name of a JSON
key, like `antennaName`, or `weather.windSpeed`.

If the `parameter` is a JSON key name, then you can specify any level of key by separating each level by
a `.`. For example `antennaName` would create a key in the top-level of the JSON:
```
{"antennaName":"value"}
```
Whereas `configuration.receiver` would make an entry like:
```
{"configuration":{"receiver":"value"}}
```

Any configuration can take one or more `value`, and an optional `type` if it refers to a MonICA point.
If more than one MoniCA point is given, then the JSON output will be an array, otherwise it will just
be a single value. The `type` is either `value` (to get the value of the MoniCA point), or `error`, to
get the error status of that point.

For example:
```
weather.temperature=site.environment.weather.Temperature,value
```
will output:
```
{"weather":{"temperature":25.9}}
```
Whereas:
```
stateError=ca01.servo.State,ca02.servo.State,ca03.servo.State,ca04.servo.State,ca05.servo.State,error
```
will output:
```
{"stateError":["false","false","false","false","false"]}
```
Note that the order of the values in the array is always the same as the order of the points listed
in the configuration entry.

## Output formatting
The script itself has a routine called `standardise_outputs`, which enforces the standards for each key.
These standards are defined in the hash:
```
%keystandards = (
 'weather.windSpeed' => [ "number" ],
 'configuration.tickPhase' => [ "number" ],
 'azimuth' => [ "number" ], 'elevation' => [ "number" ],
 'rightAscensionICRF' => [ "sexagesimal" ],
 'declinationICRF' => [ "sexagesimal" ],
 'weather.temperature' => [ "number" ],
 'configuration.frequencies' => [ "number" ]
);
```

You may add any entries you like to this hash to get the script to output values as you would like,
but these standard entries ensure the values for the standard keys are output as expected, and therefore
should not be changed.

For each standard key (like `rightAscensionICRF`), an array of modifiers can be specified to convert
the value into the correct format. The standard routines available are `number` to convert to a floating
point value, or `sexagesimal` to convert to something like HH:MM:SS.SS.

If no modifier is listed for the key in this hash, the output will remain as a string.
