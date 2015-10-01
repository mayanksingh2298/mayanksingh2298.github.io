---
layout: post
title:  "Linux+Python=Deadly"
date:   2015-10-01 20:52:25
categories: Linux Python
image: /assets/article_images/2015-10-01-deadly-linux-python/dyna.png
---
<br/>
<br/>
<br/>
>Set the volume to 10% and increase the brightness by 30%.
How's the weather in New Delhi and play Rap God on YouTube.

I always wanted to control my laptop like that and yesterday I finally did. It was super fun to mess up, for example I said 'play as crazy as it is' and it played 'as crazy ass dance'.

I am supposed to submit a project by the end of this semester and gawd I have spent some time searching a doable project. From building an online fractal generator to a music streaming app and a few more ideas had to be shot down before zeroing down to this. Dyna is your virtual assistant for Linux and I don't claim that it can do everything but I do claim that it can make the world a better place(Silicon Valley reference).

The reason that Dyna doesn't suck is because it's powered by [Wit.ai](http://wit.ai), a facebook acquired startup which excels in language processing. The best thing about it is it's support. The service itself is nearly perfect but so is its API for various languages, which makes it easy to develop applications on top of it. I chose Python because I wanted to try it and it has been a wise decision. It is extremely easy to learn but I guess you know better since I started late.

Here's some background about wit.ai. You make your application on the site, and add some intents(stuff you want your app to understand, then you get the client token and finally you send a .wav file along with the token to the server and expect a json response telling you the extracted data. In python, you get a straightforward API. The API's function handles recording and returns the json data.

What I found amazing is the crazy control I have and in particular the os module of python. `os.sytem` is pure gold and also `os.popen.read`(stackoverflow did not recommend the use of it). Here is a sample code for extracting current volume of the system
{% highlight python %}
currentVolume = int(os.popen('amixer sget Master').read().split()[-3].split('[')[1].split('%')[0])
{% endhighlight %}

It could be 'meh' for you or 'been there done that' but for me it's freaking cool. Plus coming from an Android background, everything on linux looks like an API to me, like the `notify-osd` is similar to the Notification API in android, and I like it. And dynamic typing, boy that is new. I have done some java, C and scala and I am used to statically typed thinking, but again it's ease of use impressed me. I completed the project in one day, and all the credit goes to Wit.ai and Python, thank you for being so easy. Here's the video demo of Dyna and the [source code](https://github.com/iostreamer-X/Dyna).

<iframe width="560" height="315" src="https://www.youtube.com/embed/2Jy_rw5PW6Y" frameborder="0" allowfullscreen> </iframe>
<br/>
And yes, lastly, `exec`. It made my job a whole lot easier, actually not that much but with it I didn't have to use if/else. The idea is to extract the intent from json response, use that variable as module name directly. I guess code will explain better.

{% highlight python %}
import wit
import time
import json
import os
import thread
import hue_lightstrip
import volume
import playvideo
import search
import go_to_link
import music_control

context = 'null'
if __name__ == '__main__':
	def handle_response(response):
    		decoded = json.loads(response)
		body = decoded['_text']
		if body is not None:
			confidence = decoded['outcomes'][0]['confidence']
			intent = decoded['outcomes'][0]['intent'] #extract
			if confidence >= 0.67:
				exec(intent+'.handle(response)') #use it as module


	wit.init()

	while True:
		os.system("pkill notify-osd && notify-send Listening")
		wit.voice_query_start('O66U5BV3JAAAZ7YENBNJVHTWN2DXGZ3Z')
		time.sleep(5)
		os.system("pkill notify-osd && notify-send Processing")
		response = wit.voice_query_stop()
		try:
			thread.start_new_thread(handle_response,(response,))
		except:
			print "Dafaq"

	wit.close()
{% endhighlight %}
