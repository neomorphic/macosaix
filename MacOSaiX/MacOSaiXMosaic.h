//
//  MacOSaiXMosaic.h
//  MacOSaiX
//
//  Created by Frank Midgley on 10/4/05.
//  Copyright 2005 Frank M. Midgley. All rights reserved.
//

@class MacOSaiXHandPickedImageSource, MacOSaiXTile;
@protocol MacOSaiXTileShapes, MacOSaiXImageOrientations, MacOSaiXImageSource, MacOSaiXExportSettings;


@interface MacOSaiXMosaic : NSObject
{
    NSImage							*targetImage;
	NSString						*targetImagePath, 
									*targetImageIdentifier;
	id<MacOSaiXImageSource>			targetImageSource;
	float							targetImageAspectRatio;
	
    NSMutableArray					*imageSources,
									*tiles;
	
	NSLock							*imageSourcesLock;
	
	id<MacOSaiXTileShapes>			tileShapes;
	id<MacOSaiXImageOrientations>	imageOrientations;
	id<MacOSaiXExportSettings>		exportSettings;
	
	NSSize							averageTileSize;
	
		// Image usage settings
	int								imageUseCount,
									imageReuseDistance,
									imageCropLimit;
	
	NSLock							*tilesWithoutBitmapsLock;
	BOOL							tileBitmapExtractionThreadAlive;
	NSMutableArray					*tilesWithoutBitmaps;
	
	NSString						*diskCachePath;
	NSMutableDictionary				*diskCacheSubPaths;
	
		// Image source enumeration
    NSLock							*enumerationsLock;
	NSMutableArray					*imageSourceEnumerations;
	NSMutableDictionary				*imagesFoundCounts;
    NSMutableArray					*imageQueue, 
									*revisitQueue;
    NSLock							*imageQueueLock;
	
		// Image matching
    NSLock							*calculateImageMatchesLock;
	BOOL							calculateImageMatchesThreadAlive;
	NSMutableDictionary				*betterMatchesCache, 
									*imageIdentifiersInUse;
	
    BOOL							paused, 
									pausing;
    float							overallMatch,
									lastDisplayMatch;
	
	id<MacOSaiXImageSource>			probationaryImageSource;
	NSMutableSet					*probationImageQueue;
	NSDate							*probationStartDate;
	NSRecursiveLock					*probationLock;
}

	// Target image
- (void)setTargetImage:(NSImage *)image;
- (NSImage *)targetImage;
- (void)setTargetImagePath:(NSString *)path;
- (NSString *)targetImagePath;
- (void)setTargetImageIdentifier:(NSString *)identifier source:(id<MacOSaiXImageSource>)source;
- (NSString *)targetImageIdentifier;
- (id<MacOSaiXImageSource>)targetImageSource;

- (void)setAspectRatio:(float)ratio;
- (float)aspectRatio;

	// Tile shapes
- (void)setTileShapes:(id<MacOSaiXTileShapes>)tileShapes creatingTiles:(BOOL)createTiles;
- (id<MacOSaiXTileShapes>)tileShapes;
- (NSSize)averageTileSize;

	// Image orientations
- (void)setImageOrientations:(id<MacOSaiXImageOrientations>)imageOrientations;
- (id<MacOSaiXImageOrientations>)imageOrientations;

	// Export settings
- (void)setExportSettings:(id<MacOSaiXExportSettings>)exportSettings;
- (id<MacOSaiXExportSettings>)exportSettings;

	// Image usage
- (int)imageUseCount;
- (void)setImageUseCount:(int)count;
- (int)imageReuseDistance;
- (void)setImageReuseDistance:(int)distance;
- (int)imageCropLimit;
- (void)setImageCropLimit:(int)cropLimit;

- (NSArray *)tiles;
- (BOOL)allTilesHaveExtractedBitmaps;

- (BOOL)isBusy;
- (NSString *)busyStatus;

- (unsigned long)numberOfImagesFound;
- (unsigned long)numberOfImagesInUse;

	// Image sources methods
- (NSArray *)imageSources;
- (void)addImageSource:(id<MacOSaiXImageSource>)imageSource;
- (void)imageSource:(id<MacOSaiXImageSource>)imageSource didChangeSettings:(NSString *)changeDescription;
- (void)removeImageSource:(id<MacOSaiXImageSource>)imageSource;
- (BOOL)imageSourcesExhausted;
- (unsigned long)numberOfImagesFoundFromSource:(id<MacOSaiXImageSource>)imageSource;
- (unsigned long)numberOfImagesInUseFromSource:(id<MacOSaiXImageSource>)imageSource;

	// Disk cache paths
- (NSString *)diskCachePath;
- (void)setDiskCachePath:(NSString *)path;
- (NSString *)diskCacheSubPathForImageSource:(id<MacOSaiXImageSource>)imageSource;
- (void)setDiskCacheSubPath:(NSString *)path forImageSource:(id<MacOSaiXImageSource>)imageSource;

	// Hand picked images
- (MacOSaiXHandPickedImageSource *)handPickedImageSource;
- (void)setHandPickedImageAtPath:(NSString *)path withMatchValue:(float)matchValue forTile:(MacOSaiXTile *)tile;
- (void)removeHandPickedImageForTile:(MacOSaiXTile *)tile;

	// Pause/resume
- (BOOL)isPaused;
- (void)pause;
- (void)resume;

@end


	// Notifications
extern NSString	*MacOSaiXMosaicDidChangeImageSourcesNotification;
extern NSString	*MacOSaiXMosaicDidChangeBusyStateNotification;
extern NSString	*MacOSaiXTargetImageDidChangeNotification;
extern NSString *MacOSaiXTileContentsDidChangeNotification;
extern NSString *MacOSaiXTileShapesDidChangeStateNotification;
extern NSString *MacOSaiXImageOrientationsDidChangeStateNotification;
extern NSString *MacOSaiXMosaicImageSourceDidChangeCountsNotification;

