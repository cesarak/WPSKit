/**
 **   NSStringTests
 **
 **   Created by Kirby Turner.
 **   Copyright 2011 White Peak Software. All rights reserved.
 **
 **   Permission is hereby granted, free of charge, to any person obtaining 
 **   a copy of this software and associated documentation files (the 
 **   "Software"), to deal in the Software without restriction, including 
 **   without limitation the rights to use, copy, modify, merge, publish, 
 **   distribute, sublicense, and/or sell copies of the Software, and to permit 
 **   persons to whom the Software is furnished to do so, subject to the 
 **   following conditions:
 **
 **   The above copyright notice and this permission notice shall be included 
 **   in all copies or substantial portions of the Software.
 **
 **   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
 **   OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
 **   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
 **   IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
 **   CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
 **   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
 **   SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 **
 **/

#import "NSStringTests.h"
#import "NSString+WPSKit.h"

@implementation NSStringTests

- (void)testStringWithData
{
   NSString *stringToMatch = @"This is a test.";
   NSData *data = [stringToMatch dataUsingEncoding:NSUTF8StringEncoding];
   NSString *resultString = [NSString wps_stringWithData:data];
   XCTAssertTrue([resultString isEqualToString:stringToMatch], @"String values do not match.");
}

- (void)testStringWithUUID
{
   NSString *uuid = [NSString wps_stringWithUUID];
   XCTAssertNotNil(uuid, @"Unexpected nil value.");
   XCTAssertTrue([uuid length] > 0, @"Unexpected zero-length string.");
}

- (void)testIsURL
{
   NSString *string = @"http://thecave.com";
   XCTAssertTrue([string wps_isURL], @"'%@' is not a URL.'", string);
   
   string = @"thecave.com";
   XCTAssertTrue([string wps_isURL], @"'%@' is not a URL.'", string);

   string = @"THis is most certainly not a URL.";
   XCTAssertFalse([string wps_isURL], @"'%@' is not a URL.'", string);
}

- (void)testStringContainsSubstring
{
   NSString *string = @"The rain in Spain falls mainly on the plains.";
   NSString *substring = @"Spain";
   XCTAssertTrue([string wps_containsSubstring:substring], @"Substring not found.");
}

- (void)testStringDoesNotContainSubstring
{
   NSString *string = @"The rain in Spain falls mainly on the plains.";
   NSString *substring = @"Sprain";
   XCTAssertFalse([string wps_containsSubstring:substring], @"Substring found unexpectedly.");
}

- (void)testURLEncodedString
{
   NSString *encodedString = [@"The rain & Spain." wps_URLEncodedStringWithEncoding:NSUTF8StringEncoding];
   XCTAssertTrue([encodedString isEqualToString:@"The%20rain%20%26%20Spain."], @"Unexcepted URL encoded string value.");
}

- (void)testEmptyStringIfNil
{
   NSString *string = nil;
   NSString *emtpyString = wps_emptyStringIfNil(string);
   XCTAssertNotNil(emtpyString, @"A nil string value was returned.");
   XCTAssertTrue([emtpyString isEqualToString:@""], @"Unexcepted string value.");
}

- (void)testEmptyStringIfNilWhenNotNil
{
   NSString *string = @"chicken lips";
   NSString *emtpyString = [NSString wps_emptyStringIfNil:string];
   XCTAssertNotNil(emtpyString, @"A nil string value was returned.");
   XCTAssertTrue([emtpyString isEqualToString:string], @"Unexcepted string value.");
}

@end
