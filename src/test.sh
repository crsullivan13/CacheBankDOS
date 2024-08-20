#!/bin/bash

corun=$1

> /sys/fs/cgroup/palloc/part1/cgroup.procs
> /sys/fs/cgroup/palloc/part2/cgroup.procs

if [ "$corun" = "co" ]; then
    echo "Running attackers....."
    for i in 1 2 3; do 
        ./BkPLL -m 2000 -b 0x0 -e 1 -z -l 12 -c $i -i 999999999999 -a write > /dev/null 2>&1 &
        attacker_pid=$!
        echo $attacker_pid | tee -a /sys/fs/cgroup/palloc/part2/cgroup.procs
        #pagetype -k 0x70000 -p $attacker_pid | tail -9
    done

    sleep 10
fi

echo -e "\nRunning victim....."

chrt -f 1 perf stat -e  LLC-loads,LLC-load-misses ./BkPLL -m 2000 -b 0x0 -e 3 -z -l 12 -c 0 -i 150000 &
victim_pid=$!
echo $victim_pid | tee /sys/fs/cgroup/palloc/part1/cgroup.procs
wait $victim_pid
echo -e "\nVictim done....."

if [ "$corun" = "co" ]; then
    echo "killing co-runners"
    killall -9 BkPLL
    wait &> /dev/null
fi
