analytics-ios
=================

analytics-ios is an iOS client for [Segment.io](https://segment.io)

Special thanks to [Tony Xiao](https://github.com/tonyxiao) for his contributions to this library!

## Documentation

Documentation is available at [https://segment.io/libraries/ios](https://segment.io/libraries/ios).

## Development

libAnalytics itself strives to have as few dependencies as possible to create the most compatible and 
lightweight Analytics SDK for ObjC developers. However, there is no such restriction during testing time,
and in order to contribute to the SDK, you will need cocoapods, as well as an additional pod specs repo. 
This can be accomplished as follow

`[sudo] gem install cocoapods`
`pod repo add Collections-Podspecs git@github.com:collections/Podspecs.git`
`pod install`

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
