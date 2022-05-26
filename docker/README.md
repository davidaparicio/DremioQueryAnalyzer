## Build and push
```
docker build --no-cache -t gcr.io/dremio-ps/dremio-query-analyzer:1.20 .
docker push gcr.io/dremio-ps/dremio-query-analyzer:1.20
docker build -f DockerfileVdsCreator --no-cache -t gcr.io/dremio-ps/dremio-query-analyzer-vdscreator:1.4 .
docker push gcr.io/dremio-ps/dremio-query-analyzer-vdscreator:1.4
docker run -e DREMIO_ENDPOINT=https://carsten.eastus.cloudapp.azure.com/ -e DREMIO_USERNAME=carsten -e DREMIO_PASSWORD="pwd" gcr.io/dremio-ps/dremio-query-analyzer-vdscreator:1.4
```

## CronJob specification

### Create custom service account for Dremio jobs
```
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  # "namespace" omitted since ClusterRoles are not namespaced
  name: dremio-jobs-role
rules:
- apiGroups: [""]
  #
  # at the HTTP level, the name of the resource for accessing Secret
  # objects is "secrets"
  resources: ["pods", "pods/exec"]
# create is required.
  verbs: ["get", "list", "watch", "create"]
----

apiVersion: v1
kind: ServiceAccount
metadata:
  name: dremio-jobs


----
apiVersion: v1
kind: Secret
metadata:
  name: dremio-jobs-secret
  annotations:
    kubernetes.io/service-account.name: dremio-jobs
type: kubernetes.io/service-account-token

-----

apiVersion: rbac.authorization.k8s.io/v1
# This role binding allows "jane" to read pods in the "default" namespace.
# You need to already have a Role named "pod-reader" in that namespace.
kind: RoleBinding
metadata:
  name: dremio-jobs
  namespace: default
subjects:
# You can specify more than one "subject"
- kind: ServiceAccount
  name: dremio-jobs
  namespace: default
roleRef:
  # "roleRef" specifies the binding to a Role / ClusterRole
  kind: Role #this must be Role or ClusterRole
  name: dremio-jobs-role
  apiGroup: rbac.authorization.k8s.io
```

### Create CronJob for AWS
```
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: dremio-query-analyser
spec:
  schedule: "10 */6 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: dremio-jobs
          automountServiceAccountToken: true
          containers:
          - name: dremio-query-analyzer
            image:  gcr.io/dremio-ps/dremio-query-analyzer:1.18
            imagePullPolicy: Always
            env:
              - name: DREMIO_STORAGE_TYPE
                value: s3
              - name: DREMIO_USERNAME
                value: "carsten"
              - name: DREMIO_PASSWORD
                value: "yourpass"
              - name: AWS_ACCESS_KEY_ID
                value: "YOURKEY"
              - name: AWS_SECRET_ACCESS_KEY
                value: "YOURKEY"
              - name: DREMIO_STORAGE_PATH
                value: s3://dremio-carsten-data/queryanalyzer
          restartPolicy: OnFailure
```

### Create CronJob for ADLS
```
apiVersion: batch/v1
kind: CronJob
metadata:
  name: dremio-query-analyzer
spec:
  schedule: "10 5 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: dremio-jobs
          automountServiceAccountToken: true
          containers:
          - name: dremio-query-analyzer
            image:  gcr.io/dremio-ps/dremio-query-analyzer:1.18
            imagePullPolicy: Always
            env:
              - name: DREMIO_STORAGE_TYPE
                value: adls
              - name: DREMIO_USERNAME
                value: "<USERNAME>"
              - name: DREMIO_PASSWORD
                value: "<PAT_TOKEN>"
              - name: AZURE_SAS_URL
                value: "<SAS_URL>"
          restartPolicy: OnFailure
```

### Create CronJob for GCP

Run and name the file as on your disk: dremio-ps-f209e5d75609.json

```
kubectl create secret generic gcp-service-principal-secret --from-file=gcp-service-principal.json=dremio-ps-f209e5d75609.json
```

Specification
```
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: dremio-query-analyzer-gcp
spec:
  schedule: "10 6 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: dremio-jobs
          automountServiceAccountToken: true
          containers:
          - name: dremio-query-analyzer
            image:  gcr.io/dremio-ps/dremio-query-analyzer:1.18
            volumeMounts:
            - mountPath: /opt/dremio/conf
              name: gcp-service-principal-secret
              readOnly: true
            imagePullPolicy: Always
            env:
              - name: DREMIO_STORAGE_TYPE
                value: gcs
              - name: DREMIO_USERNAME
                value: "carsten"
              - name: DREMIO_PASSWORD
                value: "yourpass"
              - name: GCS_SERVICE_PRINCIPAL
                value: carstenqueryanalyzer@dremio-ps.iam.gserviceaccount.com
              - name: DREMIO_STORAGE_PATH
                value: "gs://carstendremiotest"
          restartPolicy: OnFailure
          volumes:
            - name: gcp-service-principal-secret
              secret:
                secretName: gcp-service-principal-secret
```

Example for VDS-Import

```
apiVersion: batch/v1
kind: Job
metadata:
  name: dremio-vdscreator
spec:
  template:
    spec:
      containers:
        - name: job
          image: gcr.io/dremio-ps/dremio-query-analyzer-vdscreator:1.3
          imagePullPolicy: IfNotPresent
          env:
          - name: DREMIO_ENDPOINT
            value: "https://dremio-client:9047"
          - name: DREMIO_USERNAME
            value: "NOTSET"
          - name: DREMIO_PASSWORD
            value: "NOTSET"
      restartPolicy: Never
  backoffLimit: 4
```