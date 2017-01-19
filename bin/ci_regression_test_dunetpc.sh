#!/usr/bin/env bash


function usage {
      cat <<EOF
   usage: $0 [options]
      running CI tests for ${proj_PREFIX}_ci.
   options:
      --executable  Define the executable to run
      --nevents     Define the number of events to process
      --stage       Define the stage number used to parse the right testmask column number
      --fhicl       Set the FHiCl file to use to run the test
      --input       Set the file on which you want to run the test
      --outputs     Define a list of couple <output_stream>:<output_filename> using "," as separator
      --stage-name  Define the name of the test
      --testmask    Define the name of the testmask file
      --update-ref-files Flag to activate the "Update Reference Files" mode
      --input-files
      --reference-files
EOF
}

function initialize
{
    TASKSTRING="initialize"
    trap 'LASTERR=$?; echo -e "\nCI MSG BEGIN\n `basename $0`: error at line ${LINENO}\n Stage: ${STAGE_NAME}\n Task: ${TASKSTRING}\n exit status: ${LASTERR}\nCI MSG END\n"; exit ${LASTERR}' ERR

    echo "running CI tests for ${proj_PREFIX}_ci."
    echo
    echo "initialize $@"

    #~~~~~~~~~~~~~~~ DEFAULT VALUES ~~~~~~~~~~~~~~~~
    EXECUTABLE_NAME=no_executable_defined
    NEVENTS=1
    INPUT_FILE=""
    UPDATE_REF_FILE_ON=0
    REFERENCE_FILES=""
    INPUT_FILES=""
    UPLOAD_REFERENCE_FILE=false
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    #~~~~~~~~~~~~~~~~~~~~~~GET VALUE FROM THE CI_TESTS.CFG ARGS SECTION~~~~~~~~~~~~~~~
    while :
    do
      case "x$1" in
      x-h|x--help)         usage;                                                       exit;;
      x--executable)       EXECUTABLE_NAME="${2}";                                      shift; shift;;
      x--nevents)          NEVENTS="${2}";                                              shift; shift;;
      x--stage)            STAGE="${2}";                                                shift; shift;;
      x--fhicl)            FHiCL_FILE="${2}";                                           shift; shift;;
      x--input)            INPUT_FILE="${2}";                                           shift; shift;;
      x--outputs)          OUTPUT_LIST="${2}"; OUTPUT_STREAM="${OUTPUT_LIST//,/ -o }";  shift; shift;;
      x--stage-name)       STAGE_NAME="${2}";                                           shift; shift;;
      x--testmask)         TESTMASK="${2}";                                             shift; shift;;
      x--input-files)      INPUT_FILES="${2}";                                          shift; shift;;
      x--reference-files)  REFERENCE_FILES="${2}";                                      shift; shift;;
      x--update-ref-files) UPDATE_REF_FILE_ON=1;                                        shift;;
      x)                                                                                break;;
      x*)            echo "Unknown argument $1"; usage; exit 1;;
      esac
    done

    if [ ${UPDATE_REF_FILE_ON} -gt 0 ]; then
        echo -e "\n***************************************************"
        echo "This CI build is running to update reference files:"
        echo "- data product comparison is disabled"
        echo "- number of events is set to 1"
        echo -e "***************************************************\n"
        TESTMASK=""
        NEVENTS=1
    fi

    if [ -n "${INPUT_FILES}" ]; then
        fetch_files input ${INPUT_FILES}
    fi
    if [ -n "${REFERENCE_FILES}" ]; then
        fetch_files reference ${REFERENCE_FILES}
    fi

    #~~~~~~~~~~~~~~~~~~~~~PARSE THE TESTMASK FILE TO UNDERSTAND WHICH FUNCTION TO RUN ~~~~~~~~~~~~
    if [ -n "${TESTMASK}" ];then
        check_data_production=$(sed -n '1p' ${TESTMASK} | cut -d ' ' -f ${STAGE})
        check_compare_names=$(sed -n '2p' ${TESTMASK} | cut -d ' ' -f ${STAGE})
        check_compare_size=$(sed -n '3p' ${TESTMASK} | cut -d ' ' -f ${STAGE})
    else
        check_data_production=1
        check_compare_names=0
        check_compare_size=0
    fi

    echo "Input file:  ${INPUT_FILE}"
    echo "Output files: ${OUTPUT_LIST}"
    echo "FHiCL file:  ${FHiCL_FILE}"
    echo
    echo -e "\nRunning\n `basename $0` $@"

    exitstatus $?
}


function fetch_files
{
    old_taskstring="$TASKSTRING"
    old_errorstring="$ERRORSTRING"
    TASKSTRING="fetching $1 files"
    if [ "$1" == "reference" ];then
        ERRORSTRING="Warning in fetching $1 files,We tried to upload the file on your reference folder directory"
    elif [ "$1" == "input" ];then
        ERRORSTRING="Warning in fetching $1 files,Check if the file is available in your reference folder directory"
    fi

    #trap 'LASTERR=$?; echo -e "\nCI MSG BEGIN\n `basename $0`: error at line ${LINENO}\n Stage: ${STAGE_NAME}\n Task: ${TASKSTRING}\n exit status: ${LASTERR}\nCI MSG END\n"; exit ${LASTERR}' ERR
    echo
    echo "fetching $1 files for ${proj_PREFIX}_ci."
    echo
    echo "fetch_files $@"
    echo

    maxretries_backup= $IFDH_CP_MAXRETRIES
    debug_backup= $IFDH_DEBUG
    export IFDH_DEBUG=0
    export IFDH_CP_MAXRETRIES=0

    for file in ${2//,/ }
    do
        echo "Copying: " $file
        echo "Command: ifdh cp $file ./"
        ifdh cp $file ./

        if [ $? -ne 0 ]; then
            if [ "$1" == "reference" ];then #if it's a
                #skip the error and use something to execute first the data production and then coppy the reference dile on dcache
                check_data_production=1
                check_compare_names=0
                check_compare_size=0
                #skip the compares because we don't have a reference file
                UPLOAD_REFERENCE_FILE=true
            else
                echo "Failed to fetch $file"
                exitstatus 203
            fi
        fi

    done

    export IFDH_DEBUG=$debug_backup
    export IFDH_CP_MAXRETRIES=$maxretries_backup

    exitstatus $?
    TASKSTRING="$old_taskstring"
    ERRORSTRING="$old_errorstring"
}


function data_production
{
    TASKSTRING="data_production"
    ERRORSTRING=""
    trap 'LASTERR=$?; echo -e "\nCI MSG BEGIN\n `basename $0`: error at line ${LINENO}\n Stage: ${STAGE_NAME}\n Task: ${TASKSTRING}\n exit status: ${LASTERR}\nCI MSG END\n"; exit ${LASTERR}' ERR

    export TMPDIR=${PWD} #Temporary directory used by IFDHC

    #~~~~~~~~~~~~~IF THE TESTMASK VALUE IS SET TO 1 THEN RUN THE PRODUCTION OF THR DATA~~~~~~~~~~~~~~~~~~
    if [[ "${1}" -eq 1 ]]
    then

        echo -e "\nNumber of events for ${STAGE_NAME} stage: $NEVENTS\n"
        echo ${EXECUTABLE_NAME} --rethrow-all -n ${NEVENTS} -o ${OUTPUT_STREAM} --config ${FHiCL_FILE} ${INPUT_FILE}
        echo

        ${EXECUTABLE_NAME} --rethrow-all -n ${NEVENTS} -o ${OUTPUT_STREAM} --config ${FHiCL_FILE} ${INPUT_FILE}
    else
        echo -e "\nCI MSG BEGIN\n Stage: ${STAGE_NAME}\n Task: ${TASKSTRING}\n skipped\nCI MSG END\n"
    fi
    exitstatus $?

    [[ "${OUTPUT_LIST}" == *"_%#"* ]] && \
        for CUR_OUT in ${OUTPUT_STREAM//-o/}
        do
            CUR_OUT=${CUR_OUT//*:/}
            CUR_OUT2=$(echo $CUR_OUT | sed -e "s/_%#// ; s/_[0-9]+.root/.root/")
            [ "${CUR_OUT//_%#.root/_1.root}" = "${CUR_OUT2}" ] || ln -sv ${CUR_OUT//_%#.root/_1.root} ${CUR_OUT2}
        done

    OUTPUT_LIST=${OUTPUT_LIST//_%#/}

}

function generate_data_dump
{
    TASKSTRING="generate_data_dump for ${file_stream} output stream"
    ERRORSTRING=""

    trap 'LASTERR=$?; echo -e "\nCI MSG BEGIN\n `basename $0`: error at line ${LINENO}\n Stage: ${STAGE_NAME}\n Task: ${TASKSTRING}\n exit status: ${LASTERR}\nCI MSG END\n"; exit ${LASTERR}' ERR

    local NEVENTS=1

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~PRINT THE COMMAND TO LOG AND THEN GENERATE THE DUMP FOR THE REFERENCE FILE ~~~~~~~~~~~~~~~~~~~
    echo -e "\nGenerating Dump for ${reference_file}"
    echo "${EXECUTABLE_NAME} --rethrow-all -n ${NEVENTS} --config eventdump.fcl ${reference_file} > ${reference_file//.root}.dump"

    ${EXECUTABLE_NAME} --rethrow-all -n ${NEVENTS} --config eventdump.fcl "${reference_file}" > "${reference_file//.root}".dump
    #~~~~~~~~~~~~~~~~~~~~~~~~~SAVE IN A VARIABLE THE PARSED REFERENCE DUMP FILE ~~~~~~~~~~~~~~~~~~~~~~
    OUTPUT_REFERENCE=$(cat "${reference_file//.root}".dump | sed -e  '/PROCESS NAME/,/^\s*$/!d ; s/PROCESS NAME.*$// ; /^\s*$/d' )

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~PRINT THE COMMAND TO LOG AND THEN GENERATE THE DUMP FOR THE CURRENT FILE ~~~~~~~~~~~~~~~~~~~
    echo -e "\nGenerating Dump for ${current_file}"
    echo "${EXECUTABLE_NAME} --rethrow-all -n ${NEVENTS} --config eventdump.fcl ${current_file} > ${current_file//.root}.dump"

    ${EXECUTABLE_NAME} --rethrow-all -n ${NEVENTS} --config eventdump.fcl "${current_file}" > "${current_file//.root}".dump
    #~~~~~~~~~~~~~~~~~~~~~~~~~SAVE IN A VARIABLE THE PARSED CURRENT DUMP FILE ~~~~~~~~~~~~~~~~~~~~~~
    OUTPUT_CURRENT=$(cat "${current_file//.root}".dump | sed -e  '/PROCESS NAME/,/^\s*$/!d ; s/PROCESS NAME.*$// ; /^\s*$/d' )

    echo -e "\nReference files for ${file_stream} output stream:"
    echo -e "\n${reference_file//.root}.dump\n"
    echo "$OUTPUT_REFERENCE"
    echo -e "\nCurrent files for ${file_stream} output strea:"
    echo -e "\n${current_file//.root}.dump\n"
    echo "$OUTPUT_CURRENT"

    exitstatus $?
}

function compare_products_names
{
    TASKSTRING="compare_products_names for ${file_stream} output stream"
    ERRORSTRING="Differences in products names,Please consider to request a new set of reference files"

    if [[ "$1" -eq 1 ]]
    then

        echo -e "\nCompare products names for ${file_stream} output stream."
        #~~~~~~~~~~~~~~~~CHECK IF THERE'S A DIFFERENCE BEETWEEN THE TWO DUMP FILES IN THE FIRST FOUR COLUMNS~~~~~~~~~~~~~~
        DIFF=$(diff  <(sed 's/\.//g ; /PROCESS NAME/,/^\s*$/!d ; s/PROCESS NAME.*$// ; /^\s*$/d' ${reference_file//.root/.dump} | cut -d "|" -f -4 ) <(sed 's/\.//g ; /PROCESS NAME/,/^\s*$/!d ; s/PROCESS NAME.*$// ; /^\s*$/d' ${current_file//.root/.dump} | cut -d "|" -f -4 ) )
        STATUS=$?

        echo -e "\nCheck for added/removed data products"
        echo -e "difference(s)\n"
        #~~~~~~~~~~~~~~~IF THERE'S A DIFFERENCE EXIT WITH ERROR CODE 200~~~~~~~~~~~~~~~
        if [[ "${STATUS}" -ne 0  ]]; then
            echo "${DIFF}"
            exitstatus 201
        else
            echo -e "none\n\n"
        fi
    else
        echo -e "\nCI MSG BEGIN\n Stage: ${STAGE_NAME}\n Task: ${TASKSTRING}\n skipped\nCI MSG END\n"
        exitstatus $?
    fi
}

function compare_products_sizes
{
    TASKSTRING="compare_products_sizes for ${file_stream} output stream"
    ERRORSTRING="Differences in products sizes,Please consider to request a new set of reference files"


    if [[ "${1}" -eq 1 ]]
    then

        echo -e "\nCompare products sizes for ${file_stream} output stream.\n"
        #~~~~~~~~~~~~~~~~CHECK IF THERE'S A DIFFERENCE BEETWEEN THE TWO DUMP FILES,IN ALL THE COLUMNS~~~~~~~~~~~~~~
        DIFF=$(diff  <(sed 's/\.//g ; /PROCESS NAME/,/^\s*$/!d ; s/PROCESS NAME.*$// ; /^\s*$/d' ${reference_file//.root/.dump}) <(sed 's/\.//g ; /PROCESS NAME/,/^\s*$/!d ; s/PROCESS NAME.*$// ; /^\s*$/d' ${current_file//.root/.dump}) )
        STATUS=$?
        echo -e "\nCheck for differences in the size of data products"
        echo -e "difference(s)\n"

        #~~~~~~~~~~~~~~~IF THERE'S A DIFFERENCE EXIT WITH ERROR CODE 201 ~~~~~~~~~~~~~~~~~~~~~~~
        if [[ "${STATUS}" -ne 0 ]]; then
            echo "${DIFF}"
            exitstatus 202
        else
            echo -e "none\n\n"
        fi
    else
        echo -e "\nCI MSG BEGIN\n Stage: ${STAGE_NAME}\n Task: ${TASKSTRING}\n skipped\nCI MSG END\n"
        exitstatus $?
    fi
}

#~~~~~~~~~~~~~~~~~~~~~~~PRINT AN ERROR MESSAGE IN THE PROGRAM EXIT WITH AN ERROR CODE~~~~~~~~~~~~~~~~
function exitstatus
{
    EXITSTATUS="$1"
    echo -e "\nCI MSG BEGIN\n Stage: ${STAGE_NAME}\n Task: ${TASKSTRING}\n exit status: ${EXITSTATUS}\nCI MSG END\n"
    if [[ "${EXITSTATUS}" -ne 0 ]]; then
        if [ -n "$ERRORSTRING" ];then
            echo "${STAGE}@${EXITSTATUS}@$ERRORSTRING" >> $WORKSPACE/data_production_stats.log
        fi
        exit "${EXITSTATUS}"
    fi
}



#~~~~~~~~~~~~~~~~~~~~~~~~MAIN OF THE SCRIPT~~~~~~~~~~~~~~~~~~
trap 'LASTERR=$?; echo -e "\nCI MSG BEGIN\n `basename $0`: error at line ${LINENO}\n Stage: ${STAGE_NAME}\n Task: ${TASKSTRING}\n exit status: ${LASTERR}\nCI MSG END\n"; exit ${LASTERR}' ERR

initialize $@

data_production "${check_data_production}"

#~~~~~~~~~~~~~~~~PROCESS ALL THE FILES DECLARED INTO THE OUTPUT LIST~~~~~~~~~~~~~~~~~
for filename in ${OUTPUT_LIST//,/ }
do
    file_stream=$(echo "${filename}" | cut -d ':' -f 1)
    current_file=$(echo "${filename}" | cut -d ':' -f 2)

    echo "filename: ${filename}"
    echo "file_stream: ${file_stream}"
    echo "current_file: ${current_file}"

    if [ -n "${build_platform}" ]
    then
        reference_file=$(echo "${current_file%`echo ${build_platform}`*}${build_platform}${current_file#*`echo ${build_platform}`}")
    else
        reference_file=$(echo "${current_file}")
    fi
    reference_file="${reference_file//Current/Reference}"

    if [[ "${check_compare_names}" -eq 1  || "${check_compare_size}" -eq 1 ]]
    then
        generate_data_dump
    else
        break
    fi

    compare_products_names "${check_compare_names}"

    compare_products_sizes "${check_compare_size}"
done
