---
layout: post
title: "Running ROS on Docker with VSCode and RVIZ support"
date: 2019-08-02 18:55:00
author: Jaci
categories: project, docker, ros
---

<img src="https://github.com/JacisNonsense/docker-ros/raw/master/rviz.gif" style="max-width: 800px" />

Developing for ROS can be less than painless. Locking your OS to a specific Ubuntu version just to develop ROS applications can make it a pain to use in the day-to-day, leading many to consider a VM or even another computer. Here, I propose a new solution using Docker with X11 passthrough and GPU support. As a bonus, you can incorporate it directly into your VSCode workspace. Here's how.

<!-- excerpt -->

## Getting Setup

There's a few initial steps we have to do to get everything running. Don't worry, it won't take too long.  

**Project GitHub: [Here](https://github.com/JacisNonsense/docker-ros)**

#### Step 1 - Install the shell utilities
First of all, we have to install the `docker-ros` shell script from the GitHub repository:

```bash
cd /tmp
git clone https://github.com/JacisNonsense/docker-ros

cd docker-ros

# Only run the next line (rm -r) if you're replacing an old version
rm -r ~/.docker-ros

cp -r shell/ ~/.docker-ros
```

#### Step 2 - Making the script executable from anywhere
Next up, change your `~/.bashrc` (or `~/.zshrc` if you're using ZSH)

Put these lines at the end:
```bash
export UID=${UID}
export GID=${GID}

source ~/.docker-ros/ros.sh

# OPTIONAL: Isolate the default HOME for the docker container if you don't want to passthrough your own.
ROS_DOCKER_HOME=path/to/my/isolated/home
```

#### Step 3 - Install the NVIDIA Docker runtime if you plan to allow GPU acceleration
If you're not using a NVIDIA GPU, you can skip this step.

You will need to install `nvidia-docker` on your system to allow docker to use the runtime. This is an official runtime released by NVIDIA themselves.  
The instructions for that are here: [nvidia-docker GitHub](https://github.com/NVIDIA/nvidia-docker)


## Running from the Command Line
There are multiple ways to run this script from the command line. I'm going to outline the basic options here, but you can inspect the script yourself to see all the options should you need them.  

By default, the `ros` script will do the following for you:
  - Detect NVIDIA acceleration, and use the `nvidia-docker2` runtime (you must install it first!)
  - Setup X forwarding
  - Create a new container image, passing through your local user and `$HOME`
  - Passthrough your current directory to `/work` via docker bind mount
  - Make the container interactive (`-it --rm`)

#### Interactive (Default)

```
$ ros <version>
```

Where `<version>` is one of the following:
  - `kinetic`, `melodic` - Aliases to `kinetic-desktop-full` and `melodic-desktop-full`
  - `kinetic-ros-core`, `kinetic-ros-base`, `kinetic-robot`, `kinetic-perception`, `kinetic-desktop`, `kinetic-desktop-full`
  - `melodic-ros-core`, `melodic-ros-base`, `melodic-robot`, `melodic-perception`, `melodic-desktop`, `melodic-desktop-full`

For example:
```
$ ros melodic
user@host:/work$ 
```

#### Launching a program directly

```
$ ros <version> <script>
```

For example:

```
$ ros melodic rviz
```

#### Specifying your own image
If you've built your own Docker image as a child of the `jaci/ros` image (for example, to install your own packages), this option is for you:

```
$ ros <version> --image yourname/yourimage:version
```

## Setting up VSCode
You can use this image to develop applications for ROS in VSCode natively! You can use this to run your VSCode instance _in the context of the Docker Container_. This has a ton of benefits, the prime one being that you get **intellisense from the ROS environment** (i.e. code completion for C++ and Python).

Note that the VSCode part of this project does not forward X11, so it's recommended to run any ROS applications from the `ros` script and use the VSCode installation purely for development.

**Make sure you've setup the shell script above! VSCode ROS integration relies on the modifications in your `.bashrc`/`.zshrc` (you may have to log out and log in again after installing the shell scripts)**

#### Step 1 - Install the `Remote - Container` extension
In the VSCode extension marketplace, find the `Remote - Container` extension and install it. This will allow us to open VSCode in the context of a docker container.

You can also do this by running the following in VSCode (`CTRL + P`)
```
ext install ms-vscode-remote.remote-containers
```

#### Step 2 - Apply the container configuration to the project
In your project root directory, copy the `.devcontainer` folder from `~/.docker-ros/.devcontainer`. You can also find this folder on the [GitHub](https://github.com/JacisNonsense/docker-ros)

#### Step 3 - Open your project in the context of the container
Open your command palette (`CTRL + SHIFT + P`) and select `Remote-Containers: Reopen Folder in Container`. VSCode will build a new container and open the editor within the context of the container, providing C++ and Python intellisense with the ROS installation.

That's it! You're good to go!