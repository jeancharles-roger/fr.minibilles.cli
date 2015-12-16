String usage = 
	"""
	   Usage: 
	     ceylon run minibilles.daemon [options*] start|stop|restart [process] [processArgs*]
	     
       Where options can be:
       - -v: print version,
       - -h: print current help,
       - -p|--pids=folder: set pid folder to given one
	   """;

interface Command of start|stop|restart {}
object start satisfies Command { 
	shared actual String string = "start";
}
object stop satisfies Command {
	shared actual String string = "stop";
}
object restart satisfies Command {
	shared actual String string = "restart";
}

[DaemonOption, [String*]] parseDaemonArguments([String*] arguments) {
	
	variable Boolean version = false;
	variable Boolean help = false;
	
	variable Command command = start;
	
	variable String process = "";
	variable [String*] processArguments = empty;
	
	variable [String*] errors = empty;
	
	void addError(String error) {
		errors = errors.append([error]);
	}
	
	if (nonempty arguments) {
		variable Boolean foundCommand = false;
		variable Boolean foundProcess = false;
		for (argument in arguments) {
			if (foundCommand) {
				if (!foundProcess) {
					foundProcess = true;
					process = argument;
				} else {
					processArguments = processArguments.append([argument]);
				}
			} else {
				switch(argument)
				case ("-v") { version = true; }
				case ("-h") { help = true; }
				case ("--") { foundCommand = true; }
				else {
					if (argument.startsWith("-")) {
						addError("Option '``argument``' isn't supported.");
					} else {
						if (!foundCommand) {
							foundCommand = true;
							value parsed = parseCaseType<Command>(argument);
							if (exists parsed) {
								command = parsed;
							} else {
								addError("Command ``argument`` isn't one of `` `Command`.caseValues ``.");
							}
						}
					}
				}
			}
		}
		
		if (!foundCommand) {
			addError("No command given (`` `Command`.caseValues ``).");
		} else if (!foundProcess) {
			addError("No process given.");
		}
		
	} else {
		addError("No argument given.");
	}
	return [
		DaemonOption(version, help, OptionPart("mano"), command, process, processArguments),
		errors
	];
}

class OptionPart(
	shared String text
) {
	shared actual String string => "OptionPart(``text``)";
}

parameters({`value command`, `value process`, `value processArguments`})
class DaemonOption(
	"Shows daemon version"
	option("version", 'v')
	 shared Boolean version = false,
	
	"Prints this help"
	option("help", 'h')
	shared Boolean help = false,
	
	"Test constructor"
	option("text", 't')
	shared OptionPart part = OptionPart("hello"),
	
	"Command to execute"
	shared Command command = start,
	
	"Process to run"
	shared String process = "",
	
	"Arguments for process to run"
	shared [String*] processArguments = empty
) {

	shared actual String string => 
			"Options:
			  - version => ``version``,
			  - help => ``help``,
			  - part => ``part``,
			  - command => ``command``
			  - process => ``process``,
			  - processArguments => ``processArguments``
			 ";
	
}

void startProcess(DaemonOption options) {
	print("Starting process '``options.process``'.");
}

void stopProcess(DaemonOption options) {
	print("Stopping process '``options.process``'.");	
}

void restartProcess(DaemonOption options) {
	stopProcess(options);
	startProcess(options);
}

"Run the module `minibilles.daemon`."
shared void run() {

/*
	print(parseType(`Integer`, "9"));
	print(parseType(`Float`, "9."));
	print(parseType(`Command`, "start"));
	print(parseType(`Path`, "/hello/world"));
*/

	print("Arguments");
	print(process.arguments);

	// parses arguments
	print("Mano");
    value [options1,errors1] = parseDaemonArguments(process.arguments);
  	print(options1);
  	print(errors1);
  	
  	print("Auto");
  	value [options2,errors2] = parseArguments<DaemonOption>(process.arguments);
  	print(options2);
  	print(errors2);
  	
  	/*
  	if (nonempty errors) {
  		// arguments are invalid
  		process.writeErrorLine("Can't start daemon:");
  		for (error in errors) {
  			process.writeErrorLine("- ``error``");
  		}
  	} else {
   		// execute command
  		switch(options.command)
   		case (start) {
   			startProcess(options);
   		}
   		case (stop) {
   			stopProcess(options);
   		}
   		case (restart) {
   			restartProcess(options);
   		}
	}	
   */
}