#!/bin/bash 

. ./functions

# Output files
OUT=figures/Fig10.dat
> $OUT

# Parameters for the victim workload
vsize=64
viters=(10000)
vtype=read
vtypestr="${vtype^}"

# Parameters for the attacker workloads
ctypes=(write) 
csizes=(64)
asizes=(64)

# Bandwidth budgets to test
budgets=(50 100 200 300 400 500 600 700 800 900 1000)

# Array to track slowdowns and LLC missrates across victim WSS
slowdowns=()
missrates=()

index=0
for budget in ${budgets[@]}; do
	slowdowns+=(); slowdowns[$index]+="$budget "
	missrates+=(); missrates[$index]+="$budget "
	
	# Update the budgets for the attacking cores
	echo mb 50000 $budget $budget $budget > /sys/kernel/debug/memguard/limit
	
	echo "Bw${vtypestr}($vsize) Victim"
	echo "Corun, Bandwidth, Latency, Slowdown, LLC_miss, LLC_access, LLC_missrate"
	
	# SOLO CASE
	BwReadVictimSolo $vsize ${viters[$index]}
	slowdowns[$index]+="1.00 "
	missrates[$index]+="$l2missrate "
	
	# VS CACHE BANK OBLIVIOUS DOS ATTACKS
	for csize in ${csizes[@]}; do
		# BW
		for ctype in ${ctypes[@]}; do
			ctypestr="${ctype^}" 
			BwWriteCorun $csize
			sleep 3
			BwReadVictimCorun $vsize $viter
			slowdowns[$index]+="$slowdown "
			missrates[$index]+="$l2missrate "
			killall $corun
			wait &> /dev/null
		done
			
		#PLL
		for ctype in ${ctypes[@]}; do
			ctypestr="${ctype^}"
			PLLWriteCorun $csize
			sleep 3
			BwReadVictimCorun $vsize $viter
			slowdowns[$index]+="$slowdown "
			missrates[$index]+="$l2missrate "
			killall $corun
		done
	done
    
	# VS CACHE BANK AWARE DOS ATTACKS
    for asize in ${asizes[@]}; do
		for ctype in ${ctypes[@]}; do
			ctypestr="${ctype^}"
			BkPLLWriteCorun $asize 1
			sleep 3
			BwReadVictimCorun $vsize $viter
			slowdowns[$index]+="$slowdown "
			missrates[$index]+="$l2missrate "
			killall $corun
			wait &> /dev/null
		done
    done
	
	index=$((index+1))
	echo ""
	
	sleep 3
done

# Output the slowdowns
for ((i=0;i<${#slowdowns[@]}; i++)); do
	echo ${slowdowns[$i]} >> $OUT
done
