---
title: "Making a Janet Button"
date: 2019-12-16T11:15:21-05:00
resources:
- name: 3m9a6680
  src: ../images/3M9A6680.jpg
---

The Good Place is almost over, but the fun isn't. For Halloween this year, we dressed up as Jason and Janet for our Halloween party and thought it'd be fun to make a Janet Button. If you don't know what that is, it is the magical reset button that is used to reboot Janet. In the show, as you approach the button, Janet begs for you to not reset her in all of the hilarious and imaginative ways that you would expect.

{{< youtube "-vDjRRb9srM" >}}

![assembled board](https://ngerakines.me/images/3M9A6680_thumbnail.JPG)
![assembled board expanded](https://ngerakines.me/images/3M9A6681_thumbnail.JPG)
![assembled housing wires](https://ngerakines.me/images/3M9A6685_thumbnail.JPG)
![assembled housing](https://ngerakines.me/images/3M9A6686_thumbnail.JPG)

Back on earth, the Janet Button is a large red button way to detect if someone is within range of the button and a component that plays audio clips.

I decided to use an Arduino Uno, an Adafruit "Music Maker" MP3 Shield, LV-MaxSonar-EZ1 Ultrasonic Range Finder, and a simple push button. I also planned on using a PIR motion sensor, but ended up not using it in the final product. The housing is just a spray painted pringles can and a spray painted foam hemisphere.

The cost of primary parts is about $100, and it is assumed that you also have a soldering iron, general electrical equipment (wire strippers, cutting equipment, etc.), prototyping equipment (broadboard, jumpers, etc.), and a 10k resistor.

I would consider this a good beginner level project because it doesn't have a ton of complexity in the physical components, but does require a fair amount of soldering. If have a few arduino projects under your belt and feel comfortable with a soldering iron, this is a great project.

![janet-button-breadboard](https://raw.githubusercontent.com/ngerakines/janet-button/master/janet-button-bb.jpg)

![janet-button-schematic](https://raw.githubusercontent.com/ngerakines/janet-button/master/janet-button-schematic.jpg)

In the above layout images, you can see that the button connected to 5-volt and is grounded to a 10k resistor with output connected to gpio-8. The LV-MaxSonar-EZ1 is connected to 5-volt, ground, and analog-2.


When moving off of the breadboard and onto something a bit more permanent, I decided to go with some simple PCB strips that run across the shield. I also made small PCB strips to hold the range and button components.

The housing is just a spray painted pringles can. The button PCB is mostly flat, so I fit it through a slit on the lid and used some tape to hold it down. When cutting a hole for the range housing, a glue gun can help error correct. It is better to have a more snug fit, than a looser fit.

Lastly, I drilled two small holes in the back for the power and audio cables.

Assembled board and housing pictures: https://photos.app.goo.gl/CMKYWSyM9qPxpH8Y6

The experience that I went for was to have a small pool of short (under 3 second) audio clips that are played at random as someone approaches the button. Then, when the button is activated, play an alert clip several times before resetting.

* boot.mp3 - "Everything is fine"
* track1.mp3 - "No no no!"
* track2.mp3 - "Please don't hurt me!"
* track3.mp3 - "No no, please please, I don't want to die!"
* track4.mp3 - "No no no, please wait, I have kids."
* killed.mp3 - "Attention. I have been murdered."

If you add more tracks, be sure to update the tracks variable so they are added to the pool of randomly selected tracks.

The Adafruit "Music Maker" shield was perfect for this project. I used the Windows 10 Voice Recorder program to record my clips and then loaded them onto the SD card. The program is one big event and state machine to track the range of the person and status of the button press.

The source code for the project can be found on github: https://github.com/ngerakines/janet-button

{{< youtube etJ6RmMPGko >}}
