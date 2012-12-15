---
layout: post
title: Formatting and Code Organization
category: posts
---

Formatting and organization have been discussed and debated to great lengths because of one simple fact: it is incredibly important. How code is formatted and organized has a huge impact on how easy it is to comprehend and change. Here we will be discussing some of the readability and class organization aspects of formatting and code organization.

> Perhaps you thought that "getting it working" was the first order of business for a professional developer. I hope by now, however, that [Clean Code] has disabused you of that idea. The functionality that you create today has a good chance of changing in the next release, but the readability of your code will have a profound effect on all the changes that will ever be made. The coding style and readability set precedents that continue to affect maintainability and extensibility long after the original code has been changed beyond recognition. Your style and discipline survives, even though your code does not.

Whether you are new to the team or not, it is blindingly apparent that our projects are developed over large periods of time and change very frequently. We may not always get to rewrite some particularly complex piece of code or feature, so it is imperitive that we help ourselves and coworkers in the future by writing it as cleanly and neatly as possible. One of the most basic things we can do is to ensure that our code is formatted consistently.

I like using the newspaper metaphor because it is appropiate for a lot of the code that we write. When you read an article or essay, you read from the top to the bottom and expect finer detail as you read through it. The heading provides a quick, grabbing description of what you are about to read and, depending on the length of the article, the first 5 to 10 percent of the article may include action items, a high level summary and a lead-in to more details. If the article is particularly long, it may have a table of contents or segments to allow you to jump to different sections easily.

The same holds true for the code that we write. Since a lot of the code that we write involves java classes, we'll focus on those.

Formatting is more than just using tabs instead of spaces or naming variables. Those things are important, but equally important are things new line usage, vertical density and vertical spacing. These other aspects of formatting and code organization play a big part in how easy it is to determine the intent and complexity of a piece of code by quickly scanning it.

{% highlight java linenos %}
    /** This is a usefuly and concise single-line description of the class */
    public class OutputStreamWriter {
        private static final Logger LOGGER = LoggerFactory.getFactor(Writter.class);
    
        @Autowired
        private FileSystem fileSystem;
    
        private final OutputStream outputStream;
        private final String fileName;
    
        public Writer(OutputStream outputStream, String fileName) {
            this.outputStream = outputStream;
            this.fileName = fileName;
        }
    
        public void write() throws WriterException {
            if (outputStream.isValid() == false) {
                throw new WriterException("Outputstream is invalid.")
            }
    
            File file = getFile();
            if (file == null) {
                throw new WriterException("Could not create file instance.")
            }
    
            try {
                file.write(outputStream);
            } catch (IOException e) {
                throw new WriterException("IO Exception", e);
            } finally {
                file.close();
            }
        }
    
        public getFileSystem() {
            return fileSystem;
        }
    
        private File getFile() {
            try {
                return new File(fileName);
            } catch (IOException e) {
                LOGGER.error("Could not create file for {}", fileName);
            }
            return null;
        }
    
    }
{% endhighlight %}

In the above example there are several rules used to ensure that this class is cleanly formatted. Reading the class top to bottom, we first see a description of the class before all other things. Next comes the name of the class and any classes it extends or implements. Within the class are variables used by the class. The first set of variables are constants, both private and public. The next set of variables represent dependencies. I like using the @Autowired functionality of Spring because it both reduces the class size and also plainly documents what things the class depends on. After dependencies are object variables, both mutable and immutable.

What is important to note is that without looking at any of the methods or class specific logic, I already know (a) what the class is (b) what the name of the class is and what classes it derives its intent from (c) the things it depends on (d) the state that it manages internally.

There are two things in action so far: new lines and grouping. Variables are grouped by the scope they maintain. Constants are grouped by themselves, dependencies are near each other and "state" variables are grouped together as well. New lines are used to seperate the groups and ensure that I can quickly scan which groups exists.

Method placement also follows the top-down model. It can safely be assumed that the reader of a class is most interested in how it is made (constructors) followed by how it is used (public methods, the API) and then how it works (private methods, segmented logic). In the above example, we place the constructor above all other methods followed immediately by public methods and then private methods.

When you are working on a particularly large class or one that has many public methods that reference private methods, it is perfectly acceptable to ensure that the distance between methods that reference each other is short. The concept of vertical distance is such that methods that call each other should be placed near each other in a class. This makes it easier for developers jump between methods within a class and follow the chain of commands.

Within methods, code should follow the same grouping and distance model. A simple rule to follow is that variables should be used and referenced as close to as where they were created as possible. Next, when you move from one variable to another, put a new line between the clusters of code. These two things make it easier to follow how logic is grouped together in a method and also makes it easier to refactor code because you are doing less jumping within a method to find and change where and how things are used and referenced.

Although we do OOP (object oriented programming), we tend to think procedurally and that thought process often drives how we place and organize. While generally this is good (most of us think alike, therefor we have a certain amount of consistency), we need to ensure that as we write code, we are laying it out in the most clean way possible.