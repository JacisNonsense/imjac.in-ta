## Kubernetes Dashboard
https://github.com/kubernetes/dashboard can be quite useful

## Microk8s
The following microk8s plugins are required:
```sh
microk8s enable storage
microk8s enable dns
```

## gcr.io
You'll also have to give k8s access to the Google Cloud Container Registry.
https://blog.container-solutions.com/using-google-container-registry-with-kubernetes