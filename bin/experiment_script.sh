#!/bin/bash

ups active

# copy input data
#------------------

# ifdh cp /pnfs/dune/persistent/users/vito/ci_tests_inputfiles/AntiMuonCutEvents_LSU_v2_dune35t_Reference_gen_default.root AntiMuonCutEvents_LSU_v2_dune35t_Reference_gen_default.root

# run experiment code on input data
#----------------------------------

echo "1: $1"
shift
echo "2: $2"
shift
echo "@: $@"
echo "@: ${@//@/ }"

echo CMD: $(eval echo \$executable_${2}) $(eval echo \$arguments_${2} -c \$FHiCL_${2} -n \$nevents_per_job_${2} -o \$output_filename_${2} \$input_filename_${2})

# # # $(eval echo \$executable_${2}) $(eval echo \$arguments_${2} -c \$FHiCL_${2} -n \$nevents_per_job_${2} -o \$output_filename_${2} \$input_filename_${2})



echo CMD: ifdh cp ${CI_DCACHEDIR}/$(eval echo \$input_from_stage_${2}/\$input_filename_${2} ${CI_DCACHEDIR}/${2}/)

# # # ifdh cp ${CI_DCACHEDIR}/$(eval echo \$input_from_stage_${2}/\$input_filename_${2} ${CI_DCACHEDIR}/${2}/)

# lar --rethrow-all -n 1 -o AntiMuonCutEvents_LSU_v2_dune35t_Current_geant_default.root --config standard_g4_dune35t.fcl AntiMuonCutEvents_LSU_v2_dune35t_Reference_gen_default.root
report_exitcode=$?

ls -lh
