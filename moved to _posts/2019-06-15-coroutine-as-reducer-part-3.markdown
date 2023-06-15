---
layout: post
title:  "Fun with JavaScript Proxies"
date:   2019-06-15 02:02:25
categories: javascript
---

No more 'Cannot set property of undefined'

____


A proxy, as the name suggests, acts as an interceptor to an object. Every property one accesses, every property one sets, every operation, goes through the proxy.

Here are some articles to get you to speed on proxies:

- [https://ponyfoo.com/articles/es6-proxies-in-depth](https://ponyfoo.com/articles/es6-proxies-in-depth)
- [https://ponyfoo.com/articles/more-es6-proxy-traps-in-depth](https://ponyfoo.com/articles/more-es6-proxy-traps-in-depth)

Now that we have some idea of using proxies, we can try to solve this problem which came up while implementing our multitenant architecture at Shipsy.

Let’s say we have an empty object `x = {}` and for some reason we want to do `x.y.z = 23;` and not just `x.y.z` we want to do add keys and subkeys, infintely to `x`. So, `x.y.z = 23` and `x.y.z.a.i.v.b.n.s = 99` should not throw an error but rather should create the following objects respectively:

```js
x = {
  y: {
    z: 23
  }
}
```

and

```js
x = {
  y: {
    z: {
      a: {
        i: {
          v: {
            b: {
              n: {
                s: 99
              }
            }
          }
        }
      }
    }
  }
}
```

Problem is, if we were to do `x.y.z = 23` on `x = {}`, we’d be trying to access property `z` assuming `y` exists on `x`, but actually it doesn’t, all we have in `x` is `{}`.

But what if our `x` was smart, so much so, that if we tried to access a property which doesn’t exist, it will create that property on the fly and our code won’t even know!

What if we intercepted every property access call on `x`, checked if the property actually exists, if it doesn’t, initialize it with empty object and then go about our usual business?!

So, doing `x.y.z = 23` will first create `y` on `x` and then will set `z`

And this is where proxies shine, we could do this magic with a simple proxy like this:
```js
function getUndefinedHandlerProxy() {
    const undefinedHandlerProxy =  new Proxy({}, {
        get(target, key) {
            if (target[key] === undefined) {
                target[key] = {};
            }
            return target[key];
        },
    });
    return undefinedHandlerProxy;
}
```

The first argument to `new Proxy($1, $2)` is basically `x`, or the object we want a layer on, the object we want to intercept. The second argument is our handler, a collection of traps and interceptors. 

Here, we decided to intercept property access calls using `get` trap. As we planned before, we will check if the property(or key in this case) exists on our object(called target here). This is done using the line `if (target[key] === undefined)` and if it doesn’t, we return an empty object, like we planned.

Let’s see how this helps us solve our problem:
```js
const x = getUndefinedHandlerProxy();
x.y.z = 23;
console.log(x.y.z);
```

Our `x` is a proxy now, `x.y.z` was performed on our proxy, which caught us when 
we tried to access `y`. It checked if `y` existed, and since it did not, `x.y` returned an empty object, after which, `z` was simply set on that returned empty object!

One little problem though, what if we had  `x = getUndefinedHandlerProxy();` and did `x.y.z.a = 78`? 
Since `x` is proxy, `y` would be automatically created as a blank object. But since `y` is simple plebian,
accessesing `y.z.a` would be problematic, as `z` doesn’t actually exist, so, we’d be setting `a`
on `undefined`, and now we are back to our original problem. We need `y` to be as smart as `x` and not a simple object, same goes for all the sub properties that get created. What if `y` was actually a proxy, just like `x`?

We could do that by changing our proxy a bit, rather than doing `target[key] = {}`, we could do
`target[key] = getUndefinedHandlerProxy()`. 

And now our final code would be:
```js
function getUndefinedHandlerProxy() {
    const undefinedHandlerProxy =  new Proxy({}, {
        get(target, key) {
            if (target[key] === undefined) {
                target[key] = getUndefinedHandlerProxy({});
            }
            return target[key];
        },
    });
    return undefinedHandlerProxy;
}
```

And this, handles **everything**.

One last caveat though, our proxy would always create an object when we try to access a property and it doesn’t exist. Now, what if we wanted to check if a property exists or not, which is a very common scenario in day to day javascript. 

Doing:
```js
if(ourSpecialProxy.a && ourSpecialProxy.a.x) {
  // Some special code
}
```
would not work as intended, the condition will **always** return true.

One way to avoid this, is not checking property existence directly, we need to check if the property is an actual object/string/number. Or if the property is anything but a proxy. 

For this, we have:
```js
function getActualValueFromUndefinedhandlerProxy(target, key) {
    if (util.types.isProxy(target[key])) {
        return undefined;
    }
    return target[key];
}
```

It’s a simple function which takes a target and key, if `targey[key]` is proxy, then the whole thing is a facade, it returns `undefined`. If not, then `target[key]` is returned. 

And that’s it, we achieved what we set out to. 

*No more 'Cannot set property of undefined'!*