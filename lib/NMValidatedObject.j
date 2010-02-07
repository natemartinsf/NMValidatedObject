//
//  NMValidatedObject.j
//  Circuit
//
//  Created by Nathaniel Martin on 9/25/09.
//  Copyright Nathaniel Martin 2009. All rights reserved.
//

@import <Foundation/CPObject.j>
@import "NMValidatedObjectContext.j"


// Relationship  types
NMRelationshipTypeHasMany					= @"HasManyRelationship"; // One-To-Many
NMRelationshipTypeBelongsTo				= @"BelongsToRelationship"; // One-to-One, or inverse of One-To-Many
NMRelationshipTypeManyToMany			= @"ManyToManyRelationship";  //Many-to-many

// Validation types
NMValidationTypeExclusion					= @"_validateExclusionOfKey:info:"; 
NMValidationTypeFormat						= @"_validateFormatOfKey:info:";
NMValidationTypeInclusion					= @"_validateInclusionOfKey:info:";
NMValidationTypeLength						= @"_validateLengthOfKey:info:";
NMValidationTypeNumericality			= @"_validateNumericalityOfKey:info:";
NMValidationTypePresence					= @"_validatePresenceOfKey:info:";


@implementation NMValidatedObject : CPObject
{
	CPMutableDictionary _relationships;
	CPMutableDictionary _observedKeys;
	CPMutableDictionary _validations;
	BOOL				        _autoPersists				@accessors(property=autoPersists);
	BOOL                _creating;
	CPString  backendClass  @accessors;
	CPString  created_at    @accessors;
	CPString  updated_at    @accessors;
	int       id            @accessors;
	NMValidatedObjectContext  context @accessors;
}

//TODO:
//More options for validations
//Persistance
//Error propagation

-(id)init
{
	self = [super init];
	if(self)
	{
		_relationships = [[CPMutableDictionary alloc] init];
		_observedKeys = [[CPMutableDictionary alloc] init];
		_validations = [[CPMutableDictionary alloc] init];
		_creating = false;
    var string = [[CPString alloc] init];
    backendClass = [self className];
	}
	return self;
}


//Method that is called whenever an observed key changes.
//Runs any validations on the key, reverting changes if needed.
//Then sets inverse relations if this key is a relationship
//We should have some way to notify the user that a validation failed
- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObject change:(CPDictionary)changes context:(id)aContext
{

	var capitalizedKey = [self _capitalizedKey:aKeyPath],
	    validationList = [_validations objectForKey:aKeyPath],
		  infoDict;
  
  CPLog(@"observing value");
  //Setup dictionary to pass to validation method
  //Add the changes that happened to this key
	infoDict = [[CPMutableDictionary alloc] init];
	[infoDict setObject:changes forKey:@"changes"];
	
	var i=0,
	    validation;
	
	for(i; i<[validationList count]; i++)
	{
		validation = [validationList objectAtIndex:i];
		
		//Add the options that we set when we defined the validation
		[infoDict setObject:[validation objectForKey:@"options"] forKey:@"options"];

    //Validate the changes
		if (![self performSelector:[validation objectForKey:@"selector"] withObject:aKeyPath withObject:infoDict])
		{
			//Validation failed, so revert changes
			//Have to turn off observing to avoid loop though.
			[self removeObserver:self forKeyPath:aKeyPath];
			[self setValue:[changes objectForKey:@"CPKeyValueChangeOldKey"] forKeyPath:aKeyPath];
			[self  addObserver: self
			forKeyPath: aKeyPath
				options: (CPKeyValueObservingOptionNew |
					        CPKeyValueObservingOptionOld)
				context:	nil];
				
			//Add a notification that the validation faile.
			//[[CPNotificationCenter defaultCenter] ]
				
			return;
		}
	}

	//validation succeeded, so make sure inverse relationship is set if needed.
	var relationship = [_relationships objectForKey:aKeyPath];
	if(relationship)
	{
		[self performSelector: [relationship objectForKey:@"selector"] withObject:changes withObject:aKeyPath];
	}
	var changed = [changes objectForKey:@"CPKeyValueChangeNewKey"] != [changes objectForKey:@"CPKeyValueChangeOldKey"];
	if(!_creating && changed){
	  [context updateKey:aKeyPath forRegisteredObject:self];
	}
	
}


//Setup KVO on the key, if it hasn't already been
-(void)observeKey:(CPString)key
{
	if([_observedKeys objectForKey:key] == nil)
	{
		[self  addObserver: self
				forKeyPath: key
					options: (CPKeyValueObservingOptionNew |
						CPKeyValueObservingOptionOld)
					context:	nil];
		[_observedKeys setObject:YES forKey:key];
	}
}


-(CPString)_capitalizedKey:(CPString)key
{
	return key.charAt(0).toUpperCase() + key.substring(1);
}

-(CPString)_lowercaseKey:(CPString)key
{
	return key.charAt(0).toLowerCase() + key.substring(1);
}

@end

@implementation NMValidatedObject (Relationships)

//Public methods

//Generic method to define a key as a relationship
//Expects the keyname, the type of relationship, the inversekey name, and the class of the inverse key
-(void)addRelationshipForKey:(CPString)key type:(CPString)type inverseKey:(CPString)inverseKey className:(CPString)className
{

	//Observe keypath if we aren't already
	[self observeKey:key];
	//create selector for normalizing
	var selectorString = @"_normalize"+type+@"WithChange:keyPath:";
		  selector = CPSelectorFromString(selectorString);
		
	//Add the description of the relationship to the dictionary of relationships
	var relationship = [[CPMutableDictionary alloc] initWithObjects: [CPArray arrayWithObjects: key, className, selector, inverseKey]
															forKeys: [CPArray arrayWithObjects: @"key", @"className", @"selector", @"inverseKey"]];

															
	[_relationships setObject:relationship forKey:key]; 

}

//Convinience method to add a belongsTo relationship to a key
-(void)belongsToKey:(CPString)key
{
  //We assume that the inverse key is the simple plural of the keyname.
  //If this is not true, define the relationship manually with
  //addRelationshipForKey:type:inverseKey:className:
	var capitalizedKey = [self _capitalizedKey:key],
		  inverseKey = [self _lowercaseKey:[self className]]+"s";
	
	[self addRelationshipForKey:key type:NMRelationshipTypeBelongsTo inverseKey:inverseKey className:capitalizedKey];

}

//Convinience method to add a hasMany relationship to a key
-(void)hasManyOfKey:(CPString)key
{
  //We assume that the classname of the inverse is the lowercase singular version of the key and
  // the inverse key is the lowercase of this object's classname.
  //If this is not true, define the relationship manually with
  //addRelationshipForKey:type:inverseKey:className:
	var generatedClassName = [self _capitalizedKey:key].substring(0, key.length-1),
		  inverseKey = [self _lowercaseKey:[self className]];
		
	[self addRelationshipForKey:key type:NMRelationshipTypeHasMany inverseKey:inverseKey className:generatedClassName];
}

//Convinience method to add a ManyToMany relationship to a key
-(void)hasAndBelongsToManyOfKey:(CPString)key
{
	//We assume that the classname of the inverse is the lowercase singular version of the key and
  // the inverse key is the lowercase plural of this object's classname.
  //If this is not true, define the relationship manually with
  //addRelationshipForKey:type:inverseKey:className:
	var generatedClassName = [self _capitalizedKey:key].substring(0, key.length-1),
		  inverseKey = [self _lowercaseKey:[self className]]+"s";
		
	[self addRelationshipForKey:key type:NMRelationshipTypeManyToMany inverseKey:inverseKey className:generatedClassName];
}

//Private Methods

//Sets the inverse key of a one-to-many relationship
-(void)_normalizeHasManyRelationshipWithChange:(CPDictionary)changes keyPath:(CPString)aKeyPath
{
	var relationship = [_relationships objectForKey:aKeyPath],
		  theInverseKey = [relationship objectForKey:@"inverseKey"],
		  newKey = [changes objectForKey:@"CPKeyValueChangeNewKey"], //An array containing the new value of the key
		  newObject,
		  oldKey = [changes objectForKey:@"CPKeyValueChangeOldKey"],
		  oldObject;
      
  //I don't know why, but the changes dictionary gives me an array, and the first object is the object added to the key
  //If something was removed, it is null.
  
  if(newKey != null)
  {
    //We have a new key, so let's get the actual object
    newObject = [newKey objectAtIndex:0];
    
    //Now let's set ourselves to be the inverse, if needed.
    
    if([newObject valueForKey:theInverseKey] != self)
    {
      [newObject setValue:self forKey:theInverseKey];
    }
  }
  else if (oldKey != null)
  {
    //We have an old key, so let's get the actual object.
    oldObject = [oldKey objectAtIndex:0];
    
    //We have an old key, we should set it to be nil if it's still pointing at us.
    if([oldObject valueForKey:theInverseKey] == self)
    {
      [oldObject setValue:nil forKey:theInverseKey];
    } 
  }
  else
  {
    //We don't have a new or an old key!
    CPLog.error("normalizing hasMany relationship with no new or old key")
  }
}



-(void)_normalizeBelongsToRelationshipWithChange:(CPDictionary)changes keyPath:(CPString)aKeyPath
{
	var relationship = [_relationships objectForKey:aKeyPath],
		  theInverseKey = [relationship objectForKey:@"inverseKey"],
		  newObject = [changes objectForKey:@"CPKeyValueChangeNewKey"],
		  oldObject = [changes objectForKey:@"CPKeyValueChangeOldKey"],
		  newObject,
		  oldObject,
		  inverseArray;
		  
  if([newObject class] != CPNull)
  {
    //The key has been set to a new object.
    //Let's get the inverse array
    inverseArray = [newObject valueForKey:theInverseKey];
    //So let's add ourselves to the object's array if needed.
    if(![inverseArray containsObject:self])
    {
      //We're not in the array, so let's add it.
      
      //We're not using the KVC accessor, but that should be ok because we don't want a loop
      [inverseArray addObject:self];
    }
  }
  else if([oldObject class] != CPNull)
  {
    //There's an old key
    //Let's get the inverse array
    inverseArray = [oldObject valueForKey:theInverseKey];
    //Let's remove ourselves from the array if needed
    if([inverseArray containsObject:self])
    {
      //We're in the array, so let's remove ourselves.
      //WE're not using the KVC accesssor, but that should be ok because we don't want a loop
      [inverseArray removeObject:self];
    }
  }
  else
  {
    //We don't have a new or an old key!
    CPLog.error("normalizing belongsTo relationship with no new or old key")
  }

}



-(void)_normalizeManyToManyRelationshipWithChange:(CPDictionary)changes keyPath:(CPString)aKeyPath
{
	var relationship = [_relationships objectForKey:aKeyPath],
		theInverseKey = [relationship objectForKey:@"inverseKey"],
		newKey = [changes objectForKey:@"CPKeyValueChangeNewKey"],
		newObject,
		oldKey = [changes objectForKey:@"CPKeyValueChangeOldKey"],
		oldObject,
		newInverseArray,
		oldInverseArray;
		
  //I don't know why, but the changes dictionary gives me an array, and the first object is the object added to the key
  //If something was removed, it is null.
	if(newKey != null)
	{
	  //The key has been set to a new object.
    //Let's get the inverse array
		newObject = [newKey objectAtIndex:0];
		newInverseArray = [newObject valueForKey:theInverseKey];
		//So let's add ourselves to the object's array if needed.
    
		if(! [newInverseArray containsObject:self] )
		{
		  //We're not in the array, so let's add it.
      
      //We're not using the KVC accessor, but that should be ok because we don't want a loop
			[newInverseArray addObject:self];
		}
	}	
	if(oldKey != null)
	{
	  //There's an old key
    //Let's get the inverse array
		oldObject = [oldKey objectAtIndex:0];	
		oldInverseArray = [oldObject valueForKey:theInverseKey];
		
		if([oldInverseArray containsObject:self])
		{
		  //We're in the array, so let's remove ourselves.
      //WE're not using the KVC accesssor, but that should be ok because we don't want a loop
			[oldInverseArray removeObject:self]
		}
	}
	
}

@end

@implementation NMValidatedObject (Validations)

//Public methods

//Generic method to add a validation
//Can either pass one of the existing validation types, or a custom one you define.
//See Department.j for an example of custom validations
//**************************
//We should have more options for validations, like only on create, only on update. etc
//This method adds a dictionary to the validations array for the key
//that descries which validations are to be run after it changes.
//Key is the key to add the validation to
//Validationg type is a string describing the validation
//Options is a dictionary of settings, different for each validation.
-(void)addValidationForKey:(CPString)key validationType:(CPString)validationType options:(CPDictionary)options
{
    //Make sure the key is being observed
	[self _observeKey:key];

	var selector, 
	    newValidation;
	
	
	selector = CPSelectorFromString(validationType);
	newValidation  = [[CPDictionary alloc] initWithObjects: [CPArray arrayWithObjects: selector, options]
															forKeys: [CPArray arrayWithObjects:  @"selector", @"options"]];
	var validationsList;
	//Get the existing list of validations of this key, or create if needed
	if (!(validationsList = [_validations objectForKey:key]))
	{
		validationsList = [[CPMutableArray alloc] init];
	}
	
	//Add the validation
	[validationsList addObject:newValidation];

	[_validations setObject:validationsList forKey:key];
	
}

//Convinience method to add a length validation
//If you don't have both a minimum and a maximum, use a custom validator.
//We should probably add options to this for just min and just max
-(void)validatesLengthOfKey:(CPString)key minimum:(int)min maximum:(int)max
{	
	var options = [[CPDictionary alloc] initWithObjects: [CPArray arrayWithObjects: min, max]
												forKeys: [CPArray arrayWithObjects: @"minimum", @"maximum"]];
												
	[self addValidationForKey:key validationType:NMValidationTypeLength options:options];
	
}



//Exclusion
//Validates that the key does not equal certain values
//Expects an array of values to exclude
-(void)validatesExclusionOfKey:(CPString)key values:(CPArray)values
{
	var options = [[CPDictionary alloc] init];
	[options setObject: values forKey: @"values"];
												
	[self addValidationForKey:key validationType:NMValidationTypeExclusion options:options];
}



//Format
//Validates that the key matches a regexp
//Expects a standard javascript regex
-(void)validatesFormatOfKey:(CPString)key regExp:(var)re
{
var options = [[CPDictionary alloc] init];
	[options setObject: re forKey: @"regExp"];
												
	[self addValidationForKey:key validationType:NMValidationTypeFormat options:options];
}


//Inclusion
//Validates that the key is one of a set of values
//Expects an array of values to include
-(void)validatesInclusionOfKey:(CPString)key values:(CPArray)values
{
	var options = [[CPDictionary alloc] init];
	[options setObject: values forKey: @"values"];
												
	[self addValidationForKey:key validationType:NMValidationTypeInclusion options:options];
}


//Numericality
//Validates that the key is a number
-(void)validatesNumericalityOfKey:(CPString)key
{
//Should have more options
	var options = [[CPDictionary alloc] init];
	[self addValidationForKey:key validationType:NMValidationTypeNumericality options:options];
}

//Presence
//Validates that the key is not nil
-(void)validatesPresenceOfKey:(CPString)key
{
	var options = [[CPDictionary alloc] init];
	[self addValidationForKey:key validationType:NMValidationTypePresence options:options];
}


//Private methods

//All validation methods return YES if the validation passes an NO if the validation fails

//This validates the length of the key
-(BOOL)_validateLengthOfKey:(CPString)key info:(CPDictionary)info
{
	var theProperty,
		options;
	theProperty = [self valueForKey:key];
	options = [info objectForKey:@"options"];

	return (([options valueForKey:@"minimum"] <= [theProperty length]) && ( [theProperty length] <= [options valueForKey:@"maximum"]) );
}

//This validates that the key is not in a set of values
-(BOOL)_validateExclusionOfKey:(CPString)key info:(CPDictionary)info
{
	var theProperty,
		options;
	theProperty = [self valueForKey:key];
	
	options = [info objectForKey:@"options"];
	
	return !([[options objectForKey:@"values"] containsObject:theProperty]);
}

//This validates that the key is in a set of values
-(BOOL)_validateInclusionOfKey:(CPString)key info:(CPDictionary)info
{
	var theProperty,
		options;
	theProperty = [self valueForKey:key];
	
	options = [info objectForKey:@"options"];
	
	return ([[options objectForKey:@"values"] containsObject:theProperty]);
}


//This runs a regexp against the value, and confirms that it matches.
-(BOOL)_validateFormatOfKey:(CPString)key info:(CPDictionary)info
{
	var theProperty,
		options;
	theProperty = [self valueForKey:key];
	
	options = [info objectForKey:@"options"];
	var pattern = [options objectForKey:@"regExp"];
	return (pattern.test(theProperty));
}

//Checks that the key is a number
-(BOOL)_validateNumericalityOfKey:(CPString)key info:(CPDictionary)info
{
	var theProperty,
		options;
	theProperty = [self valueForKey:key];
	
	options = [info objectForKey:@"options"];
	
	return !isNaN(theProperty)
}

//Checks that the value is not nil.
-(BOOL)_validatePresenceOfKey:(CPString)key info:(CPDictionary)info
{
	var theProperty,
		options;
	theProperty = [self valueForKey:key];
	
	options = [info objectForKey:@"options"];
	
	return theProperty != nil;
}

@end


@implementation NMValidatedObject (Persistence)

+(id)newValidatedObjectWithJSON:(id)JSONobject
{

  var myClass   = CPClassFromString([self className]),
      newObject = [[myClass alloc] init],
      backendName = [newObject backendClass],
      dataObject = JSONobject[backendName];
      
  _creating=true;
      
  for (var property in dataObject){
    
    [newObject setValue:dataObject[property] forKey:property];
  }
  
  _creating=false;
  
  return newObject;
}



@end


