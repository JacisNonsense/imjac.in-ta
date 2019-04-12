---
layout: post
title: "RoboRIO Vision Tracking at 30fps without a Coprocessor"
date: 2016-11-14 08:00:15
categories: roborio, frc, asm, coprocessor, vision, kinect
---
 **TL;DR: We can run 30fps Vision Tracking on the RoboRIO at 7-8ms per frame, equating to only about 23% CPU Time. For scale, the FRC Network Comms program uses about 20% CPU constantly** 

<!-- excerpt -->

One of the 'end goals' of any FRC team is to make a fast vision tracking pipeline that works. Multiple efforts have been made to make this more and more accessible to teams, including Open-Source releases of vision libraries, language bindings, and even projects like WPI's own GRIP. I even released [our vision code for 2016](https://github.com/FRC5333/2016-Champs/tree/master/Coprocessor).

It's a common thought that you _need_ a coprocessor to do any sort of decent vision tracking solution. The CPU on the RoboRIO isn't the fastest thing in the world, so many teams opt for a coprocessor, such as a Beaglebone, Raspberry Pi, Kangaroo PC or even NVIDIA's powerful Jetson board. These are all great, but can we do better? Can we possibly run a full vision pipeline, from camera to code, at 30fps, 640x480, onboard the RoboRIO itself, with room to spare for our Robot Program? The answer is: Absolutely!

## Establishing the Baseline
First of all, we have to establish what the speed of a regular vision system is running on RoboRIO hardware. To do this, I isolated the [processing](https://github.com/FRC5333/2016-Champs/blob/master/Coprocessor/Kinect/src/processor.cpp) portion of my Vision Tracking code from 2016, using a static 640x480 monochrome image generated from random data as the input. This 640x480 monochrome format is the same format we get from the Kinect's IR camera. If you don't want to stumble through the code, here's a short outline:

- Clear Caches (previously found features, like contours and hulls)
- Filter the image with an intensity threshold
- Find the contours of the image
- Find the bounding rectangle of each contour
- Filter the rectangles based on internal area
- Find the convex hull of the rectangle
- Filter the hulls based on solidity (total area / hull area)
- Push the hull, rectangle and contours into a vector

### Inspection
Before we do any measurements, let's take a look at each of these steps and identify where the most CPU time will be. Obviously, the most CPU time will be taken on functions that crawl the image pixel-by-pixel, that is, the threshold function and contour finding. All steps from there on out rely on the contours we found, which are stored as points, so those aren't intensive at all.

So, how do we speed this up? Bar rewriting the whole `cv::findContours` function in assembly (follow-up blog post idea?), the only real option we have is to deal with the filtering based on threshold, the `cv::inRange` function. 

### cv::inRange
`cv::inRange` is a function commonly used to apply a threshold to an image or mat in OpenCV. It takes 4 arguments, the input, a low value, a high value, and the output. To put it simply, it acts a bit like `memcpy`, but if the value doesn't lay between the low and high value, the byte is set to 0, otherwise it is copied as is. Since we aren't thresholding anything too bright, for now we're just going to say that the high limit is `255`, the largest number we can store in an unsigned byte (`uint8_t`).

If we were to write a crude version of this function ourselves, it might look something like this.

~~~c
void memcpy_threshold_c(uint8_t *dest, const uint8_t *src, int count, int minimum) {
    for (int i = 0; i < count; i++) {
        dest[i] = src[i] > minimum ? src[i] : 0;
    }
}
~~~

An important thing to note here is just how expensive a memory copy is. Suddenly, we're not limited by how fast our system can execute our code, but rather, how fast we can write out to memory. Don't get me wrong, this is still fast, but it's a snail's pace compared to raw CPU power. In the above case, `count` is equal to `640*480`, which is `307,200`.

### A Benchmark
Let's write 2 sets of benchmarks. Both benchmarks will use the exact same code, but one will use `cv::inRange`, and the other will use our crude implementation, `memcpy_threshold_c`. 

```
Time for 30 Frames:
- cv::inRange:         348ms     (11.6 ms per frame)
- memcpy_threshold_c:  1071ms    (35.7 ms per frame)
```

Obviously, our implementation isn't as good, but this was to be expected. OpenCV, with all its backers and optimizations for different platforms, is going to be way faster than our crude implementation. 

The keen-eyed may recognize that this is already faster than 30fps. For 30fps, each frame must be less than 33ms, and `cv::inRange` executes in only 11.6ms. That's only about 1/3rd CPU time, leaving a generous 2/3rds for our normal code. That's great, but we can go even faster. 

## SIMD and ARM NEON
Allow me to introduce my friend, SIMD, Single Instruction, Multiple Data, and his wingman, ARM NEON. In short, these allow you to do arithmetic logic on multiple numbers at the same time, instead of sequentially. 

On ARM NEON (supported by the RoboRIO), we have a number of different registers we can use. These registers are pretty large, the largest being the Q set, boasting 128 bits (16 bytes), with the D set coming in second at 64 bits (8 bytes). Q0 is made up of D0 and D1, Q1 is made up of D2 and D3, and so on. 

We can use special instruction calls to perform operations on these register, 'splitting' the register based on some size. For example, I can fill Q0 with 16 unsigned bytes (`uint8_t`), and then Q1 with another 16 unsigned bytes, and then execute an addition operation for Q0 + Q1 of datatype `U8` (unsigned byte), and put it in Q2. Q2 will now contain 16 unsigned bytes that are the result of adding each byte of Q0 and Q1. What's really great is that this happens all in _one instruction_, which means for a large enough scale (640*480 bytes), we can do this extremely fast. 

I know this concept is pretty hard to understand, so let me leave you with [this](https://www.kernel.org/pub/linux/kernel/people/geoff/cell/ps3-linux-docs/CellProgrammingTutorial/BasicsOfSIMDProgramming.html). The pictures paint a pretty good picture of how it works, if you don't want to read the entire thing.

Using the [ARM Instruction Reference](http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.dui0489c/CJAJIIGG.html), we can start to produce our own version of a threshold function that uses SIMD to filter our image. Let's get started

## A Faster Threshold Function
Let's establish our assumptions and requirements
- Assume that the size of the image is divisible by 128 (the size of a Q register). (640*480/128 = 2400)
- Image input and output referenced as `uint8_t` pointers
- Filter based on greater than our threshold value
- Be faster than `cv::inRange`

Let's get started. We're going to write it in assembly, but don't worry, I'll explain what we're doing.

First, we need to add our C binding. This tells C that the function it's looking for is already provided by assembly:

```c
extern "C" void memcpy_threshold_asm(uint8_t *dest, const uint8_t *src, int count, int minimum);
```

Now, our assembly file, `memory.S`

```nasm
.global memcpy_threshold_asm
memcpy_threshold_asm:
    push {fp}
    add fp, sp, #0
```
This is the basis of our function. The `.global` and `memcpy_threshold` are our definition of the function. The last 2 lines are used to push a new Stack Frame (used by C)

```nasm
lsr r2, #4
```
`lsr` is the assembly instruction for "Logical Right Shift". What we're actually doing here is dividing our `count` argument (stored in r2) by 16, as `2^4 == 16`. Shifting operations are typically much faster than math operations, so try to use them where possible. We're dividing by 16 as we can do 16 numbers at a time. This is our loop counter.

```nasm
vdup.8 q3, r3
```
Here we're just copying the byte value of r3 (our threshold value) into register q3 in 8-bit (1 byte) chunks, filling q3 with 16 copies of our threshold value.

```nasm
_loop:
   vld1.64 d0, [r1]!
   vld1.64 d1, [r1]!
```
Here we have begun the loop, and have shifted our `src` pointer (stored in r1) into the 64-bit NEON Register `d0`. The `!` will automatically add how many bytes were transferred (in this case, 64/8 == 8) to our pointer. We do this again into d1 to get another 64 bits, taking 128 bits (16 bytes) in total in the register pair d0, d1.

```nasm
   vcgt.u8 q1, q0, q3
```
Here we are doing a single greater-than comparison on q0 (d0, d1 i.e. our source bytes) and q3 (our threshold), and storing the result in q1. This function stores the result as either all 1s (255) if it is greater, or all 0s (0) otherwise.

```nasm
   vand.u8 q2, q1, q0
```
Here are are doing a bitwise AND operation between our comparison result (q1) and our original numbers (q0). This AND operation will give us back the original number if our comparison is true (greater than threshold), or 0 otherwise. We store this in q2

```nasm
   vst1.64 d4, [r0]!
   vst1.64 d5, [r0]!
```
Here we are storing our resultant (q2 = d4, d5) into our destination pointer (stored in r0). This is the opposite of the `vld` instruction we saw earlier.

```nasm
   sub r2, r2, #1
   cmp r2, #0
   bgt _loop
```
This is used to run the loop. First, we subtract 1 from our counter. If the new value of the counter is greater than 0, jump up to `_loop`. If not, continue on.

```nasm
sub sp, fp, #0
pop {fp}
bx lr
```
This is cleanup for the C function call, popping our stack frame off and returning control to whoever called us.

That's it, so how did it perform?

## Results
```
Time for 30 Frames:
- cv::inRange:          348ms     (11.6 ms per frame)
- memcpy_threshold_c:   1071ms    (35.7 ms per frame)
- memcpy_threshold_asm: 231ms     (7.7  ms per frame)
```

Awesome, we've increased the speed of our thresholding function. Granted, only about 4ms per frame, but that's still a pretty significant difference at 30fps (over 100ms total, that's 10% CPU time!). If we add up the time it takes to fetch the image from the camera via the USB driver, and the running background processes on the RoboRIO, this is more than adequate to run our vision system at 30fps, 640x480 with room to spare.

Taking 231ms for 30 frames, that's about 23% CPU load. Obviously this will have some drift depending on the kernel, what the image looks like, etc. 23% CPU sounds like a lot, but lets put that into perspective.
The FRC Network Communications Daemon (the thing that talks to the Driver Station) takes up 20% CPU _constantly_ while connected. While this is a lot for a daemon like this, adding these two up still takes us to less than 50% CPU usage, leaving your user program plenty of headroom.

## Conclusion
Yes, we can run 30fps, 640x480 vision tracking on the RoboRIO at about 23% CPU usage. Maybe something to think about next time your coprocessor refuses to connect to FMS?

You can see the source code for this experiment [here](https://github.com/JacisNonsense/neon_vision)
