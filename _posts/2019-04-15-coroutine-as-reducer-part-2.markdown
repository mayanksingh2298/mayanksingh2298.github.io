---
layout: post
margin-left: 150px
title:  "Coroutines as Lazy Reducers: Part 2"
date:   2019-04-16 02:02:25
categories: abstract-tech
---

In the first part, we discussed what it means to `"reduce"` something. Although, we assumed we were iterating synchronously.
And why shouldn't we? If given any array of numbers, that is how one is supposed to iterate.

[Part 1](/abstract-tech/2019/04/15/coroutine-as-reducer-part-1.html)

____


> When I think of iteration, I imagine it as someone walking up a staircase, 
climbing the stairs, one by one, till they reach the top.
<br/>
-Part 1

In spirits of the staircase example mentioned in Part 1, what if we had some magic/mischief to our stairs? 
What if, one could only move to the next stair, if you solved a little puzzle? 

Now, you can see all the stairs
but they all look locked to you, you are at the first step, and you look at the next one, you sigh with disdain because 
who in their right mind would design a staircase like this, you solve the puzzle, and immediately the next step is accesible,
you step up and continue this cycle.

Now, I know this magical staircase sounds vague and nutty, 
<br/>
**but this is exactly what coroutines are!**

Let's take the example of bluebird's way of using a coroutine
{%  highlight js %}
const Promise = require('bluebird');

function someAsyncFunction() {
    // some long running task
    return Promise.resolve(Math.random());
}

function someOtherAsyncFunction(seed) {
    // some long running task
    return Promise.resolve(Math.random() + 200*seed);
}

// Seems like Promise.coroutine takes a single argument, a generator function.
Promise.coroutine(function* () {
    // And then as all coroutines go, each line is executed synchronously
    
     // synchronous call
    const result1 = yield someAsyncFunction();
     // synchronous call, this won't be called till the line above completes
    const result2 = yield someOtherAsyncFunction(result1);

    console.log(result1, result2);
})();
{%  endhighlight %}

So, you can see how coroutines come handy when writing async code. No more writing long promise chains!

If we had to build a coroutine library of our own, the simplest and most naive way would have been
to iterate the generator function, assemble all the promises in an array, and then do some operations.

There's a catch though, because each promise requires the result of its previous promise's result. For example:

{%  highlight js %}
function* () {
    const result1 = yield someAsyncFunction();
    
    // To execute the next statement, 
    // we need the result of previous statement
    const result2 = yield someOtherAsyncFunction(result1);

    console.log(result1, result2);
}
{%  endhighlight %}

So assembling into an array isn't exactly possible because of this backward dependency.
But here's what we can do:

- Iterate the generator function lazily/recursively
- With each iteration, receive the promise that needs to be `yield`ed
- Execute that promise
- Start next iteration with previous one's result
- Stop when nothing left to iterate
- Return last iteration's result

Here's how it looks in code:

{%  highlight js %}
function _executor(iterator, result) {
    
    // Iterate and receive the promise
    // Start next iteration with previous one's result
    const { value: promiseOrValue, done } = iterator.next(result);
    
    // Stop when nothing to iterate and return result
    if (done) {
        return Promise.resolve(promiseOrValue);
    }
    
    // Execute yielded promise
    return promiseOrValue.then(
        // Recursive call, turns this into a lazy function
        result => _executor(iterator, result)
    );

}
{%  endhighlight %}


Drawing Parallels
===
<br>
As discussed in [Part 1](/abstract-tech/2019/04/15/coroutine-as-reducer-part-1.html),
reduction is all about iteration and mutation.

Aforementioned snippet can be visualized as below:
{%  highlight js %}
+-------+
|       |
|  P1   +-----------+
|       |           |
+-------+           |
                  +-v-+
                  |   |
                  +-+-+
+-------+           |
|       +<----------+
|  P2   |
|       +-----------+
+-------+           |
                  +-v-+
                  |   |
                  +-+-+
+-------+           |
|       |           |
|  P3   +<----------+
|       |
+-------+

{%  endhighlight %}

Here, we are iterating lazily over a collection of promises. At the same time, we are maintaining a bucket.
Each promise(`P1`) puts its result in the bucket, and passes the bucket to the next promise(`P2`). Then the next promise(`P2`)
takes out the contents of the bucket, uses them and the puts its own result in the bucket. And the cycle continues, 
till all the promises have been covered. 

And now we can see clearly, **`iteration`** and **`mutation`**. In our case, we are iterating through recursion. And we too, have a bucket
which we mutate after each iteration.

{%  highlight js %}
// Here, `result` is our bucket
function _executor(iterator, result) {
    // Contents of the bucket `result` being used
    const { value: promiseOrValue, done } = iterator.next(result);
    
    if (done) {
        return Promise.resolve(promiseOrValue);
    }
    
    return promiseOrValue.then(
        // Iteration though recursion
        // Bucket being flushed, and a new bucket being passed(Mutation)
        result => _executor(iterator, result)
    );

}

// It's simply a wrapper which provides some basic functionalities
// like, receiving and forwarding params, extracting an iterator from given generator
function co(generator) {
    return function executor(params) {
        const iterator = generator(params);
        return _executor(iterator);
    }
}
{%  endhighlight %}


________________________________________________________________

`Reduce` has always baffled beginners. I believe because it's such an abstract concept, but that's exactly
what gives it so much power. While learning and programming, you'd come across complicated patterns but with a keen eye
you'd be able to see that it's nothing but a specific way of implementing a general or abstract concept.

Such is the case with `coroutines` too. You'd think, maybe expect it to be something complicated. Whereas in reality, it's 
a nice little reducer.

So go ahead, venture into the land of code and you just might encounter a `reducer` in wild.