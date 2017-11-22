import ceylon.json {
    JsonObject,
    JsonArray
}
import ceylon.test {
    test
}

import fr.minibilles.cli {
    option,
    parameters,
    help,
    optionsAndParameters,
    parseArguments,
    parseJson,
    Info,
    info
}

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


void example1([String*]|JsonObject args) {
    // parses some arguments
    value result = switch(args)
    case (is [String*]) parseArguments<Example1>(args)
    case (is JsonObject) parseJson<Example1>(args.string);

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
}

test void testExample1() {
    example1(["-h"]);
    example1(["--show", "10", "file1.txt", "file2.txt"]);
    example1(["--version"]);
}

test void testExample1Json() {
    example1(JsonObject{"help" -> true});
    example1(JsonObject{"show" -> 10, "--" -> JsonArray{"files1.txt", "file2.txt"}});
    example1(JsonObject{"version" -> true});
}
