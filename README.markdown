# NMValidatedObject #

A simple model-level framework for Cappuccino. Inspired by ActiveRecord and CoreData, it allows you to validate properties of model objects, and manage relationships between models.

I wrote this class when I started working on a Cappuccino application with a fairly complex domain model. I didn't want to manage all the validations and relationships in each model I wrote, so I made a class to handle all of that for me.

To use NMValidatedObject, you simply include it in your project, and subclass it for each of your model objects. Then perform any setup needed in your init method.

See the included tests for details on how to use it.

## Example ##

    @import "NMValidatedObject.j"
    @import "Department.j"

    @implementation Employee : NMValidatedObject
    {
    	// All properties must have accessors for KVO to work
    	Department		    department		@accessors;
    	CPString		    name			@accessors;
    	CPMutableArray	    projects		@accessors;
    }

    -(id)init
    {
    	self = [super init];
    	if (self)
    	{
    		projects = [[CPMutableArray alloc] init];
		
    		[self belongsToKey:@"department"];		
    		[self hasAndBelongsToManyOfKey:@"projects"];
    		[self validatesLengthOfKey:@"name" minimum:5 maximum:25];
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
    
## Requirements and limitations ##

*   All properties that are validated, or have relationships, must have KVC accessors.
*   You must always access the properties only through those accessors, or validations will not run.
*   HasMany and ManyToMany relationships only work with arrays right now. I will add support for sets after Cappuccino gets KVO working with sets.
*   In order to use the validation and relationship convenience methods you must follow some conventions:
    *   hasMany keys should be the lowercase plural of the target classname
    *   belongsTo keys should be the lowercase singular of the target classname
*   The conventions assume simplistic pluralization (add or remove an 's'). If the acutal plurilization is more difficult than that, you should use the generic relationship methods.

## Todo ##

*   More options for validation, such as:
    *   Validate only on create, or only on update
    *   More flexible convenience methods (min with no max, etc)
*   Persistence
    *   Plugin based system to persist to multiple backends
        * ActiveRecord
        * CouchDB
        * Persevere
        * GoogleGears (for local storage)
        * Atlas server-side
        * more?
*   Querying
    *   Probably will need to be plugin based as well, for each backend

## License ##

Feel free to use this for any projects, commercial or free, open or closed source, with attribution. If you make any modifications, release those modifications back to the community. 