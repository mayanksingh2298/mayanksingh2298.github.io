---
layout: post
title:  "Voice authentication in Linux using Android in 4 lines"
date:   2016-04-01 20:52:25
categories: Linux Bash Android
image: /assets/images/unlock.png
---

You open terminal, enter a command, it asks for password, you swipe your thumb over
the fingerprint sensor and voila, the command executes. Sounds perfect, except
I don't have a fingerprint sensor, nor do I have a phone with one. What I do have, is
a normal phone on which "Ok Google" works like a charm. So, I scribbled some code, googled
a bit and made my own voice authentication system, which sounds so wrong because I just wrote 4 lines.


My whole thought process was to use my phone's Ok google feature, which would run a script to provide the password.
In case you are wondering that the script would have the password in plain text form and that it is stupid then yes, you are right. Almost everyone I know already knows my laptop's password, plus I didn't make this to be secure, I made this because I am extremely lazy. Now, my first attempt was to use Android's Voice Recognition API which would run a callback function whenever I said "Ok google" and the function would contact my laptop through Wifi, but that plan simply did not work. But while debugging I noticed that whenever the search dialog was opened(after I said _OK Google_), the logcat reflected it through `Keeping mic open: true`. Which gave me the final plan.
Monitor logcat output and whenever that specific string comes up, emulate the keyboard events of typing the password and pressing enter. Tada!


So here are the steps I followed:

- Install some dependencies `sudo apt-get install xdotool xautomation`

- Make a script and run it, with script being
{%  highlight bash %}
while true;do
	adb logcat -c
	adb logcat | grep -q 'Keeping mic open: true' && xte "str your-passwd-in-plain-text-yes-plain-effing-text" && xte "key Return"
done
{%  endhighlight %}

- Connect my phone and allow USB debugging.

- Write a stupid command which asks for sudo access and then say _Ok Google_ and then watch it work perfectly.

- Cry a bit because it worked and it was so easy.

Script explained
==
<br/>

- `adb logcat -c` clears the logcat output. If I don't clear it then the magic string `Keeping mic open: true` will always be present which is problematic.

- `grep -q [text] [file or stdin] && command` is a pattern which executes the **command** when **text** is found in **file or stdin**.

- `xte "str [text]"` is the real deal. It generates fake input **text** and `xte "key [key]"` fakes **key** presses.
