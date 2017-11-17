import ceylon.language.meta {
    annotations
}
import ceylon.language.meta.declaration {
    ValueDeclaration
}
import ceylon.language.meta.model {
    Class
}

 shared String optionsAndParameters<T>(T source) given T satisfies Object {
	value type = `T`;
	assert(is Class<T> type);
	
	value options = [
		for (oneValue in type.declaration.memberDeclarations<ValueDeclaration>()) 
			if (exists option = annotations(`OptionAnnotation`, oneValue)) oneValue 
	];
	
	value optionsPrint = {
		for (option in options) 
			if (exists attribute = type.getAttribute<T, Anything>(option.name)) 
				if (exists get = attribute.bind(source).get()) 
					"-``option.name``: ``get``"
	};
	
	value parameters = annotations(`ParametersAnnotation`, type.declaration);
	value parametersPrint = {
		if (exists parameters) 
			for (parameter in parameters.declarations) 
				if (exists attribute = type.getAttribute<T, Anything>(parameter.name)) 
					if (exists get = attribute.bind(source).get()) 
						"-``parameter.name``: ``get``"
	};
	
	return concatenate(optionsPrint, parametersPrint).fold(type.declaration.name+":")((a,i) => a +"\n"+ i);
}

String tabbedString(String source) => "\t\t``source.replace("\n", "\n\t\t")``";

String prettyPrintShortName(Character shortName, Boolean hasValue = true) =>
	let (v = if (hasValue) then " value" else "")
		if (!shortName == '\0') then "-``shortName````v``, " else "";

String prettyPrintLongName(String longName, Boolean hasValue = true) =>
	"--``longName````if (hasValue) then "=value" else ""``";

String optionPrettyString(ValueDeclaration declaration, OptionAnnotation option) =>
	let (hasValue = !isBooleanValue(declaration))
		prettyPrintShortName(option.shortName, hasValue) + prettyPrintLongName(option.longName, hasValue);

String infoPrettyString(InfoAnnotation info) =>
		prettyPrintShortName(info.shortName, false) + prettyPrintLongName(info.longName, false);

shared String help<T>(String programName) given T satisfies Object {
	value type = `T`;
	assert(is Class<T> type);
	
	value general = if (exists doc = annotations(`DocAnnotation`, type.declaration)) then doc.description else "";
	
	value additionalDoc = if (exists doc = annotations(`AdditionalDocAnnotation`, type.declaration)) then "\n``doc.docProvider.get()?.string else ""``" else "";
	
	value parameters = annotations(`ParametersAnnotation`, type.declaration);
	value parametersPrint = if (exists parameters) then 
		parameters.declarations.fold(" [--] ")((a,p) => " [" + p.name + "]") else
		"";
	
	value options = [
		for (oneValue in type.declaration.memberDeclarations<ValueDeclaration>()) 
			if (exists option = annotations(`OptionAnnotation`, oneValue)) option -> oneValue 
	];
	
	value optionsPrint = {
		for (option in options) 
			"\t``optionPrettyString(option.item, option.key)``\n" +
			tabbedString(if (exists doc = annotations(`DocAnnotation`, option.item)) then doc.description else "")
	};
	
	value infosPrint = [
    	for (info in type.declaration.annotations<InfoAnnotation>()) 
	        "``infoPrettyString(info)``\n``tabbedString(info.description)``"
	];
	
	return "Usage: ``programName`` [options]``parametersPrint``
	          ``general + additionalDoc``

	        where:
	        ``"\n\n".join(concatenate(optionsPrint, infosPrint).map((l)=>"  " + l))``";
	
}
