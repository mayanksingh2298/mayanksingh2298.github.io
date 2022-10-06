---
layout: post
title:  "Saving cost with timeout latches in JavaScript"
date:   2022-07-18 02:02:25
categories: javascript
image: /assets/article_images/tl.webp
---

I maintain this app called [casset](https://www.casset.app/):

<iframe src="https://www.casset.app/" frameborder="0" height="900" width="100%"></iframe>

It essentially live streams what song I am listening on spotify and lets users join in and sync with me.
It doesn't really stream audio buffers, just the song title.



And the architecture is pretty straight forward:
- Poll spotify api in background
- maintain state in memory
- push state change to client via websockets

<br/>

And it works quite well, acceptable delay, no rate limits hit(hard to when it's just my user getting polled).
But every month, I get an invoice of 25$ from Digital Ocean.

That happens because I use their k8s cluster and a load balancer. Which I know is an overkill for something like this.

And that's why I decided to not only move away to something simpler and cheaper but also explore can we only pay for the work that we do?

## Architecture Overhaul
<br/>
Firstly we need to move away from the "always on" mode to "on demand" mode.
Does the tree fall in the forest only when we observe it? In our case, yes it does. Because then we don't have to render/calculate anything unnecessarily.

So we remove the socket layer, and let the client poll our system.

Now we have two polls:
- Client polling our system
- System polling Spotify

<br/>
Is it ok if we take the shortcut and couple these two polling? That is, call Spotify API only if client calls our system.

That can work in theory, but with this our rate of API requests to spotify gets coupled with number of clients. One client is ok, maybe 10 even, but 100? 100,000?

That's when we would have problems. Problems like, rate limit and quota exhaustion.
Also, let's say I am listening to a song for a few minutes, does it even make sense to call spotify API 100,000k times to check current track?

With this, we see that coupling those two systems isn't a good idea. So what do we do next? 
We need to poll spotify but not unnecessarily, only when we have intent, but we don't want to tightly couple with incoming requests.

**_Weak coupling?_**

Let's say we have a timer with us for polling spotify, say 10s. Our system will poll spotify every second for 10s and then stop. Unless a request comes, then the timer gets reset to 10s and the cycle starts again.
If there are 100,000 requests coming to the system, the max a request can do is reset the timer, it doesn't affect the poll rate for spotify, just elongates the process.


It's best described visually [here](https://observablehq.com/d/2531ae77ca3d9231).

## Timeout latch
<br/>
It's straight forward to model this with simple timers. For example, we start a `setTimeout` and whenever we want to reset, we clear that timeout and start again.

But I didn't want the overhead of creating and deleting timers just for resetting the clock.

So I created a custom scheduler, which ticks every 1ms. On the other hand, we have a `latch`, essentially just an object with a counter.
The scheduler's job is to decay the latches by decrementing the counters.
In this universe, scheduler creates time using ticks, and latches experience that time using associated counters.

This is fairly simple and straightforward, but as I mentioned before, I wanted to explore can we only pay for whatever actual work we do?

Running a scheduler indefinitely still means we are in an "always on" mode. What's the point of creating time if there are no entities to observe it?

And that's final thing that we needed to do, stop the scheduler if all latches are done, or cancelled.

If something new is added, or an old latch gets reset then start the engine once again.

The code is maintained [here](https://github.com/iostreamer-X/timeout-latch) and published to npm as well.

## Why is this better?
<br/>
So we already established that in this case "on demand" is better than "always on". 
And in "on demand" mode as well, we wanted to be truly "on demand", that is expend resources only when necessary.

With the current setup, especially with timeout-latch, we are in a state where nothing runs unless necessary, and it halts if the intent to run isn't there anymore.

This property is extremely beneficial if we look at serverless or edge functions.
That's a model where you do pay for whatever you execute. 

Even for simple apps on Digital Ocean there's a minimum of 5$ you'd have to pay.
But for a platform that takes the "server" away from you, one can truly embrace the burstiness nature of work.

And this serves as an example where we transformed polling(very continuous) to something that's bursty and "on demand".

And that concludes my cost cutting process, the things you have to do in this economy 😁
