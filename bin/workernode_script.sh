#!/bin/bash

source ${CONDOR_DIR_INPUT}/setup_workernode.sh
#source ${_CONDOR_JOB_IWD}/generic_ci/bin/reporter_functions.sh
source ${GENERIC_CI_DIR}/bin/reporter_functions.sh

echo -e "\n\n#######\n\n"

env | sort

echo -e "\n\n#######\n\n"

pwd
ls -lh

echo -e "\n\n#######\n\n"

EXP_STAGE=${1}

#report_test_result "$report_phase" "$test_suite[not used]" "$test_name" "$statistic" "$value.0"

report_test_result "$report_phase" "" "execute_${EXP_STAGE}_${PROCESS}" "status" "-2.0"
report_test_result "$report_phase" "" "execute_${EXP_STAGE}_${PROCESS}" "status" "-1.0"



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

#setup jobsub_client
unsetup cigetcert
setup cigetcert -t
ups active


echo "1: $1"
echo "2: $2"
echo "@: $@"

standard() {
    echo "Copy input file (if any)..."
    eval echo \$input_filename_${EXP_STAGE}
    # # # [ $(eval echo \$input_filename_${EXP_STAGE}) ] &&
    # # #     ifdh cp ${CI_DCACHEDIR}/$(eval echo \$input_from_stage_${EXP_STAGE}/\$input_filename_${EXP_STAGE}) . ||
    # # #     echo "No file to transfer"
    new_input_filename=$(eval echo \$input_filename_${EXP_STAGE})
    new_input_filename=${new_input_filename//.root/_${PROCESS}.root}
    [ $(eval echo $new_input_filename) ] &&
        (echo CMD: ifdh cp ${CI_DCACHEDIR}/$(eval echo \$input_from_stage_${EXP_STAGE})/$new_input_filename .
        ifdh cp ${CI_DCACHEDIR}/$(eval echo \$input_from_stage_${EXP_STAGE})/$new_input_filename .) ||
        echo "No file to transfer"


    ls -lh

    echo "run exp code..."
    echo CMD: $(eval echo \$executable_${EXP_STAGE}) $(eval echo \$arguments_${EXP_STAGE} -c \$FHiCL_${EXP_STAGE} -n \$nevents_per_job_${EXP_STAGE} -o \$output_filename_${EXP_STAGE}) $new_input_filename
    $(eval echo \$executable_${EXP_STAGE}) $(eval echo \$arguments_${EXP_STAGE} -c \$FHiCL_${EXP_STAGE} -n \$nevents_per_job_${EXP_STAGE} -o \$output_filename_${EXP_STAGE}) $new_input_filename

    ls -lh

    echo "Copy output file..."
    new_output_filename=$(eval echo \$output_to_transfer_${EXP_STAGE})
    new_output_filename=${new_output_filename//.root/_${PROCESS}.root}
    echo CMD: mv -v $(eval echo \$output_to_transfer_${EXP_STAGE}) $new_output_filename
    mv -v $(eval echo \$output_to_transfer_${EXP_STAGE}) $new_output_filename
    ls -lh
    echo CMD: ifdh cp ${PWD}/$new_output_filename ${CI_DCACHEDIR}/${EXP_STAGE}/$new_output_filename
    ifdh cp ${PWD}/$new_output_filename ${CI_DCACHEDIR}/${EXP_STAGE}/$new_output_filename

    report_exitcode=$?

    ls -lh

    report_test_result "$report_phase" "" "execute_${EXP_STAGE}_${PROCESS}" "status" "${report_exitcode}.0"

    exit ${report_exitcode}
}

merge() {

    new_input_filename=$(eval echo \$input_filename_${EXP_STAGE})
    new_input_filename=${new_input_filename//.root/*.root}

    export IFDH_DEBUG=1

    eval echo \$input_filename_${EXP_STAGE}
    echo new_input_filename: $new_input_filename
    echo CMD: ifdh findMatchingFiles ${CI_DCACHEDIR}/$(eval echo \$input_from_stage_${EXP_STAGE}) ${new_input_filename}
    ifdh findMatchingFiles ${CI_DCACHEDIR}/$(eval echo \$input_from_stage_${EXP_STAGE}) ${new_input_filename}

    echo CMD: hadd $(eval echo \$output_filename_${EXP_STAGE}) $(for source_file in $( ifdh findMatchingFiles ${CI_DCACHEDIR}/$(eval echo \$input_from_stage_${EXP_STAGE}) ${new_input_filename} 2> /dev/null | awk '{print $1}' ) ; do echo root://fndca1/${source_file}; done)

    hadd $(eval echo \$output_filename_${EXP_STAGE}) $(for source_file in $( ifdh findMatchingFiles ${CI_DCACHEDIR}/$(eval echo \$input_from_stage_${EXP_STAGE}) ${new_input_filename} 2> /dev/null | awk '{print $1}' ) ; do echo root://fndca1/${source_file}; done)

    report_exitcode=$?


    echo CMD: calorimetry.py --tracker trackkalmanhit --input $(eval echo \$output_filename_${EXP_STAGE}) --output calorimetry_validation.root
    calorimetry.py --tracker trackkalmanhit --input $(eval echo \$output_filename_${EXP_STAGE}) --output calorimetry_validation.root

    echo CMD: makeplots.py --input calorimetry_validation.root --calorimetry
    makeplots.py --input calorimetry_validation.root --calorimetry


    #report_img "$report_phase" "$test_suite" "$testname" "hits$i" "$f" "$desc"
    for f in calorimetry/*.gif
    do
        bf=`basename $f`
        hist_desc="hits ${bf//.gif/}"
        hist_name="${bf//.gif/}"
        report_img "$report_phase" "" "execute_${EXP_STAGE}_${PROCESS}" "hist_name" "$f" "$hist_desc"
    done

    echo CMD: ifdh cp -D $(eval echo \$output_filename_${EXP_STAGE}) calorimetry_validation.root calorimetry ${CI_DCACHEDIR}/${EXP_STAGE}
    ifdh cp -D $(eval echo \$output_filename_${EXP_STAGE}) calorimetry_validation.root  ${CI_DCACHEDIR}/${EXP_STAGE}
    ifdh mkdir ${CI_DCACHEDIR}/${EXP_STAGE}/calorimetry
    ifdh cp -D  calorimetry/* ${CI_DCACHEDIR}/${EXP_STAGE}/calorimetry

    report_test_result "$report_phase" "" "execute_${EXP_STAGE}_${PROCESS}" "status" "${report_exitcode}.0"

    exit ${report_exitcode}

}


case "x$1" in
    xmerge) merge ;;
    x)      break ;;
    x*)     standard ;;
esac

