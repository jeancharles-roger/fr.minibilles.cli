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

String prettyPrintShortName(Character shortName) => if (!shortName == '\0') then " | -``shortName`` " else "";
        
String optionPrettyString(ValueDeclaration declaration, OptionAnnotation option) {
	return if (isBooleanValue(declaration)) then
		"--``option.longName``" + prettyPrintShortName(option.shortName) else 
		"--``option.longName``=value" + (if (!option.shortName == '\0') then " | -``option.shortName`` value" else "");
}

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
	
	// TODO handle spaces before new line for lisibility
	value optionsPrint = {
		for (option in options) 
			"  - ``optionPrettyString(option.item, option.key)``: " + 
			(if (exists doc = annotations(`DocAnnotation`, option.item)) then doc.description else "")
	};
	
	value infosPrint = [
    	for (info in type.declaration.annotations<InfoAnnotation>()) 
	        "  - --`` info.longName + prettyPrintShortName(info.shortName) ``: `` info.description``"
	];
	
	return "Usage: ``programName`` [options]``parametersPrint``
	          ``general + additionalDoc``
	        where:
	        ``"\n".join(concatenate(optionsPrint, infosPrint).map((l)=>"  " + l))``";
	
}
