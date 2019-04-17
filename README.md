[imjac.in/ta](https://imjac.in/ta)
===

Code for my website, written with Ruby on Rails, on top of Kubernetes.

## Running in development
Run `rake docker:up` to launch the development containers.

You can access the frontend at `localhost:3333`.

## Building the image
You can build the production images with `rake docker:build`, and likewise push them to the docker registry with `rake docker:push`.

## Deploying
See [DEPLOYING.md](DEPLOYING.md)