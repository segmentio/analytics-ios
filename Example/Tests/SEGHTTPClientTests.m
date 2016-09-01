#import <Foundation/Foundation.h>
#import <Analytics/SEGHTTPClient.h>
#import <Analytics/NSData+SEGGZIP.h>
#import <Nocilla/Nocilla.h>

SpecBegin(SEGHTTPClient);

describe(@"SEGHTTPClient", ^{
    beforeAll(^{
        [[LSNocilla sharedInstance] start];
    });
    afterAll(^{
        [[LSNocilla sharedInstance] stop];
    });
    afterEach(^{
        [[LSNocilla sharedInstance] clearStubs];
    });

    describe(@"defaultRequestFactory", ^{
        it(@"preserves url", ^{
            SEGRequestFactory factory = [SEGHTTPClient defaultRequestFactory];
            NSURL *url = [NSURL URLWithString:@"https://api.segment.io/v1/batch"];
            NSMutableURLRequest *request = factory(url);
            expect(request.URL).to.equal(url);
        });
    });

    describe(@"settingsForWriteKey", ^{
        it(@"succeeds for 2xx response", ^{
            stubRequest(@"GET", @"https://cdn.segment.com/v1/projects/foo/settings")
                .withHeaders(@{ @"Accept-Encoding" : @"gzip" })
                .andReturn(200)
                .withHeaders(@{ @"Content-Type" : @"application/json" })
                .withBody(@"{\"integrations\":{\"Segment.io\":{\"apiKey\":\"foo\"}},\"plan\":{\"track\":{}}}");

            SEGHTTPClient *client = [[SEGHTTPClient alloc] initWithRequestFactory:nil];

            waitUntil(^(DoneCallback done) {
                NSURLSessionDataTask *task = [client settingsForWriteKey:@"foo" completionHandler:^(BOOL success, NSDictionary *settings) {
                    expect(success).to.equal(YES);
                    expect(settings).to.equal(@{
                        @"integrations" : @{
                            @"Segment.io" : @{
                                @"apiKey" : @"foo"
                            }
                        },
                        @"plan" : @{
                            @"track" : @{}
                        }
                    });
                    done();
                }];
                expect(task.state).will.equal(NSURLSessionTaskStateCompleted);
            });
        });

        it(@"fails for for non 2xx response", ^{
            stubRequest(@"GET", @"https://cdn.segment.com/v1/projects/foo/settings")
                .withHeaders(@{ @"Accept-Encoding" : @"gzip" })
                .andReturn(400)
                .withHeaders(@{ @"Content-Type" : @"application/json" })
                .withBody(@"{\"integrations\":{\"Segment.io\":{\"apiKey\":\"foo\"}},\"plan\":{\"track\":{}}}");

            SEGHTTPClient *client = [[SEGHTTPClient alloc] initWithRequestFactory:nil];

            waitUntil(^(DoneCallback done) {
                NSURLSessionDataTask *task = [client settingsForWriteKey:@"foo" completionHandler:^(BOOL success, NSDictionary *settings) {
                    expect(success).to.equal(NO);
                    expect(settings).to.equal(nil);
                    done();
                }];
                expect(task.state).will.equal(NSURLSessionTaskStateCompleted);
            });
        });

        it(@"fails for json error", ^{
            stubRequest(@"GET", @"https://cdn.segment.com/v1/projects/foo/settings")
                .withHeaders(@{ @"Accept-Encoding" : @"gzip" })
                .andReturn(200)
                .withHeaders(@{ @"Content-Type" : @"application/json" })
                .withBody(@"{\"integrations");

            SEGHTTPClient *client = [[SEGHTTPClient alloc] initWithRequestFactory:nil];

            waitUntil(^(DoneCallback done) {
                NSURLSessionDataTask *task = [client settingsForWriteKey:@"foo" completionHandler:^(BOOL success, NSDictionary *settings) {
                    expect(success).to.equal(NO);
                    expect(settings).to.equal(nil);
                    done();
                }];
                expect(task.state).will.equal(NSURLSessionTaskStateCompleted);
            });
        });
    });

    describe(@"upload", ^{
        it(@"does not ask to retry for json error", ^{
            NSDictionary *batch = @{
                // Dates cannot be serialized as is so the json serialzation will fail.
                @"sentAt" : [NSDate date],
                @"batch" : @[ @{@"type" : @"track", @"event" : @"foo"} ]
            };

            SEGHTTPClient *client = [[SEGHTTPClient alloc] initWithRequestFactory:nil];

            waitUntil(^(DoneCallback done) {
                NSURLSessionDataTask *task = [client upload:batch forWriteKey:@"bar" completionHandler:^(BOOL retry) {
                    expect(retry).to.equal(NO);
                    done();
                }];
                expect(task).to.equal(nil);
            });
        });

        it(@"does not ask to retry for 2xx response", ^{
            NSDictionary *batch = @{
                @"sentAt" : @"2016-07-19'T'19:25:06Z",
                @"batch" : @[ @{@"type" : @"track", @"event" : @"foo"} ]
            };
            NSString *base64Body = @"H4sIAAAAAAAAA6tWSkosSc5QsoquViqpLEhVslIqKUpMzlbSUUotS80rAfLT8vOVamN1lIqBXEeQgJGBoZmugbmuoaV6iLqhpZWRqZWBWZRSLQB8HDmdTAAAAA==";
            NSData *body = [[NSData alloc] initWithBase64EncodedString:base64Body options:0];

            stubRequest(@"POST", @"https://api.segment.io/v1/batch")
                .withHeaders(@{
                    @"Accept-Encoding" : @"gzip",
                    @"Authorization" : @"Basic YmFyOg==",
                    @"Content-Encoding" : @"gzip",
                    @"Content-Length" : @"91",
                    @"Content-Type" : @"application/json"
                })
                .withBody(body)
                .andReturn(200)
                .withBody(@"{\"success\": true");

            SEGHTTPClient *client = [[SEGHTTPClient alloc] initWithRequestFactory:nil];

            waitUntil(^(DoneCallback done) {
                NSURLSessionDataTask *task = [client upload:batch forWriteKey:@"bar" completionHandler:^(BOOL retry) {
                    expect(retry).to.equal(NO);
                    done();
                }];
                expect(task.state).will.equal(NSURLSessionTaskStateCompleted);
            });
        });

        it(@"asks to retry for 3xx response", ^{
            NSDictionary *batch = @{
                @"sentAt" : @"2016-07-19'T'19:25:06Z",
                @"batch" : @[ @{@"type" : @"track", @"event" : @"foo"} ]
            };
            NSString *base64Body = @"H4sIAAAAAAAAA6tWSkosSc5QsoquViqpLEhVslIqKUpMzlbSUUotS80rAfLT8vOVamN1lIqBXEeQgJGBoZmugbmuoaV6iLqhpZWRqZWBWZRSLQB8HDmdTAAAAA==";
            NSData *body = [[NSData alloc] initWithBase64EncodedString:base64Body options:0];

            stubRequest(@"POST", @"https://api.segment.io/v1/batch")
                .withHeaders(@{
                    @"Accept-Encoding" : @"gzip",
                    @"Authorization" : @"Basic YmFyOg==",
                    @"Content-Encoding" : @"gzip",
                    @"Content-Length" : @"91",
                    @"Content-Type" : @"application/json"
                })
                .withBody(body)
                .andReturn(304)
                .withBody(@"{\"success\": true");

            SEGHTTPClient *client = [[SEGHTTPClient alloc] initWithRequestFactory:nil];

            waitUntil(^(DoneCallback done) {
                NSURLSessionDataTask *task = [client upload:batch forWriteKey:@"bar" completionHandler:^(BOOL retry) {
                    expect(retry).to.equal(YES);
                    done();
                }];
                expect(task.state).will.equal(NSURLSessionTaskStateCompleted);
            });
        });

        it(@"does not ask to retry for 4xx response", ^{
            NSDictionary *batch = @{
                @"sentAt" : @"2016-07-19'T'19:25:06Z",
                @"batch" : @[ @{@"type" : @"track", @"event" : @"foo"} ]
            };
            NSString *base64Body = @"H4sIAAAAAAAAA6tWSkosSc5QsoquViqpLEhVslIqKUpMzlbSUUotS80rAfLT8vOVamN1lIqBXEeQgJGBoZmugbmuoaV6iLqhpZWRqZWBWZRSLQB8HDmdTAAAAA==";
            NSData *body = [[NSData alloc] initWithBase64EncodedString:base64Body options:0];

            stubRequest(@"POST", @"https://api.segment.io/v1/batch")
                .withHeaders(@{
                    @"Accept-Encoding" : @"gzip",
                    @"Authorization" : @"Basic YmFyOg==",
                    @"Content-Encoding" : @"gzip",
                    @"Content-Length" : @"91",
                    @"Content-Type" : @"application/json"
                })
                .withBody(body)
                .andReturn(401)
                .withBody(@"{\"success\": true");

            SEGHTTPClient *client = [[SEGHTTPClient alloc] initWithRequestFactory:nil];

            waitUntil(^(DoneCallback done) {
                NSURLSessionDataTask *task = [client upload:batch forWriteKey:@"bar" completionHandler:^(BOOL retry) {
                    expect(retry).to.equal(NO);
                    done();
                }];
                expect(task.state).will.equal(NSURLSessionTaskStateCompleted);
            });
        });

        it(@"asks to retry for 5xx response", ^{
            NSDictionary *batch = @{
                @"sentAt" : @"2016-07-19'T'19:25:06Z",
                @"batch" : @[ @{@"type" : @"track", @"event" : @"foo"} ]
            };
            NSString *base64Body = @"H4sIAAAAAAAAA6tWSkosSc5QsoquViqpLEhVslIqKUpMzlbSUUotS80rAfLT8vOVamN1lIqBXEeQgJGBoZmugbmuoaV6iLqhpZWRqZWBWZRSLQB8HDmdTAAAAA==";
            NSData *body = [[NSData alloc] initWithBase64EncodedString:base64Body options:0];

            stubRequest(@"POST", @"https://api.segment.io/v1/batch")
                .withHeaders(@{
                    @"Accept-Encoding" : @"gzip",
                    @"Authorization" : @"Basic YmFyOg==",
                    @"Content-Encoding" : @"gzip",
                    @"Content-Length" : @"91",
                    @"Content-Type" : @"application/json"
                })
                .withBody(body)
                .andReturn(504)
                .withBody(@"{\"success\": true");

            SEGHTTPClient *client = [[SEGHTTPClient alloc] initWithRequestFactory:nil];

            waitUntil(^(DoneCallback done) {
                NSURLSessionDataTask *task = [client upload:batch forWriteKey:@"bar" completionHandler:^(BOOL retry) {
                    expect(retry).to.equal(YES);
                    done();
                }];
                expect(task.state).will.equal(NSURLSessionTaskStateCompleted);
            });
        });
    });

    describe(@"attribution", ^{
        it(@"fails for json error", ^{
            NSDictionary *device = @{
                // Dates cannot be serialized as is so the json serialzation will fail.
                @"sentAt" : [NSDate date]
            };

            SEGHTTPClient *client = [[SEGHTTPClient alloc] initWithRequestFactory:nil];

            waitUntil(^(DoneCallback done) {
                NSURLSessionDataTask *task = [client attributionWithWriteKey:@"bar" forDevice:device completionHandler:^(BOOL success, NSDictionary *properties) {
                    expect(success).to.equal(NO);
                    done();
                }];
                expect(task).to.equal(nil);
            });
        });

        it(@"succeeds for 2xx response", ^{
            NSDictionary *context = @{
                @"os" : @{
                    @"name" : @"iPhone OS",
                    @"version" : @"8.1.3"
                },
                @"ip" : @"8.8.8.8"
            };

            stubRequest(@"POST", @"https://mobile-service.segment.com/v1/attribution")
                .withHeaders(@{
                    @"Accept-Encoding" : @"gzip",
                    @"Authorization" : @"Basic Zm9vOg==",
                    @"Content-Encoding" : @"gzip",
                    @"Content-Length" : @"72",
                    @"Content-Type" : @"application/json"
                })
                .andReturn(200)
                .withBody(@"{\"provider\": \"mock\"}");

            SEGHTTPClient *client = [[SEGHTTPClient alloc] initWithRequestFactory:nil];


            waitUntil(^(DoneCallback done) {
                NSURLSessionDataTask *task = [client attributionWithWriteKey:@"foo" forDevice:context completionHandler:^(BOOL success, NSDictionary *properties) {
                    expect(success).to.equal(YES);
                    expect(properties).to.equal(@{
                        @"provider" : @"mock"
                    });
                    done();
                }];
                expect(task.state).will.equal(NSURLSessionTaskStateCompleted);
            });
        });

        it(@"fails for non 2xx response", ^{
            NSDictionary *context = @{
                @"os" : @{
                    @"name" : @"iPhone OS",
                    @"version" : @"8.1.3"
                },
                @"ip" : @"8.8.8.8"
            };

            stubRequest(@"POST", @"https://mobile-service.segment.com/v1/attribution")
                .withHeaders(@{
                    @"Accept-Encoding" : @"gzip",
                    @"Authorization" : @"Basic Zm9vOg==",
                    @"Content-Encoding" : @"gzip",
                    @"Content-Length" : @"72",
                    @"Content-Type" : @"application/json"
                })
                .andReturn(404)
                .withBody(@"not found");

            SEGHTTPClient *client = [[SEGHTTPClient alloc] initWithRequestFactory:nil];

            waitUntil(^(DoneCallback done) {
                NSURLSessionDataTask *task = [client attributionWithWriteKey:@"foo" forDevice:context completionHandler:^(BOOL success, NSDictionary *properties) {
                    expect(success).to.equal(NO);
                    expect(properties).to.equal(nil);
                    done();
                }];
                expect(task.state).will.equal(NSURLSessionTaskStateCompleted);
            });
        });
    });

});

SpecEnd
