#pragma once
#import <Foundation/Foundation.h>

#if __has_feature(objc_arc)

	#undef STRONG_OR_RETAIN
	#define STRONG_OR_RETAIN strong

	#undef AUTORELEASE
	#define AUTORELEASE(x) (x)

	#undef RELEASE
	#define RELEASE(x)

	#undef RETAIN
	#define RETAIN(x) (x)

	#undef SUPER_DEALLOC
	#define SUPER_DEALLOC

	#undef BRIDGE
	#define BRIDGE __bridge

	#undef BRIDGE_RETAINED
	#define BRIDGE_RETAINED __bridge_retained

	#undef BRIDGE_TRANSFER
	#define BRIDGE_TRANSFER __bridge_transfer

#else

	#undef STRONG_OR_RETAIN
	#define STRONG_OR_RETAIN retain

	#undef AUTORELEASE
	#define AUTORELEASE(x) [(x) autorelease]

	#undef RELEASE
	#define RELEASE(x) [(x) release]

	#undef RETAIN
	#define RETAIN(x) [(x) retain]

	#undef SUPER_DEALLOC
	#define SUPER_DEALLOC [super dealloc]

	#undef BRIDGE
	#define BRIDGE

	#undef BRIDGE_RETAINED
	#define BRIDGE_RETAINED

	#undef BRIDGE_TRANSFER
	#define BRIDGE_TRANSFER

#endif

