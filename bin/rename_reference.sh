#!/usr/bin/env bash

get_reference_path(){
    for path in `env | grep "_DIR" | sed -e "s/.*=//g"`;do
        fname="${path}/test/ci_tests.cfg"
        if [ -f "${fname}" ];then
            echo `cat $fname | grep "^INPUTFILEDIR_EXPERIMENT" | sed -e "s/.*=//g"`
            break
        fi
    done
}

rename_reference_files(){
    reference_path=`get_reference_path`
    echo "Reference folder for the update process: $reference_path"
    #for file in `ifdh ls /pnfs/dune/scratch/users/mfattoru/temporary 2>/dev/null | grep -E "[0-9]{8}"`; do #the timestamp should be at least 8 digit long,AAAAMMDD
    for file in `ifdh ls ${reference_path}/temporary 2>/dev/null | grep "${build_timestamp}"`; do
        echo "current file: $file"
        filename=${file}
        #renamed_filename=`echo ${file}| sed 's/[0-9]\{8,14\}//g'`
        renamed_filename=`echo ${file}| sed "s/${build_timestamp}//g"`
        echo "renamed file: ${renamed_filename}"
        temp_status=`ifdh ls ${renamed_filename} 2>/dev/null`
        echo "###THIS IS THE STATUS OF THE FILE: $temp_status"
        if [ -n "$temp_status" ];then #the file exist
            echo "The file ${renamed_filename} already existed.deleting it"
            echo ifdh rm ${renamed_filename}
        fi
        echo -e "renaming the file\n"
        echo ifdh rename ${filename} ${renamed_filename}

    done
    echo "all the files have been renamed"
}

echo "############### Renaming Updated Reference Files ###############"
rename_reference_files
