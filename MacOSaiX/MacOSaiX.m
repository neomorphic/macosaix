#import "MacOSaiX.h"
#import "PreferencesController.h"
#import "MacOSaiXTileShapes.h"
#import "MacOSaiXImageSource.h"


@implementation MacOSaiX


+ (void)initialize
{
	isalpha('a');	// get rid of weak linking warning

    NSUserDefaults		*defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary	*appDefaults = [NSMutableDictionary dictionary];
    
    [appDefaults setObject:@"15" forKey:@"Autosave Frequency"];
    [defaults registerDefaults:appDefaults];
    [defaults setBool:YES forKey:@"AppleDockIconEnabled"];
}


- (id)init
{
	if (self = [super init])
	{
		tileShapesClasses = [[NSMutableArray arrayWithCapacity:1] retain];
		imageSourceClasses = [[NSMutableArray arrayWithCapacity:4] retain];
		loadedPlugInPaths = [[NSMutableArray arrayWithCapacity:5] retain];
	}
	return self;
}


- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	// TODO: version check
	
		// Do an initial discovery of plug-ins
		// (Now done lazily in MacOSaiXWindowController.)
	//[self discoverPlugIns];

		// To provide a service:
    //[NSApp setServicesProvider:[[EncryptoClass alloc] init]];
}


//- (void)newMacOSaiXWithPasteboard:(NSPasteboard *)pBoard userObject:(id)userObj error:(NSString **)error
//{
//}


- (void)openPreferences:(id)sender
{
#if 1
	NSRunAlertPanel(@"Preferences" , @"Preferences are not available in this version.", @"Drat", nil, nil);
#else
    PreferencesController	*windowController;
    
    windowController = [[PreferencesController alloc] initWithWindowNibName:@"Preferences"];
    [windowController showWindow:self];
    [[windowController window] makeKeyAndOrderFront:self];

    // The windowController object will now take input and, if the user OK's, save the preferences
#endif
}


	// Check our Plug-Ins directory for tile setup and image source plug-ins and add any new ones to the known lists.
- (void)discoverPlugIns
{
	NSString				*plugInsPath = [[NSBundle mainBundle] builtInPlugInsPath];
	NSDirectoryEnumerator	*pathEnumerator = [[NSFileManager defaultManager]
 enumeratorAtPath:plugInsPath];
	NSString				*plugInSubPath;
	
	while (plugInSubPath = [pathEnumerator nextObject])
	{
		NSString	*plugInPath = [plugInsPath stringByAppendingPathComponent:plugInSubPath];
		
		if ([loadedPlugInPaths containsObject:plugInPath])
			[pathEnumerator skipDescendents];
		else
		{
			NSBundle	*plugInBundle = [NSBundle bundleWithPath:plugInPath];
			
			if (plugInBundle) // then the path is a valid bundle
			{
				Class	plugInPrincipalClass = [plugInBundle principalClass];
				
				if (plugInPrincipalClass && [plugInPrincipalClass conformsToProtocol:@protocol(MacOSaiXTileShapes)])
				{
					[tileShapesClasses addObject:plugInPrincipalClass];
					[loadedPlugInPaths addObject:plugInsPath];
				}

				if (plugInPrincipalClass && [plugInPrincipalClass conformsToProtocol:@protocol(MacOSaiXImageSource)])
				{
					[imageSourceClasses addObject:plugInPrincipalClass];
					[loadedPlugInPaths addObject:plugInsPath];
				}

					// don't look inside this bundle for other bundles
				[pathEnumerator skipDescendents];
			}
		}
	}
}


- (NSArray *)tileShapesClasses
{
	return tileShapesClasses;
}


- (NSArray *)imageSourceClasses
{
	return imageSourceClasses;
}


@end
