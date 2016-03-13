import ceylon.language.meta.declaration {
	FunctionDeclaration,
	ValueDeclaration,
	ClassDeclaration
}

"Annotation for an option."
shared final annotation class OptionAnnotation(
	shared String longName, 
	shared Character shortName
) 
		satisfies OptionalAnnotation<OptionAnnotation, ValueDeclaration> {
	shared actual String string => 
			"--``longName``=value" +
			(if (!shortName == '\0') then " | -``shortName`` value" else "");
}

"Defines value as an option of the format '-shortName argument' or '--longName=argument':
 - if value is a Boolean the argument is optional, 
 - if value is a String the argument will be copied,
 - if value is a Float|Integer the argument is parsed,
 - if value is a case Class, it searches for the children with given name in lower case,
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

