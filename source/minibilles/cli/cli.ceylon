import ceylon.collection {
	HashMap,
	ArrayList
}
import ceylon.language.meta {
	annotations
}
import ceylon.language.meta.declaration {
	ValueDeclaration,
	ClassDeclaration,
	OpenClassOrInterfaceType,
	ClassOrInterfaceDeclaration,
	FunctionDeclaration
}
import ceylon.language.meta.model {
	ClassOrInterface,
	Class,
	Type
}

"Annotation for an option."
shared final annotation class OptionAnnotation(
	shared String longName, 
	shared Character shortName
) 
satisfies OptionalAnnotation<OptionAnnotation, ValueDeclaration> {
	shared actual String string => 
			"--``longName``=value" +
            (if (!shortName == '\0') then "|-``shortName`` value" else "");
}

"Defines value as an option of the format '-shortName argument' or '--longName=argument':
 - if value is a Boolean the argument is optional, 
 - if value is a String the argument will be copied,
 - if value is a Float|Integer the argument is parsed,
 - if value is a case Class, it searches for the object where `Object.string` matches,
 - for other case, it needs a [[creator]] annotation.
 
 Example:
     option(\"text\", 'a') Boolean text = false
     option(\"exclude\") {String*} exclude = empty
 "
shared annotation OptionAnnotation option(
	String longName, Character shortName = '\0'
) => OptionAnnotation(longName, shortName);


"Annotation for parameters."
shared final annotation class ParametersAnnotation(
	shared {ValueDeclaration*} declarations
) satisfies OptionalAnnotation<ParametersAnnotation, ClassDeclaration> 
{
	shared actual String string => declarations.string;
}

"Defines class with parameters by giving the list of values it needs as parameter.
 
 Example:
     parameters({`value pattern`, `value files`}) 
 "
shared annotation ParametersAnnotation parameters({ValueDeclaration*} declarations)
	 => ParametersAnnotation(declarations);

"Annotation for creator."
shared final annotation class CreatorAnnotation(
	shared FunctionDeclaration creator
) satisfies OptionalAnnotation<CreatorAnnotation, ValueDeclaration> 
{
	shared actual String string => "Creator: ``creator``";
}

"Creator function for option or parameter"
shared annotation CreatorAnnotation creator(FunctionDeclaration creator)
	 => CreatorAnnotation(creator);

Object?|{Object?+} parseValue(ValueDeclaration declaration, String|{String+} verbatim) {
	switch(verbatim)
	case (is String) { return parseOneValue(declaration, verbatim); }
	case (is {String+}) { return { for (one in verbatim) parseOneValue(declaration, one) }; }
}

Object? parseOneValue(ValueDeclaration declaration, String verbatim) {
	value annotation = annotations(`CreatorAnnotation`, declaration);
	if (exists annotation) {
		// uses the creator
		value creator = annotation.creator.apply<Object, [String]>();
		return creator.apply(verbatim);
	} else {
		// parses the verbatim
		value childOpenType = declaration.openType;
		assert(is OpenClassOrInterfaceType childOpenType);
		value childType = childOpenType.declaration.apply<Anything>();
		if (childType == `String`) {
			return verbatim;
		} else if (childType == `Integer`) {
			return parseInteger(verbatim);
		} else if (childType == `Float`) {
			return parseFloat(verbatim);
		} else if (childType == `Boolean`) {
			return if (verbatim.empty) then true else parseBoolean(verbatim);
		} else if (is ClassOrInterface<Object> childType) {
			// searches for a case value
			value caseValue = childType.caseValues.find((Object elem) => verbatim == elem.string);
			if (exists caseValue) { return caseValue; } 
			else if (is Class<Object> childType) {
				// tries a constructor
				value constructors = childType.getCallableConstructors<[String]>();
				if (nonempty constructors) {
					return constructors.first.declaration.apply<Object, [String]>().apply(verbatim);
				} else {
					throw Exception("No constructor([String]) found for type '``childType``' for ``declaration.name``");
				}
			} else {
				throw Exception("Can't instantiate type '``childType``' for ``declaration.name``");
			}
		} else {
			throw Exception("Can't parse type '``childType``' for ``declaration.name``");
		} 
	}
}

T? parseCaseType<T>(String name) 
	given T satisfies Object 
{
	Type<T> type = `T`;
	assert(is ClassOrInterface<T> type);
	return type.caseValues.find((T elem) => name == elem.string);
}

Boolean subTypeOf(ClassOrInterfaceDeclaration subType, ClassOrInterfaceDeclaration superType) {
	if (subType == superType) { return true; }
	value extendedType = subType.extendedType;
	if (exists extendedType, subTypeOf(extendedType.declaration, superType)) { return true; }
	for (satisfied in subType.satisfiedTypes) {
		if (subTypeOf(satisfied.declaration, superType)) {return true;}
	}
	return false;
}

// TODO add check options 

"Parses arguments to construct given type."
shared [T?, [String*]] parseArguments<T>([String*] arguments) 
	given T satisfies Object {
	
	value type = `T`;
	assert(is Class<T> type);
	
	value parameters = annotations(`ParametersAnnotation`, type.declaration);
	if (exists parameters) {
		value options = [
			for (oneValue in type.declaration.memberDeclarations<ValueDeclaration>()) 
				let (option = annotations(`OptionAnnotation`, oneValue))
					if (exists option) then oneValue -> option else null
		].coalesced;
		
		value verbatimOptionMap = HashMap<ValueDeclaration, String>();
		value verbatimParameterList = ArrayList<String>();
		T? result;
		value errors = ArrayList<String>();

		// collects options and parameters from arguments
		if (nonempty arguments) {
			variable Boolean optionsMode = true;
			for (argument in arguments) {
				if (optionsMode && argument == "--") {
					// options are ended
					optionsMode = false;
				} else if (optionsMode && argument.startsWith("-")) {
					// decodes option
					value islongOption = argument.startsWith("--");
					value trimmedOption = argument.trim('-'.equals);
					value equalsIndex = trimmedOption.firstOccurrence('=', 0, trimmedOption.size);
					value [optionName, verbatimOption] = 
						if (exists equalsIndex) 
							then [trimmedOption.spanTo(equalsIndex-1), trimmedOption.spanFrom(equalsIndex+1)] 
							else [trimmedOption, ""]; 
					
					value option = options.find((element) => 
						if (islongOption) then optionName == element.item.longName else optionName == element.item.shortName
					);
					
					if (exists option) {
						verbatimOptionMap.put(option.key, verbatimOption);
					} else {
						errors.add("Option '``argument``' isn't supported.");
					}
					
				} else {
					optionsMode = false;
					verbatimParameterList.add(argument); 
				}
			}
			
			value verbatimParameterMap = HashMap<ValueDeclaration, String|{String+}>();
			
			// associates parameters to their corresponding field
			for (parameter in parameters.declarations) {
				if (verbatimParameterList.empty) {
					errors.add("Missing parameters for ``parameter.name``");
					break;
				}
				
				value parameterType = parameter.openType;
				if (is OpenClassOrInterfaceType parameterType) {
					if (subTypeOf(parameterType.declaration, `interface Sequential`)) {
						value sequence = verbatimParameterList.sequence();
						// sequence can't be empty here, it's checked upstream
						assert(nonempty sequence);
						verbatimParameterMap.put(parameter, sequence);
					} else {
						value delete = verbatimParameterList.delete(0);
						assert(exists delete);
						verbatimParameterMap.put(parameter, delete);
					}
				} else {
					throw Exception("Unsupported type ``parameterType`` for parameter.");
				}
			}
			
			value namedArguments =  
				{for (decl->verbatim in concatenate(verbatimOptionMap, verbatimParameterMap)) decl.name -> parseValue(decl, verbatim)}
			;

			for (name->t in namedArguments) {
				if (exists t) {
					print("- ``name`` -> ``t``");
				} else {
					print("- ``name`` -> null");
				}
			}
			
			result = type.namedApply(namedArguments);
		} else {
			result = null;
			errors.add("No argument given.");
		}
		return [
			result, 
			errors.sequence()
		];	
	} else {
		throw Exception("Class ``type`` doesn't have 'arguments' annotation");
	}

}