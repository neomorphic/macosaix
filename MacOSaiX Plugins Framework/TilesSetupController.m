//
//  TilesSetupController.m
//  MacOSaiX
//
//  Created by Frank Midgley on Thu Jan 23 2003.
//  Copyright (c) 2003-2004 Frank M. Midgley. All rights reserved.
//

#import "TilesSetupController.h"


@implementation TilesSetupController


+ (NSString *)name
{
	return @"";
}


- (NSView *)setupView
{
	return nil;
}


- (void)setTileOutlines:(NSArray *)outlines
{
	[[self document] setTileOutlines:outlines];
}


@end
