#!/bin/bash
# mapfile / readarray builtin (4.0)
mapfile -t lines < /dev/null
echo "${#lines[@]}"
