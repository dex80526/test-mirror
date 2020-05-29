#!/usr/bin/env bash
# This script creates K8S secrets required for Istio Prow deployment.
#
#    Create namespaces via prow/cluster/build/test_pod_namespace.yaml
kubectl apply -f ../cluster/build/test_pod_namespace.yaml

#1.	Create cluster role binding

kubectl create clusterrolebinding cluster-admin-binding-"${USER}" --clusterrole=cluster-admin --user="${USER}"
# add cluster role for serviceaccout:default:defaul to avoid "Forbidden ..."
kubectl create clusterrolebinding cluster-admin-binding-default --clusterrole=cluster-admin --serviceaccount=default:default

#2.	Create GitHub secret hmac-token
#openssl rand -hex 20 > ./secrets/hmac-token-prow
kubectl create secret generic hmac-token --from-file=hmac=./secrets/hmac-token-prow

#3.	Create GitHub Oauth-token using the GitHub bot account’s access token
	# https://github.com/settings/tokens
        # save the access token to the file: robot_github-oauth-secret
kubectl create secret generic oauth-token --from-file=oauth=./secrets/robot_github-oauth-secret

#3a. create the same secrect in namespace "test-pods" for update-ref-docs-dry-run_istio job
kubectl -n test-pods create secret generic oauth-token --from-file=oauth=./secrets/robot_github-oauth-secret

#4. Create service account secrect
kubectl create secret generic service-account --from-file=service-account.json=./secrets/robot_gcs_service-account.json
kubectl -n test-pods create secret generic service-account --from-file=service-account.json=./secrets/robot_gcs_service-account.json

#4.	Add Google Cloud Storage secrect ‘gcs-credentials’ using service-account.json from GCS
	#setup a GCS bucket and get the service-account.json, save it the file: robot_gcs_service-account.json

kubectl -n test-pods create secret generic gcs-credentials --from-file=service-account.json=./secrets/robot_gcs_service-account.json


#5.	Add/create secret ‘kubconfig’
	#!!! Go to kubernets/test-infra dir
#bazel run //gencred -- --context=<kube-context> --name=default --output=./secrets/kubeconfig.yaml --serviceaccount

kubectl create secret generic kubeconfig --from-file=istio-config=./secrets/kubeconfig.yaml

#6.	Setup GitHub OAuth (authn) and create secret ‘robot_github_oauth-config’ 
	#https://github.com/kubernetes/test-infra/blob/master/prow/cmd/deck/github_oauth_setup.md
	# create github_oauth_config.yaml file
	# with the following content
#       client_id: <your oauth client id>
#       client_secret: <client secret>
#       redirect_url: http://prow.dev.twistio.io/github-login/redirect
#       final_redirect_url: http://prow.dev.twistio.io/pr
#       scopes:
#       - repo

	kubectl create secret generic github-oauth-config --from-file=secret=./secrets/robot_github_oauth-config.yaml

#7. Add cookie secret

openssl rand -out /tmp/cookie.txt -base64 32

kubectl create secret generic cookie --from-file=secret=/tmp/cookie.txt

#8. Add/create prow-service-account secret (??)
    # what is the account and how it is used?
    # get and save prow-service-account.json file
kubectl create secret generic prow-service-account --from-file=service-account.json=./secrets/gcs_prow-service-account.json

#9. for private GitHub repos, add/create ssh-key-secret for ssh based clone operations
kubectl -n test-pods create secret generic ssh-key-secret --from-file=secret=./secrets/prow_bot_id_rsa

# Create dummy grafana token
kubectl -n test-pods create secret generic  grafana-token --from-file=token=./secrets/dummy-grafana-token

# Slack OAuth Access Token can be obtained as follows:

# Navigate to: https://api.slack.com/apps.
# Click Create New App.
# Provide an App Name (e.g. Prow Slack Reporter) and Development Slack Workspace (e.g. Kubernetes).
# Click Permissions.
# Add the chat:write.public scope using the Scopes / Bot Token Scopes dropdown and Save Changes.
# Click Install App to Workspace
# Click Allow to authorize the Oauth scopes.
# Copy the OAuth Access Token.
# Once the access token is obtained, you can create a secret in the cluster using that value:

kubectl create secret generic slack-token --from-file=token=./secrets/slack-token

# Add secrets for release-builder
kubectl -n test-pods create secret generic rel-pipeline-docker-config --from-file=config.jon=secrets/docker_config.json
kubectl -n test-pods create secret generic rel-pipeline-github --from-file=rel-pipeline-github=secrets/robot_github-oauth-secret
kubectl -n test-pods create secret generic rel-pipeline-service-account --from-file=rel-pipeline-service-account.json=secrets/robot_gcs_service-account.json
