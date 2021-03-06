//
//  MacOSaiXTileEditor.m
//  MacOSaiX
//
//  Created by Frank Midgley on Jun 10, 2006
//  Copyright 2006 Frank M. Midgley. All rights reserved.
//

#import "MacOSaiXTileEditor.h"

#import "MacOSaiXImageCache.h"
#import "MacOSaiXImageMatcher.h"
#import "MacOSaiXMosaic.h"
#import "Tiles.h"
#import "NSString+MacOSaiX.h"


@implementation MacOSaiXTileEditor


- (NSImage *)highlightTileOutlineInImage:(NSImage *)image croppedPercentage:(float *)croppedPercentage
{
		// Scale the image to at most 128 pixels.
    NSImage				*highlightedImage = [[[NSImage alloc] initWithSize:[image size]] autorelease];
	
		// Figure out how to scale and translate the tile to fit within the image.
	NSBezierPath		*tileOutline = [tile rotatedOriginalOutline];
    NSSize				tileSize = [tileOutline bounds].size;
    float				scale;
    NSPoint				origin;
	
    if (([image size].width / tileSize.width) < ([image size].height / tileSize.height))
    {
			// Width is the limiting dimension.
		scale = [image size].width / tileSize.width;
		
		float	heightDiff = [image size].height - tileSize.height * scale;
		origin = NSMakePoint(0.0, heightDiff / 2.0);
    }
    else
    {
			// Height is the limiting dimension.
		scale = [image size].height / tileSize.height;
		
		float	widthDiff = [image size].width - tileSize.width * scale;
		origin = NSMakePoint(widthDiff / 2.0, 0.0);
    }
	
		// Create a transform to scale and translate the tile outline.
    NSAffineTransform	*transform = [NSAffineTransform transform];
    [transform translateXBy:origin.x yBy:origin.y];
    [transform scaleBy:scale];
    [transform translateXBy:-NSMinX([tileOutline bounds]) yBy:-NSMinY([tileOutline bounds])];
	NSBezierPath		*transformedTileOutline = [transform transformBezierPath:tileOutline];
	
	if (croppedPercentage)
	{
		float	imageArea = [image size].width * [image size].height, 
				tileArea = NSWidth([transformedTileOutline bounds]) * NSHeight([transformedTileOutline bounds]);
		
		*croppedPercentage = (imageArea - tileArea) / imageArea * 100.0;
	}
    
	NS_DURING
		[highlightedImage lockFocus];
				// Start with the original image.
			[image compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
			
				// Lighten the area outside of the tile.
			NSBezierPath	*lightenOutline = [NSBezierPath bezierPath];
			[lightenOutline moveToPoint:NSMakePoint(0, 0)];
			[lightenOutline lineToPoint:NSMakePoint(0, [highlightedImage size].height)];
			[lightenOutline lineToPoint:NSMakePoint([highlightedImage size].width, [highlightedImage size].height)];
			[lightenOutline lineToPoint:NSMakePoint([highlightedImage size].width, 0)];
			[lightenOutline closePath];
			[lightenOutline appendBezierPath:transformedTileOutline];
			[[NSColor colorWithCalibratedWhite:1.0 alpha:0.5] set];
			[lightenOutline fill];
			
				// Darken the outline of the tile.
			[[NSColor colorWithCalibratedWhite:0.0 alpha:0.5] set];
			[transformedTileOutline stroke];
		[highlightedImage unlockFocus];
	NS_HANDLER
		#ifdef DEBUG
			NSLog(@"Could not lock focus on editor image");
		#endif
	NS_ENDHANDLER
	
    return highlightedImage;
}


- (void)awakeFromNib
{
	newImageTitleFormat = [[chosenImageBox title] copy];
	
	NSImage		*browserIcon = nil;
	CFURLRef	browserURL = nil;
	OSStatus	status = LSGetApplicationForURL((CFURLRef)[NSURL URLWithString:@"http://www.apple.com/"], 
												kLSRolesViewer,
												NULL,
												&browserURL);
	if (status == noErr)
	{
		browserIcon = [[NSWorkspace sharedWorkspace] iconForFile:[(NSURL *)browserURL path]];
		[browserIcon setSize:[openCurrentImageURLButton frame].size];
		[openCurrentImageURLButton setImage:browserIcon];
	}
	else
	{
		[openCurrentImageURLButton removeFromSuperview];
		openCurrentImageURLButton = nil;
	}
	
}


- (void)chooseImageForTile:(MacOSaiXTile *)inTile 
			modalForWindow:(NSWindow *)window 
			 modalDelegate:(id)inDelegate
			didEndSelector:(SEL)inDidEndSelector
{
	tile = inTile;
	delegate = inDelegate;
	didEndSelector = inDidEndSelector;
	
	if (!accessoryView)
		[NSBundle loadNibNamed:@"Tile Editor" owner:self];
	
		// Create the image for the "Original Image" view of the accessory view.
	NSRect		originalImageViewFrame = NSMakeRect(0.0, 0.0, [originalImageView frame].size.width, 
													[originalImageView frame].size.height);
	NSImage		*originalImageForTile = [[[NSImage alloc] initWithSize:originalImageViewFrame.size] autorelease];
	NS_DURING
		[originalImageForTile lockFocus];
		
				// Start with a black background.
			[[NSColor blackColor] set];
			NSRectFill(originalImageViewFrame);
			
				// Determine the bounds of the tile in the original image and in the scratch window.
			NSRect			origRect = [[tile originalOutline] bounds];
			
				// Expand the rectangle so that it's square.
			if (origRect.size.width > origRect.size.height)
				origRect = NSInsetRect(origRect, 0.0, (origRect.size.height - origRect.size.width) / 2.0);
			else
				origRect = NSInsetRect(origRect, (origRect.size.width - origRect.size.height) / 2.0, 0.0);
			
				// Copy out the portion of the original image contained by the tile's outline.
			[[[tile mosaic] originalImage] drawInRect:originalImageViewFrame fromRect:origRect operation:NSCompositeCopy fraction:1.0];
		[originalImageForTile unlockFocus];
	NS_HANDLER
		#ifdef DEBUG
			NSLog(@"Exception raised while extracting tile images: %@", [localException name]);
		#endif
	NS_ENDHANDLER
	[originalImageView setImage:[self highlightTileOutlineInImage:originalImageForTile croppedPercentage:nil]];
	
		// Set up the current image box
	MacOSaiXImageMatch	*currentMatch = [tile displayedImageMatch];
	if (currentMatch)
	{
		id<MacOSaiXImageSource>	currentSource = [currentMatch imageSource];
		NSString				*currentIdentifier = [currentMatch imageIdentifier];
		NSSize					currentSize = [[MacOSaiXImageCache sharedImageCache] 
													nativeSizeOfImageWithIdentifier:currentIdentifier 
																		 fromSource:currentSource];
		
		if (NSEqualSizes(currentSize, NSZeroSize))
		{
				// The image is not in the cache so request a random sized rep to get it loaded.
			[[MacOSaiXImageCache sharedImageCache] imageRepAtSize:NSMakeSize(1.0, 1.0) 
													forIdentifier:currentIdentifier 
													   fromSource:currentSource];
			currentSize = [[MacOSaiXImageCache sharedImageCache] nativeSizeOfImageWithIdentifier:currentIdentifier 
																					  fromSource:currentSource];
		}
		
		NSBitmapImageRep	*currentRep = [[MacOSaiXImageCache sharedImageCache] imageRepAtSize:currentSize 
																				  forIdentifier:currentIdentifier 
																					 fromSource:currentSource];
		NSImage				*currentImage = [[[NSImage alloc] initWithSize:currentSize] autorelease];
		[currentImage addRepresentation:currentRep];
		float				croppedPercentage = 0.0;
		[currentImageView setImage:[self highlightTileOutlineInImage:currentImage croppedPercentage:&croppedPercentage]];
		//		float				worstCaseMatch = sqrtf([selectedTile worstCaseMatchValue]), 
		//							matchPercentage = (worstCaseMatch - sqrtf([currentMatch matchValue])) / worstCaseMatch * 100.0;
		[currentMatchQualityTextField setStringValue:[NSString stringWithFormat:@"%.0f%%", 100.0 - [currentMatch matchValue] * 100.0]];
		[currentPercentCroppedTextField setStringValue:[NSString stringWithFormat:@"%.0f%%", croppedPercentage]];
		[currentImageSourceImageView setImage:[currentSource image]];
		[currentImageSourceNameField setObjectValue:[currentSource descriptor]];
		NSString	*description = [currentSource descriptionForIdentifier:currentIdentifier];
		[currentImageDescriptionField setStringValue:(description ? description : NSLocalizedString(@"No description available", @""))];
		
		[currentImageContextURL release];
		currentImageContextURL = [[currentSource contextURLForIdentifier:currentIdentifier] retain];
		[openCurrentImageURLButton setEnabled:(currentImageContextURL != nil)];
		[openCurrentImageURLButton setToolTip:[currentImageContextURL absoluteString]];
	}
	else
	{
		[currentImageView setImage:nil];
		[currentMatchQualityTextField setStringValue:@"--"];
		[currentPercentCroppedTextField setStringValue:@"--"];
		[openCurrentImageURLButton setEnabled:NO];
	}
	
	// Set up the chosen image box.
	[chosenImageBox setTitle:[NSString stringWithFormat:newImageTitleFormat, NSLocalizedString(@"No File Selected", @"")]];
	[chosenImageView setImage:nil];
	[chosenMatchQualityTextField setStringValue:@"--"];
	[chosenPercentCroppedTextField setStringValue:@"--"];
	
	// Prompt the user to choose the image from which to make a mosaic.
	NSOpenPanel	*openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:NO];
	if ([openPanel respondsToSelector:@selector(setMessage:)])
		[openPanel setMessage:NSLocalizedString(@"Choose an image to be displayed in this tile:", @"")];
	[openPanel setPrompt:NSLocalizedString(@"Choose", @"")];
	[openPanel setDelegate:self];
	
	[openPanel setAccessoryView:accessoryView];
	NSSize	superSize = [[accessoryView superview] frame].size;
	[accessoryView setFrame:NSMakeRect(5.0, 5.0, superSize.width - 10.0, superSize.height - 10.0)];
	[accessoryView setAutoresizingMask:NSViewWidthSizable];
	
	[openPanel beginSheetForDirectory:nil
								 file:nil
								types:[NSImage imageFileTypes]
					   modalForWindow:window
						modalDelegate:self
					   didEndSelector:@selector(chooseImagePanelDidEnd:returnCode:contextInfo:)
						  contextInfo:nil];
}


- (void)panelSelectionDidChange:(id)sender
{
	if ([[sender URLs] count] == 0)
	{
		[chosenImageBox setTitle:[NSString stringWithFormat:newImageTitleFormat, NSLocalizedString(@"No File Selected", @"")]];
		[chosenImageView setImage:nil];
		[chosenMatchQualityTextField setStringValue:@"--"];
		[chosenPercentCroppedTextField setStringValue:@"--"];
	}
	else
	{
			// This shouldn't be necessary but updating the views right away often crashes because of some interaction with the AppKit thread that is creating a preview of the selected image.
		[self performSelector:@selector(updateUserChosenViewsForImageAtPath:) withObject:[[sender filenames] objectAtIndex:0] afterDelay:0.0];
	}
}


- (void)updateUserChosenViewsForImageAtPath:(NSString *)imagePath
{
	NSString			*chosenImageIdentifier = imagePath, 
						*chosenImageName = [[NSFileManager defaultManager] displayNameAtPath:chosenImageIdentifier];

	[chosenImageBox setTitle:[NSString stringWithFormat:newImageTitleFormat, chosenImageName]];
	
	NSImage				*chosenImage = [[[NSImage alloc] initWithContentsOfFile:chosenImageIdentifier] autorelease];
	[chosenImage setCachedSeparately:YES];
	[chosenImage setCacheMode:NSImageCacheNever];
	
	if (chosenImage)
	{
		NSImageRep			*originalRep = [[chosenImage representations] objectAtIndex:0];
		NSSize				imageSize = NSMakeSize([originalRep pixelsWide], [originalRep pixelsHigh]);
		[originalRep setSize:imageSize];
		[chosenImage setSize:imageSize];
		
		float				croppedPercentage = 0.0;
		[chosenImageView setImage:[self highlightTileOutlineInImage:chosenImage croppedPercentage:&croppedPercentage]];
		
		[chosenPercentCroppedTextField setStringValue:[NSString stringWithFormat:@"%.0f%%", croppedPercentage]];
		
			// Calculate how well the chosen image matches the selected tile.
		[[MacOSaiXImageCache sharedImageCache] cacheImage:chosenImage withIdentifier:chosenImageIdentifier fromSource:nil];
		NSBitmapImageRep	*chosenImageRep = [[MacOSaiXImageCache sharedImageCache] imageRepAtSize:[[tile bitmapRep] size] 
																					  forIdentifier:chosenImageIdentifier 
																						 fromSource:nil];
		chosenMatchValue = [[MacOSaiXImageMatcher sharedMatcher] compareImageRep:[tile bitmapRep]  
																		withMask:[tile maskRep] 
																	  toImageRep:chosenImageRep
																	previousBest:1.0];
		[chosenMatchQualityTextField setStringValue:[NSString stringWithFormat:@"%.0f%%", 100.0 - chosenMatchValue * 100.0]];
	}
}


- (IBAction)openWebPageForCurrentImage:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:currentImageContextURL];
}


- (void)chooseImagePanelDidEnd:(NSOpenPanel *)openPanel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[openPanel orderOut:self];
	
	if ([openPanel respondsToSelector:@selector(setMessage:)])
		[openPanel setMessage:@""];
	
	if (returnCode == NSOKButton)
	{
		[[tile mosaic] setHandPickedImageAtPath:[[openPanel filenames] objectAtIndex:0]
								 withMatchValue:chosenMatchValue
										forTile:tile];
	}
	
	if ([delegate respondsToSelector:@selector(didEndSelector)])
		[delegate performSelector:didEndSelector];
	
	tile = nil;
	delegate = nil;
	didEndSelector = nil;
}


- (void)dealloc
{
	[accessoryView release];
	[newImageTitleFormat release];
	[currentImageContextURL release];
	
	[super dealloc];
}


@end
