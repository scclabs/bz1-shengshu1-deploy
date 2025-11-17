# create kubeconfig for specific namespace

1. create ServiceAccount, Role and RoleBinding
   ```sh
   kubectl apply -k kubeconfig/hooks/dev
   ```
2. get token
   ```sh
   kubectl get secret -n sa-management vm-developer -o jsonpath="{.data.token}" | base64 -d
   ```
3. create kubeconfig

```sh
apiVersion: v1
kind: Config
preferences: {}
clusters:
- name: dev1-vm
  cluster:
    insecure-skip-tls-verify: true
    server: https://36.103.234.68:7443

users:
- name: dev1-vm
  user:
    as-user-extra: {}
    token: <ServiceAccount token! Be very sure that this is the ServiceAccount token!>

contexts:
- name: dev1-vm
  context:
    cluster: dev1-vm
    user: dev1-vm
    namespace: vm

current-context: dev1-vm
```
