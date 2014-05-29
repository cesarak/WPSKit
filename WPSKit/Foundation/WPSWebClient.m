//
// WPSWebClient.m
//
// Created by Kirby Turner.
// Copyright 2012 White Peak Software. All rights reserved.
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

#import "WPSWebClient.h"
#import "UIApplication+WPSKit.h"
#import "NSString+WPSKit.h"


/**
 HTTPError function provided by 0xced.
 https://github.com/0xced/CLURLConnection
 */
NSString *const kWPSHTTPErrorDomain = @"HTTPErrorDomain";
NSString *const kWPSHTTPBody = @"HTTPBody";

static inline NSError* httpError(NSURL *responseURL, NSInteger httpStatusCode, NSData *httpBody)
{
   NSString *httpBodyString = [NSString wps_stringWithData:httpBody encoding:NSUTF8StringEncoding];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                             responseURL, NSURLErrorKey,
                             responseURL, @"NSErrorFailingURLKey",
                             [responseURL absoluteString], @"NSErrorFailingURLStringKey",
                             [NSHTTPURLResponse localizedStringForStatusCode:httpStatusCode], NSLocalizedDescriptionKey,
                             [NSNumber numberWithInteger:httpStatusCode], @"HTTPStatusCode",
                             httpBodyString, kWPSHTTPBody, nil];
   
	return [NSError errorWithDomain:kWPSHTTPErrorDomain code:httpStatusCode userInfo:userInfo];
}

@interface WPSWebClient ()
@property (nonatomic, copy) WPSWebClientCompletionBlock completion;
@property (nonatomic, strong) NSMutableData *receivedData;
@property (nonatomic, strong) NSString *cacheKey;
@property (nonatomic, assign) NSInteger HTTPStatusCode;
@property (nonatomic, strong) NSURL *responseURL;
@property (nonatomic, assign) NSInteger numberOfAttempts;
@property (nonatomic, strong) NSURLRequest *request;
- (void)startConnection;
- (void)incrementNumberOfAttempts;
- (NSString *)cacheKeyForURL:(NSURL *)URL parameters:(NSDictionary *)parameters;
- (NSData *)cachedDataForURL:(NSURL *)URL parameters:(NSDictionary *)parameters;
@end

@implementation WPSWebClient

@synthesize cache = _cache;
@synthesize cacheAge = _cacheAge;
@synthesize completion = _completion;
@synthesize receivedData = _receivedData;
@synthesize cacheKey = _cacheKey;
@synthesize HTTPStatusCode = _HTTPStatusCode;
@synthesize responseURL = _responseURL;
@synthesize retryCount = _retryCount;
@synthesize numberOfAttempts = _numberOfAttempts;
@synthesize request = _request;
@synthesize additionalHTTPHeaderFields = _additionalHTTPHeaderFields;

- (id)init
{
   self = [super init];
   if (self) {
      [self setRetryCount:5];
      [self setCacheAge:300];   // 5 minutes
   }
   return self;
}

static NSString * URLEncodedStringFromStringWithEncoding(NSString *string, NSStringEncoding encoding)
{
   static NSString * const kTMLegalCharactersToBeEscaped = @"?!@#$^&%*+,:;='\"`<>()[]{}/\\|~ ";
   
   CFStringRef encodedStringRef = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, NULL, (__bridge CFStringRef)kTMLegalCharactersToBeEscaped, CFStringConvertNSStringEncodingToEncoding(encoding));
   NSString *encodedString = (__bridge_transfer NSString *)encodedStringRef;
   // Note: Do not need to call CFRelease(encodedStringRef). This is done
   // for us by using __bridge_transfer.
   return [encodedString copy];
}

- (NSString *)encodeQueryStringWithParameters:(NSDictionary *)parameters encoding:(NSStringEncoding)encoding
{
   if (parameters == nil) return nil;
   
   NSMutableArray *mutableParameterComponents = [NSMutableArray array];
   for (id key in [parameters allKeys]) {
      id value = [parameters valueForKey:key];
      if ([value isKindOfClass:[NSArray class]] == NO) {
         NSString *component = [NSString stringWithFormat:@"%@=%@",
                                URLEncodedStringFromStringWithEncoding([key description], encoding),
                                URLEncodedStringFromStringWithEncoding([[parameters valueForKey:key] description], encoding)];
         [mutableParameterComponents addObject:component];
      } else {
         for (id item in value) {
            NSString *component = [NSString stringWithFormat:@"%@[]=%@",
                                   URLEncodedStringFromStringWithEncoding([key description], encoding),
                                   URLEncodedStringFromStringWithEncoding([item description], encoding)];
            [mutableParameterComponents addObject:component];
         }
      }
   }
   NSString *queryString = [mutableParameterComponents componentsJoinedByString:@"&"];
   return queryString;
}

- (NSData *)postDataWithParameters:(NSDictionary *)parameters
{
   NSStringEncoding stringEncoding = NSUTF8StringEncoding;
   NSString *string = [self encodeQueryStringWithParameters:parameters encoding:stringEncoding];
   NSData *data = [string dataUsingEncoding:stringEncoding allowLossyConversion:YES];
   return data;
}

- (void)post:(NSURL *)URL HTTPmethod:(NSString *)HTTPMethod parameters:(NSDictionary *)parameters completion:(WPSWebClientCompletionBlock)completion
{
  NSDictionary *header = @{@"content-type":@"application/x-www-form-urlencoded"};
  NSData *postData = [self postDataWithParameters:parameters];
  [self post:URL HTTPmethod:HTTPMethod HTTPHeaders:header data:postData completion:completion];
}

- (void)post:(NSURL *)URL HTTPmethod:(NSString *)HTTPMethod HTTPHeaders:(NSDictionary *)headerFields data:(NSData *)postData completion:(WPSWebClientCompletionBlock)completion
{
  [self setCompletion:completion];
  [self setNumberOfAttempts:0];
  
  NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
  
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
  [request setHTTPMethod:HTTPMethod];
  if ([self additionalHTTPHeaderFields]) {
    [[self additionalHTTPHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
      [request setValue:value forHTTPHeaderField:key];
    }];
  }
  if (headerFields) {
    [headerFields enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
      [request setValue:value forHTTPHeaderField:key];
    }];
  }
  
  [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
  [request setHTTPBody:postData];
  [self setRequest:request];
  
  [self startConnection];
}


- (void)startConnection
{
   if ([self request]) {
      [self setReceivedData:[[NSMutableData alloc] init]];
      
      NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:[self request] delegate:self startImmediately:NO];
      [connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
      [connection start];
      [[UIApplication sharedApplication] wps_pushNetworkActivity];
      [self incrementNumberOfAttempts];
   }
}

- (void)incrementNumberOfAttempts
{
   NSInteger numberOfAttempts = [self numberOfAttempts];
   [self setNumberOfAttempts:numberOfAttempts + 1];
}

#pragma mark - Public Methods

- (void)post:(NSURL *)URL parameters:(NSDictionary *)parameters completion:(WPSWebClientCompletionBlock)completion
{
   [self post:URL HTTPmethod:@"POST" parameters:parameters completion:completion];
}

- (void)post:(NSURL *)URL contentType:(NSString *)contentType data:(NSData *)data completion:(WPSWebClientCompletionBlock)completion
{
  NSDictionary *header = @{@"content-type":contentType};
  [self post:URL HTTPmethod:@"POST" HTTPHeaders:header data:data completion:completion];
}

- (void)put:(NSURL *)URL parameters:(NSDictionary *)parameters completion:(WPSWebClientCompletionBlock)completion
{
   [self post:URL HTTPmethod:@"PUT" parameters:parameters completion:completion];
}

- (void)get:(NSURL *)URL parameters:(NSDictionary *)parameters completion:(WPSWebClientCompletionBlock)completion
{
   NSData *cachedData = [self cachedDataForURL:URL parameters:parameters];
   if (cachedData) {
      completion(URL, cachedData, YES, [self cacheKey], nil);
      return;
   }
   
   [self setCompletion:completion];
   [self setNumberOfAttempts:0];
   
   NSMutableURLRequest *request = [self getRequestWithURL:URL parameters:parameters];
   [self setRequest:request];
   
   [self startConnection];
}

- (NSMutableURLRequest *)getRequestWithURL:(NSURL *)URL parameters:(NSDictionary *)parameters
{
  NSString *queryString = [self encodeQueryStringWithParameters:parameters encoding:NSUTF8StringEncoding];
  // Add the queryString to the URL. Be sure to append either ? or & if
  // ? is not already present.
  NSURL *getURL = URL;
  if (queryString) {
    NSString *path = [URL absoluteString];
    NSUInteger location = [path rangeOfString:@"?"].location;
    NSString *stringFormat = location == NSNotFound ? @"?%@" : @"&%@";
    NSString *getURLString = [path stringByAppendingFormat:stringFormat, queryString];
    getURL = [NSURL URLWithString:getURLString];
  }
  
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:getURL];
  [request setHTTPMethod: @"GET"];
  if ([self additionalHTTPHeaderFields]) {
    [[self additionalHTTPHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
      [request setValue:value forHTTPHeaderField:key];
    }];
  }
  
  return request;
}

#pragma mark - Caching

- (NSString *)cacheKeyForURL:(NSURL *)URL parameters:(NSDictionary *)parameters
{
   NSString *path = [URL absoluteString];
   NSString *queryString = [self encodeQueryStringWithParameters:parameters encoding:NSUTF8StringEncoding];
   // Add the queryString to the URL. Be sure to append either ? or & if
   // ? is not already present.
   if (queryString) {
      NSUInteger location = [path rangeOfString:@"?"].location;
      NSString *stringFormat = location == NSNotFound ? @"?%@" : @"&%@";
      path = [path stringByAppendingFormat:stringFormat, queryString];
   }
   return path;
}

- (NSData *)cachedDataForURL:(NSURL *)URL parameters:(NSDictionary *)parameters
{
   NSString *cacheKey = [self cacheKeyForURL:URL parameters:parameters];
   [self setCacheKey:cacheKey];
   NSData *cachedData = [[self cache] dataForKey:cacheKey];
   return cachedData;
}

#pragma mark - NSURLConnection delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
   [[self receivedData] setLength:0];
   
   [self setResponseURL:[response URL]];
   
   NSInteger statusCode = 0;
   if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
      statusCode = [(NSHTTPURLResponse *)response statusCode];
   }
   [self setHTTPStatusCode:statusCode];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
   [[self receivedData] appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
   [[UIApplication sharedApplication] wps_popNetworkActivity];
   
   WPSWebClientCompletionBlock completion = [self completion];
   
   if ([self HTTPStatusCode] < 500) {
      if ([self cache]) {
         [[self cache] cacheData:[self receivedData] forKey:[self cacheKey] cacheLocation:WPSCacheLocationFileSystem cacheAge:[self cacheAge]];
      }
      
      completion([self responseURL], [self receivedData], NO, [self cacheKey], nil);
      
   } else {
      NSError *error = httpError([self responseURL], [self HTTPStatusCode], [self receivedData]);
      completion(nil, nil, NO, nil, error);
   }
   
   [self setReceivedData:nil];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
   [[UIApplication sharedApplication] wps_popNetworkActivity];
   [self setReceivedData:nil];
   
   if ([self numberOfAttempts] < [self retryCount]) {
      [self performSelector:@selector(startConnection) withObject:nil afterDelay:1.0];
   } else {
      WPSWebClientCompletionBlock completion = [self completion];
      completion(nil, nil, NO, nil, error);
   }
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
   BOOL canAuthenticate = NO;
   if (self.canAuthenticateBlock) {
      canAuthenticate = self.canAuthenticateBlock(protectionSpace);
   } else if ([self defaultCredential]) {
      canAuthenticate = YES;
   }
   return canAuthenticate;
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
   if (self.didReceiveAuthenticationChallengeBlock) {
      self.didReceiveAuthenticationChallengeBlock(challenge);
   } else if ([self defaultCredential]) {
      if ([challenge previousFailureCount] > 0) {
         WPSWebClientCompletionBlock completion = [self completion];
         if (completion) {
            NSURLResponse *response = [challenge failureResponse];
            NSInteger statusCode = 0;
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
               statusCode = [(NSHTTPURLResponse *)response statusCode];
            }
            
            if (statusCode >= 400) {
               [[UIApplication sharedApplication] wps_popNetworkActivity];
               NSError *error = httpError([response URL], statusCode, nil);
               completion(nil, nil, NO, nil, error);
            }
         }
         
      } else {
         [[challenge sender] useCredential:[self defaultCredential] forAuthenticationChallenge:challenge];
      }
   }
}

@end

