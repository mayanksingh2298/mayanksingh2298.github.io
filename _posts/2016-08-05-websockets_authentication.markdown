---
layout: post
title:  "Websocket authentication in Node.js using JWT and WS"
date:   2016-05-08 02:02:25
categories: WS Node.JS JWT
image: /assets/images/jwt.jpg
---

Sooooo, I like backend now. Primarily because of Node.js, I love that thing.
And as you might know, this blog streams my laptop's speaker output, so using websockets was
an obvious choice. Now, I would not want someone else to take over and hence would deploy some
authentication mechanism.

The websocket library I chose to use is `ws`. And my plan is simple.

- Acquire a token from the server
- Send that token as an additional header
- On server side, receive the header, if valid, then ok but if not then fail the connection

And I got to know this really cool thing called [JWT]('https://jwt.io'). In one line, it is a
brilliant way of having stateless authentication.

And to quote them:

> JSON Web Token (JWT) is an open standard (RFC 7519) that defines a compact and self-contained way for securely transmitting information between parties as a JSON object. This information can be verified and trusted because it is digitally signed. JWTs can be signed using a secret (with the HMAC algorithm) or a public/private key pair using RSA.


Equipped with all the awesome libraries and articles the Node.js community provides, I ended up actually implementing
the plan.


JWT module for node provides all the necessary functions and the ones relevant in my case were `sign` and `verify`.

To sign an object I need a secret key and the object to sign. I can also give additional options such as after how long the token will expire. And it looks some thing like this:

{%  highlight js %}
var jwt = require('jsonwebtoken')
var token = jwt.sign({name:'iostreamer'},'secret-key',{
    expiresIn : 15 * 24 * 60 * 60 * 1000 // 15 days
})
{%  endhighlight %}

Handle tokens with care, these are **signed** using the secret key not encrypted.

Client side
===
<br/>
<br/>
Now in client land, I am supposed to have a token. Let's say I fetched it from the server. Next is to establish
a websocket connection and send this acquired token in headers' section.

And this is how we do it (*I think*) using the `ws` module. While initializing, we pass an [options] object, which
contains the token, and specifies that it should be added to the headers.

{%  highlight js %}
WebSocket = require 'ws'
ws = new WebSocket 'ws://localhost:8000',{
    headers : {
        token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiaW9zdHJlYW1lciJ9.oNx-4e9hldyATpdPZghd_sjX8DhTkQFVDBxIhKh4MC4"
    }
}
{%  endhighlight %}

Server side
===
<br/>
<br/>
The server land follows the same pattern as in the client land. While initializing, we pass an [options]
object, which has a function under the property field `verifyClient`.

`verifyClient` is provided with two arguments:

- `info` Object:
  - `origin` String: The value in the Origin header indicated by the client.
  - `req` http.ClientRequest: The client HTTP GET request.
  - `secure` Boolean: `true` if `req.connection.authorized` or `req.connection.encrypted` is set.
- `cb` Function: A callback that must be called by the user upon inspection of the `info` fields. Arguments in this callback are:
  - `result` Boolean: Whether the user accepts or not the handshake.
  - `code` Number: If `result` is `false` this field determines the HTTP error status code to be sent to the client.
  - `name` String: If `result` is `false` this field determines the HTTP reason phrase.


And this is how I did it in my code:

{%  highlight js %}
var WebSocketServer = require('ws').Server
var ws = new WebSocketServer({
    verifyClient: function (info, cb) {
        var token = info.req.headers.token
        if (!token)
            cb(false, 401, 'Unauthorized')
        else {
            jwt.verify(token, 'secret-key', function (err, decoded) {
                if (err) {
                    cb(false, 401, 'Unauthorized')
                } else {
                    info.req.user = decoded //[1]
                    cb(true)
                }
            })

        }
    }
})
{%  endhighlight %}

Since we use the middleware pattern so heavily with `express`, I tried doing the same with `ws`.
So, with [1] I make available the user as a property of `req`.

And while handling connections it is available like this:

{%  highlight js %}
ws.on('connection', (conn) => {
    var user = conn.upgradeReq.user
    conn.send('Welcome! ' + user.name)
    conn.on('message', (data) => {})
})
{%  endhighlight %}


And that is all I did today. Along with watching Big Bang Theory. 
