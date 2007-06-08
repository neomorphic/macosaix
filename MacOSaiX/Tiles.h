//  Created by fmidgley on Mon Apr 11 2001.
//  Copyright (c) 2001-2005 Frank M. Midgley. All rights reserved.

#import <Cocoa/Cocoa.h>

#import "MacOSaiXImageSource.h"
#import "MacOSaiXImageMatch.h"


#define TILE_BITMAP_SIZE		16.0


@class MacOSaiXMosaic;


typedef enum { fillWithUniqueMatch, fillWithHandPicked, fillWithTargetImage, fillWithColor } MacOSaiXTileFillStyle;


@interface MacOSaiXTile : NSObject
{
	NSBezierPath			*outline;				// The shape of this tile
	NSNumber				*imageOrientation;		// The orientation of this tile (in degrees), nil if not defined.
	
	NSBitmapImageRep		*bitmapRep,				// The portion of the target image that is in this tile
							*maskRep;
	
	MacOSaiXTileFillStyle	fillStyle;
	MacOSaiXImageMatch		*uniqueImageMatch,
							*bestImageMatch,
							*userChosenImageMatch;	// will be nil if user has not choosen an image
	NSColor					*fillColor;
	
	MacOSaiXMosaic			*mosaic;				// The mosaic this tile is a part of (non-retained)
}

	// designated initializer
- (id)initWithOutline:(NSBezierPath *)outline 
	 imageOrientation:(NSNumber *)angle
			   mosaic:(MacOSaiXMosaic *)mosaic;

- (void)setImageOrientation:(float)angle;
- (BOOL)hasImageOrientation;
- (float)imageOrientation;

- (void)setMosaic:(MacOSaiXMosaic *)mosaic;
- (MacOSaiXMosaic *)mosaic;

- (void)setOutline:(NSBezierPath *)outline;
- (NSBezierPath *)outline;
- (NSBezierPath *)rotatedOutline;

- (NSBitmapImageRep *)bitmapRep;
- (NSBitmapImageRep *)maskRep;
- (void)resetBitmapRepAndMask;

- (void)setFillStyle:(MacOSaiXTileFillStyle)style;
- (MacOSaiXTileFillStyle)fillStyle;

- (void)setUniqueImageMatch:(MacOSaiXImageMatch *)match;
- (MacOSaiXImageMatch *)uniqueImageMatch;

- (void)setBestImageMatch:(MacOSaiXImageMatch *)match;
- (MacOSaiXImageMatch *)bestImageMatch;

- (void)setUserChosenImageMatch:(MacOSaiXImageMatch *)match;
- (MacOSaiXImageMatch *)userChosenImageMatch;

- (void)setFillColor:(NSColor *)color;
- (NSColor *)fillColor;

@end
