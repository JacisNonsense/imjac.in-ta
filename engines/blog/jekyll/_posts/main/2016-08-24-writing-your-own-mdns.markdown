---
layout: post
title: "Writing your own mDNS implementation to hack the FRC Driver Station"
date: 2016-08-24 13:55:35
author: Jaci
categories: mdns, toast, frc
---
  When I wrote Toast for Java, I had a master plan for the simulation environment, and it had to fit the following agenda:

- It has to work with the official FRC Driver Station
- It has to work when the Driver Station is on a different computer
- It has to be easy to use
- It can't have external dependencies outside of the bundled software.

<!-- excerpt -->

WELP. In Toast Java, the Driver Station communications didn't follow those last two points. It required you to do [all this](https://github.com/Open-RIO/ToastAPI/wiki/Simulating-Joysticks-and-the-Driver-Station). Painful, right?

Well, for Toast C++ I decided to try and fix this. I played around with a few ideas:

- Use the bonjour SDK (eww, it requires me to link a system library, it's not cross platform and generally just not a fun time)
- Exec a command to `dns-sd` (still requires bonjour, doesn't work on linux, and is basically identical to the Toast Java implementation)
- RollYourOwn™ mDNS implementation (well, I *guess*).

So, here we are. TL;DR, [here's the code](https://github.com/JacisNonsense/ToastCPP/blob/master/Providers/simulation/src/ds_comms.cpp#L35-L131). Toast C++ will now broadcast its own mDNS service that the Driver Station can connect to immediately.
  
  
## How does FRC use mDNS?
FRC uses mDNS to provide a path from the Driver Station to the RoboRIO. When you enter your team number into the Driver Station, it tries to connect to a lot of different hosts, including:

- `roborio-####-frc.local`
- `roborio-####.local`
- `roborio-####.lan`
- `10.##.##.2`
- `172.22.11.2`

This is how the Driver Station communicates with your robot, through UDP to be exact, with a separate TCP channel being used to pass log messages, fault status and joystick descriptors (actually joystick values are passed through UDP).

mDNS uses services in order to broadcast information about different devices. Each service has a name, a type, a domain and a port. Let's look at our friend: The RoboRIO.

For our RoboRIO, `roborio-####-frc` is the name of the service. The type is `_ni._tcp`, with `_ni` belonging to National Instruments, the manufacturers of the RoboRIO. The domain is `local`, which is fairly standard in the world of mDNS. Finally, the port we're going to use is `3580`. 

To register this on the command line of a bonjour-enabled windows computer, we can use `dns-sd -R roborio-####-frc _ni._tcp local 3580`, which will allow the computer's bonjour server to listen for discovery requests to this service and reply with the current computer. Neato.

But, we don't want to use `dns-sd`. I want the hard way, dammit.

## The Hard Way
First, I had to figure out how the mDNS packet format worked. Thankfully, I knew already that mDNS works on a request-response type system. When your computer wants to know who owns an mDNS service, it sends out a request over multicast (multicast is the 'm' in 'mDNS'), and if a computer responds to that, it sends a response back. Because it's multicast, it is sent over UDP, and therefore doesn't require a handshake, which means I don't have to kill the running bonjour service on my computer in order to run my own responder. Neato.

I also found out, to my delight, that the requests/responses don't have a sequence number, which means I can send out responses on a timer instead of waiting for a request, I opted for a 5 second loop.

Now, figuring out the response packet protocol itself. I searched an searched, but the first result that came up was **literally that wiki entry I wrote for Toast Java**, so I could tell I wasn't going to get far. All the information I found was incredibly vague and didn't really help much, at least not in this purpose.

So, off to wireshark we go.

I needed a test-case to base my observations on. I don't have a RoboRIO with me currently, so I just observed UDP port 5353 (the mDNS port) for a while on my network to see if there were any devices on my network broadcasting. There was my chromecast, but that didn't prove to be much help. Interestingly enough, my printer showed up. I remembered that my printer runs a HTTP server to check supply levels and queue jobs and whatnot, as its got a print-server built in. This is my new test subject.

## Cutting In
I connected to the HTTP Interface on my printer and took a look at the wireshark capture. I hadn't accessed the printer's Web UI in a long time, so I knew it wasn't in my computer's domain name cache, so theoretically my computer should send out a request, and the printer should send back a response. Sure enough,

![](http://i.imgur.com/zLu6SsP.png)

Here we have something I can work with. The first 42 bytes are the UDP and Internet Protocols themselves, so we can disregard those. The actual mDNS packet starts at `0x2A`. Interestingly enough, wireshark has an inbuilt inspector for mDNS packets, allowing me to skip a lot of the dirty work and figure out what everything is called very easily. A+.

The first 2 bytes are the Transaction ID. These bytes are always `0` in an mDNS packet. The next 2 bytes are the flags, for us, its `0x80` or `0x84`.

The next few bytes describe how many questions we're asking (0, as we're a response), how many answers we're giving (in our case, 3), authority RRs (0), and additional RRs (1 for us, the A record).

Now comes the fun stuff.

### The PTR Record
Our first record is the humble PTR record. PTR is short for domain name **P**oin**T**e**R**. In mDNS, the PTR record is used to lookup instances of a service type. In the case of my printer, it links the `_http._tcp.local` service type to `Samsung CLP-310 Series (CLP-315w)._http._tcp.local` (a mouthful, right?). The PTR record is really just a descriptor for the type of a registered service.

### The SRV Record (and fun encoding stuff)
The SRV record is used to link a server instance to a service, or, in this case, a service to a target name (more on this later). In the case of my printer, it links `Samsung CLP-310 Series (CLP-315w)._http._tcp.local` to `SEC001599377D00.local`, on port `80`. This links the service with a port and hostname that the client can connect to, therefore registering an 'instance' of the service. 

This is really cool and all, but here comes the fun part of the protocol. Occasionally, instead of a string of bytes representing a name, it may give you `0xc0 <some byte>`. `0xc0` is a mask of bits that tells the protocol to look back to the `<some byte>` index, and read the name at that position. In our case, instead of repeating the name of the service (`Samsung CLP-310 Series (CLP-315w)._http._tcp.local`), it instead uses `0xc0 0x28`, to look at hexadecimal index `0x28`, which is, you guessed it, the service name. 

### The TXT Record
Our next, and final 'Answer' record is the TXT record. TXT records are used to carry custom key-value data pairs. In our case, we don't have any of these pairs, as we don't really need them, but alas, we shall keep the record anyway.

### Additional Records..?

### But wait, first some implementation information.
So far I've talked about my humble old printer, let's put this into some context.

#### PTR
For us, the PTR record links the `roborio-####-frc._ni._tcp.local` service name to the `_ni._tcp` service type and `local` domain. 

#### SVR
The SVR record links the `roborio-####-frc._ni._tcp.local` service name, on port `3580` to some host name. For us, we're going to use `some-host-name.local`. Usually this would be your `<computer hostname>.local`, but it can really be whatever you want. In Toast C++, we use `toast-mdns-resolve.local` by default.

### Okay, now you can have Additional Records!
Our last record is the `A` record. If you've done any work with DNS before, whether it be hosting a website or whatnot, this will seem familiar.

The A record takes some hostname, and links it to an IP address that our computers can understand. In our case, it will match `some-host-name.local` to the local loopback, `127.0.0.1` (localhost). 

Putting this all together, we get a working mDNS responder that can tell the Driver Station that you are in fact the RoboRIO, allowing you to 'simulate' the RoboRIO, while still using the official Driver Station. Cool stuff.

![](http://i.imgur.com/4YBt2Qn.png)

### Why localhost?
Really, you can use whatever IP address you want. The reason we use localhost is simple: the simulation is running on the same computer as the driver station... most of the time. In Toast C++, you can change this localhost to any IP you want. If you want other computers on your network to be able to run their driver station and connect to your running simulation, you can set this IP address to the IP address of your computer as seen by your network, e.g. `10.0.0.x`. This may be useful if your development computer is different from your driver station, such as if you use a Mac for development, but the Driver Station only runs on windows.

Another useful quirk of using localhost is that other computers on your network that try to connect to `roborio-####-frc.local` will resolve the IP address to `127.0.0.1`, and connect to themselves. This is particularly useful if you work in a team environment where multiple programmers are testing at once, which can stop conflicts for which driver station gets which simulation. 

### Conclusion.
I hope you enjoyed this little write up, and helps you understand a little bit more about mDNS in the FRC sense. Feel free to look through the Driver Station Communications code for C++ [here](https://github.com/JacisNonsense/ToastCPP/blob/master/Providers/simulation/src/ds_comms.cpp). If you have any questions, feel free to email me at [jaci.brunning@gmail.com](mailto:jaci.brunning+questions@gmail.com)