---
layout: post
title: Using BitTorrent Sync, GPG and Linode for secure messaging and storage
date: 2013-08-11T09:00:00-00:00
---

There has been a lot of discussion lately on the state of privacy. I'm not going to comment on whether or not people who assumed that there was some notion of privacy and security between ISPs were right or wrong; I can only look at what has been made very clear and proven.

With that, I've been reading different opinions on things like lavabit and spider oak and how they compare to existing storage services like Hightail, dropbox, etc. I'm also very interested in BitTorrent and how it can be used and applied here.

All of this lead to me starting to phase out my use of dropbox and, in some ways, email. The problem with dropbox is pretty clear: Because they have absolutely zero support for encrypted, zero-knowledge storage, I can't use them and strongly advise anyone that does to move to something else.

The issue with email is a bit more complex but boils down to three big problems. SMTP, the protocol used to send email on the Internet, is a plain text protocol that (much like HTTP in some ways) and servers are not required to secure connections between each other when sending email. Some SMTP servers do support SSL/TLS but it is not required, and as far as I know the major providers like Google, Microsoft and Yahoo do not use TLS when sending and receiving messages.

The second big issue is that even if the servers involved in transferring a message do use SSL/TLS, that doesn't do anything about securing the message before and after it is sent. If I have a mail server running somewhere that Outlook or Thunderbird connect to for sending email, that server may store that email locally in a "sent" folder that is insecure. The same holds true for the server receiving the message.

The last issue involves the use of encryption technologies like GPG/PGP. When I send an email and encrypt the message, the only part of the message that is being encrypted is the actual body of the message. The subject, to and from parts of the message are untouched, as are the rest of the message headers.

So where does that leave us? Ideally a new, more secure message protocol will emerge that enforces server security as well as message security, but I'm not going to wait around for that. What I've done instead is much more simple and uses [BitTorrent Sync](http://labs.bittorrent.com/experiments/sync.html), a [linode](http://www.linode.com/?r=9d59273a4dd47bafd01ba615b69c90c49996b9a6) instance and GPG.

If you aren't aware of what BT Sync is, it is a simple client that uses the BitTorrent protocol to transfer files between two or more devices that supports some basic discovery constructs. In short, if I have two computers configured to sync with each other, when I place a file in one of the sync folders on computer a, after some period of time it shows up in the sync folder on computer b.

Doing this between my laptop and desktop is pretty simple. Their website has a getting started guide that shows how this can be done. What I'm doing is taking things one step farther to make synced data available to other computers when my computer is offline. To do that, I'm using a linode instance.

My linode instance is running debian 6 and I've gone through the usual steps to secure it. On that machine, I downloaded the linux bt sync client and used the following config.

	{
	  "device_name": "host",
	  "listening_port" : 4444,
	  "storage_path" : "/home/user/.sync",
	  "check_for_updates" : true,
	  "use_upnp" : true,
	  "download_limit" : 0,
	  "upload_limit" : 0,
	  "shared_folders" :
	  [
	    {
	      "secret" : "FOLDER SECRET",
	      "dir" : "/home/user/documents-btsync",
	      "use_relay_server" : false,
	      "use_tracker" : true,
	      "use_dht" : false,
	      "search_lan" : false,
	      "use_sync_trash" : false,
	      "known_hosts" : []
	    }
	  ]
	}

When the Linux BitTorrent Sync client starts, it forks itself and runs in the background. Meanwhile, on my computer I add a new direct host entry to the linode IP with the port specified by the config. Both locally and remotely, I can add files and then see that they are synced correctly across computers.

On the linux server, the sync directory that I'm using looks something like this:

	./keys/DFAD0D40.gpg
	./keys/0F751A8E.gpg
	./keys/4F96B2E4.gpg
	./messages/70b70a33086871aa9ac0c1538002162fad69556e.asc
	./messages/a4e88213f8a2470e51af12f64ea125ef28016015.asc
	./notes/e73ce84b1fdcd5b50aa1e39975747196d9fde3c5.asc
	./notes/f36cf086a11af381301455e261e87e5e8231a845.asc
	./software/gpg4win-2.2.0-beta34.exe
	./software/GPG Suite - 2013.08.06.dmg

Files in the messages directory are GPG encrypted blobs of text. Here, the policy is that if there is a message that you can read, because you can decrypt it, then once you read it you can delete it from the folder and the delete gets propagated. Files in the notes directory are encrypted blobs of text that aren't meant to be deleted and may be read by a group/shared key. The software folder is just there to bootstrap a new sync.

This system is great if you've got a handful of people that want to send and receive encrypted notes and messages to each other. It takes a little bit of know-how to setup, but very little maintenance once it is up and running. I think bt sync has a lot of potential and I'm eager to see where and how it is used.
