#include "Neon.h"
#include <sys/utsname.h>

NSArray *themes;
NSDictionary *prefs;
NSCache *pathsCache;

@implementation Neon

+ (NSArray *)themes {
  return themes;
}

+ (NSDictionary *)prefs {
  return prefs;
}

// why all this hustle yeah cuz we can't use UIScreen for the scale before SpringBoard fully loads cuz it crashes

CFPropertyListRef MGCopyAnswer(CFStringRef property);

+ (NSNumber *)deviceScale {
  return (__bridge NSNumber *)MGCopyAnswer(CFSTR("main-screen-scale"));
}

+ (NSString *)deviceScaleString {
  int scale = [[Neon deviceScale] intValue];
  if (scale == 2) return @"@2x";
  else if (scale == 3) return @"3x";
  return @"";
}

// Usage: fullPathForImageNamed:@"SBBadgeBG" atPath:@"/Library/Themes/Viola Badges.theme/Bundles/com.apple.springboard/" (last symbol of basePath should be a slash (/)!)
+ (NSString *)fullPathForImageNamed:(NSString *)name atPath:(NSString *)basePath {
  if (!name || !basePath) return nil;
	NSMutableArray *potentialFilenames = [[NSMutableArray alloc] init];
  [potentialFilenames addObject:[name stringByAppendingString:@"-large.png"]];
  NSString *device = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) ? @"~ipad" : @"~iphone";
  NSString *scale = [Neon deviceScaleString];
  [potentialFilenames addObject:[NSString stringWithFormat:@"%@%@.png", name, scale]];
  [potentialFilenames addObject:[NSString stringWithFormat:@"%@%@.png", name, device]];
  [potentialFilenames addObject:[NSString stringWithFormat:@"%@%@%@.png", name, device, scale]];
  [potentialFilenames addObject:[NSString stringWithFormat:@"%@%@%@.png", name, scale, device]];
  // THEMERS STUPID AND FORGET TO ADD 2X IMAGES SO WE GOTTA PROBABLY RESIZE 3X EVEN THO THATS STUPID AS SHIT!!!!!
  if ([[Neon deviceScale] intValue] > 1) {
    scale = @"@3x";
    [potentialFilenames addObject:[NSString stringWithFormat:@"%@%@.png", name, scale]];
    [potentialFilenames addObject:[NSString stringWithFormat:@"%@%@.png", name, device]];
    [potentialFilenames addObject:[NSString stringWithFormat:@"%@%@%@.png", name, device, scale]];
    [potentialFilenames addObject:[NSString stringWithFormat:@"%@%@%@.png", name, scale, device]];
  }
  for (NSString *filename in potentialFilenames) {
    NSString *fullFilename = [basePath stringByAppendingString:filename];
    if ([[NSFileManager defaultManager] fileExistsAtPath:fullFilename isDirectory:nil]) return fullFilename;
  }
	return nil;
}

+ (NSString *)iconPathForBundleID:(NSString *)bundleID {
  if (!bundleID) return nil;
  NSString *cachedPath = [pathsCache objectForKey:bundleID];
  if (cachedPath) return ([cachedPath isEqualToString:@""]) ? nil : cachedPath;
  for (NSString *theme in themes) {
    NSString *path = [Neon iconPathForBundleID:bundleID fromTheme:theme];
    if (path && [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) {
      [pathsCache setObject:path forKey:bundleID];
      return path;
    }
  }
  [pathsCache setObject:@"" forKey:bundleID];
  return nil;
}

// Usage: iconPathForBundleID:@"com.saurik.Cydia" fromTheme:@"Viola"
+ (NSString *)iconPathForBundleID:(NSString *)bundleID fromTheme:(NSString *)theme {
  // Protection against dumbasses (me)
  if (!bundleID || !theme) return nil;
  // Check if theme dir exists
  NSString *themeDir = [NSString stringWithFormat:@"/Library/Themes/%@/IconBundles/", theme];
  if (![[NSFileManager defaultManager] fileExistsAtPath:themeDir isDirectory:nil]) return nil;
	// Return filename (or nil)
  NSString *path = [Neon fullPathForImageNamed:bundleID atPath:themeDir];
  if (!path && [bundleID isEqualToString:@"com.apple.mobiletimer"]) {
    themeDir = [NSString stringWithFormat:@"/Library/Themes/%@/Bundles/com.apple.springboard/", theme];
    path = [Neon fullPathForImageNamed:@"ClockIconBackgroundSquare" atPath:themeDir];
  }
  return path;
}

@end

%ctor {
  prefs = [NSDictionary dictionaryWithContentsOfURL:[NSURL fileURLWithPath:@"/var/mobile/Library/Preferences/com.artikus.neonboardprefs.plist"] error:nil];
  if (!prefs) return;
  pathsCache = [NSCache new];
  NSMutableArray *mutableThemes = [[prefs valueForKey:@"enabledThemes"] mutableCopy] ? : [NSMutableArray new];
  for (int i = mutableThemes.count - 1; i >= 0; i--) {
    NSString *path = [NSString stringWithFormat:@"/Library/Themes/%@/IconBundles", [mutableThemes objectAtIndex:i]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) [mutableThemes removeObjectAtIndex:i];
  }
  if (mutableThemes.count > 0) themes = [mutableThemes copy];
}
