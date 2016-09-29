#!/bin/bash

source ${CONDOR_DIR_INPUT}/setup_workernode.sh
source ${CONDOR_DIR_INPUT}/reporter_functions.sh


echo -e "\n\n#######\n\n"

env | sort

echo -e "\n\n#######\n\n"

pwd
ls -lh

echo -e "\n\n#######\n\n"


#report_test_result "$report_phase" "$test_suite[not used]" "$test_name" "$statistic" "$value.0"

report_test_result "$report_phase" "" "${CLUSTER}_${PROCESS}" "status" "-2.0"
report_test_result "$report_phase" "" "${CLUSTER}_${PROCESS}" "status" "-1.0"



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
source /cvmfs/uboone.opensciencegrid.org/products/setup_uboone.sh || source /grid/fermiapp/products/uboone/setup_uboone.shsource ${PWD}/localProducts_*/setup

#eval $(ups list -aK+ dunetpc -z localProducts_* | awk '{if ( $1 ~ "dunetpc" ) {print "setup "$1" "$2" -q "$4} }')
eval $(ups list -aK+ uboonecode -z localProducts_* | awk '{if ( $1 ~ "uboonecode" ) {print "setup "$1" "$2" -q "$4} }')

ups active


echo "1: $1"
echo "2: $2"
echo "@: $@"


echo "Copy input file (if any)..."
[ $(eval echo \$input_filename_${1}) ] &&
    ifdh cp ${CI_DCACHEDIR}/$(eval echo \$input_from_stage_${1}/\$input_filename_${1}) . ||
    echo "No file to transfer"


echo "run exp code..."
echo CMD: $(eval echo \$executable_${1}) $(eval echo \$arguments_${1} -c \$FHiCL_${1} -n \$nevents_per_job_${1} -o \$output_filename_${1} \$input_filename_${1})
$(eval echo \$executable_${1}) $(eval echo \$arguments_${1} -c \$FHiCL_${1} -n \$nevents_per_job_${1} -o \$output_filename_${1} \$input_filename_${1})

echo "Copy output file..."
new_output_filename=$(eval echo \$output_filename_${1})
new_output_filename=${new_output_filename//.root/_${PROCESS}.root}
echo CMD: ifdh cp ${PWD}/$(eval echo \$output_filename_${1} ${CI_DCACHEDIR}/${1}/$new_output_filename)
ifdh cp ${PWD}/$(eval echo \$output_filename_${1} ${CI_DCACHEDIR}/${1}/$new_output_filename)

# sh ${CONDOR_DIR_INPUT}/experiment_script.sh "$@"
report_exitcode=$?

ls -lh

report_test_result "$report_phase" "" "${CLUSTER}_${PROCESS}" "status" "${report_exitcode}.0"

exit ${report_exitcode}
