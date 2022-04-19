## Redis Multi-Namespace OCP Script

### Usage: 

Requirements are quite extensive: 
- Logged into OC command line with user that can:
  - Create namespace if it doesnt already exist
  - Apply Role & RoleBinding 
  - Edit ConfigMaps in the Redis Operator installed namespace
- Updated the 'role.yaml' and 'role_binding.yaml' to reflect Redis Operator configuration 
  - Please refer to github for assistance: https://github.com/RedisLabs/redis-enterprise-k8s-docs/blob/master/multi-namespace-redb
- 'role.yaml' and 'role_binding.yaml' are expected in the same DIR as this script. 


- Please read the help: 
```bash
$ ./watch-namespaces.sh -h
Short script to Create/Add new Namespaces/Projects in OCP & add to the Redis Operator watchlist
Pre-reqs: 
  - Logged into OCP with OC client, have sufficient privileges to Add new projects, add Role & RoleBindings and edit the ConfigMap in the Redis Operators namespace
  - The role.yaml and role_binding.yaml are expected in the same DIR as this script. Please copy and update from https://github.com/RedisLabs/redis-enterprise-k8s-docs/blob/master/multi-namespace-redb

NOTE: Error checking is minimal, so you know.. tread carefully ;)

Syntax: scriptTemplate [-g|h|v|V]
options:
w     Comma Separated List of Namespaces for the Redis Operator to Watch
n     Namespace which Operator is installed. Default is 'Redis'
h     Print help..!

```

To run the script please execute: 

```bash
$ ./watch-namespaces.sh -w redis-apps -n redis
Are you sure you want to add these namespaces: 'redis-apps' to the Operator watchlist in 'redis'? 'y' to continue or 'n' to bail! y

Processing redis-apps and adding to redis 
Executing redis-apps && redis what about redis
Creating project :: redis-apps
Already on project "redis-apps" on server "https://api.uki-okd.demo.redislabs.com:6443".

You can add applications to this project with the 'new-app' command. For example, try:

    oc new-app rails-postgresql-example

to build a new example application in Ruby. Or use kubectl to deploy a simple Kubernetes application:

    kubectl create deployment hello-node --image=k8s.gcr.io/serve_hostname

Applying Role to 'redis-apps'
role.rbac.authorization.k8s.io/redb-role created
Applying Role to 'redis-apps'
rolebinding.rbac.authorization.k8s.io/redb-role created
Successfully created/updated namespace redis-apps with additional Role & RoleBinding
Adding the following NEW namespaces to the Operator watch list: redis-apps
Current namespaces watched: ''
New redis watched namespaces list:  'redis-apps'
Final Patch Command: '{"data":{"REDB_NAMESPACES":"redis-apps"}}'
Patching the Redis Operator in '' namespace to watch 'redis-apps'
configmap/operator-environment-config patched
Redis Operator now watching namespaces :: redis-apps
```