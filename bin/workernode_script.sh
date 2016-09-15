#!/bin/bash

source ${CONDOR_DIR_INPUT}/setup_workernode.sh


echo -e "\n\n#######\n\n"

env | sort

echo -e "\n\n#######\n\n"

pwd
ls -lh

echo -e "\n\n#######\n\n"


curl  $curl_extra -v -o tr.out "$build_db_uri/build/add_test_result?fullname=${report_fullname}&serverurl=${report_serverurl}&phase=${report_phase}&testname=${CLUSTER}_${PROCESS}&statisticname="status"&platform=${report_platform}&buildtype=${report_buildtype}&hostname=${report_hostname}&value=-2.0"

curl  $curl_extra -v -o tr.out "$build_db_uri/build/add_test_result?fullname=${report_fullname}&serverurl=${report_serverurl}&phase=${report_phase}&testname=${CLUSTER}_${PROCESS}&statisticname="status"&platform=${report_platform}&buildtype=${report_buildtype}&hostname=${report_hostname}&value=-1.0"



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

ifdh cp /pnfs/dune/persistent/users/vito/ci_tests_inputfiles/AntiMuonCutEvents_LSU_v2_dune35t_Reference_gen_default.root AntiMuonCutEvents_LSU_v2_dune35t_Reference_gen_default.root

lar --rethrow-all -n 1 -o AntiMuonCutEvents_LSU_v2_dune35t_Current_geant_default.root --config standard_g4_dune35t.fcl AntiMuonCutEvents_LSU_v2_dune35t_Reference_gen_default.root
report_exitcode=$?

ls -lh

curl  $curl_extra -v -o tr.out "$build_db_uri/build/add_test_result?fullname=${report_fullname}&serverurl=${report_serverurl}&phase=${report_phase}&testname=${CLUSTER}_${PROCESS}&statisticname="status"&platform=${report_platform}&buildtype=${report_buildtype}&hostname=${report_hostname}&value=0.0"

curl  $curl_extra -v -o ep.out "$build_db_uri/build/end_phase?fullname=${report_fullname}&phase=${report_phase}&exitcode=${report_exitcode}&platform=${report_platform}&hostname=${report_hostname}&buildtype=${report_buildtype}"
