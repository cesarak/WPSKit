//
// WPSCache.m
//
// Created by Kirby Turner.
// Copyright 2011 White Peak Software. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
//  Disclaimer:
//    The following code is inspired by and derived from SDWebImage.
//    http://github.com/rs/SDWebImage
//

#import "WPSCache.h"
#import <CommonCrypto/CommonDigest.h>

@interface WPSCache ()
@property (nonatomic, strong) NSCache *memoryCache;
@property (nonatomic, strong) NSString *cachePath;
@property (nonatomic, copy) NSString *cacheName;
- (void)commonInit;
- (NSString *)pathExtensionWithKey:(NSString *)key;
- (NSString *)cachePathForKey:(NSString *)key;
- (void)persistData:(NSData *)data forKey:(NSString *)key withCacheAge:(NSInteger)cacheAge;
- (BOOL)isStalePath:(NSString *)path;
@end

@implementation WPSCache

@synthesize memoryCache = _memoryCache;
@synthesize cachePath = _cachePath;
@synthesize cacheName = _cacheName;

#pragma mark - Create and Init Methods

+ (instancetype)sharedCache
{
    static WPSCache *sharedCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCache = [[self alloc] init];
    });
    
    return sharedCache;
}

- (void)dealloc
{
   [self removeObservers];
}

- (void)commonInit
{
   // Initialize the memory cache.
   [self setMemoryCache:[[NSCache alloc] init]];
   
   // Initialize the disk cache.
   NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
   NSString *path = [paths[0] stringByAppendingPathComponent:[self cacheName]];
   [self setCachePath:path];
   
   NSFileManager *fileManager = [[NSFileManager alloc] init];
   if (![fileManager  fileExistsAtPath:path]) {
      NSError *error = nil;
      if (![fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error]) {
         NSDictionary *userInfo = @{NSUnderlyingErrorKey: error};
         NSException *exc = nil;
         NSString *reason = @"Cannot create cache directory.";
         exc = [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:userInfo];
         @throw exc;
      }
   }
   
   // Subscribe to application events.
   [self addObservers];
}

- (id)init
{
   self = [self initWithCacheName:@"WPSCache"];
   if (self) {
      
   }
   return self;
}

- (id)initWithCacheName:(NSString *)cacheName
{
   self = [super init];
   if (self) {
      [self setCacheName:cacheName];
      [self commonInit];
   }
   return self;
}

#pragma mark - Public Methods

- (void)cacheData:(NSData *)data forKey:(NSString *)key cacheLocation:(WPSCacheLocation)cacheLocation
{
   [self cacheData:data forKey:key cacheLocation:cacheLocation cacheAge:kWPSCacheMaxCacheAge];
}

- (void)cacheData:(NSData *)data forKey:(NSString *)key cacheLocation:(WPSCacheLocation)cacheLocation cacheAge:(NSInteger)cacheAge
{
   if (nil == data || nil == key) {
      return;
   }
   
   if ((cacheLocation & WPSCacheLocationMemory) == WPSCacheLocationMemory) {
      [[self memoryCache] setObject:data forKey:key];
   }
   
   if ((cacheLocation & WPSCacheLocationFileSystem) == WPSCacheLocationFileSystem) {
      [self persistData:data forKey:key withCacheAge:cacheAge];
   }
}

- (void)cacheFileAt:(NSURL *)location forKey:(NSString *)key
{
   [self cacheFileAt:location forKey:key cacheAge:kWPSCacheMaxCacheAge];
}

- (void)cacheFileAt:(NSURL *)location forKey:(NSString *)key cacheAge:(NSInteger)cacheAge
{
   if (location == nil || [location isFileURL] == NO || key == nil) {
      return;
   }
   
   NSString *path = [self cachePathForKey:key];
   
   NSError *error = nil;
   NSFileManager *fileManager = [[NSFileManager alloc] init];
   if ([fileManager copyItemAtPath:[location path] toPath:path error:&error] == NO) {
      NSLog(@"Failed to cache file. %@", [error localizedDescription]);
   } else {
      // The modified date is the expiration date for the cached item.
      NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:cacheAge];
      NSDictionary *modifiedDict = @{NSFileModificationDate: expirationDate};
      if ([fileManager setAttributes:modifiedDict ofItemAtPath:path error:&error] == NO) {
         NSLog(@"Failed to set file attributes. %@", [error localizedDescription]);
      }
   }
}

- (NSData *)dataForKey:(NSString *)key
{
   if (nil == key) {
      return nil;
   }
   
   NSData *data = [[self memoryCache] objectForKey:key];
   if (!data) {
      NSString *path = [self cachePathForKey:key];
      if ([self isStalePath:path] == NO) {
         data = [NSData dataWithContentsOfFile:path];
      }
   }
   
   return data;
}

- (NSURL *)fileURLForKey:(NSString *)key
{
   if (nil == key) {
      return nil;
   }
   
   NSString *path = [self cachePathForKey:key];
   NSURL *url = nil;
   NSFileManager *fileManager = [[NSFileManager alloc] init];
   if ([fileManager fileExistsAtPath:path]) {
      url = [NSURL fileURLWithPath:path];
   }
   return url;   
}

- (void)flushCache
{
   [self flushMemoryCache];
   [self flushFileSystemCache];
}

- (void)flushMemoryCache
{
   [[self memoryCache] removeAllObjects];
}

- (void)flushFileSystemCache
{
   NSFileManager *fileManager = [[NSFileManager alloc] init];
   [fileManager removeItemAtPath:[self cachePath] error:NULL];
   [fileManager createDirectoryAtPath:[self cachePath] withIntermediateDirectories:YES attributes:nil error:NULL];
}

- (void)cleanStaleCacheFromFileSystemWithCompletion:(void(^)())completion
{
   NSString *cachePath = [self cachePath];
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      NSDate *now = [NSDate date];
      NSFileManager *fileManager = [[NSFileManager alloc] init];
      NSDirectoryEnumerator *fileEnumerator = [fileManager enumeratorAtPath:cachePath];
      for (NSString *fileName in fileEnumerator) {
         NSString *filePath = [cachePath stringByAppendingPathComponent:fileName];
         NSDictionary *attrs = [fileManager attributesOfItemAtPath:filePath error:NULL];
         if ([[[attrs fileModificationDate] laterDate:now] isEqualToDate:now]) {
            [fileManager removeItemAtPath:filePath error:nil];
         }
      }
      
      if (completion) {
         dispatch_async(dispatch_get_main_queue(), ^{
            completion();
         });

      }
   });
}

#pragma mark - Notification Handlers

- (void)addObservers
{
   UIApplication *app = [UIApplication sharedApplication];
   NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
   [nc addObserver:self selector:@selector(willTerminate:) name:UIApplicationWillTerminateNotification object:app];
   [nc addObserver:self selector:@selector(willTerminate:) name:UIApplicationDidEnterBackgroundNotification object:app];
}

- (void)removeObservers
{
   UIApplication *app = [UIApplication sharedApplication];
   NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
   [nc removeObserver:self name:UIApplicationWillTerminateNotification object:app];
   [nc removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:app];
}

- (void)willTerminate:(NSNotification *)notification
{
   [self cleanStaleCacheFromFileSystemWithCompletion:nil];
}

#pragma mark - Private Methods

- (NSString *)pathExtensionWithKey:(NSString *)key
{
   NSString *pathExt = nil;
   NSArray *components = [key componentsSeparatedByString:@"?"];
   if ([components count] > 0) {
      pathExt = [components[0] pathExtension];
   }
   return pathExt;
}

- (NSString *)cachePathForKey:(NSString *)key
{
   NSString *pathExtension = [self pathExtensionWithKey:key];
   const char *str = [key UTF8String];
   unsigned char r[CC_MD5_DIGEST_LENGTH];
   CC_MD5(str, (CC_LONG)strlen(str), r);
   NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                         r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
   
   // The path extension is appended to the file name because some iOS
   // services such as the media player rely on the extension to determine
   // the file type.
   if (pathExtension) {
      filename = [filename stringByAppendingPathExtension:pathExtension];
   }
   
   return [[self cachePath] stringByAppendingPathComponent:filename];
}

- (void)persistData:(NSData *)data forKey:(NSString *)key withCacheAge:(NSInteger)cacheAge
{
   NSString *path = [self cachePathForKey:key];

   // The modified date is the expiration date for the cached item.
   NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:cacheAge];
   NSDictionary *modifiedDict = @{NSFileModificationDate: expirationDate};

   NSFileManager *fileManager = [[NSFileManager alloc] init];
   [fileManager createFileAtPath:path contents:data attributes:modifiedDict];
}

- (BOOL)isStalePath:(NSString *)path
{
   BOOL stale = NO;
   NSFileManager *fileManager = [[NSFileManager alloc] init];
   NSDate *now = [NSDate date];
   NSDictionary *attrs = [fileManager attributesOfItemAtPath:path error:NULL];
   if ([[[attrs fileModificationDate] laterDate:now] isEqualToDate:now]) { 
      [fileManager removeItemAtPath:path error:nil];
      stale = YES;
   }
   return stale;
}

@end
