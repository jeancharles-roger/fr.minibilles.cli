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


// TODO adds error handling for parsing integer, float and boolean
Anything? parseValue(ValueDeclaration declaration, String|[String+] verbatim) {
	value annotation = annotations(`CreatorAnnotation`, declaration);
	if (exists annotation) {
		// uses the creator
		value creator = annotation.creator.apply<Object, [String|[String+]]>();
		return creator.apply(verbatim);
	} else {
		switch (verbatim)
		case (is String) {
			value childOpenType = declaration.openType;
			assert(is OpenClassOrInterfaceType childOpenType);
			return parseSingleValue(declaration.name, childOpenType.declaration, verbatim);
		}
		case (is [String+]) {
			return parseMultipleValue(declaration, verbatim);
		}
	}
}

[Object*] parseMultipleValue(ValueDeclaration declaration, [String+] verbatim) {
	// parses the verbatim
	value childOpenType = declaration.openType;
	assert(is OpenClassOrInterfaceType childOpenType);
	if (subDeclarationOf(childOpenType.declaration, `interface Sequential`)) {
		value typeArguments = childOpenType.typeArgumentList;
		assert(nonempty typeArguments, is OpenClassOrInterfaceType childType = typeArguments[0]);
		// XXX handle other types than String
		value result = sequence({for (single in verbatim) /*parseSingleValue(declaration.name, childType.declaration, single)*/ single}.coalesced);
		return if (exists result) then result else empty;
	} else {
		throw Exception("Can't parse value '``verbatim``' for type '``childOpenType``' in ``declaration.name``");
	}
}


// TODO adds error handling for parsing integer, float and boolean
Object? parseSingleValue(String name, ClassOrInterfaceDeclaration type, String verbatim) {
	// parses the verbatim
	if (subDeclarationOf(type,`class String`)) {
		return verbatim;
	} else if (subDeclarationOf(type,`class Integer`)) {
		return parseInteger(verbatim);
	} else if (subDeclarationOf(type,`class Float`)) {
		return parseFloat(verbatim);
	} else if (subDeclarationOf(type,`class Boolean`)) {
		return if (verbatim.empty) then true else parseBoolean(verbatim);
	} else if (is ClassOrInterface<Object> type) {
		// searches for a case value
		value caseValue = type.caseValues.find((Object elem) => verbatim == elem.string);
		if (exists caseValue) { return caseValue; } 
		/*else if (is Class<Object> type) {
			// tries a constructor
			value constructors = type.getCallableConstructors<[String]>();
			if (nonempty constructors) {
				return constructors.first.declaration.apply<Object, [String]>().apply(verbatim);
			} else {
				throw Exception("No constructor([String]) found type '``type``' in ``name``");
			}
		}*/ 
		else {
			throw Exception("Can't instantiate value '``verbatim``' for type '``type``' in ``name``");
		}
	} else {
		throw Exception("Can't parse value '``verbatim``' for type '``type``' in ``name``");
	} 
}

T? parseCaseType<T>(String name) 
	given T satisfies Object 
{
	Type<T> type = `T`;
	assert(is ClassOrInterface<T> type);
	return type.caseValues.find((T elem) => name == elem.string);
}

Boolean subDeclarationOf(ClassOrInterfaceDeclaration subType, ClassOrInterfaceDeclaration superType) {
	if (subType == superType) { return true; }
	value extendedType = subType.extendedType;
	if (exists extendedType, subDeclarationOf(extendedType.declaration, superType)) { return true; }
	for (satisfied in subType.satisfiedTypes) {
		if (subDeclarationOf(satisfied.declaration, superType)) {return true;}
	}
	return false;
}

"Parses arguments to construct given type."
shared [T?, [String*]] parseArguments<T>([String*] arguments) 
	given T satisfies Object
{
	value type = `T`;
	assert(is Class<T> type);
	
	// reads options
	value options = [
	for (oneValue in type.declaration.memberDeclarations<ValueDeclaration>()) 
		if (exists option = annotations(`OptionAnnotation`, oneValue)) oneValue -> option
	];
	
	value verbatimOptionMap = HashMap<ValueDeclaration, String>();
	value verbatimParameterList = ArrayList<String>();
	T? result;
	value errors = ArrayList<String>();
	
	// collects options and parameters from arguments
	if (nonempty arguments) {
		variable [String*] tail = arguments;
		while (true) {
			// gets the argument
			value argument = tail[0];
			// removes argument from list
			tail = tail.spanFrom(1);
			
			if (exists argument) {
				// analyzes argument 
				value optionStop = argument.equals("--");
				if ( optionStop || !argument.startsWith("-") ) {
					// parameters
					if (!optionStop) { verbatimParameterList.add(argument); }
					verbatimParameterList.addAll(tail);
					tail = empty; 
				} else {
					// decodes option
					value longOption = argument.startsWith("--");
					value trimmedOption = argument.trim('-'.equals);
					value equalsIndex = trimmedOption.firstOccurrence('=', 0, trimmedOption.size);
					value [optionName, verbatimOption] = 
							if (exists equalsIndex) 
					then [trimmedOption.spanTo(equalsIndex-1), trimmedOption.spanFrom(equalsIndex+1)] 
					else [trimmedOption, ""]; 
					
					if (longOption) {
						// searches for one long option
						value option = options.find((element) => optionName == element.item.longName);
						if (exists option) {
							verbatimOptionMap.put(option.key, verbatimOption);
						} else {
							errors.add("Option --'``argument``' isn't supported.");
						}
						
					} else {
						// searches for short options
						variable String neededArgument = verbatimOption;
						for (oneShortOption in optionName) {
							value option = options.find((element) => oneShortOption == element.item.shortName);
							if (exists option) {
								if (is OpenClassOrInterfaceType openType = option.key.openType, openType.declaration == `class Boolean`) {
									verbatimOptionMap.put(option.key, verbatimOption);
								} else {
									// needs an argument
									if (neededArgument.size > 0) {
										// argument is already fetched
										verbatimOptionMap.put(option.key, neededArgument);
									} else {
										// fetchs the argument using next one in line
										if (exists newArgument = tail[0]) {
											neededArgument = newArgument;
											verbatimOptionMap.put(option.key, newArgument);
											tail = tail.spanFrom(1);
										} else {
											errors.add("Option -'``argument``' needs an argument.");
										}
									}
								}
							} else {
								errors.add("Option -'``argument``' isn't supported.");
							}
						}
					}
					
				}
			
			} else {
				// stops the loop
				break;
			}
		}
	
		// reads parameters
		value parameters = annotations(`ParametersAnnotation`, type.declaration);
		value verbatimParameterMap = HashMap<ValueDeclaration, String|[String+]>();
		if (exists parameters) {
			// associates parameters to their corresponding field
			for (parameter in parameters.declarations) {
				if (verbatimParameterList.empty) {
					errors.add("Missing parameters for ``parameter.name``");
					break;
				}
				
				value parameterType = parameter.openType;
				if (is OpenClassOrInterfaceType parameterType) {
					 if (subDeclarationOf(parameterType.declaration, `interface Sequential`)) {
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
		}
		
		value namedArguments = [
			for (decl->verbatim in concatenate(verbatimOptionMap, verbatimParameterMap))
				if (exists parsed = parseValue(decl, verbatim))
					decl.name -> parsed
		];
		
		result = type.namedApply(namedArguments);
		return [
			result, 
			errors.sequence()
		];	
	} else {
		return [null, ["No argument given."]];
	}
}