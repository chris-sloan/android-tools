#!/bin/bash
# local -n nameref (4.3)
f() { local -n ref=$1; ref=set; }
f out
[[ $out == set ]]
