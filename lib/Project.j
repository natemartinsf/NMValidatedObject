//Project object
//Project belongs to department
//Project has a name that must be betweeen 5 and 25 characters

@import "NMValidatedObject.j"

@implementation Project : NMValidatedObject
{
	// All properties must have accessors for KVO to work
	CPMutableArray	employees	@accessors;
}

-(id)init
{
	self = [super init];
	if (self)
	{
		employees = [[CPMutableArray alloc] init];
		
		[self hasAndBelongsToManyOfKey:@"employees"];
	}
	
	return self;
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