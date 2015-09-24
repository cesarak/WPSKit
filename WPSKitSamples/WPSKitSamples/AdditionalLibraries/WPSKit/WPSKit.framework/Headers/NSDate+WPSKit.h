//
// WPSKit
// NSDate+WPSKit.h
//
// Created by Kirby Turner.
// Copyright 2015 White Peak Software. All rights reserved.
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

@interface NSDate (WPSKit)

/**
 Returns an `NSDate` representing today starting at midnight.
 
 @return An `NSDate`.
 */
+ (NSDate *)wps_todayAtMidnight;

/**
 Returns an `NSDate` representing the date starting at midnight.
 
 @return An `NSDate`.
 */
- (NSDate *)wps_dateAtMidnight;

/**
 Returns an `NSDate` with the hour, minute, and second set to the provided values.
 
 @param hour The hour.
 @param minute The minute.
 @param second The second.
 @return An `NSDate`.
 */
- (NSDate *)wps_dateWithHour:(NSInteger)hour minute:(NSInteger)minute second:(NSInteger)second;

@end
