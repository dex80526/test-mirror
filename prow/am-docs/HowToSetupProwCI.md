# Deploy Private Prow With AWS
[Prow](https://github.com/kubernetes/test-infra/tree/master/prow) is a Kubernetes based CI/CD system. Jobs can be triggered by various types of events and report their status to many different services. In addition to job execution, Prow provides GitHub automation in the form of policy enforcement, chat-ops via /foo style commands, and automatic PR merging.

## Preparation
* Create a Prow K8S cluster hosted in AWS (via EKS or provisioned using kops)
   * m5.12xlarge EC2 instance types are recommended 
   * disk space: 100 GiB
   * 9-21 worker nodes
* GitHub bot account for Prow CI
* Create a EFS via aws cli or console by following AWS EFS [instructions](https://docs.aws.amazon.com/efs/latest/ug/creating-using-create-fs.html)
* kubectl is installed and configured to access the Prow cluster
* [Configure Google Cloud Storage](#configure-google-cloud-storage)
* Prepare SSL/TLS certs (request certs via ACM) via [AWS Load Balancer] (https://aws.amazon.com/premiumsupport/knowledge-center/terminate-https-traffic-eks-acm/)

## Deploy Prow
### 1. Clone test-infra-private repository
```sh
  $  git clone git@github.com:aspenmesh/test-infra-private.git
```
### 2. Create and Deploy Prow resources
Note: The following steps are captured in create_k8s_secrets.sh and config_prow.sh as a reference if you want to script them. The scripts assume the secret files are under ./secrets which do not exist in the Git.
* Create Persistent Volume and Persistent Volume Claim of build cache
  * The persistent volume and the claim are defined in prow/cluster/aws_build_cache.yaml. The parameters such as volumeHandle needs to be adjusted and match to the real value in AWS.
```sh
  $ kubectl apply -f prow/cluster/build/aws_buildcache.yaml
```
* Create tune sysctl Daemonset 
```sh
  $ kubectl apply -f prow/cluster/build/tune-sysctls_daemonset.yaml
```
* Create namespaces
```sh
  $ kubectl apply -f prow/cluster/build/test_pod_namespace.yaml
```
* Create cluster role binding
```sh
  $  kubectl create clusterrolebinding cluster-admin-binding-"${USER}" --clusterrole=cluster-admin --user="${USER}"

  $  kubectl create clusterrolebinding cluster-admin-binding-defauluser --clusterrole=cluster-admin --serviceaccount=default:default
```
* Create GitHub webhook secret (hmac-token)
```sh
  $ openssl rand -hex 20 > ./hmac-secret
  $ kubectl create secret generic hmac-token --from-file=hmac=./hmac-secret
```
* Create GitHub Prow bot account personal access token and save the access token to the file 'oauth-secret' following GitHub [instruction](https://github.com/settings/tokens) with the following scopes (see details [here](https://github.com/kubernetes/test-infra/blob/master/prow/scaling.md#working-around-githubs-limited-acls)):
  * repo: status
  * public_repo 
* Create K8S secret of the GitHub OAuth token
```sh
  $ kubectl create secret generic oauth-token --from-file=oauth=./oauth-secret
  $ kubectl -n test-pods create secret generic oauth-token --from-file=oauth=./oauth-secret
```
* Add Google Cloud Storage secret ‘gcs-credentials’ using service-account.json from GCS. See [instructions](#configure-google-cloud-storage) for creating the service-account.json
```sh
  $ kubectl -n test-pods create secret generic gcs-credentials --from-file=./service-account.json
```

* Setup GitHub [OAuth](https://github.com/kubernetes/test-infra/blob/master/prow/cmd/deck/github_oauth_setup.md) and create secret ‘github-oauth-config’ 
  
	* create github_oauth_config.yaml file with the following content:
 ```code
       client_id: <your oauth client id>
       client_secret: <client secret>
       redirect_url: https://prow.dev.twistio.io/github-login/redirect
       final_redirect_url: https://prow.dev.twistio.io/pr
       scopes:
       - repo
```
 * create github-oauth-config secret
```sh
	$ kubectl create secret generic github-oauth-config --from-file=secret=./github_oauth_config.yaml
  ```

* Add cookie secret
```sh
  $ openssl rand -out cookie.txt -base64 32
  $ kubectl create secret generic cookie --from-file=secret=cookie.txt
```

* Add/create ssh-key-secret for ssh based clone operations
```sh
  $ kubectl -n test-pods create secret generic ssh-key-secret --from-file=secret=.ssh/prow_bot_id_rsa
```
* [Optional] Create Slack OAuth secret for Slack notification following the [instruction](#create-slack-oauth-token-for-slack-notification)

* Bootstrap Prow config, plugins and job-config
```sh
  $ prow/recreate_prow_configmaps.sh
  $ prow/recreate_am_jobconfig.sh
```

* Deploy Prow cluster configuration/resources
   * Apply private Istio Prow CI specifics
```sh
$ kubectl apply -f prow/cluster/aspenmesh/
```

### 3. Check the Prow deployments status:
```sh
    $  kubectl get deployments

    $  kubectl get svc
```
Here is what the output looks like:
```console
NAME           TYPE           CLUSTER-IP       EXTERNAL-IP                                                              PORT(S)                         AGE
cherrypicker   ClusterIP      10.100.80.119    <none>                                                                   80/TCP                          15d
deck           LoadBalancer   10.100.50.100    a758bfdd27fe411ea8e0d02c7b127717-566388216.us-west-2.elb.amazonaws.com   80:30041/TCP,9090:32063/TCP     28d
ghproxy        ClusterIP      10.100.88.48     <none>                                                                   80/TCP,9090/TCP                 15d
hook           LoadBalancer   10.100.69.212    a75428ca87fe411ea8e0d02c7b127717-873336481.us-west-2.elb.amazonaws.com   8888:30829/TCP,9090:32485/TCP   28d
kubernetes     ClusterIP      10.100.0.1       <none>                                                                   443/TCP                         28d
needs-rebase   NodePort       10.100.237.200   <none>                                                                   80:31362/TCP                    15d
plank          ClusterIP      10.100.106.143   <none>                                                                   9090/TCP                        15d
sinker         ClusterIP      10.100.18.215    <none>                                                                   9090/TCP                        15d
tide           NodePort       10.100.156.233   <none>                                                                   80:30785/TCP,9090:31169/TCP     28d
tot            NodePort       10.100.196.182   <none>                                                                   80:31850/TCP                    15d
```

### 4. Access the Prow's Deck via External IP
* 
    e.g.  http://a758bfdd27fe411ea8e0d02c7b127717-566388216.us-west-2.elb.amazonaws.com
    
### 5. Add a CNAME for the public addresses of deck and hook to Route 53
*
   e.g. 
   * prow.dev.twistio.io
   * prow-hook.dev.twistio.io

### 6. Add the Webhook to GitHub
* go to your GitHub repo page
* click on Settings -> Webhooks
    - Add the Payload URL 
        - the public accessible URL for hook service, e.g. http://prow-hook.twistio.io:8080/hook
    - Add the hmac key created above as the Secret.
    - Set content type to "application/json"
    
    A green tick will appear on the webhook if the webhook is working.


# Configure Google Cloud Storage
Google Cloud Storage (GCS) is used by Prow to store artifacts such as build logs. GCS service account credential and storage buckets are created in the following steps:
```sh
$ gcloud iam service-accounts create prow-gcs-publisher # step 1
identifier="$(  gcloud iam service-accounts list --filter 'name:prow-gcs-publisher' --format 'value(email)' )"

$ gsutil mb gs://am-prow-artifacts/ # step 2

$ gsutil iam ch allUsers:objectViewer gs://am-prow-artifacts # step 3

$ gsutil iam ch "serviceAccount:${identifier}:objectAdmin" gs://am-prow-artifacts # step 4

$ gcloud iam service-accounts keys create --iam-account "${identifier}" service-account.json # step 5
```

# Create Slack OAuth Token for Slack notification
 Slack OAuth Access Token can be obtained as follows:

* Navigate to: https://api.slack.com/apps.
* Click Create New App.
* Provide an App Name (e.g., am-prow-notification)
* Click Permissions
  * Add the chat:write.public scope using the Scopes / Bot Token Scopes dropdown and Save Changes.
  * Click Install App to Workspace
  * Click Allow to authorize the OAuth scopes.
  * Copy the OAuth Access Token.
  * Once the access token is obtained, you can create a secret in the cluster using that value:
```sh
$ kubectl create secret generic slack-token --from-literal=token=< access token >
```

# Private Istio Build Release Process
[release-build-private](https://github.com/aspenmesh/release-builder-private) is used to control the release build publish process. Please read the README.md for the details.
## Set up release builder K8S secrets and dependency configmaps
  * create docker_config secret
The release builder needs docker credentials to access image registry such as quay.io or docker.io.
```sh
$ kubectl -n test-pods create secret generic  rel-pipeline-docker-config --from-file=config.jon=secrets/docker_config.json
```
  * create secret for Github access
  ```sh
$ kubectl -n test-pods create secret generic rel-pipeline-github --from-file=rel-pipeline-github=secrets/robot_github-oauth-secret
```
  * create secret for GCS access
  ```sh
$ kubectl -n test-pods create secret generic rel-pipeline-service-account --from-file=rel-pipeline-service-account.json=secret/robot_gcs_service-account.json
```
* create dependency configmaps for different releases
  
  The script in test-infra-private/prow/am-create-deps-cm.sh can be used to create dependency configmaps. For an example, to create configmaps for release-1.5 by running the script as the following (assuming the current working dir is in test-infra-private/):
```sh
$ prow/am-create-deps-cm.sh --branch=release-1.5 --namespace=test-pods --key=dependencies --interactive release-1.5-istio-deps

$ prow/am-create-deps-cm.sh --branch=release-1.5 --namespace=test-pods --key=dependencies --interactive release-1.5-deps
```

## Trigger a new release build and publish
* Clone release-build-private

* Trigger a release build
  * Create a new branch, e.g. "am-rc-1-build"
  * Edit release/trigger-build to change the release version to the desired value, for an example, 1.5.3-am-rc-1
  * Commit and publish the change
  * Create a PR to trigger the Prow presubmit jobs
  * Check the the CI job status and results
  * Merge the PR to trigger the postsubmit jobs if all checks are passed
* Trigger a release publish 
  * Create a new branch, e.g. "am-rc-1-publish"
  * Edit release/trigger-publish to change the release version to match the value in trigger-build
  * Create a PR to trigger the Prow publish presubmit jobs
  * Check the CI job status
  * Merge the PR to trigger publish postsubmit jobs if all checks are passed
  * Check the new release created in istio-private/releases
  


