`minibilles.cli` allows to create command line interfaces (CLI) 
using simple annotations.

Using `option` and `parameters` annotation you can simply create a CLI:

```ceylon
"Grep class that defines options and parameters like the unix grep command."
parameters({`value pattern`, `value files`})
shared class Grep(
	"Pattern to search"
	shared String pattern,
	
	"Files where to search"
	shared [String*] files = empty,
	
	"Print num lines of trailing context after each match.  See also the -B and -C options."
	option("after-context", 'A') Integer afterContext = 0,

	"Print num lines of leading context before each match.  See also the -A and -C options."
	option("before-context", 'B') Integer beforeContext = 0,
	
	"Treat all files as ASCII text.  Normally grep will simply print \`\`Binary file ... matches'' if files contain binary characters.  Use of this option
     forces grep to output lines matching the specified pattern."
	option("text", 'a') Boolean text = false,
	
	"The offset in bytes of a matched pattern is displayed in front of the respective matched line."
	option("byte-offset", 'b') Integer byteOffset = 0,
	
	"Print num lines of leading and trailing context surrounding each match.  The default is 2 and is equivalent to -A 2 -B 2.  Note: no whitespace may be
     given between the option and its argument."
	option("context", 'C') Integer context = 2,
	
	"Only a count of selected lines is written to standard output."
	option("count", 'c') Boolean count = false,
	
	"If specified, it excludes files matching the given filename pattern from the search.  Note that --exclude patterns take priority over --include pat-
     terns, and if no --include pattern is specified, all files are searched that are not excluded.  Patterns are matched to the full path specified, not
     only to the filename component."
	option("exclude") {String*} patterns = empty
) { }
```


# Notes

- Multiple parameters must be of type `Sequential`, `Iterable` isn't supported.