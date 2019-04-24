#!/bin/bash

eval $(docker-machine env $1 --shell /bin/bash)
shift
eval $@