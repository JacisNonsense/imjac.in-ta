---
layout: post
title: "Thoughtful functionality - Writing well-structured, reliable, and flexible FRC code"
date: 2019-01-11 01:00:00
categories: frc, code
---

In all the buzz of build season, it's common that we forget what we're meant to be teaching. In terms of programming and coding skills, well-structured programs and good practice are often foregone in favour of unstructured spaghetti designed to 'just get the robot moving'. In this post, we'll be talking about how to structure our code for flexibility, reliability, and how to solve the "mechanical team isn't ready yet" dependency problem.

<!-- excerpt -->

# Preface
In this post, I'll be talking from the point of view of a C++ FRC programmer, with a few people in my programming team. These concepts are also transferrable to Java, but examples will be syntactically written for C++. Note that it's more important to take the concepts away from this post, not so much the examples themselves. Take your time, read through with an active brain and ensure you understand the _why_, not the how.

We'll be focussing mostly on modularity and dependency injection in this post, both concepts which make it easier for us to write resilient, reliable, testable and flexible code.

Finally, this post is centred around how we choose to structure our code, designed for flexibility, reliability and testability. One size may not fit all, but standing in anothers shoes may make us a bit more reflective about our design decisions.

# Part 1: Infrastructure
All software projects have to start somewhere, and that somewhere is infrastructure. Before you can get into the fun stuff, like making the robot smash into a wall, or doing the all-important #victoryspins, we have to lay the foundations first.

## The Robot Class - The Plumber
<img src='/ta/img/structuring-frc-code/google-pump-room.jpg' alt="A Datacentre Pump Room" style='width:700px;' /><br/>
_A Datacentre Pump Room. Photo by [Google](https://blog.google/outreach-initiatives/environment/deepmind-ai-reduces-energy-used-for/)_

When starting out, you'll get a `Robot` class. It'll be pretty empty by this point, but it's the main entrypoint in your robot program - containing the init and periodic methods for all of your operating modes. 

It's appetizing to try and write your first code directly in this class, but resist the temptation! What may seem like a quick flirt with an `frc::Spark` here, and a fling with an `frc::XboxController` there can quickly turn into a 500 line file filled with `double aVar3 = 15.23` and `// TODO: I haven't slept in 4 days. All I want to do is cross the auto line.`

Think of `Robot` like a hub. It's where all of your systems come together, where they're all created, but little more. It shouldn't contain any logic on its own, and should be very thin and lightweight.

Allow this class to be the 'plumbing' for your program. Want to change a mechanism? Redirect the pipes, don't reconstruct the room.

## Motors and Sensors - The Map
At some point, we're going to need to access the components of our robot - the motor controllers, the pistons, the sensors, the pretty blinking lights. It would be mighty convenient to put these all together, so if we change the wiring or layout of the robot, there's one simple place to find what we need to change, and one place only.

Introducing, the map class (or classes). There are a few ways to structure this. We can have everything in one class, or break it down by subsystem (elevator, drivetrain, grabber, etc), or nested. Personally, I prefer nested, since it still provides everything in one single location, while still having some structure to it that's immediately obvious and easy to see. Observe:

```cpp
struct robot_map {

  struct drivetrain {
    // Left motors
    frc::Spark left_a{0}, left_b{1};
    frc::SpeedControllerGroup left{left_a, left_b};
    
    // Right motors
    frc::Spark right_a{2}, right_b{3};
    frc::SpeedControllerGroup right{right_a, right_b};

    // Sensors
    frc::Encoder left_encoder{0, 1};
    frc::Encoder right_encoder{2, 3};
  };

  drivetrain dt;

  struct elevator {
    // Lift motor - with encoder attached
    CANTalonSRX lift{12};
  };

  elevator lift;

};
```

See how we can see everything at a glance, while still being able to see the summary of where everything is? Now it's super easy to change the lift motor configuration, or add a new drive motor per side, or change the CAN IDs or Ports. It's simple, it's elegant, and it doesn't require much thought.

## Generic Interfaces
In FRC, we have 'smart' motor controllers, and 'dumb' motor controllers. Smart motor controllers, like the Talon SRX, or Spark MAX, augment their ability by allowing you to attach sensors, switches and other goodness to them, which can be accessed from our program. Dumb motor controllers, like the Talon SR, Spark, or Victor 888 only provide motor output, no sensor input.

With this knowledge, let us pose the following question:
> If I want my robot to function with either a smart motor controller, or a dumb motor controller + an external encoder, how would I add this flexibility into my program?

There are a number of reasons why we might ask this question. What if we need a quick fix on the field? What if we don't know what our electronics layout will look like yet? What if we want to reuse our logic on other robots?

This is the perfect opportunity for us to use generic interfaces. Generic interfaces allow us to 'categorize' our objects in terms of their capabilities. For example, `frc::SpeedController` is implemented by anything that controls speed (like a motor controller). 

Let's break our problem down. We have two main functionalities we want to provide:
- Control the speed of the motor (Motor Controllers)
- Sense the position / velocity of whatever the motor is attached to (Encoders)
 
Each of these functionalities is an interface we may want to provide. In our case, it might look like the following:  

![](/ta/img/structuring-frc-code/inherit.png)  

As you can see, we can provide the full functionality we want by using either a Spark (PWM) + Encoder (Digital In), or a single Talon SRX. Now, we can create our generic interface classes:

`frc::SpeedController` is already provided to us, so we don't have to write our own definition of it.

WPILib also provides a generic interface for an encoder-like object, `frc::CounterBase`, but both `frc::CounterBase` and `frc::SpeedController` have a method named `Get()`, meaning we can't implement both at once since the method is ambiguous, hence we write our own encoder class:

```cpp
class encoder {
 public:
  virtual int get_encoder_counts() = 0;
};
```

Now, we can write our Talon SRX class. We have to write our own wrapper for the Talon SRX, since the CTRE version doesn't inherit from what we need it to. Notice here that we're implementing _both_ `frc::SpeedController` and our own `encoder` class, allowing the `talon_srx` to appear as it is both a motor controller and a sensor.

```cpp
class talon_srx : public frc::SpeedController, public encoder {
 public:
  int get_encoder_counts() override;
  void Set(double speed) override;
  // ...
};
```

Since we have a custom interface for `encoder`, we should also write an adapter that allows a WPILib encoder to appear as our encoder:

```cpp
class encoder_adapter : public encoder {
 public:
  encoder_adapter(frc::CounterBase &frcEncoder);
  int get_encoder_counts() override;
  // ...
};
```

An adapter is used as a kind of 'translator', in this case, we're translating the interface of `frc::CounterBase` to our interface of `encoder`, allowing us to convert a WPILib Digital Encoder to our form of encoder using the following:

```cpp
frc::Encoder frc_encoder{0, 1}; // Digital quad encoder on port 0, 1
encoder_adapter my_encoder{frc_encoder};

std::cout << my_encoder.get_encoder_counts() << std::endl;
```

Now that we have a generic interface for encoders (`encoder`) and motor controllers (`frc::SpeedController`), we can fuse them together to provide the functionality that we want. On an elevator, we _always_ want a motor to have an encoder paired with it, so we can tell where the elevator is at any given time. Instead of loosely enforcing this, by accessing the motor and the encoder from the lift class, we can provide a single data structure that holds both:

```cpp
struct sensored_transmission {
  frc::SpeedController  *motor;
  encoder               *sensor;
};
```

We're calling this `sensored_transmission` since we're sensing the speed on the transmission itself (which in this case, is the gearbox). Note that we don't include things like limit switches on here, since limit switches are placed on the mechanism, and not the transmission. You can think of the transmission as a single unit, a building block, of a larger mechanism.

By adding this class, we can do the following:
```cpp
// Talon SRX Only
talon_srx my_talon{99};

sensored_transmission lift_transmission{&my_talon, &my_talon};

// Spark + External Sensor
frc::Spark my_spark{0};
frc::Encoder my_encoder{0, 1};

sensored_transmission lift_transmission{&my_spark, new encoder_adapter{my_encoder}};

// Talon SRX + External Sensor
talon_srx my_talon{99};
frc::Encoder my_encoder{0, 1};

sensored_transmission lift_transmission{&my_spark, new encoder_adapter{my_encoder}};

// Dual Motor - Talon SRX + Spark, Talon SRX serves double duty as sensor.
talon_srx my_talon{99};
frc::Spark my_spark{0};
frc::SpeedControllerGroup motors{my_talon, my_spark};

sensored_transmission lift_transmission{&motors, &my_talon};
```

The possibilities here are endless, and the great thing is that our lift doesn't need to change its code in order to adapt to changes - we only have to change what we provide to `sensored_transmission`, and then provide `sensored_transmission` to the lift. This is the advantage of using generic interfaces - we can be flexible and resilient to change.

You may also choose to not create `sensored_transmission`, and instead pass the motor and encoder separately, but there are reasons why I've chosen to bundle them together. The main one is simulation. When creating `sensored_transmission`, we've already 'bound' a motor and an encoder together, so we don't have to tell the simulation elsewhere that they are physically connected. Another reason is that it solidifies the fact that they are, indeed, physically connected and are not separate, meaning we can enforce this constraint when creating the data structure, instead of every time we use it.

# Part 2: Putting it all together - Dependency Injection
Now that we've got all the parts, let's put them all together.

A typical FRC program might look a little something like the following:  
![](/ta/img/structuring-frc-code/complex.png)  

See how complex that looks? The Robot class sets up the Map, but also sets up all the other mechanisms, which just access the Map directly again! If we want to reuse any of the mechanism classes, we have to change it since it depends on the team-specific Map class. What would be better is if we could design our mechanism classes such that they don't have to directly touch the Map class, but instead get the motors, sensors and other components they need from the Robot class.

![](/ta/img/structuring-frc-code/simple.png)

See now that we can add / remove mechanisms extremely easily, and transfer mechanisms to the codebase of other robots. With each mechanism not depending on the Map, our mechanism code now becomes robot agnostic, and also means that it's super easy to change our robot layout. The Robot class is serving its purpose as a plumber - it handles the passing of data from the Map to the mechanism. Notice how the graph resembles a bicycle wheel - which is why it's sometimes given the name 'hub and spoke', with the Robot class being the hub we mentioned earlier.  

Let's see how we would implement this in code. For simplicity, we'll do it with a single mechanism - the lift. First, let's take a look at the most simple class - the Map:

```cpp
struct robot_map {

  struct elevator {
    // Motors
    talon_srx motor_a{99};
    frc::Spark motor_b{0};
    frc::SpeedControllerGroup motor_group{motor_a, motor_b};
    // Sensored Transmission
    sensored_transmission transmission{&motor_group, &motor_a};
  };

  elevator lift;

};
```

Now let's take a look at our `elevator` / `lift` class. We're going to design this to fit the requirements that we described above, that is:
- Does not touch the Robot Map directly,
- Does not need to be modified in order to work on different robots, and,
- Is easy to understand.

Let's go ahead and set out the skeleton of our class. We know that the elevator requires a motor and an encoder at the least, so we can go ahead and add that to what we need to store in the class. We'll also add a few other methods that are typical of an elevator.

```cpp
class elevator {
 public:
  elevator(sensored_transmission &transmission);
  
  void update();  // Called periodically

  void set_goal(double goal);
  double get_goal() const;

  double get_height() const;

 private:
  sensored_transmission &_transmission;
};
```

Next, let's take a look at our robot class (usually in C++ this would be split across the .h and .cpp file, but here I'm doing it in one file for the purposes of illustration):

```cpp
class robot : public frc::TimedRobot {
 public:
  void RobotInit() override {
    _map = new robot_map();
    _lift = new elevator(_map->lift.transmission);
  }

  void RobotPeriodic() override {
    _lift->update();
  }

 private:
  robot_map *_map;
  elevator  *_lift;
};
```

You'll notice that we're passing in all the things from `robot_map` that the `elevator` requires in the constructor. This is a specific type of "Dependency Injection" - Constructor Injection. Note that by using constructor injection, we can interchange _what_ we provide from `robot_map` to the `elevator` without modifying either of the classes implementation. If we want to pass in a different motor, we don't need to modify `elevator` at all. In other words, what we're saying is that `elevator` has a dependency on a `sensored_transmission` (a motor + an encoder), **not** `robot_map` (the entire robot layout).

The effect is that our program is not as tightly coupled. Coupling is the concept of code being _concretely dependent on another, specific piece of code_. This isn't desirable at it increases effort needed to perform maintenance on the code, decreases flexibility, increases complexity, and makes the code less testable. If we want to reuse `elevator` on another robot, we don't need to change `elevator` to fit the new robot map, instead `elevator` asks `robot` to provide what it needs in the form of constructor parameters.

This should help illustrate how `robot` acts as a plumber. It's a very thin class that only serves to create and manage the mechanisms and structures of the robot, offloading the logic to whatever class is responsible. This makes it extremely easy to add and remove mechanisms. You could have a code library that you build up over the years, or before your robot is even ready, and writing `robot` to adapt to your specific robot.

# Part 3: Testability
Since we've designed our code to be loosely-coupled, we can be extremely flexible in how it's implemented. So flexible, in fact, that we don't have to give it real motor controllers or sensors at all.

By providing fake, or simulated, motors and sensors, we can see how our code works in a simulator, or automatically run tests on its different sections. By testing each class separately (unit testing), we can not only hunt down issues, but we can also develop a large part of our code before even having a real robot to test on. We call this 'test driven development'. Combined with a simulator, this can be extremely powerful.

Take for example the elevator. By providing it with a simulated encoder and motor, derived from mathematical models, we can automatically test how our elevator responds to certain situations. Can we implement tests to make sure our elevator can go from bottom to top in less than 2 seconds? Can we make sure that if we ask it to go to the middle, it doesn't overshoot? Of course we can!

Let's come up with a real quick and dirty simulation. For this, we're just going to base the encoder readings off of the motor speed as a running sum. For a better solution, I'd recommend viewing Austin Schuh's workshops on [system modelling](https://www.youtube.com/watch?v=RLrZzSpHP4E) and [test driven development](https://www.youtube.com/watch?v=uGtT8ojgSzg). 

To make this happen, we're going to use mock classes, which are kind of 'fake' implementations for our tests. Let's go ahead and start with our motor class:
```cpp
class mock_motor : public frc::SpeedController {
 public:
  // ...

  void Set(double speed) override {
    _speed = speed;
  }

  double Get() override const {
    return _speed;
  }
 private:
  double _speed;
};
```

All this does is store a value for the speed whenever anything calls `Set()`, and also gives us a mechanism to retrieve the value with `Get()`. Easy peasy. 

Now, let's take a look at the encoder class. To help us, we're going to take in the gearbox reduction as well as the encoder ticks per revolution. We'll also take in the maximum speed of the motor, since the speed returned by `mock_motor` is on a scale from -1..1, which aren't real units!

```cpp
class mock_encoder : public encoder {
 public:
  mock_encoder(int counts_per_rev, double gearbox_ratio, double free_speed) : 
    _cpr(counts_per_rev), _G(gearbox_ratio), _free_speed(free_speed) {}

  int get_encoder_counts() override {
    return _counts;
  }

  // dt = time diffference, since we're converting speed to position (integrating)
  // speed = motor value from -1 .. 1
  void update(double dt, double speed) {
    double rpm = (speed * _free_speed) / _G;      // RPM @ encoder shaft
    double rev_difference = (rpm / 60.0) * dt;    // RPM / 60 = revs per second, multiply by seconds = revolutions
    _counts += rev_difference * _cpr;             // Counts = revolutions * counts / revolutions
  }

  // reset the simulated position
  void reset() {
    _counts = 0;
  }

  // ...
 private:
  int _counts;

  int _cpr;
  double _G;
  double _free_speed;
};
```

What we're doing here is setting the data inside of `mock_encoder` from the simulation, instead of the `encoder` prompting a real-world sensor. We need `dt` for this, which is the difference in simulated time between calls to `update`, since we're summing up the speed over time (integrating).

Now, let's plumb all this together with a simple test:
```cpp
TEST(Elevator, FullHeightTime) {
  mock_motor motor;
   // 1000 cpr, 12.75 gearbox reduction (kit of parts chassis), 5330 rpm (CIM motor)
  mock_encoder encoder{ 1000, 12.75, 5330 };

  // From earlier examples in this post
  sensored_transmission transmission{&motor, &encoder};
  elevator lift{transmission};

  double dt = 0.1;        // 0.1 seconds between update() calls
  double goal = 1.8;      // 1.8 metres
  double max_time = 2.0;  // 2 seconds

  encoder.set_goal(goal);

  // We're making the simulation stop once it reaches full height, or at 10s, whatever comes first.
  bool running = true;
  double time;
  for (time = 0; time < 10 && running; time += dt) {
    lift.update();

    double speed = motor.Get();
    encoder.update(dt, speed);

    if (lift.get_height() >= goal)
      running = false;
  }

  // Check that the height is roughly equal to the maximum
  // Verifies that we actually got to the goal
  ASSERT_EQ(goal, encoder.get_height(), 0.01);
  // Check that it took less than max_time (2 seconds)
  ASSERT_LT(max_time, time);
}
```

This test verifies that we reach `goal` (1.8 metres) in less than `max_time` (2 seconds). Note that it doesn't check for overshoot, but it can be modified to do so (hint: change the `running = false` check to check for speed, instead of just the lift height). 

Using this, we can test if our code works before it even goes on the robot! Furthermore, this test is run when you call `./gradlew build`, which means that it will be tested everytime you make a change to the code, ensuring you don't break `elevator` when making changes.

With some more effort, you can even make a full-fledged simulation to interactively test your code. 

# Part 4: Closing thoughts
That covers the gist of it. Hopefully, this post demonstrates some simple, low-effort, high-gain changes we can implement in our code, and in our practices, in order to develop well thought-out, flexible and clean code. 

If you'd like to see some of this in action, we're developing ours throughout the season in our own codebase. It includes simulation, unit testing and a whole bunch of other stuff. Please note that a lot of it is still in development.
Take a look for yourself: [https://github.com/CurtinFRC/2019-DeepSpace](https://github.com/CurtinFRC/2019-DeepSpace)

You can also take a look at Austin Schuh's workshops, particularly on test driven development. They're really well presented and focus more on the testing methodology and development practices. [https://www.youtube.com/watch?v=uGtT8ojgSzg](https://www.youtube.com/watch?v=uGtT8ojgSzg)