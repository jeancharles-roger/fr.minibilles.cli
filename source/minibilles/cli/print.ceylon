import ceylon.language.meta {
	annotations
}
import ceylon.language.meta.declaration {
	ValueDeclaration,
	NestableDeclaration
}
import ceylon.language.meta.model {
	Class
}

shared String printOptionsAndParameters<T>(T source) given T satisfies Object {
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

String getDescription(NestableDeclaration declaration) {
	return 
		if (exists doc = annotations(`DocAnnotation`, declaration)) then
			doc.description
		else
			"";
}

shared String printHelp<T>(String programName) {
	value type = `T`;
	assert(is Class<T> type);
	
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
			"  - ``option.key.string``" + (if (exists doc = annotations(`DocAnnotation`, option.item)) then doc.description else "")
	};
	
	return "Usage: ``programName`` [options]``parametersPrint``
	         where:
	         ``optionsPrint.fold("")((a,i) => a +"\n"+ i)``
	        ";
	
}