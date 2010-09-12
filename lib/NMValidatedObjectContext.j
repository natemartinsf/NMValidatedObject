//@import "CPPredicate/CPPredicate.j"
@import "NMFetchRequest.j"

NMObjectRegisteredNotification	= @"NMObjectRegisteredNotification"; 
NMValidatedObjectContextLoadedNotification = @"NMValidatedObjectContextLoadedNotification";

@implementation NMValidatedObjectContext : CPObject
{
  CPURL         baseURL         @accessors;
  CPDictionary  managedClasses  @accessors;
  CPDictionary  classesForPath  @accessors;
  CPDictionary  fetchedObjects  @accessors;
  CPDictionary  fetches         @accessors;
  CPDictionary  registeredObjects @accessors;
}

- (id)initWithBaseURL:(CPURL)theBaseURL
{
  if(self = [super init])
  {
    managedClasses = [[CPDictionary alloc] init];
    classesForPath = [[CPDictionary alloc] init];
    registeredObjects = [[CPDictionary alloc] init];
    fetchedObjects = [[CPDictionary alloc] init];
    fetches         = [[CPDictionary alloc] init];
    baseURL = theBaseURL;
    
    var selectorString = @"_getClassURLsWithData:";
  		  selector = CPSelectorFromString(selectorString);
    [self startJSONGETRequestForURL:baseURL delegate:self callback:selector];
  }
  return self;
}

-(id)getOrCreateValidatedObjectWithID:(int)objectId ClassName:(CPString)className
{
  var url = [managedClasses objectForKey:className] + "/"+objectId
  return [self getOrCreateValidatedObjectWithURL:url ClassName:className];
}

-(id)getOrCreateValidatedObjectWithURL:(CPURL)theUrl ClassName:(CPString)className
{
  if([registeredObjects containsKey:theUrl])
  {
    return [registeredObjects objectForKey:theUrl];
  }
  else 
  {
    var newObject = [[CPClassFromString(className) alloc] init];
    [newObject setUrl:[CPURL URLWithString:theUrl]];
    [newObject setContext:self];
    [registeredObjects setObject:newObject forKey:theUrl];
    return newObject;
  }
}


-(CPArray)objectsForFetchIdentifier:(CPString)identifier
{
  //Need to check that this exists
  //maybe check if it is up to date too.
  return [fetchedObjects objectForKey:identifier];
}

-(void)setObjects:(CPArray)objects ForFetchIdentifier:(CPString)identifier
{
  [fetchedObjects setObject:objects forKey:identifier];
}


-(void)_getClassURLsWithData:(CPObject)data
{
  var classes = [CPDictionary dictionaryWithJSObject:data recursively:YES],
      enumerator = [classes keyEnumerator],
      classname;
  
  while(classname=[enumerator nextObject])
  {
    [self addPath:[[classes objectForKey:classname] objectForKey:@"url"] forClassName:classname];
    //Set count of objects, so dummy objects can be created when needed
    
    //CPLog.info(classname);
  }
  
  [[CPNotificationCenter defaultCenter] postNotificationName:NMValidatedObjectContextLoadedNotification object:self];
  //CPLog(classes);
}


//Starts to fetch objects. Returns objects to a callback. 
//If the objects are already in memory, it will return those, otherwise it will return dummy objects
//and return the real ojects later.
//This should take a CPPredicate, but we'll just use name/value pairs for now.
-(void)executeFetchRequest:(NMFetchRequest)request
{
  
  //Need to check in memory objects before doing the fetch.
  //Do this when I switch to using the predicate
  [fetches setObject:request forKey:[request identifier]];
  var urlString = [managedClasses objectForKey:[request validatedObjectClass]];
  [request setContext:self];
  
 // var querystring = "inline="+[request retrievesInlineObjects]+";";
  //urlString = urlString+"?"+querystring;
  
  var url = [CPURL URLWithString:urlString];
  
  //Need to handle queries
 /*   queryString = '',
    enumerator = [queryParameters keyEnumerator];
    
  while(queryKey=[enumerator nextObject])
  {
    queryString += queryKey+"="+[queryParameters objectForKey:queryKey]+",";
  }
  [url setResourceValue:queryString forKey:@"query"]; */
  var selectorString = @"_evaluateFetchRequestWithData:";
		  selector = CPSelectorFromString(selectorString);
  [self startJSONGETRequestForURL:url delegate:request callback:selector];
}

//Method to get arbitrary objects. If existing, return them. If not, pull from DB.
//Maybe some sort of local caching?
//How about when to update them?


-(void)addPath:(CPString)pathName forClassName:(CPString)className
{
  [managedClasses setObject:pathName forKey:className];
  [classesForPath setObject:className forKey:pathName];
}

-(void)allObjectsForClassName:(CPString)className
{
  var path = [managedClasses objectForKey:className],
      fullPath = [CPURL URLWithString:[baseURL absoluteString] + path];
  [self startJSONGETRequestForURL:fullPath identifier:"all"];
}


-(void)updateKey:(CPString)aKeyPath forRegisteredObject:(id)object {
  var path = [managedClasses objectForKey:[object className]],
      fullPath = [CPURL URLWithString:[baseURL absoluteString] + path + "/" + [object id]],
      classname = [object backendClass],
      newvalue = [object valueForKey:aKeyPath];
      //Is there a better way to do this?
      payload={}
      keyvalue={}
      keyvalue[aKeyPath]=newvalue;
      payload[classname]=keyvalue;
      var payloadJSON = [CPString JSONFromObject:payload];
      //This should be a POST, since we're just updating one key. But RoR expects a PUT
      [self startJSONPUTRequestForURL:fullPath payload:payloadJSON];
  
}


- (void)connection:(CPURLConnection)aConnection didReceiveData:(CPString)data
{
  
  var dataObject= [data objectFromJSON],
      callback = aConnection.callback,
      delegate = aConnection.delegate;
      
  [delegate performSelector:callback withObject:dataObject];
  
  /*var dataObject,
      identifier = aConnection.connectionID;

  
  if (identifier == "all")
  {
    dataObject= [data objectFromJSON];
    
    var i=0;
    for (i;i<[dataObject count];i++ )
    { */
     /* if (property == "isa")
     {
        continue;
      } */
      //CPLog.info(dataObject[property]);
  /*    var url = dataObject[i];
      [self startJSONGETRequestForURL:url identifier:"init"];
    }
  }
  if (identifier == "init")
  {
    dataObject= [data objectFromJSON];
    
    var path = [[aConnection.url stringByDeletingLastPathComponent] lastPathComponent],
        className = [classesForPath objectForKey:path],
        theClass = CPClassFromString(className),
        newObject = [theClass newValidatedObjectWithJSON:dataObject];
        
    [newObject setContext:self];
    [registeredObjects addObject:newObject];
    [[CPNotificationCenter defaultCenter] postNotificationName:NMObjectRegisteredNotification object:self];
    
  } */
}

- (void)connection:(CPURLConnection)aConnection didFailWithError:(CPError)anError
{
  CPLog.info(@"error!");
  CPLog.info(anError);
}

- (void)startJSONGETRequestForURL:(CPURL)url delegate:(id)delegate callback:(SEL)selector
{
  var request = [[CPURLRequest alloc] initWithURL:url];
  [request setHTTPMethod:@"GET"];
  [request setValue:"application/json" forHTTPHeaderField:@"Content-Type"];
  [request setValue:"application/json" forHTTPHeaderField:@"Accept"];
  var urlConnection = [[CPURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
  urlConnection.delegate = delegate;
  urlConnection.callback = selector;
  [urlConnection start];
    
}


/*- (void)startJSONGETRequestForURL:(CPURL)url identifier:(CPString)identifier
{
  var request = [[CPURLRequest alloc] initWithURL:url];
  
  [request setHTTPMethod:@"GET"];
  [request setValue:"application/json" forHTTPHeaderField:@"Content-Type"];
  [request setValue:"application/json" forHTTPHeaderField:@"Accept"];
  var urlConnection = [[CPURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
  urlConnection.connectionID = identifier;
  urlConnection.url = url; 
  [urlConnection start];
} */

- (void)startJSONPOSTRequestForURL:(CPURL)url payload:(CPString)data
{
  
  var request = [[CPURLRequest alloc] initWithURL:url];
  
  [request setHTTPMethod:@"POST"];
  [request setValue:"application/json" forHTTPHeaderField:@"Content-Type"];
  [request setValue:"application/json" forHTTPHeaderField:@"Accept"]; 
  [request setHTTPBody:data];
  var urlConnection = [[CPURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
  urlConnection.connectionID = "update";
  urlConnection.url = url; 
  [urlConnection start];
}

- (void)startJSONPUTRequestForURL:(CPURL)url payload:(CPString)data
{
  
  var request = [[CPURLRequest alloc] initWithURL:url];
  
  [request setHTTPMethod:@"PUT"];
  [request setValue:"application/json" forHTTPHeaderField:@"Content-Type"];
  [request setValue:"application/json" forHTTPHeaderField:@"Accept"]; 
  [request setHTTPBody:data];
  var urlConnection = [[CPURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
  urlConnection.connectionID = "update";
  urlConnection.url = url; 
  [urlConnection start];
}

@end
