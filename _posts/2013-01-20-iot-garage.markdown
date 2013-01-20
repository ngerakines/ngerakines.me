---
layout: post
title: IOT Garage
category: posts
---

I started getting back into hardware hacking when I first heard about the Arduino. Since then, I've made a started and finished a few projects, one of which is a small device used in the garage. This device is used to help park our van using a motion sensor, distance sensor and some leds.

# Goals

The goal of this project is to help park our van in our garage. We currently have a standing plastic stop sign, but it gets knocked over and moved very easily. This device would be mounted on the wall that the van moves toward to when parking and has very clear visual indicators (red, yellow and green LEDs).

A nice-to-have goal is to make this an internet connected device that is connected to other devices in the house. I've been watching projects like [sticknfind](http://www.sticknfind.com/) and want to put one on the inside of the van's bummer as well as on the inside of my car to have the garage "known" which car is parked in it.

# Parts Used

* Arduino Uno
* Parallax PING\)\)\) Ultrasonic Distance Sensor
* Parallax PIR Motion Sensor \(Passive Infrared\)
* 3 LEDs \(Red, Yellow and Green\)
* 3x 220 OHM resistors \(red, red, brown, gold\)

It is assumed that you've got a breadboard and an assortment of jumpers as well.

# Hardware Layout

This is what the device looks like on a breadboard.

![Fritzing render](/images/iot-garage.jpg)

Fritzing didn't have the PING\)\)\) part, so I used the mystery part there. I'm new to the app and couldn't figure out how to accurately represent it.

As you can see there are 3 LEDs connected to the Arduino's 3, 5 and 6 pins. The distance sensor and motion sensor are both connected to the 5v line and the ground line as well as the 2 and 7 Arduino pins.

![Top view](/images/iot-garage-top.jpg)
![Size view](/images/iot-garage-side.jpg)

# Software

I used the following skitch to test the behavior. Keep in mind that you'll have to tweek the yellow and red distance values.


{% highlight c %}
const int led_1 = 3;
const int led_2 = 5;
const int led_3 = 6;
const int ping_pin = 7;
const int pir_pin = 2;

const int red_distance = 12;
const int yellow_distance = 24;

boolean led_1_on = false;
boolean led_2_on = false;
boolean led_3_on = false;

int val = 0;
int tick = 0;

void setup() {
  pinMode(led_1, OUTPUT);
  pinMode(led_2, OUTPUT);
  pinMode(led_3, OUTPUT);
  pinMode(pir_pin, INPUT); 
  Serial.begin(9600);
}

void loop() {
  val = digitalRead(pir_pin);
  if (val == HIGH) {
    tick = 30;
  }

  if (tick > 0) {
    activity();
  }

  int old_tick = tick;

  tick -= 1;

  if (old_tick > 0 && tick < 1) {
    if (led_1_on) {
      led_1_on = false;
      digitalWrite(led_1, LOW);
    }
    if (led_2_on) {
      led_2_on = false;
      digitalWrite(led_2, LOW);
    }
    if (led_3_on) {
      led_3_on = false;
      digitalWrite(led_3, LOW);
    }
  }

  delay(100);
}

void activity() {
  long duration, inches;
  
  clearPingPin();

  pinMode(ping_pin, INPUT);
  duration = pulseIn(ping_pin, HIGH);

  inches = microsecondsToInches(duration);
  
  if (inches < red_distance) {
    if (led_2_on) {
      led_2_on = false;
      digitalWrite(led_2, LOW);
    }
    if (led_3_on) {
      led_3_on = false;
      digitalWrite(led_3, LOW);
    }
    if (led_1_on == false) {
      digitalWrite(led_1, HIGH);
      led_1_on = true;
    }
  } else if (inches < yellow_distance) {
  if (led_1_on) {
      led_1_on = false;
      digitalWrite(led_1, LOW);
    }
    if (led_3_on) {
      led_3_on = false;
      digitalWrite(led_3, LOW);
    }
    if (led_2_on == false) {
      digitalWrite(led_2, HIGH);
      led_2_on = true;
    }
  } else {
    if (led_1_on) {
      led_1_on = false;
      digitalWrite(led_1, LOW);
    }
    if (led_2_on) {
      led_2_on = false;
      digitalWrite(led_2, LOW);
    }
    if (led_3_on == false) {
      digitalWrite(led_3, HIGH);
      led_3_on = true;
    }
  }
}

void clearLed() {
  if (led_1_on) {
    digitalWrite(led_1, LOW);
  }
  if (led_2_on) {
    digitalWrite(led_2, LOW);
  }
  if (led_3_on) {
    digitalWrite(led_3, LOW);
  }
}

void clearPingPin() {
  // The PING))) is triggered by a HIGH pulse of 2 or more microseconds.
  // Give a short LOW pulse beforehand to ensure a clean HIGH pulse:
  pinMode(ping_pin, OUTPUT);
  digitalWrite(ping_pin, LOW);
  delayMicroseconds(2);
  digitalWrite(ping_pin, HIGH);
  delayMicroseconds(5);
  digitalWrite(ping_pin, LOW);
}

long microsecondsToInches(long microseconds)
{
  // According to Parallax's datasheet for the PING))), there are
  // 73.746 microseconds per inch (i.e. sound travels at 1130 feet per
  // second).  This gives the distance travelled by the ping, outbound
  // and return, so we divide by 2 to get the distance of the obstacle.
  // See: http://www.parallax.com/dl/docs/prod/acc/28015-PING-v1.3.pdf
  return microseconds / 74 / 2;
}
{% endhighlight %}

# Next Steps

The next step is to convert the parts on the breadboard into something more permanant that can be mounted. Stay tuned for part 2.
