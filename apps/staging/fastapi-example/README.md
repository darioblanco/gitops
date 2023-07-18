# fastapi-example

Create docker secret:

```sh
kubectl create secret docker-registry fastapi-example-docker \
 --dry-run \
 --docker-server=ghcr.io \
 --docker-username=myusername \
 --docker-password=mypassword \
 --namespace=fastapi-example -o yaml > docker-secret.yaml
```
