#!/bin/bash

for i in 0 1 2; do ./BkPLL -m 2048 -e 2 -z -l 12 -c $i -i 99999999999999 -d 1 & done