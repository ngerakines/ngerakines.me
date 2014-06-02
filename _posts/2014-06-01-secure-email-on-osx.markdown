---
layout: post
title: Secure Email On OSX
---

There are a few really good articles out there on how to send and
receive secure email using Thunderbird and GPG. This small guide will
show you how you can use Mail.app along with GPG Tools for the same
result.

## Install GPG Tools

First, head over to [https://gpgtools.org/](https://gpgtools.org/) and
download the latest release. At the time of this article, the latest
stable release is 2.1.

To start off on the right foot, before you install it, open up terminal
and verify that you've downloaded a package that matches the following
signature: ac7a636bfee1027d8f43a12a82eea54e7566dcb8. This can be
accomplished with the following commands:

    $ cd ~/Downloads
    $ shasum GPG\ Suite\ -\ 2013.10.22.dmg
    ac7a636bfee1027d8f43a12a82eea54e7566dcb8  GPG Suite - 2013.10.22.dmg

Once you can verify that the dmg file that you've downloaded hasn't been
tampered with during transfer, go ahead and open it and run through the
install process. This will install the base GPG tools, a graphical key
manager and a plugin for Mail.

## Create A Key

Next you'll want to create a key. Open the newly installed "GPG Keychain
Access" application and click the "New" button to create a key. You'll
br prompted for your full name and email address, which you should fill
in. Be sure to also check the box to have the public key uploaded once
generated.  Having accurate information is vital and if this is your first time
going through this process, I strongly recommend setting the `comment`
to your website or twitter under the advanced options.

Next, you'll be prompted to set a password for your key. **Choose a strong
password.** Depending on your system, it may take a few moments for the
key to be generated after your password is accepted. Don't be alarmed.

## Configure Mail

There shouldn't be anything extra needed to send and receive encrypted
and or signed email through the Mail app now. In the Mail app
preferences is a "GPGMail" section that should indicate that GPGMail is
ready for use. I have it set to encrypt/sign drafts and sign all new
messages by default.

## Test Sending Signed Mail

From Mail, create a new message to send to a loved one, friend, coworker
or the like. Once you fill in the To, Subject and Body ensure that the
message is "Signed" by clicking the checkmark box button within the new
mail window. If you have Mail configured to sign by default, you may be
prompted within a few seconds to give the password for the key.

It is important to note that you can sign outbound email to anyone, but
you can only encrypt email messages to people who have given you their
public key. This is where the GPG Keychain Access app comes into play.

With the GPG Keychain Access app you can also import key files given to
you and search for keys for people you may know. If someone sends you
their public key you can use the "import" feature to load the key into
your keyring. Alternatively, if you know the email address or name, you
can attempt to search for keys associated with them on public key
servers.

When composing emails to addresses that have public keys associated with
them, you'll have the option of encrypting the email messages being
sent. If you don't have any other public keys in your key ring, you can
test this by sending an encrypted email to yourself.

## Tips

***Guard your private key.*** It is critical that you ensure your
private key is safe and secure. For everyday use, keeping it on a
personal, non-public computer is probably enough. If you feel that a
computer that has your private key on it has been compromised, infected
by a virus or malware, etc then you revoke the key and create a new one.

Find a thumbdrive that you don't use and back up your keyring to it.
This should also include a revocation certificate. A revocation
certificate will allow you to revoke the key if the key is lost or
compromised.

When backing up your private key, consider using symmetric encryption
using a password to encrypt the backup file. This can be done with GPG
using the following command:

    $ cd /Volumes/thumbdrive
    $ gpg --output backup.zip.gpg --symmetric backup.zip

When you need to decyrpt your backup, you can use the following command:

    $ gpg --output backup.zip -d backup.zip.gpg

When publishing your key on your blog or website, you can export a plain
text version of your key that can be read as text and imported easily
using the following command:

    gpg --armor --export person@wherever.place

The output of that command can be placed inside of a pre block as-is. It
is the most direct way to share your key wih someone viewing your blog
or website. An alternative would be to create a small signature block
telling people how to find your key.

    $ gpg --fingerprint nick@gerakines.net
    pub   4096R/4F96B2E4 2013-06-15
          Key fingerprint = 9530 23D8 48C3 5059 A2E2  4888 33D4 3D85 4F96 B2E4
    ...
    $ gpg --clearsign

    You need a passphrase to unlock the secret key for
    user: "Nick Gerakines (http://ngerakines.me/) <nick@gerakines.net>"
    4096-bit RSA key, ID 4F96B2E4, created 2013-06-15

    9530 23D8 48C3 5059 A2E2  4888 33D4 3D85 4F96 B2E4
    nick@gerakines.net

    ^D
    -----BEGIN PGP SIGNED MESSAGE-----
    Hash: SHA256

    9530 23D8 48C3 5059 A2E2  4888 33D4 3D85 4F96 B2E4
    nick@gerakines.net

    -----BEGIN PGP SIGNATURE-----
    Version: GnuPG/MacGPG2 v2.0.22 (Darwin)
    Comment: GPGTools - http://gpgtools.org

    iQIcBAEBCAAGBQJTi8pOAAoJEDPUPYVPlrLkwZkP/3PxOQfNAlF0W5JVImPltVMr
    9rqNK/9T07cU8qCugECX0U+CPsz5+fY9t6KuPb9XQv1SZT/s0Cdu0NoV83/zyTJe
    VmCpnDwDYa1k8PsfiYHziM/BQ4N8HFlc/rNwsyfS+v9o2Pa2nEJA6OmU+jsVg25A
    vyGfgH6fK/QeWRIlFIMfuh5b0+XSOA0E6/xTHFSNHdn3oYA4xjNsE6AajHekcYAS
    l99uZZhqu+bnKLaCpxLHjZbTcjGuZcacIyTXNh20VcHtgZS0VvUWKyRvJ9PPZcwJ
    oidbGTQkx5GJJJrXREoncHsh5uVt0SUJk/Cb2B43sICzTD1+5tENpK6kUnxlo2bi
    O0rzEFSZRVme3GiDTZc5pV7DoWUS28EiJl6LLc7hU7d8lwsme69/3tV85mEdyDzJ
    4OnFDQ39qIHfHhnswyumTAYnI/31GWrWfCl/UL3MOd4HKQhxsuQWi/zOWVAlvHJN
    /lwIh3yiH5PGJsOUKs04XoOgNaZLC2A2vq9FUng+hi7WfGBzYkPc/RLgNxI9cU9H
    dADC+Np4DRQ71YMSX9oYpUpybq6IdA68rrWbdjfDMc+ZQBDZz83zk7xRMLfws1ut
    u2n6uzAVvYe/FjGjBaNXJ++yE8oIC38RDBG14nJDBK+cdqZpBP0Lxd+nGRB6VxcX
    ZBOr7eKH1bpVjSbuOX1S
    =OhTU
    -----END PGP SIGNATURE-----

