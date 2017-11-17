import ceylon.test {
    test
}

import fr.minibilles.cli {
    option,
    info,
    parameters,
    optionsAndParameters
}

"Grep class that defines options and parameters like the unix grep command."
info("Print a brief help message.", "help")
info("Display version information and exit.", "version", 'V')
parameters({`value pattern`, `value files`})
shared class Grep(
	"Pattern to search"
	shared String pattern,
	
	"Files where to search"
	shared [String*] files = empty,
	
	"Print num lines of trailing context after each match.  
	 See also the -B and -C options."
	option("after-context", 'A')
	shared Integer afterContext = 0,

	"Print num lines of leading context before each match.  
	 See also the -A and -C options."
	option("before-context", 'B') 
	shared Integer beforeContext = 0,
	
	"Treat all files as ASCII text.  Normally grep will simply print 
	 ''Binary file ... matches'' if files contain binary characters.
	 Use of this option forces grep to output lines matching the 
	 specified pattern."
	option("text", 'a') 
	shared Boolean text = false,
	
	"The offset in bytes of a matched pattern is displayed in front 
	 of the respective matched line."
	option("byte-offset", 'b') 
	shared Integer byteOffset = 0,
	
	"Print num lines of leading and trailing context surrounding each
	 match.  The default is 2 and is equivalent to -A 2 -B 2.  
	 Note: no whitespace may be given between the option and its 
	 argument."
	option("context", 'C') 
	shared Integer context = 2,
	
	"Only a count of selected lines is written to standard output."
	option("count", 'c') 
	shared Boolean count = false,
	
	"If specified, it excludes files matching the given filename pattern
	 from the search.  Note that --exclude patterns take priority over 
	 --include patterns, and if no --include pattern is specified, all 
	 files are searched that are not excluded.  Patterns are matched to 
	 the full path specified, not only to the filename component."
	option("exclude") 
	shared [String*] excludePatterns = empty,

	"If specified, only files matching the given filename pattern are
     searched.  Note that --exclude patterns take priority over
     --include patterns.  Patterns are matched to the full path speci-
     fied, not only to the filename component."
	option("include") 
	shared [String*] includePatterns = empty
) {
	
	shared actual Boolean equals(Object other) {
		// TODO really bad
		return string.equals(other.string);
	}
	
	shared actual String string {
		return optionsAndParameters(this);
	}
	
}

shared test void testGrepSimplest() => 
	testArguments(
		["toto", "file1.txt"], 
		Grep{pattern = "toto"; files = ["file1.txt"];}
	);
		
shared test void testGrepTwoFiles() =>
	testArguments(
		["toto", "file1.txt", "file2.txt"], 
		Grep{pattern = "toto"; files = ["file1.txt", "file2.txt"];}
	);

shared test void testGrepA3() => 
	testArguments(
		["-A", "3", "toto", "file1.txt", "file2.txt"], 
		Grep{afterContext = 3; pattern = "toto"; files = ["file1.txt", "file2.txt"];}
	);

shared test void testGrepAequals3() => 
	testArguments(
		["-A=3", "toto", "file1.txt", "file2.txt"], 
		Grep{afterContext = 3; pattern = "toto"; files = ["file1.txt", "file2.txt"];}
	);


shared test void testGrepAfterContext3() => 
	testArguments(
		["--after-context", "3", "toto", "file1.txt", "file2.txt"], 
		Grep{afterContext = 3; pattern = "toto"; files = ["file1.txt", "file2.txt"];}
	);

shared test void testGrepAfterContextEquals3() => 
		testArguments(
	["--after-context=3", "toto", "file1.txt", "file2.txt"], 
	Grep{afterContext = 3; pattern = "toto"; files = ["file1.txt", "file2.txt"];}
);

shared test void testGrepA3B5() => 
	testArguments(
		["-A", "1", "-B", "5", "toto", "file1.txt", "file2.txt"],
		Grep{afterContext = 1; beforeContext = 5; pattern = "toto"; files = ["file1.txt", "file2.txt"];}
	);

shared test void testGrepAC() => 
	testArguments(
		["-ac", "toto", "file1.txt", "file2.txt"],
		Grep{text = true; count = true; pattern = "toto"; files = ["file1.txt", "file2.txt"];}
	);

shared test void testGrepAB8() => 
	testArguments(
		["-AB", "8", "toto", "file1.txt", "file2.txt"],
		Grep{afterContext = 8; beforeContext = 8; pattern = "toto"; files = ["file1.txt", "file2.txt"];}
	);

shared test void testGrepAB() {
	testArguments<Grep>(
		["-AB", "5", "file1.txt", "file2.txt"],
		Grep{afterContext = 5; beforeContext = 5; pattern = "file1.txt"; files = ["file2.txt"];}
	);
}

shared test void testGrepHelp() => testHelp<Grep>();
