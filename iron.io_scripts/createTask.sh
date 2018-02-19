#!/bin/bash
#
# Script to retrieve code information for Veritone projects
# See http://dev.iron.io/worker/reference/api/#list_tasks
#
# Make sure to define an environment variable IRONIO_TOKEN
# e.g
#     IRONIO_TOKEN=YOURTOKEN  scripts
#
#  Output will be project:name, archived or not, link to code information, the config itself.
# ---------------------------------------------------------
#
zero=0
NOW=$(date "+%s")

function printUsage(){
  echo "IRONIO_TOKEN=xxx NUM_DAYS=xx FILTER=xxx $0"
  echo "DEFAULT values:"
  echo "     FILTER:  error=1&timeout=1"
  echo "     NUM_DAYS = 7"
  exit 1
}
# Get rid of the quotes as returned by jq (to indicate strings)
## ret_val has the result
function getRidOfQuotes() {
    ret_val=$(sed 's/\"//g' <<< "$1")
}

## Getting tasks that were created with filter
## after fromDay (e.g 7th day ago) for one day (e.g. til 6th day ago)
function getTasksForOneDayAProject () {
    proj=$1
    projName=$2
    OUTDIR=$3
    fromDay=$4
    filter=$5

    ONEDAY=1
    ONE_DAY_IN_SECONDS=$(($ONEDAY * 3600 * 24 ))
    NSECONDS_FROMDAY=$(($fromDay * $ONE_DAY_IN_SECONDS))
    NSECONDS_TODAY=$(($NSECONDS_FROMDAY - $ONE_DAY_IN_SECONDS))
    START_TIME=$(($NOW - $NSECONDS_FROMDAY))
    END_TIME=$(($NOW - $NSECONDS_TODAY))


    token=${IRONIO_TOKEN}

    echo "=================== ${projName} ======================="
    echo "Querying for tasks with $filter, from $fromDay"
    echo "START_TIME=${START_TIME}"
    echo "END_TIME=${END_TIME}"
    echo "FILTER=$filter"
    page_size=100

    baseurl=https://worker-aws-us-east-1.iron.io/2/projects/${proj}
    url=${baseurl}/tasks
    header1="Authorization: OAuth ${token}"
    header2="Accept: application/json"
    header3="Accept-Encoding: gzip/deflate"
    header4="Content-Type: application/json"

    #echo ${baseurl}
    echo ${url}

    tmp1=${OUTDIR}/${projName}_tasks
    header3="Accept-Encoding: gzip/deflate".txt

    resultFile=${outdir}/${projName}_results.csv
    TOTAL_DAY_TASKS=0

    delim=","
    i=0
    if [ ! -z $CODE_NAME ];
    then
      echo "CODE_NAME=$CODE_NAME"
      QCODE_NAME="&code_name=$CODE_NAME"
      resultFile=${outdir}/${projName}_${CODE_NAME}.csv
    else
      QCODE_NAME=""
    fi

    if [ ! -z $FILTER ];
    then
      QFILTER=&filter
  fi

    # theoretically do a while loop and set the page - just iterate until nnone is left
    for i in `seq 0 99`;
    do
        #set -x
        curl -s -X GET -H "${header1}" -H "${header2}" -H "${header3}" -H "${header4}" "${url}?per_page=${page_size}&page=${i}&from_time=${START_TIME}&to_time=${END_TIME}${filter}$QCODE_NAME" -o ${tmp1}
        #et +x
            ntasks=$(cat ${tmp1} | jq '.tasks|length')
            echo ${ntasks} tasks found
            if [[ ntasks -eq zero ]];
            then
                break
            fi
            TOTAL_DAY_TASKS=$((TOTAL_DAY_TASKS + ntasks))
            (( ntasks-- ))
            for i in $(seq 0 $ntasks); do
                id=`cat ${tmp1} | jq ".tasks[${i}].id"`
                code_name=`cat ${tmp1} | jq ".tasks[${i}].code_name"`
                status=`cat ${tmp1} | jq ".tasks[${i}].status"`
                start_time=`cat ${tmp1} | jq ".tasks[${i}].start_time"`
                msg=`cat ${tmp1} | jq ".tasks[${i}].msg"`
                payload=`cat ${tmp1} | jq ".tasks[${i}].payload"`
                getRidOfQuotes $code_name
                code_name=${ret_val}

                getRidOfQuotes $id
                id=${ret_val}

                getRidOfQuotes $status
                status=${ret_val}

                getRidOfQuotes $start_time
                start_time=${ret_val}

                #echo ${code_name},${id},${status}
                task_link=https://hud-e.iron.io/worker/projects/${proj}/tasks/${id}

                echo ${code_name}${delim}${status}${delim}${start_time}${delim}${task_link}${delim}${msg}${delim}${payload}>> ${resultFile}

            done
    done


    echo TOTAL TASKS for Day ${fromDay} = ${TOTAL_DAY_TASKS}
    echo See ${resultFile}
    rm -f ${tmp1}
}


# create a task with a payload in prod
function createTask() {
  proj=$1
  projName=$2
  payload_file=$3
  code_name=$4
  cluster=$5

  token=${IRONIO_TOKEN}

  echo "=================== ${projName} ======================="
  echo "Creating job for $code_name using $payload_file"

  baseurl=https://worker-aws-us-east-1.iron.io/2/projects/${proj}
  url=${baseurl}/tasks
  header1="Authorization: OAuth ${token}"
  header2="Accept: application/json"
  header3="Accept-Encoding: gzip/deflate"
  header4="Content-Type: application/json"

  #echo ${baseurl}
  echo ${url}

  file_contents=$(<$payload_file)
  echo $file_contents
  echo ------------------------

      set -x
      curl -s -X POST -H "${header1}" -H "${header2}" -H "${header3}" -H "${header4}" "${url}" \
      -d '{"tasks": [{"code_name": "'$code_name'","cluster":"'$cluster'","payload": "'$file_contents'"}]}'
      set +x
}


if [ "$IRONIO_TOKEN" == "" ]; then
  echo "ERROR! Please define the variable IRONIO_TOKEN to the script or"
  printUsage
fi

TODAY=$(date +"%Y%m%d_%H%M%S")
echo DATE=$TODAY
core_v3_prod=5570c47ac0293c000600008b
#core_v3_stage=56afcfd5428876000a000205
#core_v3_dev=5570c45981b1f60006000089
#core_v3_prod_uk=59443967cc288e0009d18381
#core_v3_gov=57fd6d20ce60dc0007dd3677
CODE_NAME=transcribe-nuance-containerized-eng-usa
CLUSTER=59a5d97ef62d8500093813bc
if [ -z $PAYLOAD_FILE ];
then
  echo "Need to define PAYLOAD_FILE"
  exit 1
fi

#PAYLOAD_FILE=payload/55059275.json

createTask ${core_v3_prod} core_v3_prod $PAYLOAD_FILE $CODE_NAME $CLUSTER
