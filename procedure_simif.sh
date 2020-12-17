#!/bin/bash

while [ true ]
do
	orario="0730"
	dataset=nc/sorted_surf_C5M.nc
	if [[ " $(date +%H%M) " =~ " $orario " ]]
	then
		# controllo che il file .nc sia aggiornato, se non lo e' non faccio nulla
		datafull=$(stat -c %y $dataset)
		dayfile_raw=${datafull:0:10}
		dayfile=$(date -d "$dayfile_raw" +%Y%m%d)
		if [[ $[$dayfile - $(date +%Y%m%d)] -eq 0 ]]
		then
			(bash Rscript /opt/simif/function/db_creation.R) 
			(bash Rscript /opt/simif/app.R) &
		fi
	fi
	sleep 1m
done

