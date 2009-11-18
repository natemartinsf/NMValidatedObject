//Employee object
//Employee belongs to department
//Employee has a name that must be betweeen 5 and 25 characters

@import "NMValidatedObject.j"
@import "Department.j"

@implementation Employee : NMValidatedObject
{
	// All properties must have accessors for KVO to work
	Department		  department		@accessors;
	CPString		    name			    @accessors;
	CPString		    jobTitle		  @accessors;
	CPString		    email			    @accessors;
	CPNumber		    salary			  @accessors;
	CPString		    computerType	@accessors;
	CPMutableArray	projects		  @accessors;
}

-(id)init
{
	self = [super init];
	if (self)
	{
		projects = [[CPMutableArray alloc] init];
		

		
		//Specify any relationships for properties
		//[self addRelationshipForKey:@"department" type:NMRelationshipTypeBelongsTo inverseKey:@"employees" className:@"Department"];
		
		//This can probably be simplified to:
		[self belongsToKey:@"department"];
		//Because we followed conventions
		
		[self hasAndBelongsToManyOfKey:@"projects"];
		
		// Since this is an automatic validation, we don't need a custom method.
		[self validatesLengthOfKey:@"name" minimum:5 maximum:25];
		
		[self validatesExclusionOfKey:@"jobTitle" values:[[CPArray alloc] initWithObjects:@"Paper Pusher", @"Micro Manager"]];
		
		var re = new RegExp("\w*@{1}\w*.{1}\w*", "i");
		
		[self validatesFormatOfKey:@"email" regExp:re];
		
		[self validatesNumericalityOfKey:@"salary"];
		
		[self validatesPresenceOfKey:@"computerType"];
		
		//Setup persistance.
		//Not completely sure how this will work yet.
		[self setAutoPersists:YES];
		
	}
	
	return self;
}

//Accessor methods for the array, since that's not generated automatically yet.
//I want to have support for CPSets too, but they're not KVO compliant yet.

-(void)insertObject:(id)anObject inProjectsAtIndex:(int)anIndex 
{
	[projects insertObject:anObject atIndex:anIndex];
}

-(void)removeObjectFromProjectsAtIndex:(int)anIndex
{
	[projects removeObjectAtIndex:anIndex];
}

@end