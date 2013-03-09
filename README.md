analytics-ios
==============

analytics-ios is an iOS client for [Segment.io](https://segment.io)

## Documentation
 
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

## License

```
WWWWWW||WWWWWW
 W W W||W W W
      ||
    ( OO )__________
     /  |           \
    /o o|    MIT     \
    \___/||_||__||_|| *
         || ||  || ||
        _||_|| _||_||
       (__|__|(__|__|
```

(The MIT License)

Copyright (c) 2013 Segment.io Inc. <friends@segment.io>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
