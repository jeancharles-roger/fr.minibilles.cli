import ceylon.test {
    test
}

import fr.minibilles.cli {
    option,
    info,
    creator,
    optionsAndParameters
}

{String+} parseFile(String verbatim) => verbatim.split('.'.equals);

"Base options"
info("Shows help", "help", 'h')
info("Shows version", "version", 'v')
shared class BaseOptions(

    "Files to process"
    option("files", 'f') creator(`function parseFile`)
    shared {String*} files = []

) { }

"Program options"
shared class ProgOptions(

    "Pattern for command"
    option("pattern", 'p')
    shared String pattern = "",

    {String*} files = []

) extends BaseOptions(files) {

    shared actual Boolean equals(Object other) {
        // TODO really bad
        return string.equals(other.string);
    }

    shared actual String string {
        return optionsAndParameters(this);
    }
}

shared test void testBaseHelp() => testHelp<BaseOptions>();
shared test void testProgHelp() => testHelp<ProgOptions>();

shared test void testProg1() =>
    testArguments(["-p", "myPattern"], ProgOptions {pattern = "myPattern";});

shared test void testProg2() =>
    testArguments(["-f", "file1"], ProgOptions {files = {"file1"};});
