---
layout: post
title: "Predictive current limits - Preventing issues before they happen"
date: 2019-04-14 12:00:00
author: Jaci
categories: frc, code, math
---
<script src="https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.0/MathJax.js?config=TeX-AMS-MML_HTMLorMML" type="text/javascript"></script>

Current limiting is a fantastic tool in the hands of the engineer - it allows us to keep power demands under control. But is there a better way to control the power demands of our actuators, to make them more controllable? Could we limit acceleration and torque, too? Can we stop our robot from tipping, before it happens?

<!-- excerpt -->

## The Problem
We all know about current limiting - reducing the power demand from an actuator in order to prevent drawing too much power, potentially overloading circuits or causing battery voltage to sag. 

There are many ways to implement current limiting, but most are reactive, meaning they limit the current _after_ the overcurrent event has already happened. Usually, the reaction is fast enough to prevent any noticeable problems, but there are many reasons why we might want to stop these events _before_ they happen.

### Predictability
By stopping the overcurrent event before it happens, it allows us to be able to have some comfort in knowing that we're not asking more of our system than we can deliver. Even brief events are enough to blow fuses, or cause drops in voltage.

### Controllability
Limiting current before it is sent to our system allows us to formulate a much better feed-forward model for the system, potentially increasing its stability and controllability.

### Limiting Torque and Acceleration
By limiting current, we can subsequently also limit torque and acceleration. We could limit the acceleration, such that our robot doesn't tip over with a high centre of mass. Or we could limit torque to avoid gripping objects too hard. There are many possibilities here, and is perhaps the biggest advantage to being able to do these limits proactively.

## Predictive Current Limiting
By developing a model of our system, we can determine a relationship between our system state and current draw, which allows us to limit current before the control signal is ever sent. In this example, I'll be using a brushed DC motor.

### The Motor Model
Let's start with the DC motor model:
\\[ V = IR + k_\omega \omega \\]

We can confirm the above by looking at the components of the equation above.

\\[ V_\omega = k_\omega \omega \\]
When the current is at its lowest (~ 0A), all the voltage provided to the motor is used by speed ($$\omega$$). In other words, when the motor is at free speed, with no load, its current draw is close to zero. Note that this doesn't include free current, which is an important distinction to take note of. 

\\[ V_I = IR \\]
When the speed ($$\omega$$) is 0, all the voltage provided to the motor is used by the above. In other words, when the motor is stalled, the current is at its highest, and the speed is at its lowest (zero). Note also that this is the equation for Ohm's Law. When a motor is not spinning, it acts just like a resistor, albeit with a slight inductive component that we're choosing to identify as negligible here.

### Controlling the system with Voltage
It is typically good practice to control our system using Voltage, since it not only allows us to be more resilient to voltage spikes and drops in the supply, but also allows us to use it in calculations, such as the ones we're going to use here.

This is not too hard of a change to make, as in most cases you can multiply or divide your control signal (a duty cycle, -1 -> 1) by the battery bus voltage. Using voltage to demand our system will make the rest of your life easier as you descend further into control theory.

#### Finding the acceptable applied voltage range
Using our motor model, and the known angular speed of the motor shaft in rad/s, we can determine the range of voltages we can apply to stay within the current limits ($$I_{min}$$ and $$I_{max}$$).

\\[ V_{min} = I_{min} R + k_\omega \omega \\]
\\[ V_{max} = I_{max} R + k_\omega \omega \\]

Note that $$R$$ and $$k_\omega$$ are both constants of the motor. Given our $$I$$ limits, and our current motor speed $$\omega$$, we can find $$V_{min,max}$$; the range of input voltages to satisfy staying inside the current limits.

Note also that the limits may be negative, and $$I_{min}$$ must be negative in order for the motor to ever run in reverse.

### Putting it all together
Given some demand voltage, $$V_D$$, we can enforce the following constraint:

\\[ V_{min} \leq V_D \leq V_{max} \\]
\\[ I_{min} R + k_\omega \omega \leq V_D \leq I_{max} R + k_\omega \omega \\]
\\[ I_{min} \leq \frac{V_D - k_\omega \omega}{R} \leq I_{max} \\]

## Limiting Torque and Acceleration
Now that we have current limits, we can also impose torque or acceleration limits.

Since we know that torque is proportional to current, we can deduce:
\\[ I = k_\tau \tau \\]

And, by first principles:
\\[ \tau = Fr \\]
\\[ \tau = mar \\]

Thus:
\\[ I = k_\tau mar \\]

Which can then be incorporated into our $$I_{min}$$ and $$I_{max}$$ calculations.

## Pitfalls
There are, of course, drawbacks. 

With predictive current limiting, our system may end up being too conservative, or it might not be accurate enough, causing a slight overcurrent event. Approaches like these are best fitted with an appropriate reactive limit in case our model isn't 100% correct, acting as a backup.