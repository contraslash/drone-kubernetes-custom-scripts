# Kubernetes plugin for drone.io 

This is an adaptation from [honestbee/drone-kubernetes](https://github.com/honestbee/drone-kubernetes) drone plugin,
which allows to execute a remote command in a container inside a pod 


## Usage  

This pipeline will execute the command  `echo hello world` inside the pod `pod1` in the container with name 
`my-container`

```yaml
steps:
    - name execute_command:
      image: contraslash/drone-kubernetes-command-in-pod
      pod_name: "pod1"
      container_name: "my-container"
      container_command: "echo hello world"
      secrets: [KUBERNETES_CLIENT_CERTIFICATE, KUBERNETES_CLIENT_KEY, KUBERNETES_SERVER]
```

## Required secrets

```bash
drone secret add --image=honestbee/drone-kubernetes \
    your-user/your-repo KUBERNETES_SERVER https://mykubernetesapiserver

drone secret add --image=honestbee/drone-kubernetes \
    your-user/your-repo KUBERNETES_CERT <base64 encoded CA.crt>

drone secret add --image=honestbee/drone-kubernetes \
    your-user/your-repo KUBERNETES_TOKEN eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJrdWJ...
```

When using TLS Verification, ensure Server Certificate used by kubernetes API server 
is signed for SERVER url ( could be a reason for failures if using aliases of kubernetes cluster )

## How to get token
1. After deployment inspect you pod for name of (k8s) secret with **token** and **ca.crt**
```bash
kubectl describe po/[ your pod name ] | grep SecretName | grep token
```
(When you use **default service account**)

2. Get data from you (k8s) secret
```bash
kubectl get secret [ your default secret name ] -o yaml | egrep 'ca.crt:|token:'
```
3. Copy-paste contents of ca.crt into your drone's **KUBERNETES_CERT** secret
4. Decode base64 encoded token
```bash
echo [ your k8s base64 encoded token ] | base64 -d && echo''
```
5. Copy-paste decoded token into your drone's **KUBERNETES_TOKEN** secret

### RBAC

When using a version of kubernetes with RBAC (role-based access control)
enabled, you will not be able to use the default service account, since it does
not have access to update deployments.  Instead, you will need to create a
custom service account with the appropriate permissions (`Role` and `RoleBinding`, or `ClusterRole` and `ClusterRoleBinding` if you need access across namespaces using the same service account).

As an example (for the `web` namespace):

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: drone-deploy
  namespace: web

---

apiVersion: rbac.authorization.k8s.io/v1beta1
kind: Role
metadata:
  name: drone-deploy
  namespace: web
rules:
  - apiGroups: ["extensions"]
    resources: ["deployments"]
    verbs: ["get","list","patch","update"]

---

apiVersion: rbac.authorization.k8s.io/v1beta1
kind: RoleBinding
metadata:
  name: drone-deploy
  namespace: web
subjects:
  - kind: ServiceAccount
    name: drone-deploy
    namespace: web
roleRef:
  kind: Role
  name: drone-deploy
  apiGroup: rbac.authorization.k8s.io
```

Once the service account is created, you can extract the `ca.cert` and `token`
parameters as mentioned for the default service account above:

```
kubectl -n web get secrets
# Substitute XXXXX below with the correct one from the above command
kubectl -n web get secret/drone-deploy-token-XXXXX -o yaml | egrep 'ca.crt:|token:'
```

## To do 

Replace the current kubectl bash script with a go implementation.

### Special thanks

Inspired by [drone-helm](https://github.com/ipedrazas/drone-helm).
