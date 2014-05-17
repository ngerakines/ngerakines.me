---
layout: post
title: Email logon just works
---

Recently I wrote a small (or not soo small) web application that used email instead of usernames/passwords as the method of authenticating and verifying users. I think email is an underutilized tool and often gets overlooked by web developers. This is why email basic logon just works.

**Email is simple.** Nine times out of ten, users of your website have a single primary email address and can be contacted through it. Most internet users understand what email is and how to use it. Email is one of the few internet technologies that you don't need to teach your users how to use.

**An email address is an identity.** This well estabished fact is why email addresses are used as the account identifier for almost all major websites. Entire login systems, like browser id, are based around the simple fact that for most people, an email address is both a way to communicate with them but also identify them.

**One less password.** Using a temporary login token sent to my inbox is a quick win for me because it is one fewer password that I have to remember. I'll go so far to say that for most people, when they are visiting a website that they want to logon to, they will probably have already been to or will go to their webmail.

**No more storing passwords.** As a developer, I'm reducing the impact of a service compromise. Even if I did all of the right things to encrypt and protect my user's passwords, there are known and proven ways of getting around most safe guards. By removing passwords from my database altogether, I'm avoid the problem altogether.

## How it works

When user visits website http://foo.localhost/ they are redirected to a login page, http://foo.localhost/login. On that page, they are prompted to enter their email address. When they submit the form, the receiving request handler verifies that the email address represents a valid account and generates a temporary login token for the account. It then sends an email with a link to that account. When the user follows the link from the email, it automatically signs them in.

My implementation is pretty simple. Using Spring 3, I wrote a PreAuthenticatedProcessingFilter bean that pulled a query string parameter from the request and a custom user detail service to look up accounts by the temporary login token. Once the account has been found, the session user is set and temporary token cleared from the store (database).

## An even better solution

An even better solution would be to use some sort of token that is sent to the user out of the scope of the device that the user is accessing the site with. Being able to receive a temporary password or login url via SMS or the like would be better.
