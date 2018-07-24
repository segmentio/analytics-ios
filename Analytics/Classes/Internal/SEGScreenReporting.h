#import <Foundation/Foundation.h>
#import "SEGSerializableValue.h"

/** Implement this protocol to add properties to automatic screen reporting
 */

NS_ASSUME_NONNULL_BEGIN

@protocol SEGScreenReporting
@optional @property (readonly, nullable) NSString * seg_screenName;
@optional @property (readonly, nullable) SERIALIZABLE_DICT seg_screenProperties;
@end

NS_ASSUME_NONNULL_END


