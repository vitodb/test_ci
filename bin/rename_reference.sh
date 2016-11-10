#!/usr/bin/env bash

echo -e "\n\nstarting script"
#for file in `ifdh ls /pnfs/dune/scratch/users/mfattoru/temporary 2>/dev/null | grep -E "[0-9]{8}"`; do #the timestamp should be at least 8 digit long,AAAAMMDD
for file in `ifdh ls /pnfs/dune/scratch/users/mfattoru/temporary 2>/dev/null | grep "${build_timestamp}"`; do #the timestamp should be at least 8 digit long,AAAAMMDD
    echo "current file: $file"
    filename=${file}
    #renamed_filename=`echo ${file}| sed 's/[0-9]\{8,14\}//g'`
    renamed_filename=`echo ${file}| sed "s/${build_timestamp}//g"`
    echo "renamed file: ${renamed_filename}"
    temp_status=`ifdh ls ${renamed_filename} 2>/dev/null`
    echo "###THIS IS THE STATUS OF THE FILE: $temp_status"
    if [ -n "$temp_status" ];then #the file exist
        echo "The file ${renamed_filename} already existed.deleting it"
        ifdh rm ${renamed_filename} force
    fi
    echo -e "renaming the file \n \n"
    ifdh rename ${filename} ${renamed_filename}

done
echo "all the files have been renamed"
