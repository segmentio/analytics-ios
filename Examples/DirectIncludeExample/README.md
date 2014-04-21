In order to build, first download Analytics.framework sdk from s3, then open the pod

Then download https://s3.amazonaws.com/segmentio/releases/ios/Analytics-latest-stable.zip and unzip contents inside DirectInludeExample (current) folder, where the project expects to find Analytics.framework. In addtion, one must link against following frameworks and libraries. 

### Frameworks
* Analytics
* Foundation
* UIKit
* CoreData
* SystemConfiguration
* QuartzCore
* CFNetwork
* CoreTelephony
* Security

### Libraries
* libsqlite3.dylib
* libz.dylib

### Other linker flags
 -ObjC

