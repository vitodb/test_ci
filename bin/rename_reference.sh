#!/usr/bin/env bash


get_reference_path(){
    for path in `env | grep "_DIR" | sed -e "s/.*=//g"`;do
        fname="${path}/test/ci_tests.cfg"
        if [ -f "${fname}" ];then
            final_path=${fname}
        fi
    done
    echo `cat $final_path | grep "^INPUTFILEDIR_EXPERIMENT" | sed -e "s/.*=//g"`
}

rename_reference_files(){
    reference_path=`get_reference_path`
    echo "Reference folder for the update process: $reference_path"

    for file in `ifdh ls ${reference_path}/temporary 2>/dev/null | grep "${build_timestamp}"`; do
        echo "current file: $file"
        filename="${file}"
        renamed_filename=`echo "${file}"| sed "s/${build_timestamp}//g"`
        echo "The file will be renamed in: ${renamed_filename}"
        temp_status=`ifdh ls "${renamed_filename}" 2>/dev/null`
        backup_status=`ifdh ls "${renamed_filename}.bak" 2>/dev/null`
        if [ -n "$backup_status" ] && [ -n "$temp_status" ] ;then #the backup file already exist,and we can create a new one,because a reference file is present
            echo "The backup file ${renamed_filename}.bak already exist.deleting it"
            ifdh rm "${renamed_filename}.bak"
        fi
        if [ -n "$temp_status" ];then #the reference file already exist
            echo "Converting the current reference file to backup file"
            ifdh rename "${renamed_filename}" "${renamed_filename}.bak"
        fi
        echo -e "Updating the last produced reference file to be the one used as default\n"
        ifdh rename "${filename}" "${renamed_filename}"

    done
    echo "all the files have been renamed"
}

echo -e "############### Renaming Updated Reference Files ###############\n\n"
rename_reference_files
echo -e "\n\n################################################################"
