//
// WPSKit
// NSURL+WPSKit.m
//
// Created by Kirby Turner.
// Copyright 2013 White Peak Software. All rights reserved.
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

#import "NSURL+WPSKit.h"

@implementation NSURL (WPSKit)

- (NSDictionary *)wps_queryDictionary
{
  return [[self class] wps_queryDictionaryWithString:[self query]];
}

+ (NSDictionary *)wps_queryDictionaryWithString:(NSString *)queryString
{
   /**
    The following code is derived from the SSToolKit (under MIT).
    https://github.com/samsoffes/sstoolkit
    */
   
   if (!queryString) {
      return nil;
   }
   
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	NSArray *pairs = [queryString componentsSeparatedByString:@"&"];
   
	for (NSString *kvp in pairs) {
		if ([kvp length] == 0) {
			continue;
		}
      
		NSRange pos = [kvp rangeOfString:@"="];
		NSString *key;
		NSString *val;
      
		if (pos.location == NSNotFound) {
			key = [[self class] _stringByUnescapingFromURLQuery:kvp];
			val = @"";
		} else {
			key = [[self class] _stringByUnescapingFromURLQuery:[kvp substringToIndex:pos.location]];
			val = [[self class] _stringByUnescapingFromURLQuery:[kvp substringFromIndex:pos.location + pos.length]];
		}
      
		if (!key || !val) {
			continue; // I'm sure this will bite my arse one day
		}
      
		result[key] = val;
	}
	return result;
}

- (BOOL)wps_isEqualToURL:(NSURL *)URL
{
   BOOL isEqual = NO;
   if ([[self scheme] isEqualToString:[URL scheme]] && [[self host] isEqualToString:[URL host]]) {
      NSString *path = [self _pathWithDefault:@"/"];
      NSString *compareToPath = [URL _pathWithDefault:@"/"];
      if ([path isEqualToString:compareToPath]) {
         NSNumber *port = [self _portWithDefault:@80];
         NSNumber *compareToPort = [URL _portWithDefault:@80];
         if ([port isEqualToNumber:compareToPort]) {
            isEqual = YES;
         }
      }
   }
   return isEqual;
}

- (NSString *)_pathWithDefault:(NSString *)defaultPath
{
   NSString *path = [self path];
   if (path == nil || [path length] == 0) {
      path = @"/";
   }
   return path;
}

- (NSNumber *)_portWithDefault:(NSNumber *)defaultPort
{
   NSNumber *port = [self port];
   if (!port) {
      port = defaultPort;
   }
   return port;
}

#pragma mark - URL Escaping and Unescaping

+ (NSString *)_stringByUnescapingFromURLQuery:(NSString *)string
{
  NSString *deplussed = [string stringByReplacingOccurrencesOfString:@"+" withString:@" "];
  return [deplussed stringByRemovingPercentEncoding];
}

#pragma mark - Creators

+ (NSURL *)wps_HTTPURLWithString:(NSString *)URLString secure:(BOOL)secure
{
   NSURL *URL = [NSURL URLWithString:URLString];
   if (URL == nil) {
      URLString = [URLString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
      URL = [NSURL URLWithString:URLString];
   }
   NSString *scheme = [[URL scheme] lowercaseString];
   if ([scheme length] < 1 || ([scheme isEqual:@"http"] == NO && [scheme isEqual:@"https"] == NO)) {
      if (secure) {
         URLString = [NSString stringWithFormat:@"https://%@", URLString];
      } else {
         URLString = [NSString stringWithFormat:@"http://%@", URLString];
      }
      URL = [NSURL URLWithString:URLString];
   }
   return URL;
}

@end
