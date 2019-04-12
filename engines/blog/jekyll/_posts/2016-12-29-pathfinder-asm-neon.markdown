---
layout: post
title: "Ultra-Fast Trajectory Generation (Motion Profiling)"
date: 2016-12-29 11:07:56
categories: roborio, frc, asm, motion, trajectory
---
  Alternative Title: Jaci you're not allowed to play with Assembly anymore.  
  
Motion profiling has been making the rounds lately, with more and more applications for it, including Automation, Self-Driving Vehicles, and pretty much anything that moves with a computer. A while ago I wrote the [Pathfinder](https://github.com/JacisNonsense/Pathfinder) library, which was designed for 2D S-Curve trajectory generation, in short, a path planner. Today I'm going to combine that with a post I wrote a few weeks ago on making [Vision Processing more efficient](http://imjac.in/ta/post/2016/11/14/08-00-15-generated/).  
  
**You can see the project on GitHub [here](https://github.com/JacisNonsense/neon_pathfinder)**

<!-- excerpt -->

## Results
Before I get into how this was done, I'm going to start with why you should care. Here's the results of my testing (*all tests done on a stock-standard FRC RoboRIO*)

```
TRAPEZOID (LINEAR)
	SIMD (1.0kHz x100):     23ms AVG: 0.23ms
	C    (1.0kHz x100):    126ms AVG: 1.26ms

SCURVE (LINEAR)
	C    (1.0kHz x100):   4792ms AVG: 47.92ms

TRAPEZOID (TRAJECTORY)
	SIMD (1.0kHz 10KSamples x100):   1352ms AVG: 13.52ms
	C    (1.0kHz 10KSamples x100):   2930ms AVG: 29.30ms

SCURVE (TRAJECTORY)
	SIMD (1.0kHz 10KSamples x100):   5328ms AVG: 53.28ms
	C    (1.0kHz 10KSamples x100):   6786ms AVG: 67.86ms
```

(*there is no SCURVE-LINEAR-SIMD, this is explained later*)

`TRAPEZOID` is a standard Trapezoidal motion profile. `SCURVE` is a standard SCurve Motion Profile.

`LINEAR` denotes a 1D plane of movement, that is, start moving, and stop moving x distance away. `TRAJECTORY` is 2D, allowing you to plot a path on a 2D plane (like an FRC field floor). Linear is generally more useful for subsystems, while Trajectory is more applicable for navigating the field during autonomous. Please note that part of the Trajectory benchmark in timing is due to the generation of the first, linear profile (e.g. 4792ms of the SCurve Trajectory is due to the SCurve linear generation). 

`SIMD` is the optimizations we'll be putting into place today, while `C` is the speed of a standard C implementation (identical to the Pathfinder library). 

Each profile is generated at a 1000th of a second (1kHz) timescale, meaning your following mechanism (e.g. PID) would update at 1000 times a second. To give an idea, 100Hz is much more widely used, but this is a benchmark after all. 

Each profile is generated 100 times over, with the average for a single run being displayed beside the total runtime. The `AVG:` is the speed at which the algorithm will run for a single generation.

Trajectories are put through 10,000 samples for the splines, resulting in an extremely smooth path. This is fairly typical.

You can see the specifics of the generation [here](https://github.com/JacisNonsense/neon_pathfinder/blob/master/integration_test/src/main.c), if you want an idea of what parameters are being passed to the profiles. 

Below is an image of the S-Curve Trajectory that was generated to give you an idea. The left set (blue) is in relation to the X-Axis, and the right set (red) is in relation to Time. From top to bottom: Y-Axis, Velocity, Acceleration, Distance.
![](http://i.imgur.com/THoEf5f.png)

If you want to view the Trajectories for yourself, you can download them from [my dropbox](https://www.dropbox.com/sh/mpezc8h6apsb0qv/AAADwKG9HMmbucxgqwtPynJwa?dl=0), or run the program yourself. You can view them in your favorite CSV viewer (I like Tableau). Microsoft Excel is also a good option.

## Getting into it
Let's get started. First of all, I highly recommend you see my [first post on ARM Neon](http://imjac.in/ta/post/2016/11/14/08-00-15-generated/), as I won't be going into nearly as much detail here. If you want specific implementation details, see the source code on the [GitHub project](https://github.com/JacisNonsense/neon_pathfinder).

First of all, let's start with linear trajectories. Linear Trajectories are commonly used to follow a straight line, but have some control over how it moves in that straight line (i.e. it's motion *profile*). This can include such things as how fast to speed up, "easing" into and out of acceleration, etc. 

I'll start by assuming you're somewhat familiar with the difference between Trapezoidal, Triangular and S-Curve Motion Profiles. If you're not, I highly recommend this [seminar by Team 254 & 971](https://www.youtube.com/watch?v=8319J1BEHwM).

Since we're generating profiles, we need a way to store them. In our case, we're going to store them as 'segments', with each segment having the following properties:  
- How far it has travelled (the position)  
- How fast it's going at that moment (the velocity)  
- How fast the velocity is changing (the acceleration)  

Each segment is generated at a certain time scale. This will match up with how fast you're checking and updating your control loops (usually, anywhere from 50 to 200 times a second, with 100 seeming the most common). So if we were to configure the timescale at 100Hz, there would be a 10ms gap between when one segment ends and the next begins. These segments are stored in an Array.

### Trapezoidal Profiles
Trapezoidal Profiles are fairly basic. They have a 'ramp up' potion, a 'hold steady' portion, and a 'ramp down' portion. Below is an example, with distance over time being on top, velocity over time in the middle, and acceleration over time at the bottom. 

![](http://i.imgur.com/BToLOwl.png)

The great thing about Trapezoidal Profiles is that they're incredibly easy to generate, as they are just 2 triangles, a rectangle and a few motion equations (`v = at`, `s = ut + 0.5at^2`, you get the idea). This also means that you can find the Acceleration, Velocity and Position *without looking at the entry before it*. This is great because we can use our friend ARM Neon to vectorize and parallelize the generation of Trapezoidal Profiles. In our case, we can generate 4 points at once, meaning that it only takes a quarter of the time it usually would to generate our profile. 

In short, we use the ARM Neon registers and instruction set to generate points 0, 1, 2 and 3 at the same time, then move on to 4, 5, 6, 7, etc. This is much faster than the standard alternative of going 0, then 1, then 2, then 3, etc. This is what gains us a net speed increase. This sounds all well and good, but there is a few challenges that come with this. You may have already thought about it, in fact.

The issue is, that we need to go 0, 1, 2, 3, and then 4, 5, 6, 7. If we're doing everything parallel, this is a big tough to do, as we don't really have an iterative index to work on. There is no `for (i = 0; i < len; i++)`, as we're doing it 4 at a time.

The way to overcome this is through the use of the `.rodata` section of the final binary. The `.rodata` section stands for `Read-Only Data`, and is used to store data that is immutable at runtime, and immediately available in memory (it's the equivilent of `const` in C). At the top of the ASM file we have the following: 

```nasm
.section .rodata
    f32_step_1:
        .float 0
        .float 1
    f32_step_2:
        .float 2
        .float 3
```

And later in the file, we have: 

```nasm
// Write 'segment step' into q5
ldr r6, =f32_step_1
vld1.32 d10, [r6]
ldr r6, =f32_step_2
vld1.32 d11, [r6]
```

What we're doing is loading the float values `[0, 1, 2, 3]` into the Neon registers `d10` and `d11` (which correspond to `q5`). The quadword registers can hold 4 floats each, so we've loaded one of them with those four, sequential floats. We're going to call this the 'segment step'.

Furthermore, we've also zero'd register `q4`, which we will be using as the 'segment index offset'.

At the beginning of every loop, we run the following: 
```nasm
vadd.f32 q6, q4, q5
```

This will add the segment step (`[0, 1, 2, 3]`) to the segment index offset (`[0, 0, 0, 0]`) and store it in `q6`. Now, `q6` contains the index for all four of the segments we're currently working on. After the loop, we add 4 the entire `q4` register, so on the next iteration, `q6` will be `[4 + 0, 4 + 1, 4 + 2, 4 + 3]`. This is what allows us to generate what would usually be sequential in parallel.

The Assembly Code for this is available (and commented!) in [this file.](https://github.com/JacisNonsense/neon_pathfinder/blob/master/src/asm/trapezoid.S)

### S-Curve Profiles
It's time for some sad news. Unfortunately, we can't make S-Curve linear generation any faster, as they are generating using the Chief-Delphi dubbed ["Copioli Method"](https://www.chiefdelphi.com/forums/showthread.php?t=98358&page=2), which requires knowledge of the previous generation to influence the next one. 

## Trajectory Generation
Now we've covered linear profiles, for mechanisms that move in 1 dimension. But what about 2D? This is how Pathfinder's core library works, taking Waypoints in the 2D plane and creating a smooth profile for your robot to follow. For now, we're going to focus on the generation of this path, but not any modifications (i.e. splitting the path into 2 for tank drive, or 4 for swerve drive). 

Trajectories have extra "extensions" on top of the standard segments.  
- The X-Position  
- The Y-Position  
- The Heading (bearing)

First of all, how do we generate a 2D profile? Well, first we have to have some waypoints. For example:

```
[
    x = -4, y = -1, angle = 45 deg
    x = -1, y = 2, angle = 0
    x = 2, y = 4, angle = 0
]
```

The measurement units can be whatever you want, as to avoid an argument about Metric vs Imperial.

From these Waypoints, we create some Splines. These splines are, in essence, curves that join the waypoints. In this case, we will have 2 splines, between Waypoint 0 & 1, and between Waypoint 1 & 2.  
  
Next, we flatten the Splines into a 1D profile. We find the length along the arc of the Splines (i.e. the distance covered when travelling from end-to-end along each spline), and pass that into our linear generation. This can be either Trapezoidal, S-Curve, or really any kind of profile you want. This mostly governs the speed and acceleration along the profile. The 'shape' of the profile (Y plotted against X) is dependent on how the Spline itself is generated (we use Cubic Hermite). 

Next, we generate the headings for the Spline (where the robot will face at each point along the spline). We also fit the linear path back onto the 2D plane, taking each 1D segment and fitting it along the spline. 

There are a few subroutines that go into doing this. The first is the fitting of the spline. Thankfully, this is a single iteration, so we don't need to worry about making this more efficient (you can't parallelize a single iteration). 

The next is finding the length of the spline along its arc. This is by far the most processing intensive potion. This is done by using calculus. We can't do this algebraically, so we have to do it by 'sampling' the spline over and over again. The higher the samples, the lower the time delta between calculations, and therefore, more accuracy. It's sort of like how the more accurate you measure a coastline, the longer it gets. I've put a graphical representation below (credits to [this page](http://www.drcruzan.com/DefiniteIntegrals.html)).

![](http://i.imgur.com/NH9uBrt.png)

(*I know that isn't an entirely accurate representation of how this algorithm works, but it helps to illustrate the point on how important high samples are*)

It's fairly typical to use anywhere from 1,000 to 1,000,000 samples (depending on the application) to find the arc length of this spline. This makes it a perfect candidate for Neon. Let's take a look at what the algorithm looks like in C. 

```c
float pf_spline_deriv_2(float a, float b, float c, float d, float e, float k, float p) {
    double x = p * k;
    return (5*a*x + 4*b) * (x*x*x) + (3*c*x + 2*d) * x + e;
}

// Meanwhile, in another function
    for (i = 0; i < sample_count; i = i + 1) {
        // t ranges from 0.0 -> 1.0 (a percentage)
        t = i / sample_count;    
        // a, b, c, d, e, knot are all properties of the spline
        dydt = pf_spline_deriv_2(a, b, c, d, e, knot, t);  
        integrand = sqrt(1 + dydt*dydt) / sample_count;
        arc_length += (integrand + last_integrand) / 2;
        last_integrand = integrand;
    }
    double total_arc_length = knot * arc_length;
```

This seems fairly tame, and those calculations can be easily be very processing-intensive when the `sample_count` is in the thousands. There is one problem, though, and that is `arc_length += (integrand + last_integrand) / 2`. What's happening is that we're relying on the previous result of the integrand before adding to the arc length. However, this is only a small part of the equation, with the bulk of the processing power happening in the lines above it.

There's a few ways we can fix this:  

- Store integrands in an array, and add them later (ouch, an array of size 1,000,000? Yea no)  
- Find something else to parallelize (I'm too stubborn for that, no)  
- Half and Half.  

Here's the plan. We'll put the calculation of `t`, `dydt` and `integrand` all into Neon. Since we're cutting the loop size into quarters (we can process 4 at a time), we only really have to use 4 integrands at once. If you've ever used a shift register, you'll see where I'm going with this. After the calculation of `t`, `dydt` and `integrand`, we'll do the following:

- Store a value (last_integrand) in a single-float register (in our case, `s4`)
- Store the integrand of our 4 parallel calculations in a q register (must be at or under `q7`, you'll see why)
- Add last_integrand and the first entry of `q7` (`q7[0]`), divide by 2 and add to arc length
- Add `q7[0]` and `q7[1]`, divide by 2 and add to arc length
- Add `q7[1]` and `q7[2]`, divide by 2 and add to arc length
- Add `q7[2]` and `q7[3]`, divide by 2 and add to arc length
- Make `q7[3]` the new last_integrand (store it in `s4`), ready for the next iteration.

Essentially what this does is makes the bulk of calculation happen in parallel, and then does the adding to arc length sequentially. It's a wonderful little tradeoff that works lovely.

**"But Jaci, why can't we use a register higher than Q7 for the integrand?"**.   
Well, I'm glad you asked. There's 2 ways to pull a single value out of a double or quad word register. You can either:   
- a) Push it out to memory (or the stack), then read it back again (very inefficient)  
- b) Grab it from a smaller register.

ARM Neon registers are interesting in how they are formatted. The `s` registers are 'single word' (a 'word' is 4 bytes = 32 bits, the same size as a float/integer). The `d` registers are 'double word', and the `q` registers are 'quad word'. They are quite cleverly arranged so that `d0` is made up of `s0` and `s1`, and `q0` is made up of `d0` and `d1` (`s0-s3`). You can see a graphical view of this below (credits to the ARM NEON Developer Guide): 

![](http://i.imgur.com/nrDlou3.png)

The thing is, that this only goes up to `q7`. After that, all the registers are quadword and are not made up of smaller registers. For us to access a single register (i.e. a single float), we have to access an `s` register. This is why it must be under `q7`. All other values, however, are more than happy being stored in any Neon register.

The Assembly Code for this is available (and commented!) in [this file.](https://github.com/JacisNonsense/neon_pathfinder/blob/master/src/asm/spline.S)

## Conclusion
Using some handy ARM Neon, we're able to dramatically increase the generation speed of Linear and Trajectory profiles. This can be incredibly useful for systems with low processing power, or where you want to generate profiles on the fly. 

**You can see the project on GitHub [here](https://github.com/JacisNonsense/neon_pathfinder)**