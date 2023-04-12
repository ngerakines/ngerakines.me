---
title: "Creating web did messages"
date: "2023-04-12"
---

[BlueSky](https://blueskyweb.xyz/) uses DIDs (distributed identities) to represent entities that create and manage content. One of the DID methods that is supported is `did:web`. The specification for this method is available at https://w3c-ccg.github.io/did-method-web/.

This post will walk through the code that I used to create the `did:web:ngerakines.me` document.

I've been paying close attention to the atproto project and specification because I think it has a lot of potential. Having been involved in Mastodon and activitypub, I'm really excited to see projects like this. I even started a rust project that has building blocks to create clients and services that implement the atproto specification, but more on that another time.

My did:web document can be found at [ngerakines.me/.well-known/did.json](https://ngerakines.me/.well-known/did.json) and looks like this:

```json
{
  "id": "did:web:ngerakines.me",
  "verificationMethod": [
    {
      "id": "did:web:ngerakines.me#1681308264",
      "type": "JsonWebKey2020",
      "controller": "did:web:ngerakines.me",
      "publicKeyJwk": {
        "kty": "EC",
        "crv": "secp256k1",
        "x": "TNOqBEhbaeMc2mvWy6/jmSkdQbMZhSs67HOc842vYVU=",
        "y": "2BWdFIhz3qPu3ya+8HSeb4VG7m1MQzmxBjPK+YXlhDM="
      }
    }
  ],
  "authentication": [
    "did:web:ngerakines.me#1681308264"
  ],
  "assertionMethod": [
    "did:web:ngerakines.me#1681308264"
  ],
  "service": [
    {
      "id": "did:web:ngerakines.me#blog",
      "type": "LinkedDomains",
      "serviceEndpoint": "https://blog.ngerakines.me"
    }
  ]
}
```

The important part to note is the `verificationMethod` attribute.

I started off by using the `k256` library to generate a new secp256k1 key.

```rust
    let encoded_signing_key = {
        let signing_key = SigningKey::random(&mut OsRng);
        let verifying_key = VerifyingKey::from(&signing_key);

        let encode_point = verifying_key.to_encoded_point(false);
        let x = encode_point.x().unwrap();
        let y = encode_point.y().unwrap();

        println!("x: {}", general_purpose::STANDARD.encode(x));
        println!("y: {}", general_purpose::STANDARD.encode(y));

        general_purpose::STANDARD.encode(signing_key.to_bytes())
    };
```

When creating that key, I'm printing out the base64 encoded x and y values.

Next, I'm creating a small signature to verify my key is compatible with other libraries and tools.

```rust
    let encoded_message_signature = {
        let decoded_signing_key = general_purpose::STANDARD
            .decode(encoded_signing_key.clone())
            .unwrap();
        let signing_key_slice = decoded_signing_key.as_slice();
        let signing_key = SigningKey::from_bytes(signing_key_slice.into()).unwrap();

        let signature: Signature = signing_key.sign("hello".as_bytes());

        general_purpose::STANDARD.encode(signature.to_bytes().as_slice())
    };
```

After that, I'm reading the signed message and signature and verifying the signature is correct.

```rust
    // Using the signing key to verify a signed message.
    {
        let decoded_signing_key = general_purpose::STANDARD
            .decode(encoded_signing_key.clone())
            .unwrap();
        let signing_key_slice = decoded_signing_key.as_slice();
        let signing_key = SigningKey::from_bytes(signing_key_slice.into()).unwrap();

        let verifying_key = VerifyingKey::from(&signing_key);

        let decoded_message_signature = general_purpose::STANDARD
            .decode(encoded_message_signature)
            .unwrap();
        let message_signature =
            Signature::from_bytes(decoded_message_signature.as_slice().into()).unwrap();

        println!(
            "OK {}",
            verifying_key
                .verify("hello".as_bytes(), &message_signature)
                .is_ok()
        );
    }
```

Lastly, I'm going to create a JWT that I can use to verify my did with some external tools.

```rust
    // Generate a JWT that can be used to verify the published signing key.
    {
        let decoded_signing_key = general_purpose::STANDARD
            .decode(encoded_signing_key)
            .unwrap();
        let key_pair = ES256kKeyPair::from_bytes(&decoded_signing_key).expect("decode signing key");

        let claims = Claims::create(Duration::minutes(30))
            .with_issuer("did:web:ngerakines.me")
            .with_audience("did:web:ngerakines.me")
            .with_subject("ngerakines.me".to_string());

        let token = key_pair.sign(claims).expect("failed to sign token");
        println!("token: {}", token);
    }
```

The dependencies include:

```toml
[dependencies]
base64 = "0.21.0"
hex = "0.4.3"
jwt-simple = "0.11.4"
k256 = {version = "0.13.1", features=["jwk", "ecdsa-core", "pem", "serde", "std"]}
rand_core = {version = "0.6.4", features=["getrandom", "serde", "std"]}
```

All together the output looks like:

```
x: 4BcSR4kTERePfHak3/veqt5MR+Rc6CG6hj3ZEi98qcg=
y: VHpGrY8qn4pgEuLS4djBV5JhpNkyo2PlVHiBMoQg/D0=
encoded_signing_key: /q5ducNoEOXAOwoukbWr+EnILGsW5vaYafGZHjo1Chw=
encoded_message_signature: Ywog1XSYatUOqwXGyDfPAtrX1pzbMY0shkc20f1vxTxQPD9I7FKFwIQQlJCIM2tYz+MH/6VyIrMfRU90HYIRnA==
OK true
token: eyJhbGciOiJFUzI1NksiLCJ0eXAiOiJKV1QifQ.eyJpYXQiOjE2ODEzMTY3NjQsImV4cCI6MTcxNTUzMTE2NCwibmJmIjoxNjgxMzE2NzY0LCJpc3MiOiJkaWQ6d2ViOm5nZXJha2luZXMubWUiLCJzdWIiOiJuZ2VyYWtpbmVzLm1lIiwiYXVkIjoiZGlkOndlYjpuZ2VyYWtpbmVzLm1lIn0.AEf900gK_IhTdc3_hVGkOQObvxd5hB_MIXp5JhbyeJhx_2EyPuVprqCzSvxogfG0AdOYZhepMqcbNZUrbJDVBg
```

The `x` and `y` can be used as-is. The `encoded_signing_key` value should be thrown into your password manager for safe keeping. The `token` value is going to be used later on to verify the did is served correctly.

Now that I have a private key, signed message, and some public key bits. I wanted to verify that the keys that I'm generating and using are both correct and compatible with use in other tools, so I decided to use https://pypi.org/project/secp256k1/ to assert some things.

First, I took the base64 encoded signing key (private key) and encoded it to hex to then pipe into the secp256k1 tool:

```bash
export BASE64_SIGNING_KEY="/q5ducNoEOXAOwoukbWr+EnILGsW5vaYafGZHjo1Chw="
export HEX_SIGNING_KEY=$(echo -n "${BASE64_SIGNING_KEY}" | base64 -d | hexdump -v -e '/1 "%02x" ')
```

Then I took the output of that and signed a message:

```bash
python3 -m secp256k1 signrec -k ${HEX_SIGNING_KEY} -m hello | cut -f1 -d' ' - | xxd -r -p | base64 -w 0
```

I then just commented out the block that set `encoded_message_signature` and replaced it with a String literal and verified that the signature was OK.

So at this point I have a the keys used to make my did-web document available to the public. The next step was to publish it.

The site https://ngerakines.me/ is a static site and isn't terribly fancy. Under the hood, nginx is serving content and it is relatively simple. The did-method-web spec says that dids should be available at a specific location but also available with different content types, specifically `application/did+json`, `application/did+ld+json`, and `application/did+cbor`.

CBOR is a binary format that is compatible with JSON, but we'll need a tool to do some conversion.

First, I created the `did.json` as displayed at the top of this post and merged the following content to the document:

```json
{
   "@context": [
    "https://www.w3.org/ns/did/v1",
    "https://w3id.org/security/suites/jws-2020/v1"
  ]
}
```

Then I just uploaded it to the server and created a small nginx location rule to set the content type:

```nginx
# [...]

location = /.well-known/did.json {
    types { } default_type "application/did+ld+json";
}

# [...]

```

Requesting the file shows the correct content type:

```
curl --head https://ngerakines.me/.well-known/did.json
HTTP/2 200
date: Wed, 12 Apr 2023 16:14:09 GMT
content-type: application/did+ld+json
content-length: 846
server: nginx/1.18.0 (Ubuntu)
last-modified: Wed, 12 Apr 2023 15:05:38 GMT
vary: Accept-Encoding
etag: "6436c8c2-34e"
strict-transport-security: max-age=31536000
accept-ranges: bytes
```

Lastly, I'm going to use the [did-jwt](https://www.npmjs.com/package/did-jwt), [did-resolver](https://www.npmjs.com/package/did-resolver), and [web-did-resolver](https://www.npmjs.com/package/web-did-resolver) npm libraries to verify that my published did can validate the locally generated token:

```javascript
import { verifyJWT } from 'did-jwt';
import { Resolver } from 'did-resolver'
import { getResolver } from 'web-did-resolver'
const webResolver = getResolver()
const resolver = new Resolver({...webResolver})
verifyJWT("<token>", {
  resolver,
  audience: 'did:web:ngerakines.me'
}).then(({ payload }) => {
  console.log(payload)
})
```

The result looks good!

```javascript
{
  iat: 1681316562,
  exp: 1715530962,
  nbf: 1681316562,
  iss: 'did:web:ngerakines.me',
  sub: 'ngerakines.me',
  aud: 'did:web:ngerakines.me'
}
```

# What's Next?

As the spec evolves and matures, I'm planning on running my own [data repository](https://atproto.com/guides/data-repos#data-repositories). I plan on having this domain for a while, so using a web did makes sense for me.
