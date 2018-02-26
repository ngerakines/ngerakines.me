---
layout: post
title: Do One Thing
date: 2012-08-27T09:00:00-00:00
---

In [Clean Code by Robert C. Martin][1], one of the messages that is repeated again and again is that classes and methods should do one thing and one thing only. Some of you may know this as the Single Responsibility Principle which was first used by the same author in the book Agile Software Development. Others may recognize this from the informal name bestowed by Coding Horror as "Curly's Law".

Most of the time, methods have two roles: transform and notify. When a method is changing the state of an object, performing IO operations or processing some piece of data, it is playing the part of a transformer. When a method is retrieving information and returning it or setting an alarm that an event has occurred, it is playing the part of a notifier.

This rule simply states that functions and methods should only do one or the other, never both. Going further with the idea, not only should functions never have both roles, when it picks a role it should do only the simplest form of a single action. If a method accepts a parameter and sets an object variable as well as returns a flag, it would be in violation of this rule.

There are a lot of times when we, as engineers, decide that a shortcut can be made and a piece of functionality can be shoveled into an existing method. While it may seem like a quick and easy solution at the time, it dilutes the intent of the method making it more difficult for others understand. Violating this rule is what leads us to have massive functions that have many (and often misleading) entry and exit points that are often error prone.

How can this rule be applied? Very easily. When writing code and viewing existing code, when you encounter a method simply ask yourself "What does this do?" and if at any point you can't answer it simply or find yourself saying "well, and this, and that" then the method needs to be simplified. Some static code analyzers can help find "hot" areas of code where it may be more severe by looking at the depth of a method (how many conditionals, branches, try/catch blocks, etc).

References:

*   [http://en.wikipedia.org/wiki/Single\_responsibility\_principle][2]
*   <http://www.codinghorror.com/blog/2007/03/curlys-law-do-one-thing.html>

 [1]: http://www.amazon.com/gp/product/0132350882/ref=as_li_ss_tl?ie=UTF8&camp=1789&creative=390957&creativeASIN=0132350882&linkCode=as2&tag=socklabs-20
 [2]: http://en.wikipedia.org/wiki/Single%5C_responsibility%5C_principle
