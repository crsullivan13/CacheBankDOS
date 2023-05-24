#!/bin/bash 

. ./functions

# Output files
OUT=figures/Fig6.dat
> $OUT

# Parameters for the victim workload
vsizes=(64    128   192   256   320   1024  2048) 
viters=(10000 10000 10000 10000 10000 10000 10000) 
vtypes=read
vtypestr="${vtype^}"

# Parameters for the attacker workloads
csizes=(64)
asizes=(64)
dsizes=(16384)
ctypes=(write) 

# Array to track slowdowns and LLC missrates across victim WSS
slowdowns=()
missrates=()

index=0
for vsize in ${vsizes[@]}; do
	slowdowns+=(); slowdowns[$index]+="$vsize "
	missrates+=(); missrates[$index]+="$vsize "
	
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
			
		# PLL
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
	
	# VS PRIOR DOS-FITTING DOS ATTACKS
	for dsize in ${dsizes[@]}; do
		# BW
		BwWriteCorun $dsize
		sleep 3
		BwReadVictimCorun $vsize $viter 
		slowdowns[$index]+="$slowdown "
		missrates[$index]+="$l2missrate "
		killall $corun
        
		# PLL
        PLLWriteCorun $dsize 
		sleep 3
		BwReadVictimCorun $vsize $viter 	
		slowdowns[$index]+="$slowdown "
		missrates[$index]+="$l2missrate "
		killall $corun
	done
	
	index=$((index+1))
	echo ""
	
	sleep 3
done

# Output the slowdowns
for ((i=0;i<${#slowdowns[@]}; i++)); do
	echo ${slowdowns[$i]} >> $OUT
done
