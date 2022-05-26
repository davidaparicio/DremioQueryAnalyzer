#!/bin/bash
# This script assumes kubectl is installed on the machine where this script is running 
# and that the kubernetes context is set to the correct Dremio kubernetes cluster.
# This script will automatically copy the current queries.json from the Dremio Master Coordinator Pod into ./dremio_queries/,
# as well as archived queries.json files going back the specified number of days.
# It will then scrub the files to ensure queryText is no longer than 32k characters and will write
# the resulting files into a scrubbed sub-folder.
# Finally, the scrubbed files are transferred into S3/ADLS/HDFS depending on the storage_type specified.
#Input: 
#	storage_type = s3/adls/hdfs 
#	storage_path = path on storage to results folder e.g s3://mybucket (AWS) or https://[account].blob.core.windows.net/[container] (Azure)
#	num_archive_days = the number of days of archived queries.json files to also copy and scrub.

# Below is a sample crontab line in case you wish to schedule periodic execution of this script.
# 05 00 * * * cd /path/to/dremio-query-analyzer/scripts/ && ./gather_queries_k8s.sh s3 s3://mybucket 1 >> /path/to/dremio-query-analyzer/logs/script_output.log 2>&1


# USER NEEDS TO ENSURE DREMIO_LOG_DIR IS SET CORRECTLY IN THIS FILE PRIOR TO EXECUTION
DREMIO_LOG_DIR="/opt/dremio/data/log"
storage_type=$1
storage_path=$2
num_archive_days=$3
today_date=`date '+%Y-%m-%d'`
processing_date=$today_date
is_gz_copied=0
count_today_archives=0

# Parameters for calling the get-error-messages.py and refresh-pds.py scripts
dremio_url="http://localhost:9047"
user_name="dremio"
#Assumes local.pwd is chmod 400 protected so only the user executing this script can read the contents. Alternatively the password can be entered in a file in a different location or entered explicitly in this file
pwd=$(cat ../../local.pwd) 


rm -f ./dremio_queries/queries*.json
rm -f ./dremio_queries/scrubbed/*queries*.json*

# Copy the current queries.json file
echo "Copying current queries.json"
kubectl cp dremio-master-0:$DREMIO_LOG_DIR/queries.json ./dremio_queries/queries.json

# Copy any archive file generated for today and for however many specified archive days
if [ "$num_archive_days" == "" ]
then
	num_archive_days=0
fi

for ((i=0;i<=$num_archive_days;i++)) 
do
  # Check if there are any archive files for the current processing date
  for f in $(kubectl exec dremio-master-0 -- bash -c "ls $DREMIO_LOG_DIR/archive/queries.$processing_date.*.json.gz 2> /dev/null || true"); do 
	filename=$(basename $f)
    echo "Copying archive file for $processing_date: $filename"
	kubectl cp dremio-master-0:$f ./dremio_queries/$filename
	  is_gz_copied=1
	  
	# if we are processing today's files, count how many archives we have
    if [ $i == 0 ]; then
	  count_today_archives=$(($count_today_archives + 1))
	  echo "Count of today's archives=$count_today_archives"
	fi
  done
  
  processing_date=$(date -I -d "$processing_date - 1 day")  
done

if [ $is_gz_copied == 1 ]; then
  echo "Unzipping archived files"
  # unzip any archived queries.json files into the current folder
  gunzip ./dremio_queries/queries*.gz
fi

echo "Scrubbing files, splitting query text into 4096 byte chunks"
python scrub-queries-json.py ./dremio_queries ./dremio_queries/scrubbed $HOSTNAME

#Renaming today's scrubbed files to incorporate the date and the next available index number for archive files
#echo "Renaming today's header.queries.json to header.queries.$today_date.$count_today_archives.json"
mv ./dremio_queries/scrubbed/header.$HOSTNAME.queries.json.gz ./dremio_queries/scrubbed/header.$HOSTNAME.queries.$today_date.$count_today_archives.json.gz

#echo "Renaming today's chunks.queries.json to chunks.queries.$today_date.$count_today_archives.json"
mv ./dremio_queries/scrubbed/chunks.$HOSTNAME.queries.json.gz ./dremio_queries/scrubbed/chunks.$HOSTNAME.queries.$today_date.$count_today_archives.json.gz

# Gather error messages for all failed queries
echo "Gathering error messages for failed queries"
python get-error-messages.py --url "$dremio_url" --user "$user_name" --password "$pwd" --queries-dir "./dremio_queries/scrubbed/" --hostname "$HOSTNAME"

if [ "$storage_type" == "s3" ]
then
	echo "Copying scrubbed header files to S3"
	for s3_scrubbed in ./dremio_queries/scrubbed/header*queries*.json.gz; do
	  aws s3 cp $s3_scrubbed $storage_path/results/
	done
	echo "Copying scrubbed chunks files to S3"
	for s3_scrubbed in ./dremio_queries/scrubbed/chunks*queries*.json.gz; do
	  aws s3 cp $s3_scrubbed $storage_path/chunks/
	done
	echo "Copying error message header files to S3"
	for s3_scrubbed in ./dremio_queries/scrubbed/errorheader*queries*.json.gz; do
	  aws s3 cp $s3_scrubbed $storage_path/errormessages/
	done
	echo "Copying error message chunks files to S3"
	for s3_scrubbed in ./dremio_queries/scrubbed/errorchunks*queries*.json.gz; do
	  aws s3 cp $s3_scrubbed $storage_path/errorchunks/
	done
elif [ "$storage_type" == "adls" ]
# Assumes the machine you are running this script from has already performed az login
then
	echo "Copying scrubbed header files to ADLS"
	for adls_scrubbed in ./dremio_queries/scrubbed/header*queries*.json.gz; do
      adls_filename=$(basename $adls_scrubbed)
      az storage copy -s $adls_scrubbed -d $storage_path/results/$adls_filename
	done
	echo "Copying scrubbed chunks files to ADLS"
	for adls_scrubbed in ./dremio_queries/scrubbed/chunks*queries*.json.gz; do
      adls_filename=$(basename $adls_scrubbed)
      az storage copy -s $adls_scrubbed -d $storage_path/chunks/$adls_filename
	done
	echo "Copying error message header files to ADLS"
	for adls_scrubbed in ./dremio_queries/scrubbed/errorheader*queries*.json.gz; do
      adls_filename=$(basename $adls_scrubbed)
      az storage copy -s $adls_scrubbed -d $storage_path/errormessages/$adls_filename
	done
	echo "Copying error message chunks files to ADLS"
	for adls_scrubbed in ./dremio_queries/scrubbed/errorchunks*queries*.json.gz; do
      adls_filename=$(basename $adls_scrubbed)
      az storage copy -s $adls_scrubbed -d $storage_path/errorchunks/$adls_filename
	done
elif [ "$storage_type" == "hdfs" ]
then
	echo "Copying scrubbed header files to HDFS"
	for hdfs_scrubbed in ./dremio_queries/scrubbed/header*queries*.json.gz; do
		hdfs dfs -copyFromLocal -f $hdfs_scrubbed $storage_path/results/
	done
	echo "Copying scrubbed files to HDFS"
	for hdfs_scrubbed in ./dremio_queries/scrubbed/chunks*queries*.json.gz; do
		hdfs dfs -copyFromLocal -f $hdfs_scrubbed $storage_path/chunks/
	done
	echo "Copying error message header files to HDFS"
	for hdfs_scrubbed in ./dremio_queries/scrubbed/errorheader*queries*.json.gz; do
		hdfs dfs -copyFromLocal -f $hdfs_scrubbed $storage_path/errormessages/
	done
	echo "Copying error message chunks files to HDFS"
	for hdfs_scrubbed in ./dremio_queries/scrubbed/errorchunks*queries*.json.gz; do
		hdfs dfs -copyFromLocal -f $hdfs_scrubbed $storage_path/errorchunks/
	done
	
	hdfs dfs -chmod 666 $storage_path/*/*.json.gz
else
	echo "Unknown storage type "$storage_type", files will remain local and will need manually copying"
fi

echo "Refreshing PDSs containing queries.json data"
python refresh-pds.py --url "$dremio_url" --user "$user_name" --password "$pwd" --pds "QueriesJson.results"
python refresh-pds.py --url "$dremio_url" --user "$user_name" --password "$pwd" --pds "QueriesJson.chunks"
python refresh-pds.py --url "$dremio_url" --user "$user_name" --password "$pwd" --pds "QueriesJson.errormessages"
python refresh-pds.py --url "$dremio_url" --user "$user_name" --password "$pwd" --pds "QueriesJson.errorchunks"
echo "Complete"