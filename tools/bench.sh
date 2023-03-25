#!/bin/bash
date
for f in {1..30}
do
  vcgencmd measure_temp
  sysbench --test=cpu --cpu-max-prime=20000 --num-threads=4 run >/dev/null 2>&1
  date
done
vcgencmd measure_temp
date
