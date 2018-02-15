#!/bin/bash
#
# Script to retrieve code information for Veritone projects
#
# Make sure to define an environment variable IRONIO_TOKEN
# Usage
#     IRONIO_TOKEN=YOURTOKEN ./listClusters.sh
#  Pipe the output to a file as .csv --> and open the .csv file, sort as you like
#
# ---------------------------------------------------------
#

# Get rid of the quotes as returned by jq (to indicate strings)
## ret_val has the result
function getRidOfQuotes() {
    ret_val=$(sed 's/\"//g' <<< "$1")
}


CURL_OPTS="-sS"
#CURL_OPTS="-v"

function getClusters () {
    token=${IRONIO_TOKEN}
    OUTDIR=tmpres

    baseurl=https://worker-aws-us-east-1.iron.io/2
    url=${baseurl}/clusters
    header1="Authorization: OAuth ${token}"
    header2="Accept: application/json"
    header3="Accept-Encoding: gzip/deflate"
    header4="Content-Type: application/json"

    #echo ${baseurl}
    #echo ${url}

    tmp1=${OUTDIR}/clusters.txt

    curl ${CURL_OPTS} -X GET -o ${tmp1} -H "${header1}" -H "${header2}" -H "${header3}" -H "${header4}" ${url}
    cat ${tmp1} | jq '' > clusters.json

    #cat clusters.json

    # grep for \"name\"\: and remove the \"E- with sed /E-/d 
    # for now, we just look for tne name

    nClusters=$(cat clusters.json | jq '.clusters|length')
    j=0
    #echo Number of clusters = $nClusters
    (( nClusters -- ))
    echo name, id, instance_type, memory, disk_space, runners_min, runners_max, runners_per_instance
    for i in $(seq 0 $nClusters); do
      name=`cat clusters.json | jq ".clusters[${i}].name" | sed 's/\"//g'`
      if [[ $name == E-* ]] || [[ $name == *TEST* ]]; then
         (( j++ ))
      else
      	 id=`cat clusters.json | jq ".clusters[${i}].id" | sed 's/\"//g'`
      	 memory=`cat clusters.json | jq ".clusters[${i}].memory" | sed 's/\"//g'`
      	 disk_space=`cat clusters.json | jq ".clusters[${i}].disk_space" | sed 's/\"//g'`
      	 runners_min=`cat clusters.json | jq ".clusters[${i}].autoscale.runners_min" | sed 's/\"//g'`
      	 runners_max=`cat clusters.json | jq ".clusters[${i}].autoscale.runners_max" | sed 's/\"//g'`
      	 runners_per_instance=`cat clusters.json | jq ".clusters[${i}].autoscale.runners_per_instance" | sed 's/\"//g'`
      	 instance_type=`cat clusters.json | jq ".clusters[${i}].autoscale.aws.instance_type" | sed 's/\"//g'`
     
         echo $name, https://hud-e.iron.io/worker/clusters/$id, $instance_type, $memory, $disk_space, $runners_min, $runners_max, $runners_per_instance
      fi
    done
}    
# Get Cluster
getClusters

