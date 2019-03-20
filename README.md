[imjac.in/ta](https://imjac.in/ta)
===

Code for my website, written with Ruby on Rails, on top of Kubernetes.

## Running in development
Run `rake docker:up` to launch the development containers.

You can access the frontend at `localhost:3000`.

## Pushing to production
This assumes there is already a kubernetes cluster setup and ready to go, but unprovisioned.
Don't forget to link it to your kubectl installation.

You can always run a local minikube installation if you want to test a prod / staging environment.

Most of this should be handled in CI / CD (like Azure). 

### Building the image
You can build the production images with `rake docker:build`, and likewise push them to the docker registry with `rake docker:push`.

### Configuring Kubernetes to use the new version.
Before deploying to prod, you will need to update the image tag in the kubernetes configuration files. 
- Get the image tag with `rake docker:get_tag`. This is the same as in the `VERSION` file.
- Update the image entry in [k8s/web.yml](k8s/web.yml)

### First-time setup
- Setup the secrets:
  - Database Credentials: `kubectl create secret generic db-user --from-literal=username=myuser --from-literal=password=mypassword`
  - Rails Secret Key Base: `kubectl create secret generic secret-key-base --from-literal=secret-key-base=$(rake secret)`
- Apply the k8s configurations:
  - `kubectl apply -f k8s`

### Forcing a pod update
If you've changed secrets, or `k8s/rails-configmap.yml`, kubernetes won't automatically roll an update. 

You can force one by deleting pods with `kubectl delete pods -l tier=app`. Here, `tier=app` is the web stuff, but you can also specify `tier=db` or others.