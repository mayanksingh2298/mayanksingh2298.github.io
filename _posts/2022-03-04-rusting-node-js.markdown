---
layout: post
title:  "Rusting NodeJS"
date:   2022-03-04 02:02:25
categories: node
image: /assets/article_images/rusting-nodejs.png
---

**Circumventing the single thread bottleneck**

___

Index:
- [NodeJS Refresher](#nodejs-refresher)
	- A brief overview of how eventloop works internally
- [Let's block the main thread](#lets-block-the-main-thread)
	- How a simple code can bring down the performance of NodeJS
- [A qr generator service](#a-qr-generator-service)
	- A realistic example and the results of load testing
- [How to improve?](#how-to-improve)
	- Can we do better than Node?
- [Rust solution](#rust-solution)
	- Using rust and neon to save the day
- [Comparison](#comparison)
	- It's a number's game
- [Conclusion](#conclusion)
	- It's all about choosing the best tool for the job

<br/>
<br/>
<br/>
<br/>

___

<br/>
<br/>

### NodeJS refresher
<br/>
At this point, we have all heard and read how nodejs is singlethreaded but not really. But just in case, here's a refresher:

- NodeJS relies on the concept of event loop. The idea is to ask the os/kernel to do the heavylifting and expect a signal saying 'hey, this is done'.
    - Each os has their own thing going on, linux has `epoll_wait`, osx has `kqueue` and windows has something weird.
    - These kernel api calls are the ones doing the actual job. It kinda looks like this
```js
//pseudocode
while(event=epoll_wait()) {
	if(event.type === 'socket') {
		// do something
		// or in our case, execute the relevant callback
	}
}
```
- NodeJS doesn't have a one size fit all event loop, rather it has a phased setup.
    - For example, it checks timers(`setTimeout` etc) first.
        - Here it's the OS's show again, and it uses `epoll` or equivalent to know if it needs to execute a callback or not.
	- Then we have the microtask queue, which handles `promises` and `nextTicks`
	- ...And more, checkout [this](https://www.youtube.com/watch?v=PNa9OMajw9w) video for full picture
	- At the end of the phased setup, it checks if there are still any more events that it needs to handle or wait for. If yes, the loop continues, if not the loop and the program exits.
- After getting a signal saying 'hey, this is done', the associated callback that you provided is executed.
	- Now mind you, the loop itself is what's single threaded. The tasks that node does in the loop, all on one thread.
	- And the associated callback that it needs to run? Well, you guessed it, the same event loop thread.

<br/>

And now you case see why there might be some confusion around the execution. Afterall, it's singlethreaded but not really. 

Also, what happens if the callback you provided is trying to calculate the meaning of life? That's when we have a problem, because now our eventloop isn't going to do anything until the callback function's execution is complete.

That's what we mean by blocking the main thread in NodeJS.

<br/>
<br/>
<br/>

### Let's block the main thread
<br/>
Let's say we have a NodeJS `express` server with us. And on each request, we calculate a cryptographic hash of given query parameters. And just to stress the system, we do this hashing 500k times and then return the result back.

```js
const express = require('express')
const app = express()
const port = 3000

function getHash(text) {
	let hashedString = text;
	for(const i=0; i<500000; i++) {
		// do fancy hashing
	}
	return hashedString;
}

app.get('/', async (req, res) => {
    const text = req.query?.text;
    const result  = getHash(text);
    res.send({ result });
})

app.listen(port, () => {
  console.log(`App listening on port ${port}`)
})
```

<br/>

Based on what we discussed in previous section, we can see how this setup can backfire and undermine the performance of NodeJS. But to show again:

1. NodeJS starts up, and starts executing our script
2. It asks OS to tell when the server starts
3. It asks OS to also tell when that server receives a connection request
4. And now the grand loop runs in phased manner, checking timer first, then i/o and so on
5. Since NodeJS still has some events that it's waiting for(server connection requests), the loop doesn't quit
6. Let's say someone hits our api, then the os tells NodeJS of that event
7. In the next iteration/tick of the grand phased loop, it checks timers first, finds nothing and then it checks i/o
8. It finds that there's a request, and promptly starts executing associated callback
9. Once the execution of callback is finished, the grand phased loop is iterated again and the queues are checked for more connection requests.

<br/>
Now, our callback isn't very easy breezy, it can take a good amount of time to execute, relatively speaking. 

And that will delay the next iteration of the grand phased loop, which will delay knowing if there's a new connection or not. And that's one very good way of losing i/o performance in NodeJS.

If you look at the code, it's quite innocent looking, nothing weird about it. But one nefarious loop or thread blocking operation is all it takes.

<br/>
<br/>
<br/>

### A qr generator service
<br/>
The previous example of hash calculation isn't very realistic. So let's say we have to build a service which can create a qr image of any given text. 

This service will have a simple `GET` api which will take text in query params. After that it will return a base64 string representing the QR version of given text.

Let's use NodeJS and commonly used libraries for this service. Here's how it looks in code:
```js
const QRCode = require('qrcode')
const express = require('express')
const app = express()
const port = 3000

app.get('/', async (req, res) => {
    const text = req.query?.text || 'QR TEST';
    const result  = await QRCode.toDataURL(text);
    res.send({ result });
})

app.listen(port, () => {
  console.log(`App listening on port ${port}`)
})
```

<br/>
Voilà! We have what we needed. A very simple script which does what we planned to do. But here's the catch, if you look at the source code of `qrcode` library, you'll find there are no async calls. It's all done in one synchronous function.

And now our code looks a lot like the 500k hashing one. But how bad can it really be?

To answer that, I setup `pm2` for some advanced monitoring and `artillery` for load testing. Here's how it went:

```
┌─ Custom Metrics ───────────────────────────────────────────┐┌─ Metadata ────────────────────────────────────────────────────────────┐
│ Used Heap Size                                  23.74 MiB  ││ App Name              index                                           │
│ Heap Usage                                        40.33 %  ││ Namespace             default                                         │
│ Heap Size                                       58.87 MiB  ││ Version               1.0.0                                           │
│ Event Loop Latency p95                            10.78 ms ││ Restarts              0                                               │
│ Event Loop Latency                                3.2 ms   ││ Uptime                2m                                              │
│ Active handles                                       1608  ││ Script path           /home/iostreamer/projects/node-qr-test/index.js │
│ Active requests                                         0  ││ Script args           N/A                                             │
│ HTTP                                       269.86 req/min  ││ Interpreter           node                                            │
│ HTTP P95 Latency                                    16 ms  ││ Interpreter args      N/A                                             │
│ HTTP Mean Latency                                    7 ms  ││ Exec mode             fork                                            │
│                                                            ││ Node.js version       16.13.2                                         │
```

```
--------------------------------
Summary report @ 16:49:34(+0530)
--------------------------------

http.codes.200: .............................49994
http.request_rate: ..........................356/sec
http.requests: ..............................49994
http.response_time:
  min: ......................................1
  max: ......................................97
  median: ...................................15
  p95: ......................................29.1
  p99: ......................................47
```

<br/>
<br/>

Some important stats out of this exercise:
```
event-loop-latency:
p95                     10.78 ms
current                 3.2 ms

http.response_time:
  min: ................ 1 ms
  max: ................ 97 ms
  median: ............. 15 ms
  p95: ................ 29.1 ms
  p99: ................ 47 ms
```

<br/>
<br/>

The response times that we are seeing, a median of `15ms` and p95, p99 of `~30ms` and `~50ms` respectively, seem like a lot. It's a fairly simple service, it makes sense to expect better. 

We know that we have a performance bottleneck, and apparently this is how it crops up. But we still don't if this is really bad or not, or if we can do better or not and if so then by how much?

<br/>
<br/>


### How to improve?
<br/>
We know the bottleneck is that we only have one thread, and if we block it, we are doomed. We need more threads for this. What if we tried `worker_threads`? 

Introduced in node 10, these are separate threads with their own eventloops, but they share the same node and v8 instance, unlike child processes. This is what makes
them analogous to standard threads in other runtimes.

Well, we probably can use them and it might even work, but I wanted to go all in and have a much leaner solution. 

That's why I went with [Rust](https://www.rust-lang.org/learn/get-started), to get some near native performance. 


<br/>
<br/>
<br/>

### Architecture
<br/>

![High level overview](/assets/article_images/nrust.png)
<br/>
<br/>
The idea is to use NodeJS for what it's known for, i.e brilliant i/o and async performance, and rust for managing threads. This way we get to have best of both the worlds.

NodeJS has `n-api`/`node-api` as a layer which enables FFI(Foreign Function Interface). Essestially, it allows node to call functions running in entirely different runtime, written in some other language.

Here are the steps involved in this new architecture for our service:
- NodeJS will still handle the http connection aspect
- On a new request, it will call our rust program to create qr
	- This will be an async call, where our rust program can be viewed like an os/kernel call
	- Like registering a callback for event, except the event is that our rust program is ready with qr base64 string.
- Once in rust domain, we will parse and clean our input given by NodeJS process
- In rust runtime, we will spawn a new thread
	- We will create a qr for given text where
	- Once done, we will intimate that we have a result for the event, and pass it back to NodeJS runtime.
- Once NodeJS knows there's data for the event, it will execute the registered callback with given data.

<br/>

The result is that we have simulated qr creation as an os/kernel api which `epoll_wait` or equivalent can take care of!

This is huge because our NodeJS program is now about handling http requests as fast as it can, without worrying about doing something heavy on its main thread.

<br/>
<br/>
<br/>

### Rust solution
<br/>
We are using [neon](https://neon-bindings.com/) to help us with creating a Rust binding for NodeJS. They have pretty good docs and example for you to start tinkering with it. 

I started with their [hello-world](https://neon-bindings.com/docs/hello-world) example and then used that as a template.

Neon creates a node compatible binary, which our NodeJS program then loads as a library and runs. 

<br/>
<br/>

Here's the rust code:
```rs
use neon::prelude::*;
use image::{DynamicImage, ImageOutputFormat, Luma};
use base64::{encode as b64encode};
use qrcode::QrCode;
use neon::event::Channel;

fn create_qr(
    text: String,
) -> Result<String, String> {
    let width = 128;
    let height = 128;

    if let Ok(qrcode) = QrCode::new(text.as_bytes()) {
        let qrcode_image_buffer = qrcode
            .render::<Luma<u8>>()
            .max_dimensions(width, height)
            .build();

        let qrcode_dynamic_image = DynamicImage::ImageLuma8(qrcode_image_buffer);

        let mut image_bytes: Vec<u8> = Vec::new();

        if let Ok(_v) = qrcode_dynamic_image.write_to(&mut image_bytes, ImageOutputFormat::Png) {
            Ok(b64encode(image_bytes))
        } else {
            Err("Error: Cannot get image bytes".to_string())
        }
    } else {
        Err("Error: Cannot encode this text".to_string())
    }
}


fn create_qr_and_send_back(text: String, callback: Root<JsFunction>, channel: Channel) {
    let result = create_qr(text);

    channel.send(move |mut cx| {
        let callback = callback.into_inner(&mut cx);
        let this = cx.undefined();
        let args = match result {
            Ok(imageString) => {

                // Save the data in a result object.
                let obj = cx.empty_object();
                let str = cx.string(imageString);
                obj.set(&mut cx, "imageString", str)?;
                vec![
                    cx.null().upcast::<JsValue>(),
                    obj.upcast(),
                ]
            }
            Err(err) => {
                let err = cx.string(err.to_string());
                vec![
                    err.upcast::<JsValue>(),
                ]
            }
        };

        callback.call(&mut cx, this, args)?;

        Ok(())
    });
}

fn parse_js_and_get_qr(mut cx: FunctionContext) -> JsResult<JsUndefined> {
    // The types `String`, `Root<JsFunction>`, and `Channel` can all be
    // sent across threads.
    let text = cx.argument::<JsString>(0)?.value(&mut cx);
    let callback = cx.argument::<JsFunction>(1)?.root(&mut cx);
    let channel = cx.channel();

    // Spawn a background thread to complete the execution. The background
    // execution will _not_ block the JavaScript event loop.
    std::thread::spawn(move || {
        // Do the heavy lifting inside the background thread.
        create_qr_and_send_back(text, callback, channel);
    });

    Ok(cx.undefined())
}

#[neon::main]
fn main(mut cx: ModuleContext) -> NeonResult<()> {
    cx.export_function("createQR", parse_js_and_get_qr)?;
    Ok(())
}

```
<br/>
<br/>


Here's the js code which uses it:
```js
const lib= require('.');
const createQR = require('util').promisify(lib.createQR);

const express = require('express')
const app = express()
const port = 3000

app.get('/', async (req, res) => {
    const text = req.query?.text || 'QR TEST';
    const { imageString }  = await createQR(text);
    res.send({ imageString });
})

app.listen(port, () => {
  console.log(`App listening on port ${port}`)
})
```


<br/>
<br/>


And it works! If we run this code, we will get our base64 representation of a qr code.

But is it any good? Does this perform better than our main thread blocking version?

```
┌─ Custom Metrics ───────────────────────────────────────────┐┌─ Metadata ─────────────────────────────────────────────────────────────────────┐
│ Used Heap Size                                  22.00 MiB  ││ App Name              index                                                    │
│ Heap Usage                                        36.74 %  ││ Namespace             default                                                  │
│ Heap Size                                       59.87 MiB  ││ Version               0.1.0                                                    │
│ Event Loop Latency p95                            2.29 ms  ││ Restarts              0                                                        │
│ Event Loop Latency                                0.17 ms  ││ Uptime                96s                                                      │
│ Active handles                                       1604  ││ Script path           /home/iostreamer/projects/node-rust-hello-world/index.js │
│ Active requests                                         0  ││ Script args           N/A                                                      │
│ HTTP                                       240.11 req/min  ││ Interpreter           node                                                     │
│ HTTP P95 Latency                     9.549999999999955 ms  ││ Interpreter args      N/A                                                      │
│ HTTP Mean Latency                                    1 ms  ││ Exec mode             fork                                                     │
│                                                            ││ Node.js version       16.13.2                                                  │
```

```
--------------------------------
Summary report @ 16:55:55(+0530)
--------------------------------

http.codes.200: .............................50005
http.request_rate: ..........................356/sec
http.requests: ..............................50005
http.response_time:
  min: ......................................0
  max: ......................................58
  median: ...................................1
  p95: ......................................12.1
  p99: ......................................22
```

<br/>
<br/>

Important stats:
```
event-loop-latency:
p95                     2.29 ms
current                 0.17 ms

http.response_time:
  min: ................ 0 ms
  max: ................ 58 ms
  median: ............. 1 ms
  p95: ................ 12.1 ms
  p99: ................ 22 ms
```


<br/>
<br/>
<br/>

### Comparison
<br/>

![HTTP performance: Latency in ms](/assets/article_images/httperf.png)

<br/>
<br/>
<br/>

![Eventloop performance: Latency in ms](/assets/article_images/eventlooperf.png)

<br/>
<br/>
<br/>

### Conclusion
<br/>
We see a tremendous performance increase, especially in p95 and p99 cases. We successfully modified our app such that not only is it faster on average, but the users facing hiccups aren't far by a huge margin. This ~2-3x increase in performance tells a lot about where node shines and where it shouldn't be used.

This ability to create native addons has huge implications for JS projects. Imagine you have your entire stack in typescript and all the engineers well versed with TS/JS ecosystem, but you finally hit the limit. Now you can rewrite and retrain, or you can simply create a fast, low surface area library which anyone can plug and play as easily as downloading it from npm.

All in all, it's looking good for NodeJS with projects like neon and languages like Rust. Given that NodeJS democratized server side development, it has been fascinating to see how the pitfalls have been plugged over the years.

We now have typescript to instill confidence and now wasm and ffi backed by reliable, safe and blazing fast languages. It's fair to say, NodeJS now has almost everything for everyone.

