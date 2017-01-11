import ceylon.test {
    test
}

import fr.minibilles.cli {
    option,
    optionsAndParameters
}

"Server command line options"
//parameters({`value files`})
shared class Server2(

"Shows this help"
option("help", 'h')
shared Boolean help = false,

"Presents version"
option("version", 'v')
shared Boolean version = false,

"Resource center directory"
option("resource-center", 'r')
shared String resourceCenterDirectory = "./rc"
) {
    shared actual Boolean equals(Object other) {
        // TODO really bad
        return string.equals(other.string);
    }

    shared actual String string {
        return optionsAndParameters(this);
    }
}

shared test void testServer2NoArgument() => testArguments([],Server2 {});

shared test void testServer2Help() => testHelp<Server2>();
