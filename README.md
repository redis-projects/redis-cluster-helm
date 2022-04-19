## Redis Operator & Cluster Helm Chard

### Usage: 

- Update the values.yaml file to the required installation 
```bash
$ helm lint .
==> Linting .
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed
```

- View the generated manifests that will be installed:

```bash
$ helm template .
---
# Source: redis-cluster/templates/rec.yaml
apiVersion: app.redislabs.com/v1
kind: RedisEnterpriseCluster
metadata:
  name: rec
  namespace: redis
spec:
  nodes: 3
  persistentSpec:
    enabled: true
    volumeSize: 30Gi
    storageClassName: "standard"
  uiServiceType: ClusterIP
  username: 
  redisEnterpriseNodeResources:
    limits:
      cpu: "4000m"
      memory: 10Gi
    requests:
      cpu: "4000m"
      memory: 10Gi
  redisEnterpriseImageSpec:
    imagePullPolicy: IfNotPresent
    repository: registry.connect.redhat.com/redislabs/redis-enterprise
    versionTag: 6.2.10-90.rhel7-openshift
  redisEnterpriseServicesRiggerImageSpec:
    repository: registry.connect.redhat.com/redislabs/services-manager
  bootstrapperImageSpec:
    repository: registry.connect.redhat.com/redislabs/redis-enterprise-operator
---
# Source: redis-cluster/templates/rec-ui-route.yaml
kind: Route
apiVersion: route.openshift.io/v1
metadata:
  name: rec-ui
  namespace: redis
  labels:
    app: redis-enterprise
    redis.io/cluster: rec
spec:
  host: rec-ui-redis.apps.uki-okd.demo.redislabs.com
  to:
    kind: Service
    name: rec-ui
  port:
    targetPort: 8443
  tls:
    termination: passthrough
    insecureEdgeTerminationPolicy: None
  wildcardPolicy: None

 ```

- Dry-Run Install the Chart into the Cluster: 
```bash
$ helm install redis-cluster --debug --dry-run . 
install.go:178: [debug] Original chart version: ""
install.go:195: [debug] CHART PATH: /Users/ajarrett/Documents/Projects/Helm/redis-cluster

NAME: redis-cluster
LAST DEPLOYED: Wed Apr 13 17:48:43 2022
NAMESPACE: redis
STATUS: pending-install
REVISION: 1
TEST SUITE: None
USER-SUPPLIED VALUES:
{}

COMPUTED VALUES:
...
```

- Install into the Cluster: 
```bash
$ helm install redis-cluster . --namespace redis --create-namespace --set redis.operator.install=true --wait  
NAME: redis-cluster
LAST DEPLOYED: Wed Apr 13 20:57:15 2022
NAMESPACE: redis
STATUS: deployed
REVISION: 1
TEST SUITE: None


```

- Wait for all three rec[0-2] pods to successfully deploy
```bash
$ oc get pods
NAME                                        READY   STATUS    RESTARTS   AGE
rec-0                                       2/2     Running   0          5m8s
rec-1                                       2/2     Running   0          4m13s
rec-2                                       2/2     Running   0          2m59s
```

- navigate to the url endpoint 
```bash
oc get route rec-ui -o json | jq -r '.spec.host'
rec-ui-redis.apps.uki-okd.demo.redislabs.com
```
NOTE: Its HTTPS - https://rec-ui-redis.apps.uki-okd.demo.redislabs.com

To get the **login** details: 
```bash
$ oc get secret rec -n redis --template={{.data.username}} | base64 -d 
demo@redislabs.com

$ oc get secret rec -n redis --template={{.data.password}} | base64 -d 
Acxvbc9N
```

### Uninstall:

Unfortunately uninstalling the cluster is not currently as simple as a `helm uninstall redis-cluster` due to the fact 
that the operator is deleted before the deletion of the redis-cluster is completed. This leaves the cluster definition in 
constant 'Termination' status due to the finalizers of the rec custom resource not being satisfied by the Operator. 

// TODO : Add Helm Pre-Uninstall and Post-Uninstall hooks to perform below tasks 

To delete follow these steps: 

```bash
$ oc delete rec rec 
redisenterprisecluster.app.redislabs.com "rec" deleted

$ helm uninstall redis-cluster 
release "redis-cluster" uninstalled

$ oc get csv
NAME                                  DISPLAY                     VERSION    REPLACES                           PHASE
openshift-gitops-operator.v1.4.5      Red Hat OpenShift GitOps    1.4.5      openshift-gitops-operator.v1.4.4   Succeeded
redis-enterprise-operator.v6.2.10-4   Redis Enterprise Operator   6.2.10-4                                      Succeeded

$ oc delete csv redis-enterprise-operator.v6.2.10-4
clusterserviceversion.operators.coreos.com "redis-enterprise-operator.v6.2.10-4" deleted

$ oc delete project redis 
project.project.openshift.io "redis" deleted
```

### View Available Operators on Openshift Cluster:

```bash
$ oc get packagemanifests -n openshift-marketplace | grep redis

redis-operator                                      Community Operators   71d
redis-enterprise-operator-cert-rhmp                 Red Hat Marketplace   71d
redis-enterprise-operator-cert                      Certified Operators   71d
```

NOTE: To view installation options:  `oc describe packagemanifests redis-enterprise-operator-cert-rhmp -n openshift-marketplace` 