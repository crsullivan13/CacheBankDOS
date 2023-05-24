#!/bin/bash 

. ./functions

# Output files
OUT=figures/Fig5.dat
> $OUT

# Parameters for the victim workload
vsizes=(64)
viters=(10000)
vtypes=read
vtypestr="${vtype^}"

# Parameters for the attacker workloads
asizes=(64)
ctype=write 

index=0
for vsize in ${vsizes[@]}; do	
	echo "Bw${vtypestr}($vsize) Victim"
	echo "Corun, Bandwidth, Latency, Slowdown, LLC_miss, LLC_access, LLC_missrate"
	
	# SOLO CASE
	BwReadVictimSolo $vsize ${viters[$index]}
    
	# VS CACHE BANK AWARE DOS ATTACKS
    for asize in ${asizes[@]}; do		
		for bank in 0 1 2 3 4 5 6 7; do
			ctypestr="${ctype^}"
			BkPLLWriteCorun $asize $bank
			sleep 3
			BwReadVictimCorun $vsize $viter 
			killall $corun
			wait &> /dev/null
			
			echo "$bank $slowdown" >> $OUT
		done
    done

	echo ""	
	sleep 3
done
