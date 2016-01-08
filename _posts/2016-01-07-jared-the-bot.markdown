---
layout: post
title: Slack bots taking over
date: 2016-01-07 02:18:01
categories: Bots
image: /assets/article_images/jared-header.png
---

>Bot: Why would you want to be something more than a machine?

>Me: Because I choose to

>Bot: Why do you choose to exist?

>Me: Because I can


#Build a slack bot and deploy on heroku
<br/>
There has been an awakening. Bots, slack bots have taken over and they are everywhere.

If you use slack you know what I am talking about. Automation, integrations and bots, these
are the things which MAKE slack. And recently I was in need of one. I named it jared(silicon valley).
I tell jared who is supposed to do what along with the deadlines, and it does the rest. Jared will message
you after every 4 days if the task is still pending, he will post on channel your task status, and will ask
you "Why do you choose to exist?". Its a pretty basic bot which does what it's told but while making
it I learned about

1. node library of Slack
2. Use mongodb on heroku without shelling out anything
3. A few heroku specific hacks for bots
4. Do a `git init` before `heroku create`


#Step by step
<br/>
###Get the token
<br/>
The first thing I did was to just start right away. To build a bot you have to have an
access token. So just go [here](https://slack.com/apps/build) and choose 'Make a custom integration'.
Choose 'Bots' on the next screen and after that you know the drill.


![The drill](/assets/article_images/new-bot.png)


###Get the library
<br/>
Once I acquired the token, I ran straight for a reliable node library for slack bots.
And found [this](https://github.com/slackhq/node-slack-client). This library is I guess
the de facto for making bots and in case its not then it should be. The lack of documentation
worried me a little but just looking around and reading the source as well as the sample
code in 'examples' made things quite clear.

####My notes on using the library
<br/>
`slack = new Slack(token, true, true)`
The slack variable is your window to the slack world of yours. It has three main events

1. open
2. message
3. error

`message` being the most important one. This event will be fired whenever your bot receives a message.
Your bot receives a message when people directly contact it or when people post to a channel/group the bot
is part of.

`slack.on 'message', (message) ->`
The message object tells you important details such as the source channel and the user who sent it.

`slack.getDMByName ($name)` returns an instance of channel. And you can use this channel to send a message
like this `channel.send "Hi"`. Same is the case with `slack.getChannelByName ($name)`, `slack.getGroupByName ($name)`.

[This](https://github.com/slackhq/node-slack-client/blob/master/examples/simple_reverse.coffee) will make it more clear. Actually just use this as a template.



###Start with heroku deployment
<br/>
Next problem I faced was with `heroku create`(actually it was my fault). I didn't initialize my project with
git. So `git push heroku master` was pretty useless. Bottom line, do a git init first and then start working on
your app.

Signup on heroku if you have't and read their 'getting-started-with-nodejs'. Their [notes](https://devcenter.heroku.com/articles/getting-started-with-nodejs) are perfect
and cover everything that is needed.

###Heroku slack bot problems
<br/>
The first time deployed the app, it crashed after a minute. The error was "*Web process failed to bind to $PORT within 60 seconds of launch*". Quick google search revealed that heroku assigns a dynamic port to your app and tries to bind to it. Since all I had was a slack bot so there was no server in my code. I wasn't listening to any connections.

Lets say if I had been listening, then there is this [dyno sleeping](https://devcenter.heroku.com/articles/dyno-sleeping) rule they have, that would have made my bot pretty much useless(I have a free plan and I hardly pay for anything, except Apple Music. I'd pay for that).

>If an app has a web dyno, and that web dyno receives no traffic in a 30 minute period, the web dyno will sleep. In addition to the web dyno sleeping, the worker dyno (if present) will also sleep.

>If a sleeping web dyno receives web traffic, it will become active again after a very short delay. If the app has a worker dyno that was scaled up before sleeping, it will be scaled up again too.

And interacting with the bot or sending it messages doesn't count as traffic. So no matter what, your bot will go
down after 30 minutes.

###Killing 3 agents with one Matrix style punch.
<br/>
**Agent 1**: "*Web process failed to bind to $PORT within 60 seconds of launch*"

**Agent 2**: Bot dies after 30 minutes

**Agent 3**: I need a clock in my code. I need to check pending tasks regularly and check their status.

**Matrix style punch**: Get a server in your code and ping it after every 25 minutes.

```javascript
http = require 'http'
request = require 'request'


strobe = ()->
  request 'https://random.herokuapp.com/', (e,r,b)->

slack.on 'open', ->
  setInterval strobe, 25*60*1000
  console.log "I am up!!"

handle = (req, res) -> res.end "42"
server = http.createServer handle
server.listen process.env.PORT || 5000

```

**Killing Agent 1**: Since you have a server running on `process.env.PORT`(the port heroku assingned to your app),
heroku is able to bind to it. Agent killed.


**Killing Agent 2**: The `strobe` function is called every 25 minutes  because of `setInterval strobe, 25*60*1000`.
And `strobe` in turn requests your app through its url. So your app can never be idle for 30 minutes, it will always receive some traffic(one request at least) before the timer runs out.

**Killing Agent 3**: Added my task checking stuff in the strobe function. So everything is checked every 25 minutes.

<center>
<img src="https://38.media.tumblr.com/90cd41140226f5b4c86d511fdff03817/tumblr_n9b7k62GSz1rshw0go2_400.gif"/>
</center>
<br/>


###MongoDB on heroku
<br/>
MongoDB add on by MongoLab needs you to provide card details, just to verify. And in case you don't want
to do that, just go to monogolab's [site](https://mongolab.com/). MongoLab is MongoDB as a Service. Signup for the
free plan and you get 500MB storage. Make a database there and you'll get a URI which you can use for
remote access. It looks like this

`mongodb://<dbuser>:<dbpassword>@ds099315.mongolab.com:99315/your-db`

To use mongo in my app I chose [mongojs](https://github.com/mafintosh/mongojs). It's a really good library
and emulates the standard MongoDB API. For example:

```javascript
var mongojs = require('mongojs')
var db = mongojs('mongodb://<dbuser>:<dbpassword>@ds099315.mongolab.com:99315/your-db', ['users','clients'])

db.users.find({name: "Thomas A. Anderson"},function (err, docs) {
    // docs is an array of all the documents in users
})
```

So that was that. The bot is on heroku 24/7 doing stuff for me. It was fun and I learned coffeescript too
while making it. It's a cool flavor of node, and coming from a scala background, I could relate. I hope these tips
come handy on your next slack bot adventure.

![Stupid bot](/assets/article_images/fin.png)
