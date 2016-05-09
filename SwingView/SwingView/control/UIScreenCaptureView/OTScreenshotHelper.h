//
//  OTScreenShotHelper.h
//
//  v4.2 Created by Markelsoft on 08/21/14.
//  v4.2.1 Updates to not use options for more recent iOS versions - this fixes retina display problems
//  v4.4   Updated 03/23/2015 - fix for retina on iPhone
//  v4.4.1 Updated 03/24/2015 - fix for retina on iPhone
//  v4.4.2 Updated 04/14/2015 - fix for retina
//  v4.4.4 Updated 08/130/2015 - added save image to photos
//  v4.5   Updated 10/05/2015 - fixed OTScreenshotHelper for iOS8+
//

#import <Foundation/Foundation.h>

@interface OTScreenshotHelper : NSObject

// Get the screenshot of a view.
+ (UIImage *)screenshotOfView:(UIView *)view;

// Get the screenshot, image rotate to status bar's current interface orientation. With status bar.
+ (UIImage *)screenshot;

// Get the screenshot, image rotate to status bar's current interface orientation. With status bar.
// AND save to Photos
+ (UIImage *)screenshotAndSave;

//Get the screenshot, image rotate to status bar's current interface orientation.
+ (UIImage *)screenshotWithStatusBar:(BOOL)withStatusBar;

//Get the screenshot with rect, image rotate to status bar's current interface orientation.
+ (UIImage *)screenshotWithStatusBar:(BOOL)withStatusBar rect:(CGRect)rect;

//Get the screenshot with rect, you can specific a interface orientation.
+ (UIImage *)screenshotWithStatusBar:(BOOL)withStatusBar rect:(CGRect)rect orientation:(UIInterfaceOrientation)o;

// save an image to Photos
+ (BOOL)saveImageToPhotos:(UIImage *)image;

@end
