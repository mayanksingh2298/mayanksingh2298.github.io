---
layout: post
title: Observable anything with Scala.Rx
date: 2016-02-29 01:44:01
categories: Scala
image: /assets/article_images/frp.png
---
<br/>
<br/>
<br/>
The functional reactive programming course on coursera got me pretty excited for the
FRP paradigm and it felt like it is the only sensible way of doing things.

I looked at my code of Grid and there was this really ugly block which took a variable, and
polled it every 0.5 seconds to check if anything changed, and published the change
if it occurred. Here's the code(don't judge please):

```scala
def watchVariable[A](check: => A) = {
		Observable[(A, A)](
			observer => {
				var initial = check
				newThread {
					while (true) {
						val current = check
						if (current != null)
							if (!current.equals(initial)) {
								observer.onNext((initial, current))
								initial = check
							}
						Thread.sleep(500)
					}
				}
			}
		)
	}

```
<br/>
This might look stupid, inefficient or bug prone but at the time of writing code,
Scala.Rx just slipped out of mind. It is a well documented and really awesome FRP
library for Scala. And if you are thinking what FRP is then I would recommend the coursera
videos if you want to have a deep understanding of everything and if you want a brief intro
then head [here](http://stackoverflow.com/questions/1028250/what-is-functional-reactive-programming).


Coming to the point, I wanted to fix that `watchVariable` design pattern, and decided to
use [Scala.Rx](https://github.com/lihaoyi/scala.rx) to do that. So, I wanted an ObservableMap(now deprecated in scala) kinda thing where
anything added to it notifies me, and I also did not want to change the existing way of using
the map like `map+=(k->v)`, because I have done that almost everywhere and I wanted the map to be
thread safe and I wanted it to fix the world.


Luckily I stumbled upon [this](http://docs.scala-lang.org/overviews/collections/maps.html) page. Go straight for **Synchronized Sets and Maps** and you will see everything we need to have. It was like you wanted an answer of a sorta tough
question from assignment and it was just there, on yahoo answers, solved by some nerd. So here's the plan,
we will use a SynchronizedHashMap(so I can haz thread safety), override the `+=` function(so that I don't have
to change any current code) and use Scala.rx to watch changes. And here's the code in all its glory:

```scala
import rx._
import scala.collection.mutable.{Map,
    SynchronizedMap, HashMap}

object Scala_rx_tut extends App {
  def makeMap(watch:Var[(String,String)]):Map[String, String] = {
    new HashMap[String, String] with
    SynchronizedMap[String, String] {
      override def +=(kv: (String,String)) ={
        val res=super.+=(kv)
        watch()=kv
        res
      }
    }
  }

  val watch=Var("bill"->"cipher")
  val map = makeMap(watch)
  watch.trigger{
    println(watch.now)
  }
  val arr=Array(("I"->"want"),("season"->"3"),("right"->"now"))
  0 to 2 foreach{
    i=>
      map+=arr(i)
  }
}

```  
<br/>
The makeMap function takes a Var argument which is basically the thing which will let us know
if a new value is being added. The Var is special variable which has a callback which is fired when
the value of the variable changes. We then use a HashMap as our base Map implementation, which then is mixed
with SynchronizedMap to provide, thread safety. The override, then changes the Var argument which in turn fires its callback. And then finally everything comes together beautifully like an orchestra. No more of that old dirty
polling function, **AND** I don't have to change any existing code. So, in my opinion this was rad because I got
exactly what I planned on having. I plan on learning more of FRP and get better at it, so expect more cool
stuff!
