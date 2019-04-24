---
layout: post
title: "Computer Vision - Scratching the Surface"
date: 2017-11-18 11:30:00
author: Jaci
categories: cv, vision, talk, frc
---

Earlier today, I did a talk for FRC Team ARTEMIS on Computer Vision, demonstrating the basics but also diving into _some_ advance topics. Here, I've released the slide deck, video and some further reading materials.

<!-- excerpt -->

## Slide Deck
Access the [Slide Deck Here](https://docs.google.com/presentation/d/1vgMuifEYkToz7KGrdd0VZSc6E1mUOK-z4cKvbQZ1kbo/edit?usp=sharing) (google slides).

## Video
Access the [VOD Recording Here](https://www.youtube.com/watch?v=d9WSAfzA6fc).

<iframe width="560" height="315" src="https://www.youtube.com/embed/d9WSAfzA6fc" frameborder="0" allowfullscreen></iframe>

<br />

## Questions
These were questions asked during the presentation.

### _Q) Is it possible to track the trajectory of balls, frisbees, etc?_

A) Yes, but it is very difficult. The first obstacle is identifying the object. Balls, frisbees and other game pieces are often not highlighted by some extraordinary feature (like retroreflective materials). You also have to deal with motion blur found in moving objects, especially when coupled with your robot movement. That being said, it's still possible to track these. Unique colours can make them easy to track, or you could use some depth information from stereoscopic or depth sensing cameras.

If you do manage to track the object, you still have to deal with the uncertainty that comes with the camera, object and environment. For some objects, air resistance can make the trajectory not quite parabolic, or unpredictable (in the case of things like paper airplanes). There is always some uncertainty, which is why it's important to keep updating your estimated path while the object is in view. This is pretty well demonstrated in Mark Rober's video of an automatic dartboard, shown below _[(link)](https://www.youtube.com/watch?v=MHTizZ_XcUM)_

<iframe width="560" height="315" src="https://www.youtube.com/embed/MHTizZ_XcUM" frameborder="0" allowfullscreen></iframe>
<br />

### _Q) What's the difference between using a phone and another coprocessor like the Raspberry Pi?_

A) Not a whole lot, although phones do provide some advantages. The first advantage is that the cameras on phones are generally pretty good. Since phone cameras are used in a variety of situations (like low light, or bright and sunny days), they tend to handle bright lights fairly well, which is important when adjusting the exposure to not over-expose the sensor. This is not true for all phones, though.

Phones generally have a pretty decent software stack, too. Most of the software you'll use in computer vision is typically readily available for most android devices, and developing an android app is insanely easy. The communication between your phone and main processor is a bit more difficult, as you can't use WiFi, BT or Cellular. That being said, android has access to the AOA (Android Open Accessory) API that can communicate over USB to a host (like the robot controller).

Phones are also typically quite accessible, you probably have a few lying around amongst your team members.

All this being said, there's nothing inherently wrong with using an SBC (single board computer) like the Raspberry Pi or Pine64. In fact, it can be superior in other ways (expandable, cheap, not as sandboxed).

### _Q) Is there an advantage for using stereo cameras, or multiple cameras?_

A) Yes! Stereo cameras is a form of sensor fusion, and can be used to sense depth in the same way that your eyes do. Two perspectives of the same image can be used, with some known parameters, to create a depth map of the image, allowing you to tell the distance as well as size and angle of features in the image. This can be very useful for some specific cases.

Multiple cameras (not necessarily stereoscopic) can also be used to aid in a variety of scenarios. A common configuration is one on the back, and one on the front. Another configuration is one, high resolution camera for processing (computer vision), and another, lower resolution one being sent raw to the driver to aid them. This lower-res camera helps in staying under the bandwidth limit, but the higher-res camera is only used onboard, helping in automated tasks.
<br />

## Further Reading
If you want to dig deeper into automated tasks, such as those used in self-driving vehicles or autonomous robots, I would suggest investing some time into researching sensor fusion, the process of combining sensors (of the same or different types) in order to provide better results (less uncertain, more accurate, more reliable, higher performance) than any one sensor used on its own. From this research, you'll also gain a bit of insight into 'state', which is a key concept in automation and robotics.

