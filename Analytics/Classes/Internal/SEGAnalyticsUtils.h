#import <Foundation/Foundation.h>
#import "SEGSerializableValue.h"

NS_ASSUME_NONNULL_BEGIN

NSString *GenerateUUIDString();

// Date Utils
NSString *iso8601FormattedString(NSDate *date);

// Async Utils
dispatch_queue_t seg_dispatch_queue_create_specific(const char *label,
                                                    dispatch_queue_attr_t _Nullable attr);
BOOL seg_dispatch_is_on_specific_queue(dispatch_queue_t queue);
void seg_dispatch_specific(dispatch_queue_t queue, dispatch_block_t block,
                           BOOL waitForCompletion);
void seg_dispatch_specific_async(dispatch_queue_t queue,
                                 dispatch_block_t block);
void seg_dispatch_specific_sync(dispatch_queue_t queue, dispatch_block_t block);

// Logging

void SEGSetShowDebugLogs(BOOL showDebugLogs);
void SEGLog(NSString *format, ...);

// JSON Utils

JSON_DICT SEGCoerceDictionary(NSDictionary *dict);

NSString *SEGIDFA(void);

NSString *SEGEventNameForScreenTitle(NSString *title);

NS_ASSUME_NONNULL_END
