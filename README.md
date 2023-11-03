# telescope-monitoring
Code for creating a useful set of monitoring tools for telescopes everywhere

## Purpose
This repository is primarily to develop a monitoring system for the diverse telescopes that make up the
Australian Long Baseline Array (LBA). However, we make this code general enough that it could be used
for any telescope, and the tools developed here may be useful for any observatory that wants to use them.

## Philosophy
The rough idea is that each telescope is responsible for generating a status object, which can be seen by
any of the front-end tools. Usually this will mean creating a JSON file that is put on a publicly-accessible
web server, and keeping this JSON up to date with the current status.

The JSON object can be customised by each observatory, but to make the front-end tools simple, we propose
that a minimum set of common parameters be utilised, which should be general enough to use for any
observatory. For the moment, because this is an LBA tool to begin with, the JSON is described on the
[LBA wiki](https://www.atnf.csiro.au/vlbi/dokuwiki/doku.php/lbaops/jsonmonitoring).

