---
layout: post
title: How I Interview
---

At Blizzard I had a reputation for being tough during interviews. I was the guy who would ask for additional time with a candidate and could easily spend 2 to 3 hours with someone. I don't claim to be perfect at it, but I do have a system that I think works and works pretty well for interviewing people for technical positions. Coniser this blog post version 1.0.0 of Nick's Technical Interview Guide.

## Before You Begin

Interviewing someone for a technical position is complicated and goes well beyond technical prowress and know-how. Candidate expectations, company expectations, company and team culture, communication ability, technical ability and personality are all factors that should be carefully evaluated. This document focuses on technical ability and how to determine what you are looking for and if a given candidate is a good fit.

## The Holy Trinity

There are three things that factor into gauging the technical ability of a canidate:

1. Fundamentals / Computer Science Knowledge
2. Tools / Software / Libraries
3. Domain Knowledge / Language

The first point, fundamentals, is the depth and bredth of knowledge that can be applied to any langauge or domain. This includes knowing object-oriented design, threading and concurrency techniques and models, data structures and algorithms, architectural patterns, etc.

The second point, tools-software-libraries, is really about specific application, toolkit and library knowledge and usage. An example would be knowing details about selenium or vagrant but also extends to more domain/language specific things like Spring or Tomcat.

The third point, domain and language knowledge, is how well the candidate understands and is able to apply knowledge about the field they work in and languages used to the day to day tasks of the position. An example would be, as a Java SWE, understanding and having experience with generics or as a front-end engineer, understanding javascript class implementations and quirks.

## Holy Trinity Balance

In my experience, you can't and shouldn't expect a candidate to have an even amount of knowledge and experience in each of the three categories. Different positions require a different amount of each and you'll probably have different needs depending on the team that the candidate will be in.

Consider the following positions to be filled.

QA Engineer: Expectations include working with software engineers and developer support teams to test and exercise an application before deployment.

Software Engineer, Application: Expectations include implementing features for and maintaining a codebase for a user facing application.

Software Engineer, Platform: Expectations include implementing services, libraries and applications used by other software engneering teams that may be distributed, multi-region and data heavy.

Software Engineer, DevOps: Expectations include working with software engineering teams to support the development, deployment and management of the applications and libraries developed.

Based on the descriptions of the above positions, you can start to see how the balance of technical ability can vary. For the QA Engineer position, I may expect them to be weaker in areas 1 (fundamentals / computer science) and 3 (domain knowledge / language)  but be very strong in area 2 (tools / software / libraries).

For the Software Engineer (Application) position, I may expect them to have a more even balance of the three. However, for the Software Engineer (Platform), I may need them to be strong in area 1 over area 2.

The Software Engineer (DevOps) position is an interesting variant because I may want them to be stronger in areas 1 and 3 and weaker in area 2.

In addition to balancing the tehnical ability requirements for a position, you may need to factor in team and company needs. Consider a situation where you may have a team that is very strong in area 1 but is very week in area 2. It may be worthwhile to bring on team members who have substantial experience in areas 2 and 3 to bring balance to the team.

## Before The Interview

Before the interview, have the candidate send you some sample code. Ideally, the candidate can provide you a link to their GitHub or BitBucket account and has 2+ projects that they've contributed to. If possible, look through both older code and newer code of the same language and make note of the evolution of their style and quality. Being able to determine growth and direction of change could make the hiring decision very quick and easy.

If the candidate does not have any publicly viewable code available, consider giving them a sample project to work on. My personal preference is to contact them directly several days before the interview with a small project that can underscore personal style preferences, project organization and code quality. I would lean toward making the project less difficult over more difficult as this isn't a direct test of competance but instead a way to quickly gauge code quality. At the end of the day, good engineers will solve simple problems with simple solutions.

## During The Interview

When going into an interview, consider the following tips:

* Never go alone. Always bring at least one other engineer, preferably either at the level of the candidate or yours.
* Bring a copy of the resume, this checklist and one or two pens. Don't be affraid to write things down and make notes. I also like to write down notable comments and quotes made by the candidate if it may be useful to the team.
* Interview the candidate in a room that is well lit and bright. At the very least, it helps keep everyone awake.
* Have a computer with projector available as well as a whiteboard. I try to avoid having the candidate write code on whiteboards and instead opt for having an editor open for them to type out an idea or example.
* Avoid having the candidate write new code during interviews in favor of reviewing existing code.

## Checklist

Based on the above areas are several sections and subsections of topics and questions. This is the checklist and flow that I use when working through a technical interview.

### Calibration

In the next section is a checklist of sorts that is broken down into each of the three areas. Before you start reading through it, it is important to calibrate your expectations of the position(s) you are trying to fill. The checklist that I outline descibes someone in the senior/staff software level. Your millage may vary.

What I advise is to print this out and with different colored highlighters, mark things that you want or expect candidates of different levels to understand. For example, highlight in green things like OO design, MVC and some basic data structures/algorithms to note things that your lowest level software engineer should be familiar with. With yellow, highlight things like unicode, unit testing, select design patterns, etc to note things that your mid level engineer should be comfortable with. You may also use a color like red or underlining to note must-have knowledge or comfort with a particular topic. If your team deals works with many regions and languages, knowledge of unicode may be a must.

### Area 1: Fundamentals / Computer Science Knowledge

#### Object Oriented Analysis & Design

http://en.wikipedia.org/wiki/Object-oriented_analysis_and_design

* Why use OO patterns instead of functional patterns?
* Expect what virtual/interface layers are and how they are used?
* What is SOLID? Can you describe some of the related patterns like DRY and GRASP?

#### Data Structures and Algorithms

* Name some data structures that you've used or implemented.
* Name some algorithms that you've used or implemented.
* What is the difference between a set and multi set? map and multimap? tree and graph?
* Can you descirbe an implementation of the following data structures?
  * bitset
  * skip list
  * binary tree
  * prefix tree
  * bloom filter
  * adjacency matrix
  * hash table

#### Big-O Notation

* What is big-O notation?
* Can you give me an example of something that is constant (O(1))? linear (O(n))? logarithmic (O(log n))? quadratic (O(n^2))?

#### Design Patterns?

* What is the builder pattern?
* What is an adapater/wrapper/translator?
* What is a decorator?
* What is a factory?
* What is a singleton?
* What is lazy initiation?
* What is a flyweight pattern?

#### Architectural Patterns

* What is MVC?
* What is MOVE?
* For a web request, what is the critical path?
* What is a tier 1 system? tier 2? tier 3? Supportive layer?
* What is REST? RPC?
* What line-wire protocols have you used before? (protocol buffers? avro? thrift? stomp? zeromq?)
* What is your experience and level of comfort with memcached? redis? RabbitMQ?
* What is SaaS (Software as a service)?
* What is the worker-manager model? What does an implementation of it look like within a single application?
* Across multiple processes? Across multiple servers?

#### Computer Organization Basics

* Why have a USER directory?
* Why have a program files or bin directory? etc? var?

#### Network Basics

* What is TCP? UDP?
* What are sockets?
* What is DNS? DNSSEC?

#### Internationalization

* What is unicode?
* What role does UTF-8 play in unicode? UTF-16?

#### Systems

* Basic understanding of compilers, linker and interpreters.
* Understands what assembly code is and how things work at the hardware level. Some knowledge of virtual memory and paging.
* Understands kernel mode vs. user mode, multi-threading, synchronization primitives and how they're implemented, able to read assembly code. Understands how networks work, understanding of network protocols and socket level programming.
* Understands the entire programming stack, hardware (CPU + Memory + Cache + Interrupts + microcode), binary code, assembly, static and dynamic linking, compilation, interpretation, JIT compilation, garbage collection, heap, stack, memory addressing, etc

### Area 2: Tools / Software / Libraries

#### Development Environments

* What tools and software do you use to write code?
* What tools and software do you use to debug code?

#### Operating Systems Basics

* What is your favorite OS?
* Any experience with Linux?
* Can you list any differences you've had to develop against between major operating systems?

#### Software Testing, Automated

* What automated software testing tools and software have you used?
* How does automated testing factor into unit testing? Component testing?
* How much testing is enough? too much?
* Where does the line blur between unit testing and integration testing?
* In your opinion, what is the ideal role and responsibility of QA?

#### Dependency Management, Maven

* What is your level of experience and comfort with maven or ivy?
* What are some package/dependency management tools or programs that you've used before? How would you describe working with them?
* What happens when a program (App A) has two dependencies (App B and App C) that require a different version on a dependency (App D 1.0 and 2.0)?

#### Continuous Integration

* What is CI?
* What is continuous deployment?

#### Version Controlling Systems

* Have you ever used Git? SVN?
* What is the difference between VCS and DVCS?
* What is branching?
* When does it make sense to commit changes? What is committing too infrequently? What is committing too frequently?

#### Area 3: Domain Knowledge / Language

This area is java specific and is based on the tech stacks that I've been using for the past several years. Your millage may vary.

#### DI (Dependency Injection)

* What is IoC?
* How do wrappers, builders, prototypes and managers fit in the big picture of DI/IoC?
* What is your level of comfort with Spring?

#### ORM (Object relational mapping)

This may or may not be useful to you. At the very least it can get a conversation started.

* What is ORM?
* What are some of the benefits of not writing your own SQL? Dangers?
* At what point should caching be integrated with ORM?

#### Requirement Analysis

* What is a stakeholder or product owner?
* When you are put on a project, do you prefer to have a spec doc given to you or open-ended requirements?
* What is your comfort level with discussing product requirements with stakeholders?
* Have you ever spent time prototyping an application/service? At what point do you spend "too much" time prototyping?

#### Writing Clean Code

* What is clean code?
* How are code reviews involved in creating clean code?

#### Service Design

* What things would you need to consider when designing a cross-regional (cross-datacenter) service.
* For what types of services would the HTTP transport be best suited? AMQP? Long-lived TCP connections?

#### Data Warehousing

* How does data decay (puring old data) factor into data warehousing?

#### Capacity Planning

* What things need to be considered when lighting up a new backend storage system?
* How you would plan for a new memcached/redis cluster?
* How would you plan for a new web application cluster?
