/** @file GenerateThumbnailForURL.m
 *
 * Copyright (c) 2015 Bartek Fabiszewski
 * http://www.fabiszewski.net
 *
 * This file is part of QLMobi.
 * Licensed under GPL, either version 3, or any later.
 * See <http://www.gnu.org/licenses/>
 */

#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h>
#import <QuickLook/QuickLook.h>
#import "BAFMobi.h"

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url,
                                 CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize) {
    @autoreleasepool {
        /** initialize mobi structure with contents of the url */
        BAFMobi *mobi = [[BAFMobi alloc] initWithURL:(__bridge NSURL *)url];
        /** get cover */
        NSData *data = [mobi coverData];
        if (data) {
            /** request thumbnail for the image data */
            QLThumbnailRequestSetImageWithData(thumbnail, (__bridge CFDataRef)(data), nil);
        }
        return noErr;
    }
}

void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail) {
}