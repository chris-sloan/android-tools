#!/bin/bash
# read -t with a fractional timeout (4.0)
read -r -t 0.5 x < <(sleep 2)
exit 0
