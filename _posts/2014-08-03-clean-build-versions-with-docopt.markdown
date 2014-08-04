---
layout: post
title: Clean Build Versions With DocOpt
---

With some recent Go projects, I've been using [docopt.go](https://github.com/docopt/docopt.go) for command line argument parsing. It greatly reduces the complexity of dealing with arguments and options. On it's own, arguments can be processed without much work:

```go
package main

import (
	"github.com/docopt/docopt.go"
)

var (
	githash string = ""
)

func main() {
	usage := `Awesome

Usage: awesome [--help --version --config=<file>]
       awesome daemon [--help --version --config <file>]
       awesome thing [--verbose... ] <with> <more>...

Options:
  --help     Show this screen.
  --version  Show version.
  --verbose  Verbose
`

	arguments, _ := docopt.Parse(usage, nil, true, version(), false)
	// ... do something with arguments
}

func version() string {
	previewVersion := "1.0.0"
	if len(githash) > 0 {
		return previewVersion + "+" + githash
	}
	return previewVersion
}

```

What I've also been doing is using a small Makefile to add extra information to the version:

```
all:
	go build -ldflags "-X main.githash `git rev-parse --short HEAD`"
```

If the `go build` command is used, then the version given to docopt is just 1.0.0, but if the main.githash is set as it is in the Makefile, then the version ends up being something like "1.0.0+b74276b".

    $ ./awesome --version
    1.0.0+b74276b

You can take it one step further and have the version set as a var that can easily be updated with sed or awk. An example would look something like:

```
package main

var (
	AWESOME_VERSION = "1.0.0"
)
```

Using awk to update the version would look like this:

    $ awk '/AWESOME_VERSION/ { sub($3, "\"2.0.0\""); print; next}1' version.go
    package main

    var (
    	AWESOME_VERSION = "2.0.0"
    )
