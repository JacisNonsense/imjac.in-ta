## Kubernetes Dashboard
https://github.com/kubernetes/dashboard can be quite useful

## Microk8s
The following microk8s plugins are required:
```sh
microk8s enable storage
microk8s enable dns
```

### Changing pod IP addresses
For some silly reason microk8s puts pods on 10.1.0.0/16, which happens to include the subnets of my network. To change this, see: 
https://github.com/ubuntu/microk8s/issues/276
