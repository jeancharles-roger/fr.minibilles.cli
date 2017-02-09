import fr.minibilles.cli {
	option,
	parameters,
	help,
	optionsAndParameters,
	parseArguments
}
import ceylon.test {
	assertEquals,
	test,
    assertTrue
}
import ceylon.language.meta.model {
    Class
}

"Simple example for command line"
parameters({`value files`})
shared class Test(
	"Files to process"
	shared [String*] files = empty,
	
	"Shows this help"
	option("help", 'h')
	shared Boolean help = false,
	
	"Presents version"
	option("version", 'v')
	shared Boolean version = false,
	
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

shared void runTest() {
	// prints help
	print(help<Test>("test"));
	
	// parses some arguments
	value [test, errors] = parseArguments<Test>(["-h", "--show", "10", "file1.txt", "file2.txt"]);
	
	// prints the result and the errors if any
	print(optionsAndParameters(test));
	print(errors);
}

shared String typeName<T>() given T satisfies Object {
	assert(is Class<T> type = `T`);
	return type.declaration.name;
}

shared void testArguments<T>([String*] arguments, T? expected) given T satisfies Object {
	print("--- ``typeName<T>()`` for ``arguments`` ---");
	value [result, errors] = parseArguments<T>(arguments);
	print(result);
	print("Errors: ``errors``");
	assertEquals(result, expected);
}

shared void testHelp<T>() given T satisfies Object {
	print("--- ``typeName<T>()`` for help ---");
	value helpString = help<T>("testProgram");
	assertTrue(helpString.size > 0);
	print(helpString);
}

shared test void testNoArguments() => testArguments(empty, Test());

shared test void testVersionHelp() => testArguments(["-v", "-h"], Test{help=true; version=true;});

shared test void testShowHelp() => testHelp<Test>();
