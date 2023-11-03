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
