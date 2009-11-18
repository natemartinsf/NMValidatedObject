// Example of managed model objects
// Still a work in progress
// 10/7/09 Nathaniel Martin
// natmartin@gmail.com


@import "NMValidatedObject.j"


//If you want to create a custom validation, define a constant string
//That is the method name of the validation method
NMValidateCount						= @"validateCountOfKey:info:";


// Department object
// Department has many Employees
// And validates that there is at least one employee
// Has one property, "purpose"

@implementation Department : NMValidatedObject
{
	// All properties must have accessors for KVO to work
	CPMutableArray	employees	@accessors;
	CPString		    purpose		@accessors;
}

-(id)init
{
	self = [super init];
	if (self)
	{
		//Initialize any properties
		employees = [[CPMutableArray alloc] init];
		
		//Specify any relationships for properties
		//The full method would be:
		//[self addRelationshipForKey:@"employees" type:NMRelationshipTypeHasMany inverseKey:@"department" className:@"Employee"];
		
		//I can figure out most of this through reflection
		//So that method can be simplified to:
		[self hasManyOfKey:@"employees"];
		//As long as you follow naming conventions
		
		//Setup validations. In this case, it will run a custom validation method
		//whenever the employees key is modified
		
		//All validation methods expect an options dictionary.
		var options = [[CPDictionary alloc] init];
		[options setObject:1 forKey:@"minimum"];
		
		[self addValidationForKey:@"employees" validationType:NMValidateCount options:options];
		
		//Use a built in validation to check that "purpose" is only certain values.
		[self validatesInclusionOfKey:@"purpose" values:[[CPArray alloc] initWithObjects:@"Research", @"Finance"]];

		
		//Setup persistance.
		//Not completely sure how this will work yet.
		//[self setAutoPersists:YES];
		
		//Because our validation requires a minimum number of employees, let's add a default one.
		var anEmployee = [[Employee alloc] init];

		[anEmployee setName:@"Default"];
		
		//Must use KVC accessors for all properties, are all the fancy management won't run!

		[self insertObject:anEmployee inEmployeesAtIndex:0];
	}
	
	return self;
}

//Validation method. Gets a dictionary of changes, and returns YES or NO
//-(BOOL)validateEmployees: (CPDictionary)changes
-(BOOL)validateCountOfKey:(CPString)key info:(CPDictionary)info
{
	var theProperty,
		options;
	theProperty = [self valueForKey:key];

	options = [info objectForKey:@"options"];
	
	if([theProperty respondsToSelector:CPSelectorFromString("count")])
	{
		return([theProperty count] >= [options objectForKey:@"minimum"]);
	}
	else
	{
	  //If the property is no longer an array for some reason, fail.
		return NO;
	}
}

//Accessor methods for the array, since that's not generated automatically yet.
//I want to have support for CPSets too, but they're not KVO compliant yet.

-(void)insertObject:(id)anObject inEmployeesAtIndex:(int)anIndex 
{
	[employees insertObject:anObject atIndex:anIndex];
}

-(void)removeObjectFromEmployeesAtIndex:(int)anIndex
{
	[employees removeObjectAtIndex:anIndex];
}

@end