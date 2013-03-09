 # Analytics-iOS by Segment.io
 For integrating analytics with your iOS app.
 
 ## Usage
 
 ```objective-c
 // Initialize the shared API instance.
 Analytics *analytics = [Analytics createSharedInstance:@"YOUR SEGMENT.IO API SECRET"];

 // Later, get the shared instance...
 Analytics *analytics = [Analytics getSharedInstance];
 

 // Identify a user.
 [analytics identify:@"USER ID"];

 // ...optionally set traits for that user
 [analytics identify:@"USER ID" traits:[NSDictionary dictionaryWithObjectsAndKeys:
    [NSNumber numberWithInt:29], @"friendCount", nil]];


 // Track an event.
 [analytics track:@"Saved Photo"];

 // ...optionally include event properties
 [analytics track:@"Saved Photo" properties:[NSDictionary dictionaryWithObjectsAndKeys:
    @"Tilt-shift", @"Filter", nil]];

```