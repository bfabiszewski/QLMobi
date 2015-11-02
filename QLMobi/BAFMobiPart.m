/** @file BAFMobiPart.m
 *
 * Copyright (c) 2015 Bartek Fabiszewski
 * http://www.fabiszewski.net
 *
 * This file is part of QLMobi.
 * Licensed under GPL, either version 3, or any later.
 * See <http://www.gnu.org/licenses/>
 */

#import <Foundation/Foundation.h>
#import <mobi.h>
#import "BAFMobiPart.h"

/**
 MobiPart represents a single parsed resource belonging to mobi document.
 It may be html part, image, font or other.
 Its corresponds to libmobi MOBIPart structure.
 */
@interface BAFMobiPart()


@property(readonly) MOBIFiletype type;
@property(readonly) MOBIPart *next;



@end

@implementation BAFMobiPart

@synthesize data, mime, size, next, rawData;

- (instancetype)initWithData:(MOBIPart *)part {
    if (part == nil) {
        return nil;
    }
    self = [super init];
    if (self) {
        data = [NSData dataWithBytesNoCopy:part->data
                                    length:part->size
                              freeWhenDone:NO];
        MOBIFileMeta meta = mobi_get_filemeta_by_type(part->type);
        mime = [NSString stringWithUTF8String:(const char *)meta.mime_type];
        size = part->size;
        next = part->next;
        rawData = part->data;
        _type = part->type;
    }
    return self;
}

- (BOOL)isHTML
{
    return (self.type == T_HTML);
}
- (BOOL)isCSS
{
    return (self.type == T_CSS);
}
- (BOOL)isPDF
{
    return (self.type == T_PDF);
}

@end