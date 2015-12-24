import minibilles.cli {
	option,
	optionsAndParameters,
	creator
}
import ceylon.test {
	test
}

[String+] parseRepos(String verbatim) {
	value result = verbatim.split(','.equals).sequence();
	assert(nonempty result);
	return result;
}

"Starts Web server"
class Server(
	"Path to static assets"
	option("assets", 'a')
	shared String assetsPath = "resource",
	
	"Served repositories for the client"
	option("repos", 'r') creator(`function parseRepos`)
	shared [String+] repos = ["repo"]
) {
	shared actual Boolean equals(Object other) {
		// TODO really bad
		return string.equals(other.string);
	}
	
	shared actual String string {
		return optionsAndParameters(this);
	}
}

shared test void testServerNoArgument() => 
	testArguments(
		[], 
		Server{}
	);

shared test void testServerAssets() => 
	testArguments(
		["--assets", "assets"], 
		Server{assetsPath = "assets";}
	);

shared test void testServerRepo1() => 
		testArguments(
	["--repos", "repo1"], 
	Server{repos = ["repo1"];}
);
