/*
	QuickTimeImageSource.h
	MacOSaiX

	Created by Frank Midgley on Wed Mar 13 2002.
	Copyright (c) 2004 Frank M. Midgley. All rights reserved.
*/

#import <Cocoa/Cocoa.h>
#import <QuickTime/QuickTime.h>

#import "MacOSaiXImageSource.h"


@interface QuickTimeImageSource : NSObject <MacOSaiXImageSource>
{
    NSString	*moviePath;
	NSMovie		*movie;
	NSLock		*movieLock;
	BOOL		movieIsThreadSafe;
	NSImage		*currentImage;
	float		aspectRatio;
	TimeValue	minIncrement,
                currentTimeValue, 
                duration;
	TimeScale	timeScale;
	BOOL		canRefetchImages;
}

- (NSString *)path;
- (void)setPath:(NSString *)path;

- (void)setCanRefetchImages:(BOOL)flag;

- (float)aspectRatio;

@end
