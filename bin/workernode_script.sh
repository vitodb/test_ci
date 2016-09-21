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

source /cvmfs/dune.opensciencegrid.org/products/dune/setup_dune.sh || source /grid/fermiapp/products/dune/setup_dune.sh
source ${PWD}/localProducts_*/setup

eval $(ups list -aK+ dunetpc -z localProducts_* | awk '{if ( $1 ~ "dunetpc" ) {print "setup "$1" "$2" -q "$4} }')

ups active

case "$1" in
    end)
        ifdh ll ${CI_DCACHEDIR}
        report_exitcode=$?

        report_test_result "$report_phase" "" "${CLUSTER}_${PROCESS}" "status" "${report_exitcode}.0"

        report_end_phase "$report_phase" "${report_exitcode}"
        ;;
    *)

        sh ${CONDOR_DIR_INPUT}/experiment_script.sh
        report_exitcode=$?

        ls -lh

        report_test_result "$report_phase" "" "${CLUSTER}_${PROCESS}" "status" "${report_exitcode}.0"

        ;;
esac

#exit 0
