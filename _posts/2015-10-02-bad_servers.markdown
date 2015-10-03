---
layout: post
title: On actor approach to socket programming
date: 2015-10-02 22:53:55
categories: akka socket
image: /assets/article_images/2015-10-02-bad_servers/mailbox.jpg
---

</br>
</br>

While working on [Grid](http://amethystlabs.org/grid) I have faced hell lot of errors.
Some related to skia, some related to json parsing and hell f****** lot about
`ENETUNREACH (Network is unreachable)`. There are two mistakes I made, first one is small,
with almost no impact on performance, the other one is a glorious blunder caused
by utter ignorance. I will start with the little one.

Grid's networking part uses Akka actors to host TCP servers, the actors look something
like this:

{% highlight scala %}
def receive = {
		case Grid.host =>
			port = 7961
			startServer()
			val temp = inStream.readUTF()
			println(temp)
			inData =
					if (temp == inData)
						temp + " <3"
					else
						temp

			self ! Grid.host
			
		case (todo: (String => Unit), onMainThread: Boolean) =>
			if (onMainThread)
				incomingMessage
						.observeOn(JavaConversions.javaSchedulerToScalaScheduler(AndroidSchedulers.mainThread()))
						.subscribe(todo)
			else
				incomingMessage
						.subscribe(todo)
		case _ =>
	}
{% endhighlight %}

Nothing fancy here, just an actor which can react to a string and a function. When
the actor receives a string "host" it kickstarts a TCP server through the startServer() call.
Firstly, notice that the actor is designed
to respond to two messages(string and anonymous function), what happens when the actor receives
"host" and then an anonymous function? Well, it starts a TCP server and waits for someone to connect to it.
Waits, that's what the actor does. And what happens to the second message?, it waits too. The result is
that the actor fails to respond to messages in time, the thread blocking code prevents it from doing that.
"Okayy, so put the thread blocking code in a new thread, what's the fuss?", you might say, but that is
not what actors are. Firstly, blocking io must be avoided in an actor. Secondly and most
importantly, actors use forkJoinPool to execute the messages, if the threads run low, new ones are spawned.
So, here is what is happening here, I have multiple actors doing blocking io which results in
an equal number of threads being spawned, no work stealing works here, no performance boost of forkJoinPool
is seen. Hence, I get nothing out of the actor approach. Normal Threads would have worked easily and would
have needed less boilerplate.

And now we come to the second part(_feels like an idiot_). Okay so you saw that the actor starts a TCP server
through a startServer() call. Under the hood, it does this:

{% highlight scala %}
def startServer() = {
		stopServer()
		serverSocket = new ServerSocket(port)
		server = serverSocket.accept()
		inStream = new DataInputStream(server.getInputStream)
		outStream = new DataOutputStream(server.getOutputStream)
	}
{% endhighlight %}

Lines:

1. Okay stopping the server if already started
2. What in the world were you thinking?

Didn't get it? Okay, here is the deal. If google had these lines then whenever someone
searched something and then finally quit the browser, the main server would go full down
and would restart, everytime, *Everytime, Reboot*. This is how it happens in my code.
The actor receives a "host" message and in turn it starts a server, the client connects and
finally leaves, and now the actor sends a "host" message to itself, which in turn calls the startServer().
And startServer() closes the socket and then makes a new one, everytime. Hence, whenever a client disconnects
a totally new server is created, and in the mean time if anyone tries to connect, well the server is just isn't
there so `connect failed: ENETUNREACH (Network is unreachable)`.

After years of research and an expedition to amazon, I found the solution. [Rx](http://reactivex.io/), the close to holy
grail of concurrency. Please do read about it if you haven't heard of it. The solution is something like this.
The `io.streamer.Server` class, takes 2 parameters, a port number, and a function. The `start()` method creates a thread which listens for incoming client connections, and returns an Observable which emits the result of the function you passed to `start()`. That function must take one argument of Socket type. Again, code will explain better:

{% highlight scala %}
import java.io.{DataInputStream,DataOutputStream}
import scala.concurrent.ExecutionContext.Implicits.global
import io.streamer.Server
import io.streamer.Client

object Io extends App {
  new Server(9000, {
      socket =>
        val inputStream = new DataInputStream(socket.getInputStream)
        val inData = inputStream.readLine
        inputStream.close
        socket.close
        inData

      }
  ).start() foreach println
}  
{% endhighlight %}

And this is how it works. A server is started on the specified port, on every connection
a new thread is spawned whis executes the function you passed as the second parameter.
The thread that was spawned earlier for a new connection is actually an observable, which
emits the result of the second parameter, the function you passed. In the code above, the passed function
is of type `socket=>String` which means it takes a socket connection and returns a String.
In our case, the returned string is the message sent by client. The final scene looks like this,
you get an observable server which can emit whatever you want. I am yet to modify the code in Grid
but I think it will work nicely. These servers are fault tolerant, so even if a connection crashes, because of server side or client side, the server remains intact.
Check out the source [here](https://github.com/iostreamer-X/io).
