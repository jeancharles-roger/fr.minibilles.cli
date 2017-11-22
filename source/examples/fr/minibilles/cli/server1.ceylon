import ceylon.json {
    JsonObject
}
import ceylon.test {
    test
}

import fr.minibilles.cli {
    option,
    optionsAndParameters,
    creator
}

[String+] parseRepos(String verbatim) {
	value result = verbatim.split(','.equals).sequence();
	return result;
}

"Starts Web server"
class Server1(
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

shared test void testServer1NoArgument() =>
	testArguments(
		[], 
		Server1 {}
	);
shared test void testServer1EmptyJson() =>
		testJson(
			JsonObject{},
			Server1 {}
		);

shared test void testServer1Assets() =>
		testArguments(
			["--assets", "assets"],
			Server1 {assetsPath = "assets";}
		);
shared test void testServer1AssetsJson() =>
		testJson(
			JsonObject{ "assets" -> "assets" },
			Server1 {assetsPath = "assets";}
		);

shared test void testServer1Repo1() =>
		testArguments(
	["--repos", "repo1"], 
	Server1 {repos = ["repo1"];}
);
shared test void testServer1Repo1Json() =>
	testJson(
		JsonObject{"repos" -> "repo1"},
		Server1 {repos = ["repo1"];}
);

shared test void testServer1Help() => testHelp<Server1>();
