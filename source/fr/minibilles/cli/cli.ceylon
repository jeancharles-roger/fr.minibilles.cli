import ceylon.collection {
	HashMap,
	ArrayList,
	MutableList
}
import ceylon.language.meta {
	annotations
}
import ceylon.language.meta.declaration {
	ValueDeclaration,
	OpenClassOrInterfaceType,
	ClassOrInterfaceDeclaration,
	OpenType,
	OpenClassType
}
import ceylon.language.meta.model {
	Class
}

// TODO adds error handling for parsing integer, float and boolean
Anything? parseValue(ValueDeclaration declaration, String|[String+] verbatim) {
	value annotation = annotations(`CreatorAnnotation`, declaration);
	switch (verbatim)
	case (is String) {
		value childOpenType = declaration.openType;
		if (exists annotation) {
			// uses the creator
			value creator = annotation.creator.apply<Object, [String]>();
			return creator.apply(verbatim);			
		} else {
			assert(is OpenClassOrInterfaceType childOpenType);
			return parseSingleValue(declaration.name, childOpenType.declaration, verbatim);
		}			
	}
	case (is [String+]) {
		if (exists annotation) {
			value creator = annotation.creator.apply<Object, [[String+]]>();
			return creator.apply(*verbatim);
		} else {
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
		return Integer.parse(verbatim);
	} else if (subDeclarationOf(type,`class Float`)) {
		return Integer.parse(verbatim);
	} else if (subDeclarationOf(type,`class Boolean`)) {
		return if (verbatim.empty) then true else Boolean.parse(verbatim);
	} else {
		// searches for a case value
		// TODO find a class in depth with the given name
		value caseType = type.caseTypes.find((OpenType elem) {
			if (is OpenClassType elem) {
				return verbatim.lowercased == elem.declaration.name.lowercased;				
			} 
			return false;
		});
		
		if (exists caseType) { return caseType; } 
		else {
			throw Exception("Can't instantiate value '``verbatim``' for type '``type``' in ``name``");
		}
	} 
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

Map<ValueDeclaration,String|[String+]> verbatimParameters<T>
	(Class<T> type, MutableList<String> verbatimParameterList, MutableList<String> errors)
given T satisfies Object 
{
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
	return verbatimParameterMap;
}

Boolean isBooleanValue(ValueDeclaration option) {
	return if (is OpenClassOrInterfaceType openType = option.openType) then openType.declaration == `class Boolean` else false;
}

"Parses arguments to construct given type."
shared [T, [String*]] parseArguments<T>(
	[String*] arguments
) 
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
							if (verbatimOption.size == 0 && !isBooleanValue(option.key)) { 
								// fetchs the argument using next one in line
								if (exists newArgument = tail[0]) {
									verbatimOptionMap.put(option.key, newArgument);
									tail = tail.spanFrom(1);
								} else {
									errors.add("Option --'``optionName``' needs an argument.");
								}
							} else {
								verbatimOptionMap.put(option.key, verbatimOption);
							}
						} else {
							errors.add("Option --'``argument``' isn't supported.");
						}
						
					} else {
						// searches for short options
						variable String neededArgument = verbatimOption;
						for (oneShortOption in optionName) {
							value option = options.find((element) => oneShortOption == element.item.shortName);
							if (exists option) {
								if (neededArgument.size == 0 && !isBooleanValue(option.key)) {
									// fetchs the argument using next one in line
									if (exists newArgument = tail[0]) {
										neededArgument = newArgument;
										verbatimOptionMap.put(option.key, newArgument);
										tail = tail.spanFrom(1);
									} else {
										errors.add("Option -'``argument``' needs an argument.");
									}
								} else {
									verbatimOptionMap.put(option.key, neededArgument);
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
	}
	// reads parameters
	value verbatimParameterMap=verbatimParameters(type, verbatimParameterList, errors);
	value namedArguments = [
		for (decl->verbatim in concatenate(verbatimOptionMap, verbatimParameterMap))
			if (exists parsed = parseValue(decl, verbatim))
				decl.name -> parsed
	];
	return [
		type.namedApply(namedArguments), 
		errors.sequence()
	];	
}
