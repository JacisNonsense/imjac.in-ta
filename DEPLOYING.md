Deploying
===

## 1. Setting up the server
This website runs on Docker Swarm, a container orchestration service allowing multiple servers to work together to service requests.

To setup swarm, we need to setup one or more servers. For this deployment, we'll be running CoreOS, since it already has docker support as a core component of the OS.

### The First Server - The Manager
- Install CoreOS on your first server. Do anything else you normally would, e.g. setting up SSH keys with `ssh-copy-id`, adding DNS A entries, etc.
- Run `docker swarm init` on the first server. This server is now the swarm manager.
- Note down the command given by `docker swarm join-token worker`, you will need it to join your worker nodes.

### Additional Worker Servers
- Install CoreOS. DNS entries and exposure to the outside internet is not required, as long as it can reach the swarm manager.
- Run `docker swarm join --token <token>`, where `<token>` is the token given by the swarm manager earlier.

### (Optional) Installing portainer
Portainer is a helpful web interface for managing docker installations. You can launch portainer on swarm by running the following on the manager, and accessing the interface on port `9000`:

_(From [Portainer Docs](https://portainer.readthedocs.io/en/stable/deployment.html))_
```
curl -L https://downloads.portainer.io/portainer-agent-stack.yml -o portainer-agent-stack.yml
docker stack deploy --compose-file=portainer-agent-stack.yml portainer
```

## 3. Setting up docker-machine
`docker-machine` is a simple program that allows remote management of docker instances. In our case, we're going to be using it to deploy our swarm. 

- Install `docker-machine`: [Instructions](https://docs.docker.com/machine/install-machine/)
- Create your deployment: `rake docker:create_deployment ip=<remote ip>`

## 4. Setting the secrets
You can deploy the secrets my logging into portainer and setting the following secrets:
- dbpass: The database password
- secretkeybase: The secret key base for Rails, used as the base for many crypto functions
- gcscreds: The credentials for Google Cloud Storage, from the Google Cloud Console
- master: The master key for the rails installation, used to access credentials.yml.enc

For non-credentials (e.g. the `secretkeybase`), you can get the value directly from rake, which will generate a random one: `rake secret | xclip -selection clipboard`

## 5. Deploying
- Deploy the image to docker hub: `rake docker:push`
- Deploy the image to the swarm: `rake docker:deploy`