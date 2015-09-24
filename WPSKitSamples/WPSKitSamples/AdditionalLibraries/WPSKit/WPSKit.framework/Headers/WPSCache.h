//
// WPSCache.h
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

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, WPSCacheLocation) {
   WPSCacheLocationMemory = 1,
   WPSCacheLocationFileSystem
};

#define kWPSCacheMaxCacheAge 60*60*24*7 // 1 week
#define kWPSCacheOneDayCacheAge 60*60*24 // 1 day

@protocol WPSCache <NSObject>
@optional

/**
 Creates a new instance with the given cacheName.
 The cache name is used as part of the path to the file system where cached
 items are stored. 
 
 Note: init() uses the default cacheName value WPSCache.
 */
- (id)initWithCacheName:(NSString *)cacheName;

/**
 Caches the data for the key to the location.
 The cache age defaults to kWPSCacheMaxCacheAge for items cached to the
 file system.
 */
- (void)cacheData:(NSData *)data forKey:(NSString *)key cacheLocation:(WPSCacheLocation)cacheLocation;

/**
 Caches the data for the key to the location for the cache age.
 The cache age only applies to items cached to the file system.
 */
- (void)cacheData:(NSData *)data forKey:(NSString *)key cacheLocation:(WPSCacheLocation)cacheLocation cacheAge:(NSInteger)cacheAge;

/**
 Caches the file at the provided location using the provided key.

 Note that the file is cached for the maximum cache age as defined by `kWPSCacheMaxCacheAge`.
 
 @param location The location of the file to cache. This is a file URL.
 @param key The key used to identify this cache item.
 */
- (void)cacheFileAt:(NSURL *)location forKey:(NSString *)key;

/**
 Caches the file at the provided location using the provided key.
 
 @param location The location of the file to cache. This is a file URL.
 @param key The key used to identify this cache item.
 @param cacheAge The time in seconds the file will remain in the cache before being flushed.
 */
- (void)cacheFileAt:(NSURL *)location forKey:(NSString *)key cacheAge:(NSInteger)cacheAge;

/**
 Returns the data found in the cache for the key.
 */
- (NSData *)dataForKey:(NSString *)key;

/**
 Returns the file URL to the cached data for the key.
 nil is returned if the cached item is in memory only.
 */
- (NSURL *)fileURLForKey:(NSString *)key;

/**
 Flushes both the memory and file system caches.
 */
- (void)flushCache;

/**
 Flushes the memory cache.
 */
- (void)flushMemoryCache;

/**
 Flushes the file system cache.
 */
- (void)flushFileSystemCache;

/**
 Removes all stale cache items from the file system.
 You do not have to call this method directly. It is called for you
 when the app is terminated or enters the background.
 */
- (void)cleanStaleCacheFromFileSystemWithCompletion:(void(^)())completion;

@end


@interface WPSCache : NSObject <WPSCache>

+ (instancetype)sharedCache;

@end

