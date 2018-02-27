---
title: "Protoc Gen Whatever"
date: 2018-02-27T10:49:30-05:00
---

Today I released version 0.1.0 of protoc-gen-whatever, a plugin that allows for protocol buffer definitions to be used as inputs to Golang's text template library to generate files.

It can be installed with `go get -u github.com/ngerakines/protoc-gen-whatever/cmd/protoc-gen-whatever` or by downloading one of the release files.

Usage is faily simple, for a given protofile as an input, you provide the template that you want rendered and the location of the output.

<center>**Sample proto file**</center>
```
syntax = "proto3";

package test;

message Example {
    string label = 1;
}

service Foo {
    rpc GetFoo(GetFooReq) returns (GetFooRes);
}

message GetFooReq {

}

message GetFooRes {

}
```

<center>**Sample template file**</center>
```
{{range .ProtoFile}}{{.Name}}{{range .MessageType}}
*{{.Name}}{{end}}{{end}}
```

Given the above input file named simple.proto and template named simple.tpl, the following command can be used:

    $ protoc --plugin=protoc-gen-whatever --whatever_out=. --whatever_opt=simple.tpl,output.txt simple.proto

The output is what you'd expect:

```
simple.proto
*Example
*GetFooReq
*GetFooRes
```

When you combine this with regular `protoc` use, it can be a very easy and powerful to way generate additional source files.