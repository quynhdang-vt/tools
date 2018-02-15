#!/bin/bash
#
# Script to retrieve code information for Veritone projects
#
# Make sure to define an environment variable IRONIO_TOKEN
# Usage
#     IRONIO_TOKEN=YOURTOKEN ./listTasks.sh
#
#  Output will be project:name, archived or not, link to code information, the config itself.
# ---------------------------------------------------------
#

# Get rid of the quotes as returned by jq (to indicate strings)
## ret_val has the result
function getRidOfQuotes() {
    ret_val=$(sed 's/\"//g' <<< "$1")
}

function getCodesForAProject () {
    proj=$1
    projName=$2
    OUTDIR=$3

    token=${IRONIO_TOKEN}

    echo "=========== ${projName} =========="
    page_size=50

    baseurl=https://worker-aws-us-east-1.iron.io/2/projects/${proj}
    url=${baseurl}/codes
    header1="Authorization: OAuth ${token}"
    header2="Accept: application/json"
    header3="Accept-Encoding: gzip/deflate"
    header4="Content-Type: application/json"

    echo ${baseurl}
    echo ${url}

    tmp1=${OUTDIR}/${projName}_codes.txt


    totalTasks=0
    zero=0
    delim="#"
    i=0
# theoretically do a while loop and set i
for i in `seq 0 10`;
do
    curl -s -X GET -H "${header1}" -H "${header2}" -H "${header3}" -H "${header4}" "${url}?per_page=${page_size}&page=${i}" -o ${tmp1}
        ntasks=$(cat ${tmp1} | jq '.codes|length')
        echo ${ntasks} tasks found
        if [[ ntasks -eq zero ]];
        then
            break
        fi
        totalTasks=$((totalTasks + ntasks))
        (( ntasks-- ))
        for i in $(seq 0 $ntasks); do
            id=`cat ${tmp1} | jq ".codes[${i}].id"`
            name=`cat ${tmp1} | jq ".codes[${i}].name"`
            getRidOfQuotes $name
            name=${ret_val}
            getRidOfQuotes $id
            id=${ret_val}
            echo ${name}
            status=`cat ${tmp1} | jq ".codes[${i}].status"`
            config=`cat ${tmp1} | jq  ".codes[${i}].config"`
            link=https://hud-e.iron.io/worker/projects/${proj}/codes/${id}
            task_link=https://hud-e.iron.io/worker/projects/${proj}/tasks/${id}/activity#?page=0
            echo ${projName}::${name}${delim}${status}${delim}${link}${delim}${task_link} >> ${resultFile}
#                       echo ${projName}::${name}${delim}${status}${delim}${link}${delim}${task_link}${delim}${config} >> ${resultFile}

        done
done


echo TOTAL TASKS = ${totalTasks}
echo See ${resultFile}
rm -f ${tmp1}
}


if [ "$IRONIO_TOKEN" == "" ]; then
  echo "ERROR! Please define the variable IRONIO_TOKEN to the script, e.g"
  echo "IRONIO_TOKEN=xxxxx  $0"
  exit 1
fi

NOW=$(date +"%Y%m%d_%H%M%S")
echo $NOW
core_v3_prod=5570c47ac0293c000600008b
core_v3_stage=56afcfd5428876000a000205
core_v3_dev=5570c45981b1f60006000089
core_v3_prod_uk=59443967cc288e0009d18381
core_v3_gov=57fd6d20ce60dc0007dd3677

outdir=results/${NOW}
mkdir -p ${outdir}
resultFile=${outdir}/results.txt

echo ${NOW} > $resultFile
echo projectName::Name#Status#Code Link#Task Link#Config >> $resultFile
getCodesForAProject ${core_v3_prod} core_v3_prod ${outdir}
getCodesForAProject ${core_v3_stage} core_v3_stage ${outdir}
getCodesForAProject ${core_v3_gov} core_v3_gov ${outdir}
getCodesForAProject ${core_v3_prod_uk} core_v3_prod_uk ${outdir}
