---
layout: post
title:  "ElementaryOS on Dell i7559"
date:   2016-09-17 02:02:25
categories: CHIP
image: /assets/images/i75590.jpg
---

It's pretty fucking easy if you don't fuck up like me. So I won't be telling what to do(Ok I will),
but rather what not to do!

Story
=======

But before that let me tell you briefly why I think this is not the universe I started with. It was a sunday, 28th August.
My parents were going out and I reminded them to get my watch fixed. When they returned I got my watch, fixed and with a new leather strap.
With that I also received my new laptop. Now, you have to know that, yes, a new laptop was due and yes, I had mentioned that I wanted a Dell, BUT my parents don't give me surprises because I don't let them. So, there you go. I am probably with a new set of parents in a different universe. A normal surprise would have been fine, but a new laptop which is kind of costly after the import surcharge and all? Unbelievable!

Background
==========

My whole work depends on using a Linux environment. I tried my luck with Elementary(Freya), it booted but WiFi did not work, at all.
Now, I could have gone ahead and installed and then later would have searched for some fix, but I didn't and tried Ubuntu 16.04.
That did not even boot. A quick search revealed that the Skylake architecture(in i7559) is supported by the new Linux 4.4 only. And that is insane,
because Freya doesn't even have 4.4 but Ubuntu 16.04 does, and the former booted when it shouldn't have and the latter did not.

So, I gave up. Pimped up my laptop with more RAM and SSD, and started using bash on windows, which is actually pretty nifty.

And then it happened, Elementary Loki was launched, based on 16.04 and the newest kernel, I knew I had to get it.

Actual meat
=============

And now, finally after all that detour above, here is how you do and don't do it.

Assuming you have a live disk, boot your system with it. In my case, I got that grub screen, and I chose "Try Elementary". And then all it did was flash the Elementary logo.It just won't go beyond that. BUT, before that screen, some errors related to noveau and graphics flashed. It was my kernel saying that
the driver for you video card derped. What I needed to do is tell kernel was that, no need to initialize video drivers till X server starts(Basically, let me boot and then do your driver thingy).

And here is how you do that. Close your laptop, hard shutdown, then get to that GRUB screen. Press 'e' to edit the config. Next, you will see
some config options and kernel parameters. There would a line starting with 'linux', at the end of the line add 'nomodeset', and then press F10 to boot.

This time it will boot but boy will it look bad. Probably 800*600 res. Well, there you go, install Elementary onto that free space or using any other method. When installed, that _not booting up_ problem would be there again, but now you know how to handle it. After the actual boot from your hdd, the visuals won't be bad, but would be slow and transitions would stutter. Simply install nvidia drivers. Here is the easy 16.04 way of doing that.

`sudo ubuntu-drivers autoinstall`

Make sure you can pull from xenial repos. If not, then do this:

{%  highlight bash %}
sudo apt-add-repository "deb http://archive.canonical.com/ubuntu/ xenial partner"
sudo apt-get update && sudo apt-get upgrade
{%  endhighlight %}


But wait! I mentioned that I messed up somewhere. Well, I pimped up my laptop. Nothing bad about that, except that when the new ssd was installed, my internal hdd
was converted to dynamic disk from basic disk. And how does that matter? Linux doesn't work with dynamic disks. So when I reached that menu to select partitions, it
didn't even see my free space. So, all that hard work, gone to waste, sort of.

There are tools to convert a dynamic disk back to basic, but I ain't paying 40$. Windows can do it for you though, if you delete all the volumes on the disk, which means just burn everything you have. So, I ordered a WD elements(1TB), took a backup, converted my internal hdd to basic, created a new volume with some unallocated space set aside for elementary.

And then finally, finally I got that sweet juice I had been waiting for. I went from GeForce GT520MX to GTX 960M, so obviously I was expecting some(eh, a lot) of improvements in visuals, was left a bit disappointed after witnessing screen tearing, just like it used to happen in my old potato box. Google search confirmed it's a known a bug.


Anyway, ending the tutorial/guide/rant. I hope you don't pimp up before installing Linux, and also that this tutorial/guide/rant helps you.
Gotta go, dinner with new parents.
