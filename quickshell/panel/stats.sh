#!/bin/bash
head -n1 /proc/stat
awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf "%d\n", (t-a)*100/t}' /proc/meminfo
gpu=$(nvidia-smi --query-gpu=temperature.gpu,utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1 | tr -d ' ')
echo "${gpu:-0,0}"
