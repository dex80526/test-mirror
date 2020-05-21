# Workflow with Private Istio Build
Developers who need to make changes to private Istio code (istio-private, cni-private and proxy-private) should follow GitHub Forking model.

When a PR is created in those private repos, pre-submit Prow CI jobs are triggered and CI jobs are created/executed in the Prow cluster.

CI job status will be displayed in the Deck dashboard at http://prow.dev.twistio.io

When a PR merges, post-submit Prow CI jobs are triggered.

Prow CI jobs are defined/configured in test-infra-private/prow/cluster/jobs/aspenmesh/*.yaml

To change Prow CI jobs, create a branch and make changes to test-infra-private. When the PR is merged, the changes to Prow jobs will be automatically updated via config-updater plugin.

Note: Deck dashboard keeps only recent jobs (TBD: how long?)
However, build logs are uploaded and available in GCS.

All CI jobs are run in parallel in own PODs.