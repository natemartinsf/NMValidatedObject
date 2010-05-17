//
//  NMFetchRequest.j
//  
//
//  Created by Nathaniel Martin on 2/27/10.
//  Copyright Nathaniel Martin 2010. All rights reserved.
//

@import <Foundation/CPObject.j>
@import "NMValidatedObject.j"
@import "NMValidatedObjectContext.j"


@implementation NMFetchRequest : CPObject
{
  CPString  validatedObjectClass    @accessors;
  CPString  identifier              @accessors; 
  boolean   retrievesInlineObjects  @accessors;   
  NMValidatedObjectContext  context @accessors;
  id        delegate                @accessors;
  SEL       callback                @accessors;

}

-(void)_evaluateFetchRequestWithData:(CPObject)data
{
  var fetchData = [CPDictionary dictionaryWithJSObject:data], 
      enumerator = [fetchData objectEnumerator],
      url,
      results = [[CPMutableArray alloc] init],
      newObject;    
      
  while(url=[enumerator nextObject])
  {
    newObject = [[CPClassFromString(validatedObjectClass) alloc] init];
    [newObject setUrl:[CPURL URLWithString:url]];
    [newObject setContext:context];
    
    [results addObject:newObject];
  }
  
  [delegate performSelector:callback withObject:results];
  
  //make dummy objects and return them
}

