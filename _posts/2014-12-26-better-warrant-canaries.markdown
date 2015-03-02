---
layout: post
title: Warrant Canaries
---

Wikipedia defines a [warrant canary](https://en.wikipedia.org/wiki/Warrant_canary) as:

> ... a method by which a communications service provider informs its users that the provider has not been served with a secret United States government subpoena.

Practically, this ends up being a file or web location that states something to the effect of, "As of ***date***, we have not received a subpoena."  The notice usually includes a disclosure stating that no warrants have been served to the entity or its employees and no searches or seizures have been performed on the entity or the employees of the entity's assets. It will also include a date as to when the notice was updated and may also include links to external websites with time-relevant information such as news articles, major headlines, tweets, etc.

The most important part of the warrant canary is the signature and signed content. All of the above information is cryptographically signed, and the public key made available to verify the signature. The act of signing the notice increases the difficulty in forging a warrant canary.

There are many cases where warrant canaries exist and are used by commercial and non-commercial entities. One of the oldest and well-known instances is the [rsync.net warrant canary](http://www.rsync.net/resources/notices/canary.txt). Other examples include:

* [https://proxy.sh/canary](https://proxy.sh/canary)
* [https://spideroak.com/canary](https://spideroak.com/canary)
* [https://subrosa.io/canary](https://subrosa.io/canary)
* [https://help.riseup.net/en/canary](https://help.riseup.net/en/canary)

There is, however, speculation that warrant canaries have questionable legal ground or could be used as an effective way to indirectly communicate said legal action by a government agency or court. At this time, there have been no cases where warrant canaries have been upheld. For more information, see the [EFF Warrant Canary FAQ](https://www.eff.org/deeplinks/2014/04/warrant-canary-faq).

# Creating A Warrant Canary

Creating a warrant canary is a fairly simple process. It requires just a small amount of time to become familiar with tools like GPG. After creating a warrant canary notice, it can be published by anyone with access to your website.

## Before You Begin

To begin, you will need to install GPG and create a signing key. Create the signing key by following the official GPG [Getting Started](https://www.gnupg.org/gph/en/manual/c14.html) guide. A key is only created once and will be used to update your canary in the future; it is crucial that the same key be used for subsequent canary updates.

## Creating The Notice

As with previous examples, the notice should contain the disclosures that are most relevant to your needs as well as information and data that can sufficiently be determined as both accurate and time relevant. This often includes the current date, sports scores, weather information, etc. For example:

	It is Friday, December 26th, 2014 at 4:50 pm EST.

	To this date no warrants, searches or seizures of any kind have ever been performed on my assets or any assets belonging to members of my household.

	Headlines from http://www.npr.org/sections/news/archive?date=12-31-2014
	Body Of Catholic Priest Found In Southern Mexico
	Businesses Buzz With Anticipation In Wake Of U.S.-Cuba Thaw
	Military Policy Impedes Research On Traumatic Brain Injuries
	In The Nation's Capital, A Signature Soup Stays On The Menu
	Already Bleak Conditions Under ISIS Deteriorating Rapidly

	Week 16 NFL Scores
	Giants 37 Rams 27
	Cols 7 Cowboys 42
	Bills 24 Raiders 26
	Seahawks 35 Cardinals 6

	You can verify this document using the public key 953023D848C35059A2E2488833D43D854F96B2E4.

With your notice saved as warrant_canary.txt, sign it with your GPG key.

	$ gpg --clearsign warrant_canary.txt

Running this command will create a file named `warrant_canary.txt.asc`.

	-----BEGIN PGP SIGNED MESSAGE-----
	Hash: SHA256

	It is Friday, December 26th, 2014 at 4:50 pm EST.

	To this date no warrants, searches or seizures of any kind have ever been performed on my assets or any assets belonging to members of my household.

	Headlines from http://www.npr.org/sections/news/archive?date=12-31-2014
	Body Of Catholic Priest Found In Southern Mexico
	Businesses Buzz With Anticipation In Wake Of U.S.-Cuba Thaw
	Military Policy Impedes Research On Traumatic Brain Injuries
	In The Nation's Capital, A Signature Soup Stays On The Menu
	Already Bleak Conditions Under ISIS Deteriorating Rapidly

	Week 16 NFL Scores
	Giants 37 Rams 27
	Cols 7 Cowboys 42
	Bills 24 Raiders 26
	Seahawks 35 Cardinals 6

	You can verify this document using the public key 953023D848C35059A2E2488833D43D854F96B2E4.
	-----BEGIN PGP SIGNATURE-----
	Comment: GPGTools - https://gpgtools.org

	iQIcBAEBCAAGBQJUndq1AAoJEDPUPYVPlrLk2fYP/jGFb1vxR2sXEu5DzHJU9urd
	Q8ia1srhm4UogchTuN6nGv39zlBgpT1H75xwLYYSyiEbjpV7CYPqwYOgZvv8xF5D
	hMRGoHu2WE7RCllQr49cKyzro0m9TEWHUt8HLxlaV/Go58Q2i3TbiKo5z0QdlB7B
	XXyQSA5ZDFSKqrdMl6oVqHI1dJhM3TRGpxmkrF/mD7RRpdqw0yJKMefqxGRFLavI
	Vg8su3XlYgl6xmlL+BAcd0Pc0SiSCH/IIiLbpBrNaWeOFeEnaAbeC4apYn45np5G
	jXPQ7+xdfcxmyt+VUSJ9aSw6WxHSYYBR2YhOvnunssCI6dev06Ot3p5+zOkgsFZt
	2rqvNFKjp92J/vB8cKCoFi8UwizftcyvrwZHHtzFcLPEg4mhqWQp4DE3ToMOp37o
	wieVqWbYhqRDMlFgQGr9Zdx0xPipnz5JwcSeaJuUZTOYUbN2L4w5s25yvCtuyT4p
	yac0D+mxoFhG96UuSXsQjtwbiot7Kddt0TeaXzfbR7nk7n9Cv5thEEQlgtoV4Htv
	f8jXua2/L3+Cl8j+WM+C9S5lXXR3t3RGy555lYcssDXAAcWsSY4UJasHaVU0vRTu
	CqDPfOJmCnqI9Pv7tlP4iBWMkkAVV9ToqyRoM4fIQ41jTDn+ncc52du4M1+LZNJq
	2tQPWQHVW8/oQtwo2W7W
	=HQN5
	-----END PGP SIGNATURE-----

That file is your current warrant canary and should be made available as you see fit. The most common url used to present your canary is "/canary". In this case, the canary is available at [http://ngerakines.me/canary](http://ngerakines.me/canary).

## Next Steps

With your canary online and available, you'll need to be sure that the signing key used to sign the notice is also available. Please refer to the [Exchanging Keys](https://www.gnupg.org/gph/en/manual/x56.html) and [Distributing Keys](https://www.gnupg.org/gph/en/manual/x457.html) documentation to export your key to share with others and make available through a GPG key server.

It may also be in your interest to have third parties verify your key and identity. This allows other key owners to demonstrate trust. More information can be found on the GPG documentation: [Validating other keys on your public keyring](https://www.gnupg.org/gph/en/manual/x334.html).

# Securing Your Canary

When a canary is not updated or is removed, it means that several things may have happened.

The first is simply human error. For safety and security purposes, the act of signing a warrant canary is a manual process. That means that a human has to be at a computer and run the commands to create and sign the warrant canary notice. There are plenty of reasons from sickness to changing companies and even simply forgetfulness that could be the reason why a canary is not updated.

It could also mean that the the entity no longer wants to include the notice. A change in management or ownership could result in the canary is neglected or removed.

Lastly, it could mean that harm, detention or a lack of control is preventing the canary from being updated.

A watchdog or [Dead man's switch](https://en.wikipedia.org/wiki/Dead_man%27s_switch) can be used mitigate damage or loss of data or reputation.

## Dead Man Switch: Revocation

Using a revocation certificate, a trusted third party can publicly revoke the key used to cryptographically sign canaries.

A core component of the warrant canary is the signature. The signature is used to determine that the contents of the canary have not been tampered with and provide a way to identify the owner of the signing key through the [web of trust](https://en.wikipedia.org/wiki/Web_of_trust). When the GPG key used to sign the canary is created, a revocation certificate should be created along with it.

> *If you forget your passphrase or if your private key is compromised or lost, this revocation certificate may be published to notify others that the public key should no longer be used.* -- [The GNU Privacy Handbook](https://www.gnupg.org/gph/en/manual/c14.html)

A revocation certificate can be securely given to a trusted third party responsible for publishing the revocation certificate under certain conditions.

Conditions could range from:

* The warrant canary not being updated after a certain period of time.
* Unusual behavior or contact with the company.
* A cue or hint that it should be done so through information contained in a [dead drop](https://en.wikipedia.org/wiki/Dead_drop) or press release.

## Multiple Signers

As a way to reduce the risk of human error from raising false concern, multiple signers can sign a canary or multiple canaries can be published used. The most common way to do this would be to have two or more members of an organization create signatures of the canary and append it to the notice.

This can be done by creating one or more detached signatures along with the canary.

    $ gpg --output canary.sig1 --detach-sig canary

When the above command is run, a file named `canary.sig1` is created that contains a signature of the canary file. You can publish these additional signatures along-side the canary or append them to the bottom of the canary file.
