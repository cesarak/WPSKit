//
// UIImage+WPSKit.m
//
// Created by Kirby Turner.
// Copyright 2011-2014 White Peak Software. All rights reserved.
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

#import "UIImage+WPSKit.h"

@implementation UIImage (WPSKit)

#pragma mark - Sizes

- (CGSize)wps_suggestedSizeWithWidth:(CGFloat)width
{
  CGSize size = [self size];
  CGFloat ratio;
  if (size.width > width) {
    ratio = width / size.width;
  } else {
    ratio = size.width / width;
  }
  
  CGSize scaleToSize = CGSizeMake(ratio * size.width, ratio * size.height);
  return scaleToSize;
}

- (CGSize)wps_suggestedSizeWithHeight:(CGFloat)height
{
  CGSize size = [self size];
  CGFloat ratio;
  if (size.height > height) {
    ratio = height / size.height;
  } else {
    ratio = size.height / height;
  }
  
  CGSize scaleToSize = CGSizeMake(ratio * size.width, ratio * size.height);
  return scaleToSize;
}

- (CGSize)wps_suggestedSizeWithMaxDimension:(CGFloat)dimension
{
  CGSize scaleToSize;
  CGSize size = [self size];
  if (size.width > size.height) {
    scaleToSize = [self wps_suggestedSizeWithWidth:dimension];
  } else {
    scaleToSize = [self wps_suggestedSizeWithHeight:dimension];
  }
  return scaleToSize;
}

#pragma mark - Scaling

- (UIImage *)wps_scaleToSize:(CGSize)newSize 
{
   UIGraphicsBeginImageContextWithOptions(newSize, YES, 1.0f);
   CGRect rect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
   [self drawInRect:rect];
   UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
   UIGraphicsEndImageContext();
   return scaledImage;
}

- (UIImage *)wps_scaleAspectToMaxSize:(CGFloat)newSize
{
   CGSize scaleToSize = [self wps_suggestedSizeWithMaxDimension:newSize];
   return [self wps_scaleToSize:scaleToSize];
}

- (UIImage *)wps_scaleAspectFillToSize:(CGSize)newSize
{
   CGSize imageSize = [self size];
   CGFloat horizontalRatio = newSize.width / imageSize.width;
   CGFloat verticalRatio = newSize.height / imageSize.height;
   CGFloat ratio = MAX(horizontalRatio, verticalRatio);   

   CGSize scaleToSize = CGSizeMake(imageSize.width * ratio, imageSize.height * ratio);
   return [self wps_scaleToSize:scaleToSize];
}

- (UIImage *)wps_scaleAspectFitToSize:(CGSize)newSize
{
   CGSize imageSize = [self size];
   CGFloat horizontalRatio = newSize.width / imageSize.width;
   CGFloat verticalRatio = newSize.height / imageSize.height;
   CGFloat ratio = MIN(horizontalRatio, verticalRatio);   
   
   CGSize scaleToSize = CGSizeMake(imageSize.width * ratio, imageSize.height * ratio);
   return [self wps_scaleToSize:scaleToSize];
}

#pragma mark - Cropping

- (UIImage *)wps_cropToRect:(CGRect)cropRect
{
   CGRect cropRectIntegral = CGRectIntegral(cropRect);
   CGImageRef croppedImageRef = CGImageCreateWithImageInRect([self CGImage], cropRectIntegral);
   UIImage *croppedImage = [UIImage imageWithCGImage:croppedImageRef];
   CGImageRelease(croppedImageRef);
   
   return croppedImage;
}

- (UIImage *)wps_scaleAndCropToSize:(CGSize)newSize 
{
   UIImage *scaledImage = [self wps_scaleAspectFillToSize:newSize];
   
   // Crop the image to the requested new size maintaining
   // the inner most parts of the image.
   CGSize imageSize = [scaledImage size];
#if CGFLOAT_IS_DOUBLE
   CGFloat offsetX = round((imageSize.width / 2.0f) - (newSize.width / 2.0f));
   CGFloat offsetY = round((imageSize.height / 2.0f) - (newSize.height / 2.0f));
#else
  CGFloat offsetX = roundf((imageSize.width / 2.0f) - (newSize.width / 2.0f));
  CGFloat offsetY = roundf((imageSize.height / 2.0f) - (newSize.height / 2.0f));
#endif
  
   CGRect cropRect = CGRectMake(offsetX, offsetY, newSize.width, newSize.height);
   UIImage *croppedImage = [scaledImage wps_cropToRect:cropRect];
   return croppedImage;
}

#pragma mark - Square

- (UIImage *)wps_squareImage
{
  CGSize imageSize = [self size];
  CGFloat dimension = MIN(imageSize.width, imageSize.height);
  return [self wps_squareImageWithDimension:dimension];
}

- (UIImage *)wps_squareImageWithDimension:(CGFloat)dimension
{
  CGSize imageSize = [self size];
#if CGFLOAT_IS_DOUBLE
  CGFloat offsetX = round((imageSize.width / 2.0f) - (dimension / 2.0f));
  CGFloat offsetY = round((imageSize.height / 2.0f) - (dimension / 2.0f));
#else
  CGFloat offsetX = roundf((imageSize.width / 2.0f) - (dimension / 2.0f));
  CGFloat offsetY = roundf((imageSize.height / 2.0f) - (dimension / 2.0f));
#endif
  
  CGRect cropRect = CGRectMake(offsetX, offsetY, dimension, dimension);
  UIImage *squareImage = [self wps_cropToRect:cropRect];
  return squareImage;
}

#pragma mark - Rounded

- (UIImage *)wps_roundedImage
{
  UIImage *squareImage = [self wps_squareImage];
  CGSize imageSize = [squareImage size];
  return [squareImage wps_roundedImageWithCornerRadius:imageSize.width/2.0f];
}

- (UIImage *)wps_roundedImageWithDiameter:(CGFloat)diameter
{
  UIImage *squareImage = [self wps_squareImage];
  UIImage *scaledImage = [squareImage wps_scaleToSize:CGSizeMake(diameter, diameter)];
  CGSize imageSize = [scaledImage size];
  return [scaledImage wps_roundedImageWithCornerRadius:imageSize.width/2.0f];
}

- (UIImage *)wps_roundedImageWithCornerRadius:(CGFloat)cornerRadius
{
  CGSize imageSize = [self size];
  
  CALayer *imageLayer = [CALayer layer];
  [imageLayer setFrame:CGRectMake(0.0f, 0.0f, imageSize.width, imageSize.height)];
  [imageLayer setContents:(id)[self CGImage]];
  [imageLayer setMasksToBounds:YES];
  [imageLayer setCornerRadius:cornerRadius];
  
  UIGraphicsBeginImageContext(imageSize);
  [imageLayer renderInContext:UIGraphicsGetCurrentContext()];
  UIImage *roundedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return roundedImage;
}

#pragma mark - Colors

+ (UIImage *)wps_imageFromColor:(UIColor *)color
{
  return [self wps_imageFromColor:color size:CGSizeMake(1.0f, 1.0f)];
}

+ (UIImage *)wps_imageFromColor:(UIColor *)color size:(CGSize)size
{
  CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
  UIGraphicsBeginImageContext(rect.size);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSetFillColorWithColor(context, [color CGColor]);
  CGContextFillRect(context, rect);
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}

+ (UIImage *)wps_imageNamed:(NSString *)name withMaskColor:(UIColor *)color
{
  UIImage *image = [UIImage imageNamed:name];
  NSAssert(image, @"nil image. Check the image name.");
  CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
  UIGraphicsBeginImageContextWithOptions(rect.size, NO, image.scale);
  CGContextRef c = UIGraphicsGetCurrentContext();
  [image drawInRect:rect];
  CGContextSetFillColorWithColor(c, [color CGColor]);
  CGContextSetBlendMode(c, kCGBlendModeSourceAtop);
  CGContextFillRect(c, rect);
  UIImage *maskedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return maskedImage;
}

@end
