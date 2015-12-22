import minibilles.cli {
	option,
	parameters,
	help,
	optionsAndParameters,
	parseArguments
}

"Simple example for command line"
parameters({`value files`})
shared class Test(
	"Files to process"
	shared [String*] files,
	
	"Shows this help"
	option("help", 'h')
	shared Boolean help = false,
	
	"Presents version"
	option("version", 'v')
	shared Boolean version = false,
	
	"Show some lines"
	option("show", 's')
	shared Integer showLine = 1
) { }

shared void runTest() {
	// prints help
	print(help<Test>("test"));
	
	// parses some arguments
	value [test, errors] = parseArguments<Test>(["-h", "--show", "10", "file1.txt", "file2.txt"]);
	
	// prints the result and the errors if any
	if (exists test) {
		print(optionsAndParameters(test));
	}
	print(errors);
}