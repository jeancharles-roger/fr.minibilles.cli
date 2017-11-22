import ceylon.json {
    JsonObject,
    JsonArray
}
import ceylon.test {
    test
}

import fr.minibilles.cli {
    option,
    info,
    creator,
    parameters,
    optionsAndParameters
}

{String+} parseFile(String verbatim) => verbatim.split('.'.equals);

"Base options"
info("Shows help", "help", 'h')
info("Shows version", "version", 'v')
parameters({`value files`})
shared class BaseOptions(

    "Map files"
    option("map", 'm') creator(`function parseFile`)
    shared {String*} map = [],

    shared [String*] files = []

) { }

"Program options"
shared class ProgOptions(

    "Pattern for command"
    option("pattern", 'p')
    shared String pattern = "",

    {String*} map = [],
    [String*] files = []
) extends BaseOptions(map, files) {

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
shared test void testProg1Json() =>
    testJson(JsonObject{"pattern" -> "myPattern"}, ProgOptions {pattern = "myPattern";});

shared test void testProg2() =>
    testArguments(["-m", "source1"], ProgOptions {map = {"source1"};});
shared test void testProg2Json() =>
    testJson(JsonObject{"map" -> "source1"}, ProgOptions {map = {"source1"};});

shared test void testProg3() =>
    testArguments(
        ["-m", "source1", "file1", "file2"],
        ProgOptions {map = {"source1"}; files= ["file1", "file2"];}
    );
shared test void testProg3Json() =>
    testJson(
        JsonObject{ "map" -> "source1", "--" -> JsonArray{"file1", "file2"}},
        ProgOptions {map = {"source1"}; files= ["file1", "file2"];}
    );
