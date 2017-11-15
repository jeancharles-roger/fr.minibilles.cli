`fr.minibilles.cli` allows to create command line interfaces (CLI) using simple annotations.

Thanks to [David Festal](https://github.com/davidfestal) for the `info` annotation and the bug fixes.

[![Build Status](https://travis-ci.org/jeancharles-roger/fr.minibilles.cli.svg?branch=master)](https://travis-ci.org/jeancharles-roger/fr.minibilles.cli)

# Getting Started

First import the module: `import fr.minibilles.cli;` in your `module.ceylon`.

Using `option`, `info` and `parameters` annotation you can simply create a CLI:

Here is a simple example for a declaration:

```ceylon
"Simple example for command line"
parameters({`value files`})
info("Show this help", "help", 'h')
info("Presents the program version", "version", 'v')
shared class Example1(
    "Files to process"
    shared [String*] files,

    "Show some lines"
    option("show", 's')
    shared Integer showLine
) { }
```

The `parameters()` annotation allows to describe a list of arguments without any dash. 
For instance, here with `example1 file1.txt file2.ceylon` will add `file1.txt` and `file2.ceylon` to the `files` value.
There can be only one `parameters` annotation on the class.

The `info()` annotation on the class adds meta options that are simple switches to print some information about the program.
The example `info("Show this help", "help", 'h')` adds a `-h|--help` options that returns as an `Info` object from the parsing.

The `option` annotation on a value declaration associates an argument flag (`-short` or `--longName`) with a value in the class.
 
Here is an example how to parse the arguments and treat the result:
```ceylon
 // parses some arguments
value result = parseArguments<Example1>(args);

switch (result)
case (is Example1) {
    print("Executing test with ``optionsAndParameters<Example1>(result)``");
}
case (is Info) {
    switch (result.longName)
    case ("help") {
        // prints help
        print(help<Example1>("example1"));
    }
    case ("version") {
        print("Version `` `module fr.minibilles.cli`.version ``");
    }
    else {
        print("Information ``result.longName`` is not supported");
    }
}
case (is [String+]) {
    print("Parsing argument has errors ``result``");
}
```


This 
```ceylon
example1(["-h"]);
example1(["--show", "10", "file1.txt", "file2.txt"]);
example1(["--version"]);
```

will print

```
Usage: example1 [options] [files]
  Simple example for command line
where:
    - --show=value | -s value: Show some lines
    - --help | -h : Show this help
    - --version | -v : Presents the program version
Executing test with Example1:
-showLine: 10
-files: [file1.txt, file2.txt]
Version 0.2.1
```

To print the help for a given class just use:

```ceylon
print(help<Example1>("example1"))
```

# Supported types

Here are the supported types:

- `String`
- `Boolean`
- `Float`
- `Integer`
- Case objects will search for the object with the matching `string`, for instance:

```ceylon
interface Command of start|stop|restart {}
object start satisfies Command { 
	shared actual String string = "start";
}
object stop satisfies Command {
	shared actual String string = "stop";
}
object restart satisfies Command {
	shared actual String string = "restart";
}
```

For any other type, a `creator` annotation can be added to set a creator function. It reference a function taking a `String` as parameter and retreiving the value type or nothing. For instance:

```ceylon
option("source") creator(`function parsePath`)
shared Path source = parsePath("/")
```

`Sequential` allows to defines multiple arguments: `[String+] files`. (see limitations for multiple arguments).

# Known limitations

- Multiple value can only be `[String*]` for now (will be fixed later on).
- In the `parameters` list the first sequential value found will use all the remaining arguments.
- Multiple parameters must be of type `Sequential`, `Iterable` isn't supported.
- Inheritance declaration haven't been tested (to be done).
- Case object won't be correctly printed for the help (todo).

# Things to come

- Reads the same options from a JSON configuration file.

# Examples

Here are some examples:

- [Test](https://github.com/jeancharles-roger/fr.minibilles.cli/blob/master/source/examples/fr/minibilles/cli/test.ceylon)
- [Grep](https://github.com/jeancharles-roger/fr.minibilles.cli/blob/master/source/examples/fr/minibilles/cli/grep.ceylon)
- [Server1](https://github.com/jeancharles-roger/fr.minibilles.cli/blob/master/source/examples/fr/minibilles/cli/server1.ceylon)
- [Server2](https://github.com/jeancharles-roger/fr.minibilles.cli/blob/master/source/examples/fr/minibilles/cli/server2.ceylon)

