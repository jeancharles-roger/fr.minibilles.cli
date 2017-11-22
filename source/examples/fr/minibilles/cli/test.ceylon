import ceylon.json {
    JsonObject
}
import ceylon.language.meta.model {
    Class
}
import ceylon.test {
    assertEquals,
    test,
    assertTrue
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
info("Shows this help", "help", 'h')
info("Presents version", "version", 'v')
shared class Test(
	"Files to process"
	shared [String*] files = empty,
	
	"Show some lines"
	option("show", 's')
	shared Integer showLine = 1
) { 
	shared actual Boolean equals(Object other) {
		// TODO really bad
		return string.equals(other.string);
	}
	
	shared actual String string {
		return optionsAndParameters(this);
	}
}

void runTest() {
	// prints help
	print(help<Test>("test"));
	
	// parses some arguments
	value result = parseArguments<Test>(["--show", "10", "file1.txt", "file2.txt"]);
	
	// prints the result and the errors if any
	switch(result)
	case(is Test) {
		print(optionsAndParameters(result));
	}
	case(is Info) {
		print("Info: ``result.longName``");
	}
	else {
		print("Errors: `` result ``");
	}
	 
}

String typeName<T>() given T satisfies Object {
	assert(is Class<T> type = `T`);
	return type.declaration.name;
}

void testArguments<T>([String*] arguments, T|Info|[String+] expected) given T satisfies Object {
	print("--- ``typeName<T>()`` for ``arguments`` ---");
	value result = parseArguments<T>(arguments);
	switch(result)
	case(is Info) {
		print("Info: ``result.longName``");
	}
	case (is [String+]) {
		print("Errors: ``result``");
	}
	else {
		print(optionsAndParameters(result));
	}
	assertEquals(result, expected);
}

void testJson<T>(JsonObject json, T|Info|[String+] expected) given T satisfies Object {
	print("--- ``typeName<T>()`` for ``json`` ---");
	value result = parseJson<T>(json.string);
	switch(result)
	case(is Info) {
		print("Info: ``result.longName``");
	}
	case (is [String+]) {
		print("Errors: ``result``");
	}
	else {
		print(optionsAndParameters(result));
	}
	assertEquals(result, expected);
}


shared void testHelp<T>() given T satisfies Object {
	print("--- ``typeName<T>()`` for help ---");
	value helpString = help<T>("testProgram");
	assertTrue(helpString.size > 0);
	print(helpString);
}

shared test void testNoArguments() => testArguments<Test>(empty, Test());
shared test void testEmptyJson() => testJson<Test>(JsonObject{}, Test());

shared test void testVersionInfo() => testArguments<Test>(["--version"], Info("version"));
shared test void testVersionInfoJson() => testJson<Test>(JsonObject{"version" -> true}, Info("version"));

shared test void testHelpInfo() => testArguments<Test>(["--help"], Info("help"));
shared test void testHelpInfoJson() => testJson<Test>(JsonObject{"help" -> true}, Info("help"));

shared test void testShowHelp() => testHelp<Test>();
