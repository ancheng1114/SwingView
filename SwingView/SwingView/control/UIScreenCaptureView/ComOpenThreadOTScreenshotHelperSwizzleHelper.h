//
//  OTSwizzleHelper.h
//
//  v4.2 Created by Markelsoft on 08/21/14.
//

#import <Foundation/Foundation.h>

@interface ComOpenThreadOTScreenshotHelperSwizzleHelper : NSObject

+ (void)swizzClass:(Class)c selector:(SEL)orig selector:(SEL)replace;

@end
