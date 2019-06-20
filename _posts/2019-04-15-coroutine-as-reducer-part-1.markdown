---
layout: post
title:  "Coroutines as Lazy Reducers: Part 1"
date:   2019-04-15 02:02:25
categories: abstract-tech
---

 > To reduce, is to iterate and mutate.
<br/>- me

**PART 1/2**

Part 2 is [here](/abstract-tech/2019/04/16/coroutine-as-reducer-part-2.html)

______

Lazy reducers huh? Like the normal ones weren't complicated enough?

Well, they are, so before starting with coroutines and what not, let's try to understand what does
it mean to `"reduce"`?

Iteration
-
<br/>
When I think of iteration, I imagine it as someone walking up a staircase, 
climbing the stairs, one by one, till they reach the top.

It could be broken down as a 2 step cyclic process:
- Notice the stair ahead
- Step up

As programmers, we have been iterating since we started learning programming.
And just like above, it has always been a two step cyclic process:
- Ask for next element
- Act

This is as rudimentary as iteration can get when involving arrays:
{%  highlight js %}
const array = [1,2,3,4];

for(let i = 0; i < array.length; i++ /*Ask for next element*/) {
    console.log(array[i]); /*Act*/
}
{%  endhighlight %}


A more common approach these days:
{%  highlight js %}
const array = [1,2,3,4];

/*Here, asking for next element part is abstracted*/
array.forEach(element => console.log(element)/*Act*/)
{%  endhighlight %}


This is how hipsters iterate in javascript:
{%  highlight js %}
const iterator = [1,2,3,4][Symbol.iterator]();

while(!(result = iterator.next()).done /*Ask for next element*/) {
    console.log(result.value); /*Act*/
}
{%  endhighlight %}


Mutation
- 
<br/>
We discussed how iteration has two parts:
- Demand next element
- Consume element

What if, we maintained an entity and as our second step(consume element), we mutated that entity? This would mean that,
after each cycle/iteration we would change our entity.

Example:
{%  highlight js %}
const array = [65, 66, 67, 68];
const entity = {}; /*Our entity*/

for(let i = 0; i < array.length; i++ /*Ask for next element*/) {
    entity[array[i]] = String.fromCharCode(array[i]); /*Mutation*/
}

// Result: { '65': 'A', '66': 'B', '67': 'C', '68': 'D' }
{%  endhighlight %}

**Each mutation is caused by iteration and affected by the data we iterated over.**

In the example above, each mutation happened inside the loop, that is, after each iteration.
And the mutation used the data it iterated over to create ASCII representations.

Does this look weird to you? A bit verbose? Feel like we could solve it with something in-built? Somethink basic?
Something like **reduce**?

{%  highlight js %}
const array = [65, 66, 67, 68];
const entity = {}; /*Our entity*/

const result = array.reduce(
    /*Abstracted iteration part*/
    (entity, currentData) => {
        /*Mutation*/
        entity[currentData] = String.fromCharCode(currentData);
        return entity;
    },
    entity
)

// Result: { '65': 'A', '66': 'B', '67': 'C', '68': 'D' }
{%  endhighlight %}

Reducers
-
<br/>
The concept of "`reduce`", as stated before, is to maintain an entity, iterate over a collection and mutate that entity for each iteration, that's all.
Now, this mutation could affect our entity in any way we want, in fact we can choose our entity to be anything we want.

This freedom allows us to imagine concepts like `"map"` and "`filter`", where each such concept can be achived by choosing our entity as an empty array,
and by mutating appropriately.

{%  highlight js %}
    Collection
       +---+
+----> |   |   Mutation         +-+ Entity
       +---+------------------->+-+
       +---+
       |   |
       +---+
       +---+
       |   |
       +---+

{%  endhighlight %}

{%  highlight js %}
    Collection
       +---+
       |   |
       +---+
       +---+                   +---+
+----> |   |  Mutation         |   |Entity
       +---+------------------>+---+
       +---+
       |   |
       +---+

{%  endhighlight %}

{%  highlight js %}
    Collection
       +---+
       |   |
       +---+
       +---+
       |   |
       +---+                   +-----+
       +---+  Mutation         |     | Entity
+----> |   +------------------>+     |
       +---+                   +-----+

{%  endhighlight %}
______

In the next part, we will learn what a lazy reducer is and how a coroutine can be imagined as one.

[Part 2](/abstract-tech/2019/04/16/coroutine-as-reducer-part-2.html)
