#!/bin/bash


echo "$0"

echo -e "\n\n#######\n\n"

export IFDH_CP_MAXRETRIES=1

env | sort

echo -e "\n\n#######\n\n"

pwd
ls -lh

echo -e "\n\n#######\n\n"

type traperror
trap

trap 'traperror $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "::%s" ${FUNCNAME[@]}) $ERRORFATAL' ERR
trap


EXP_STAGE=${1}

#report_test_result "$report_phase" "$test_suite[not used]" "$test_name" "$statistic" "$value.0"

### report_test_result "$report_phase" "" "${EXP_STAGE}_stage" "status" "-2.0"
### report_test_result "$report_phase" "" "${EXP_STAGE}_stage" "status" "-1.0"



echo CONDOR_DIR_INPUT: ${CONDOR_DIR_INPUT}
echo INPUT_TAR_FILE: ${INPUT_TAR_FILE}
echo PWD: ${PWD}

ls -lh ${CONDOR_DIR_INPUT}
ls -lh ${INPUT_TAR_FILE}

unset CETPKG_BUILD
unset OLD_MRB_BUILDDIR
unset PRODUCTS


sed -i.orig "s#setenv MRB_TOP .*#setenv MRB_TOP \"$PWD\"# ; s#setenv MRB_SOURCE .*#setenv MRB_SOURCE \"$PWD\"#" localProducts_*/setup

#source /cvmfs/dune.opensciencegrid.org/products/dune/setup_dune.sh || source /grid/fermiapp/products/dune/setup_dune.sh
source /cvmfs/uboone.opensciencegrid.org/products/setup_uboone.sh || source /grid/fermiapp/products/uboone/setup_uboone.sh

#eval $(ups list -aK+ dunetpc -z localProducts_* | awk '{if ( $1 ~ "dunetpc" ) {print "setup "$1" "$2" -q "$4} }')
eval $(ups list -aK+ uboonecode -z localProducts_* | awk '{if ( $1 ~ "uboonecode" ) {print "setup "$1" "$2" -q "$4} }')

ups active


echo "@: $@"

standard() {
    echo "Copy input file (if any)..."
    eval echo \$input_filename_${EXP_STAGE}
    new_input_filename=$(eval echo \$input_filename_${EXP_STAGE})
    new_input_filename=${new_input_filename//.root/_${CI_PROCESS}.root}

    if [ $(eval echo $new_input_filename) ]; then
        (echo CMD: ifdh cp ${CI_DCACHEDIR}/$(eval echo \$input_from_stage_${EXP_STAGE})/$new_input_filename $new_input_filename
        ifdh cp ${CI_DCACHEDIR}/$(eval echo \$input_from_stage_${EXP_STAGE})/$new_input_filename $new_input_filename)

        echo "ifdh cp exit code: $?"

        ls -lh

        if [ $(stat -c "%s" ${new_input_filename}) -eq 0 ]; then
            echo "The input file for this job has 0 size, the file is missing or ifdh failed to copy it."
            exit 1
        fi
    else
        echo "No file to transfer"

    fi



    echo "run exp code..."
    echo CMD: $(eval echo \$executable_${EXP_STAGE}) $(eval echo \$arguments_${EXP_STAGE} -c \$FHiCL_${EXP_STAGE} -n \$nevents_per_job_${EXP_STAGE} -o \$output_filename_${EXP_STAGE}) $new_input_filename
    $(eval echo \$executable_${EXP_STAGE}) $(eval echo \$arguments_${EXP_STAGE} -c \$FHiCL_${EXP_STAGE} -n \$nevents_per_job_${EXP_STAGE} -o \$output_filename_${EXP_STAGE}) $new_input_filename

    echo "exitstatus executable: $?"

    ls -lh

    echo "Copy output file..."
    new_output_filename=$(eval echo \$output_to_transfer_${EXP_STAGE})
    new_output_filename=${new_output_filename//.root/_${CI_PROCESS}.root}
    echo CMD: mv -v $(eval echo \$output_to_transfer_${EXP_STAGE}) $new_output_filename
    mv -v $(eval echo \$output_to_transfer_${EXP_STAGE}) $new_output_filename
    echo "exitstatus mv output: $?"
    ls -lh
    echo CMD: ifdh cp ${PWD}/$new_output_filename ${CI_DCACHEDIR}/${EXP_STAGE}/$new_output_filename
    ifdh cp ${PWD}/$new_output_filename ${CI_DCACHEDIR}/${EXP_STAGE}/$new_output_filename

    report_exitcode=$?
    echo "exitstatus ifdh cp: $report_exitcode"

    ls -lh

    ### report_test_result "$report_phase" "" "${EXP_STAGE}_stage" "status" "${report_exitcode}.0"

    exit ${report_exitcode}
}

merge() {

    new_input_filename=$(eval echo \$input_filename_${EXP_STAGE})
    new_input_filename=${new_input_filename//.root/*.root}

    export IFDH_DEBUG=1

    eval echo \$input_filename_${EXP_STAGE}
    echo new_input_filename: $new_input_filename
    echo CMD: ifdh findMatchingFiles ${CI_DCACHEDIR}/$(eval echo \$input_from_stage_${EXP_STAGE})/ ${new_input_filename}
    ifdh findMatchingFiles ${CI_DCACHEDIR}/$(eval echo \$input_from_stage_${EXP_STAGE})/ ${new_input_filename}

    echo CMD: hadd $(eval echo \$output_filename_${EXP_STAGE}) $(for source_file in $( ifdh findMatchingFiles ${CI_DCACHEDIR}/$(eval echo \$input_from_stage_${EXP_STAGE})/ ${new_input_filename} 2> /dev/null | awk '{print $1}' ) ; do echo root://fndca1.fnal.gov:1094/${source_file}; done)

    hadd $(eval echo \$output_filename_${EXP_STAGE}) $(for source_file in $( ifdh findMatchingFiles ${CI_DCACHEDIR}/$(eval echo \$input_from_stage_${EXP_STAGE})/ ${new_input_filename} 2> /dev/null | awk '{print $1}' ) ; do echo root://fndca1.fnal.gov:1094/${source_file//\/pnfs/pnfs\/fnal.gov\/usr}; done)

    report_exitcode=$?
    echo "exitstatus hadd: $report_exitcode"


    echo CMD: calorimetry.py --tracker trackkalmanhit --input $(eval echo \$output_filename_${EXP_STAGE}) --output calorimetry_validation.root
    calorimetry.py --tracker trackkalmanhit --input $(eval echo \$output_filename_${EXP_STAGE}) --output calorimetry_validation.root
    echo "exitstatus calorimetry.py: $?"

    echo CMD: makeplots.py --input calorimetry_validation.root --calorimetry
    makeplots.py --input calorimetry_validation.root --calorimetry
    echo "exitstatus makeplots.py: $?"


    #report_img "$report_phase" "$test_suite" "$testname" "hits$i" "$f" "$desc"
    for f in calorimetry/*.gif
    do
        bf=`basename $f`
        hist_desc="hits ${bf//.gif/}"
        hist_name="${bf//.gif/}"
        report_img "$report_phase" "" "${EXP_STAGE}_stage" "$hist_name" "$f" "$hist_desc"

        ### ### ###
        report_img "$report_phase" "" "validation_plots" "$hist_name" "$f" "$hist_desc"
        report_img "validation_plots" "" "validation_plots" "$hist_name" "$f" "$hist_desc"
        report_img "$report_phase" "" "end" "$hist_name" "$f" "$hist_desc"
        ### ### ###
    done

    echo CMD: ifdh cp -D $(eval echo \$output_filename_${EXP_STAGE}) calorimetry_validation.root ${CI_DCACHEDIR}/${EXP_STAGE}
    ifdh cp -D $(eval echo \$output_filename_${EXP_STAGE}) calorimetry_validation.root  ${CI_DCACHEDIR}/${EXP_STAGE}
    echo "exitstatus ifdh cp files: $?"
    ifdh mkdir ${CI_DCACHEDIR}/${EXP_STAGE}/calorimetry
    echo "exitstatus ifdh mkdir calorimetry: $?"
    echo CMD: ifdh cp -D calorimetry/\* ${CI_DCACHEDIR}/${EXP_STAGE}/calorimetry
    ifdh cp -D calorimetry/* ${CI_DCACHEDIR}/${EXP_STAGE}/calorimetry
    echo "exitstatus ifdh cp calorimetry dir: $?"

    ### report_test_result "$report_phase" "" "${EXP_STAGE}_stage" "status" "${report_exitcode}.0"

    ### check which exitcode report
    exit ${report_exitcode}

}


while :
do
    case "x$1" in
        x--ci-jobid)     CI_PROCESS=$2;                                         shift; shift;;
        x--stage)        EXP_STAGE=$2;                                           shift; shift;;
        x)               break;;
        x*)              echo "Unknown argument $1"; exit 1;;
    esac
done

case "x${EXP_STAGE}" in
    xmerge) merge ;;
    x)      break ;;
    x*)     standard ;;
esac

