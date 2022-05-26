#!/usr/bin/python
import os
import requests
import sys
import time
import yaml
import argparse
import json
import gzip
import math

chunkSize = 16384


def login(url, user, password, tls_verify):
    login_path = '/apiv2/login'
    login_data = {"userName": user, "password": password}

    response = requests.post(url+login_path, json=login_data, verify=tls_verify, timeout=30)
    if response.status_code != 200:
        sys.exit('Login failure, Status code : {}'.format(response.status_code))
    else:
        return '_dremio'+response.json()['token']


def query(url, auth_string, query, context=None, sleep_time=100, tls_verify=True):
    assert sleep_time > 0
    job = requests.post(url + "/api/v3/sql", headers={'Authorization': auth_string}, verify=tls_verify, json={"sql": query, "context": context})
    job_id = job.json()["id"]
    while True:
        state = get_job_status(url, auth_string, job_id, tls_verify)
        if state["jobState"] == "COMPLETED":
            row_count = state.get("rowCount", 0)
            break
        if state["jobState"] in {"CANCELED", "FAILED"}:
            # todo add info about why did it fail
            raise Exception ("job failed " + str(state), None)
        time.sleep(sleep_time)
    count = 0
    while count < row_count:
        result = get_job_results(url, auth_string, job_id, count, 100, tls_verify)
        count += 100
        yield result


def get_job_results(url, auth_string, job_id, offset=0, limit=100, tls_verify=True):
    resp = requests.get(
        url + "/api/v3/job/{}/results?offset={}&limit={}".format(job_id, offset, limit),
        headers={'Authorization': auth_string}, verify=tls_verify)
    return resp.json()


def get_job_status(url, auth_string, queryId, tls_verify):
    job_status_path = '/api/v3/job/' + queryId
    response = requests.get(url+job_status_path, headers={'Authorization': auth_string}, verify=tls_verify)
    if response.status_code != 200:
        return None
    else:
        return response.json()


def write_error_message(url, auth_string, queryId, header_dir, queries_file, tls_verify, hostname):
    job_status = get_job_status(url, auth_string, queryId, tls_verify)
    if job_status and job_status['jobState'] and 'FAILED' == job_status['jobState']:
        if 'errorMessage' in job_status:
            errorMessage = job_status['errorMessage'];
            lenErrorMessage = len(errorMessage)
            nrChunks = math.ceil(float(lenErrorMessage) / chunkSize)
            if queries_file:
                errorMessagesFilePath = os.path.join(header_dir,
                                            queries_file.replace("header." + hostname + ".queries", "errorheader." + hostname + ".queries"))
                errorChunksFilePath = os.path.join(header_dir,
                                            queries_file.replace("header." + hostname + ".queries", "errorchunks." + hostname + ".queries"))
            else:
                errorMessagesFilePath = os.path.join(header_dir, "errorheader." + hostname + ".queries.db.json.gz")
                errorChunksFilePath = os.path.join(header_dir, "errorchunks." + hostname + ".queries.db.json.gz")
            errorMessagesFile = gzip.open(errorMessagesFilePath, 'at')
            errorChunksFile = gzip.open(errorChunksFilePath, 'at')

            for j in range(0, int(nrChunks)):
                errorChunk = errorMessage[j * chunkSize:(j + 1) * chunkSize]
                if j == 0:
                    errorMessagesDict = {'queryId': queryId, 'errorMessage': errorChunk}
                errorChunkDict = {'queryId': queryId, 'queryChunk': j, 'errorMessageChunk': errorChunk}
                errorChunksFile.write(json.dumps(errorChunkDict) + '\n')
            errorMessagesFile.write(json.dumps(errorMessagesDict) + '\n')
            errorMessagesFile.close()
            errorChunksFile.close()
    else:
        print("Failed job id " + queryId + " no longer exists, continuing")


def main():
    if not tls_verify:
        requests.packages.urllib3.disable_warnings(requests.packages.urllib3.exceptions.InsecureRequestWarning)
    auth_string = login(url, user, password, tls_verify)
    if query_table:
        # need to issue a query to get the queryIds
        queryStr = "SELECT queryId FROM " + query_table + " WHERE outcome = 'FAILED'";
        results = query(url, auth_string, queryStr, None, 10, tls_verify)
        for results_rows in results:
            for results_row in results_rows['rows']:
                queryId = results_row["queryId"]
                write_error_message(url, auth_string, queryId, header_dir, None, tls_verify, hostname)
    else:
        # read the queryIds from the header.queries files
        for queriesFile in os.listdir(header_dir):
            if queriesFile.startswith("header." + hostname + ".queries"):
                queriesPath = os.path.join(header_dir, queriesFile)
                if queriesPath[-3:] == '.gz':
                    infile = gzip.open(queriesPath, "rt")
                else:
                    infile = open(queriesPath, "r")
                data = [json.loads(line) for line in infile]
                for item in data:
                    queryId = item['queryId']
                    outcome = item['outcome']
                    if outcome == "FAILED":
                        write_error_message(url, auth_string, queryId, header_dir, queriesFile, tls_verify, hostname)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Script to get error messages from failed queries in Dremio')
    parser.add_argument('--url', type=str, help='Dremio url, example: https://localhost:9047', required=True)
    parser.add_argument('--user', type=str, help='Dremio user', required=True)
    parser.add_argument('--password', type=str, help='Dremio user password', required=True)
    parser.add_argument('--tls-verify', action='store_true')
    parser.add_argument('--queries-dir', type=str, help='Folder containing scrubbed queries.json files', required=True)
    parser.add_argument('--hostname', type=str, help='Hostname where the script is being run from, used to generate the output filename', required=True)
    parser.add_argument('--query-table', help=argparse.SUPPRESS)

    args = parser.parse_args()
    url = args.url
    user = args.user
    password = args.password
    header_dir = args.queries_dir
    query_table = args.query_table
    tls_verify = args.tls_verify
    hostname = args.hostname

    main()
