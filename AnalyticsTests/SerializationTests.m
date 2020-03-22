//
//  PropSerializationTests.m
//  AnalyticsTests
//
//  Created by Brandon Sneed on 11/20/19.
//  Copyright © 2019 Segment. All rights reserved.
//

#import <XCTest/XCTest.h>
@import Analytics;

@protocol SEGSerializableDeepCopy <NSObject>
-(id _Nullable) serializableDeepCopy;
@end

@interface NSDictionary(SerializableDeepCopy) <SEGSerializableDeepCopy>
@end

@interface NSArray(SerializableDeepCopy) <SEGSerializableDeepCopy>
@end

@interface SerializationTests : XCTestCase

@end

@implementation SerializationTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testDeepCopyAndConformance {
    NSDictionary *nonserializable = @{@"test": @1, @"nonserializable": self, @"nested": @{@"nonserializable": self}, @"array": @[@1, @2, @3, self]};
    NSDictionary *serializable = @{@"test": @1, @"nonserializable": @0, @"nested": @{@"nonserializable": @0}, @"array": @[@1, @2, @3, @0]};

    NSDictionary *aCopy = [serializable serializableDeepCopy];
    XCTAssert(aCopy != serializable);
    
    NSDictionary *sub = [serializable objectForKey:@"nested"];
    NSDictionary *subCopy = [aCopy objectForKey:@"nested"];
    XCTAssert(sub != subCopy);

    NSDictionary *array = [serializable objectForKey:@"array"];
    NSDictionary *arrayCopy = [aCopy objectForKey:@"array"];
    XCTAssert(array != arrayCopy);

    XCTAssertNoThrow([serializable serializableDeepCopy]);
    XCTAssertThrows([nonserializable serializableDeepCopy]);
}

@end
