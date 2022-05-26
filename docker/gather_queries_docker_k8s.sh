#!/bin/bash
# This script assumes kubectl is installed on the machine where this script is running 
# and that the kubernetes context is set to the correct Dremio kubernetes cluster.
# This script will automatically copy the current queries.json from the Dremio Master Coordinator Pod into /opt/dremio/dremio_queries/,
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
#DREMIO_LOG_DIR="/opt/dremio/data/log"
storage_type=$DREMIO_STORAGE_TYPE
storage_path=$DREMIO_STORAGE_PATH
num_archive_days=$DREMIO_NUM_ARCHIVE_DAYS
today_date=`date '+%Y-%m-%d'`
processing_date=$today_date
is_gz_copied=0
count_today_archives=0

# Parameters for calling the get-error-messages.py and refresh-pds.py scripts
dremio_url="$DREMIO_ENDPOINT"
user_name="$DREMIO_USERNAME"
#Assumes local.pwd is chmod 400 protected so only the user executing this script can read the contents. Alternatively the password can be entered in a file in a different location or entered explicitly in this file
pwd="$DREMIO_PASSWORD"


rm -f /opt/dremio/dremio_queries/queries*.json
rm -Rf /opt/dremio/dremio_queries/scrubbed/
mkdir -p /opt/dremio/dremio_queries/scrubbed/
mkdir -p /opt/dremio/dremio_queries/scrubbed/results
mkdir -p /opt/dremio/dremio_queries/scrubbed/chunks
mkdir -p /opt/dremio/dremio_queries/scrubbed/errormessages
mkdir -p /opt/dremio/dremio_queries/scrubbed/errorchunks
mkdir -p /opt/dremio/dremio_queries/scrubbed/badrows
# Copy the current queries.json file
echo "Copying current queries.json"
kubectl cp --container dremio-master-coordinator dremio-master-0:$DREMIO_LOG_DIR/queries.json /opt/dremio/dremio_queries/queries.json

# Copy any archive file generated for today and for however many specified archive days
if [ "$num_archive_days" == "" ]
then
	num_archive_days=0
fi

for ((i=0;i<=$num_archive_days;i++)) 
do
  # Check if there are any archive files for the current processing date
  for f in $(kubectl exec dremio-master-0 --container dremio-master-coordinator  -- bash -c "ls $DREMIO_LOG_DIR/archive/queries.$processing_date.*.json.gz 2> /dev/null || true"); do
	filename=$(basename $f)
    echo "Copying archive file for $processing_date: $filename"
	kubectl cp --container dremio-master-coordinator dremio-master-0:$f /opt/dremio/dremio_queries/$filename
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
  gunzip /opt/dremio/dremio_queries/queries*.gz
fi

echo "Scrubbing files, splitting query text into 4096 byte chunks"
python3 /opt/dremio/bin/scrub-queries-json.py /opt/dremio/dremio_queries /opt/dremio/dremio_queries/scrubbed k8s

#Renaming today's scrubbed files to incorporate the date and the next available index number for archive files
#echo "Renaming today's header.queries.json to header.queries.$today_date.$count_today_archives.json"

mv /opt/dremio/dremio_queries/scrubbed/header.k8s.queries.json.gz /opt/dremio/dremio_queries/scrubbed/header.k8s.queries.$today_date.$count_today_archives.json.gz

#echo "Renaming today's chunks.queries.json to chunks.queries.$today_date.$count_today_archives.json"
mv /opt/dremio/dremio_queries/scrubbed/chunks.k8s.queries.json.gz /opt/dremio/dremio_queries/scrubbed/chunks.k8s.queries.$today_date.$count_today_archives.json.gz

# Gather error messages for all failed queries
python3 /opt/dremio/bin/get-error-messages.py --url "$dremio_url" --user "$user_name" --password "$pwd" --queries-dir "/opt/dremio/dremio_queries/scrubbed/" --hostname k8s

mv /opt/dremio/dremio_queries/scrubbed/header*queries*.json.gz /opt/dremio/dremio_queries/scrubbed/results/
mv /opt/dremio/dremio_queries/scrubbed/chunks*queries*.json.gz /opt/dremio/dremio_queries/scrubbed/chunks/
mv /opt/dremio/dremio_queries/scrubbed/errorheader*queries*.json.gz /opt/dremio/dremio_queries/scrubbed/errormessages/
mv /opt/dremio/dremio_queries/scrubbed/errorchunks*queries*.json.gz /opt/dremio/dremio_queries/scrubbed/errorchunks/
mv /opt/dremio/dremio_queries/scrubbed/badrow*queries*.json.gz /opt/dremio/dremio_queries/scrubbed/badrows/

if [ "$storage_type" == "s3" ]
then
	echo "Copying scrubbed header files to S3"
	for s3_scrubbed in /opt/dremio/dremio_queries/scrubbed/results/header*queries*.json.gz; do
	  aws s3 cp $s3_scrubbed $storage_path/results/
	done
	echo "Copying scrubbed chunks files to S3"
	for s3_scrubbed in /opt/dremio/dremio_queries/scrubbed/chunks/chunks*queries*.json.gz; do
	  aws s3 cp $s3_scrubbed $storage_path/chunks/
	done
	echo "Copying error message header files to S3"
	for s3_scrubbed in /opt/dremio/dremio_queries/scrubbed/errormessages/errorheader*queries*.json.gz; do
	  aws s3 cp $s3_scrubbed $storage_path/errormessages/
	done
	echo "Copying error message chunks files to S3"
	for s3_scrubbed in /opt/dremio/dremio_queries/scrubbed/errorchunks/errorchunks*queries*.json.gz; do
	  aws s3 cp $s3_scrubbed $storage_path/errorchunks/
	done
    echo "Copying badrow files to S3"
	for s3_scrubbed in /opt/dremio/dremio_queries/scrubbed/badrows/badrow*queries*.json.gz; do
	  aws s3 cp $s3_scrubbed $storage_path/badrows/
	done
elif [ "$storage_type" == "adls" ]
# Assumes the machine you are running this script from has already performed az login
then
	echo "Copying scrubbed header files to ADLS"
	azcopy copy --recursive --overwrite true "/opt/dremio/dremio_queries/scrubbed/*" $AZURE_SAS_URL
elif [ "$storage_type" == "gcs" ]
# Assumes the machine you are running this script from has already performed az login
then
	echo "Copying scrubbed header files to Google Cloud Storage"
  gcloud auth activate-service-account $GCS_SERVICE_PRINCIPAL --key-file=/opt/dremio/conf/gcp-service-principal.json
  gsutil -m cp -r /opt/dremio/dremio_queries/scrubbed/* $storage_path
elif [ "$storage_type" == "hdfs" ]
then
	echo "Copying scrubbed header files to HDFS"
	for hdfs_scrubbed in /opt/dremio/dremio_queries/scrubbed/results/header*queries*.json.gz; do
		hdfs dfs -copyFromLocal -f $hdfs_scrubbed $storage_path/results/
	done
	echo "Copying scrubbed files to HDFS"
	for hdfs_scrubbed in /opt/dremio/dremio_queries/scrubbed/chunks/chunks*queries*.json.gz; do
		hdfs dfs -copyFromLocal -f $hdfs_scrubbed $storage_path/chunks/
	done
	echo "Copying error message header files to HDFS"
	for hdfs_scrubbed in /opt/dremio/dremio_queries/scrubbed/errormessages/errorheader*queries*.json.gz; do
		hdfs dfs -copyFromLocal -f $hdfs_scrubbed $storage_path/errormessages/
	done
	echo "Copying error message chunks files to HDFS"
	for hdfs_scrubbed in /opt/dremio/dremio_queries/scrubbed/errorchunks/errorchunks*queries*.json.gz; do
		hdfs dfs -copyFromLocal -f $hdfs_scrubbed $storage_path/errorchunks/
	done
	
	hdfs dfs -chmod 666 $storage_path/*/*.json.gz
else
	echo "Unknown storage type "$storage_type", files will remain local and will need manually copying"
fi

#echo "Refreshing PDSs containing queries.json data"
python3 /opt/dremio/bin/refresh-pds.py --url "$dremio_url" --user "$user_name" --password "$pwd" --pds "QueriesJson.results"
python3 /opt/dremio/bin/refresh-pds.py --url "$dremio_url" --user "$user_name" --password "$pwd" --pds "QueriesJson.chunks"
python3 /opt/dremio/bin/refresh-pds.py --url "$dremio_url" --user "$user_name" --password "$pwd" --pds "QueriesJson.errormessages"
python3 /opt/dremio/bin/refresh-pds.py --url "$dremio_url" --user "$user_name" --password "$pwd" --pds "QueriesJson.errorchunks"
echo "Complete"