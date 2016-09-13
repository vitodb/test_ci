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

sed -i.orig "s;SRT_DIST=.*;SRT_DIST=$PWD;" srt/srt.sh

source ${PWD}/setup/setup_nova.sh -r ${TEST_REVISION:-development} -b "${TEST_QUALS}" -6 "${PWD}" -e "/cvmfs/nova.opensciencegrid.org/externals:/grid/fermiapp/products/common/db:/grid/fermiapp/products/nova/externals"

ifdh cp /pnfs/nova/persistent/users/vito/ci_tests_inputfiles/fardet_r00022972_s05_t00.raw fardet_r00022972_s05_t00.raw

nova --rethrow-all -n 1 -o out1:fardet_r00022972_s05_t00_Current.artdaq.root --config daq2rawdigitjob.fcl fardet_r00022972_s05_t00.raw

ls -lh

curl  $curl_extra -v -o tr.out "$build_db_uri/build/add_test_result?fullname=${report_fullname}&serverurl=${report_serverurl}&phase=${report_phase}&testname=${CLUSTER}_${PROCESS}&statisticname="status"&platform=${report_platform}&buildtype=${report_buildtype}&hostname=${report_hostname}&value=0.0"

curl  $curl_extra -v -o ep.out "$build_db_uri/build/end_phase?fullname=${report_fullname}&phase=${report_phase}&exitcode=${report_exitcode}&platform=${report_platform}&hostname=${report_hostname}&buildtype=${report_buildtype}"
