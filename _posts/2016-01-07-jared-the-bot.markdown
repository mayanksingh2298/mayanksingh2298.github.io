---
layout: post
title: Bots taking over
date: 2016-01-07 02:18:01
categories: Bots
image: /assets/article_images/jared-header.png
---

>Bot: Why would you want to be something more than a machine?

>Me: Because I choose to

>Bot: Why do you choose to exist?

>Me: Because I can


#Build a slack bot and deploy on heroku

There has been an awakening. Bots, slack bots have taken over and they are everywhere.

If you use slack you know what I am talking about. Automation, integrations and bots, these
are the things which MAKE slack. And recently I was in need of one. I named it jared(silicon valley).
I tell jared who is supposed to do what along with the deadlines, and it does the rest. Jared will message
you a day before deadline if the task is still pending, he will post on channel your task status, and will ask
you "Why do you choose to exist?". Its a pretty basic bot which does what it's told but while making
it I learned about

1. node library of Slack
2. Use mongodb on heroku without shelling out anything
3. A few heroku specific hacks for bots
4. Do a `git init` before `heroku create`


#Step by step

The first thing I did was to just start right away. To build a bot you have to have an
access token. So just go [here](https://slack.com/apps/build) and choose 'Make a custom integration'.
Choose 'Bots' on the next screen and after that you know the drill.


![The drill](/assets/article_images/new-bot.png)

Once I acquired the token, I ran straight for a reliable node library for slack bots.
And found [this](https://github.com/slackhq/node-slack-client). This library is I guess
the de facto of making bots and in case its not then it should be. The lack of documentation
worried me a little but just looking around and reading the source as well as the sample
code in 'examples' made things quite clear.

###My notes on using the library

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



Next problem I faced was with `heroku create`(actually it was my fault). I didn't initialize my project with
git. So `git push heroku master` was pretty useless. Bottom line, do a git init first and then start working on
your app.


Moving on.( Will complete tomorrow, feeling sleepy)
