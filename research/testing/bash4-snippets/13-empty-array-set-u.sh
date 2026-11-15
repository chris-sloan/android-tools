#!/bin/bash
# "${a[@]}" on an empty array under set -u (an error before 4.4)
set -u
a=()
echo "${a[@]}"
