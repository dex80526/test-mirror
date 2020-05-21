#!/usr/bin/env bash
# (re) create job-config of Prow using yaml files under test-infra/prow/cluster/jobs/aspenmesh
#
 kubectl create configmap job-config --from-file=all-presets.yaml=cluster/jobs/all-presets.yaml \
 --from-file=istio.proxy.release-1.4.yaml=cluster/jobs/aspenmesh/proxy/istio.proxy.release-1.4.yaml \
 --from-file=istio.proxy.release-1.5.gen.yaml=cluster/jobs/aspenmesh/proxy/istio.proxy.release-1.5.gen.yaml   \
 --from-file=istio.proxy.master.gen.yaml=cluster/jobs/aspenmesh/proxy/istio.proxy.master.gen.yaml   \
 --from-file=istio.proxy.release-1.6.gen.yaml=cluster/jobs/aspenmesh/proxy/istio.proxy.release-1.6.gen.yaml   \
 --from-file=istio.istio.release-1.6.gen.yaml=cluster/jobs/aspenmesh/istio/istio.istio.release-1.6.gen.yaml   \
 --from-file=istio.istio.master.gen.yaml=cluster/jobs/aspenmesh/istio/istio.istio.master.gen.yaml   \
 --from-file=istio.istio.release-1.4.gen.yaml=cluster/jobs/aspenmesh/istio/istio.istio.release-1.4.gen.yaml   \
 --from-file=istio.istio.release-1.5.gen.yaml=cluster/jobs/aspenmesh/istio/istio.istio.release-1.5.gen.yaml   \
 --from-file=istio.cni.release-1.6.gen.yaml=cluster/jobs/aspenmesh/cni/istio.cni.release-1.6.gen.yaml   \
 --from-file=istio.cni.release-1.4.gen.yaml=cluster/jobs/aspenmesh/cni/istio.cni.release-1.4.gen.yaml   \
 --from-file=istio.cni.release-1.5.gen.yaml=cluster/jobs/aspenmesh/cni/istio.cni.release-1.5.gen.yaml   \
 --from-file=istio.cni.master.gen.yaml=cluster/jobs/aspenmesh/cni/istio.cni.master.gen.yaml   \
 --from-file=istio.release-builder.master.gen.yaml=cluster/jobs/aspenmesh/release-builder/istio.release-builder.master.gen.yaml   \
 --from-file=istio-private.release-builder.release-1.4.gen.yaml=cluster/jobs/aspenmesh/release-builder/istio-private.release-builder.release-1.4.gen.yaml   \
 --from-file=istio.release-builder.release-1.6.gen.yaml=cluster/jobs/aspenmesh/release-builder/istio.release-builder.release-1.6.gen.yaml   \
 --dry-run=client -o yaml | kubectl replace configmap job-config -f -
