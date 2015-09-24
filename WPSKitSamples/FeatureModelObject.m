//
//  FeatureModelObject.m
//  WPSKitSamples
//
//  Created by Kirby Turner on 2/16/12.
//  Copyright (c) 2012 White Peak Software Inc. All rights reserved.
//

#import "FeatureModelObject.h"

NSString * const kWPSFeatureKeyTitle = @"title";
NSString * const kWPSFeatureKeyItems = @"items";
NSString * const kWPSFeatureKeyViewControllerClassName = @"viewControllerClassName";


@implementation FeatureModelObject

+ (NSArray *)features
{
   NSString *rootViewControllerClassName = @"RootViewController";
   
   NSArray *tableViewItems = @[@{kWPSFeatureKeyTitle:@"Customizations",
                                 kWPSFeatureKeyItems:@[
                                       @{kWPSFeatureKeyTitle:@"Custom Detail Disclosure Button",
                                         kWPSFeatureKeyItems:@[],
                                         kWPSFeatureKeyViewControllerClassName:@"CustomDetailDisclosureButtonViewController"}
                                       ]}];
   
   NSArray *uiKitItems = [NSArray arrayWithObjects:
                          [NSDictionary dictionaryWithObjectsAndKeys:@"UIApplication+WPSKit", kWPSFeatureKeyTitle, [NSArray array], kWPSFeatureKeyItems, rootViewControllerClassName, kWPSFeatureKeyViewControllerClassName, nil],
                          [NSDictionary dictionaryWithObjectsAndKeys:@"UIColor+WPSKit", kWPSFeatureKeyTitle, [NSArray array], kWPSFeatureKeyItems, rootViewControllerClassName, kWPSFeatureKeyViewControllerClassName, nil],
                          [NSDictionary dictionaryWithObjectsAndKeys:@"WPSTextView", kWPSFeatureKeyTitle, [NSArray array], kWPSFeatureKeyItems, @"TextViewViewController", kWPSFeatureKeyViewControllerClassName, nil],
                          @{kWPSFeatureKeyTitle:@"UITableView", kWPSFeatureKeyItems:tableViewItems, kWPSFeatureKeyViewControllerClassName:@"TableViewViewController"},
                          nil];
   
   NSArray *foundationItems = [NSArray arrayWithObjects:
                               [NSDictionary dictionaryWithObjectsAndKeys:@"NSString+WPSKit", kWPSFeatureKeyTitle, [NSArray array], kWPSFeatureKeyItems, rootViewControllerClassName, kWPSFeatureKeyViewControllerClassName, nil],
                               [NSDictionary dictionaryWithObjectsAndKeys:@"WPSWebClient", kWPSFeatureKeyTitle, [NSArray array], kWPSFeatureKeyItems, @"WebClientViewController", kWPSFeatureKeyViewControllerClassName, nil],
                               nil];
   
   NSArray *data = [NSArray arrayWithObjects:
                    [NSDictionary dictionaryWithObjectsAndKeys:@"Core Data", kWPSFeatureKeyTitle, [NSArray array], kWPSFeatureKeyItems, nil],
                    [NSDictionary dictionaryWithObjectsAndKeys:@"Core Location", kWPSFeatureKeyTitle, [NSArray array], kWPSFeatureKeyItems, nil],
                    [NSDictionary dictionaryWithObjectsAndKeys:@"Foundation", kWPSFeatureKeyTitle, foundationItems, kWPSFeatureKeyItems, nil],
                    [NSDictionary dictionaryWithObjectsAndKeys:@"MapKit", kWPSFeatureKeyTitle, [NSArray array], kWPSFeatureKeyItems, nil],
                    [NSDictionary dictionaryWithObjectsAndKeys:@"UIKit", kWPSFeatureKeyTitle, uiKitItems, kWPSFeatureKeyItems, nil],
                    nil];
   return data;
}

@end
