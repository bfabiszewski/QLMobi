/** @file BAFMobiPart.h
 *
 * Copyright (c) 2015 Bartek Fabiszewski
 * http://www.fabiszewski.net
 *
 * This file is part of QLMobi.
 * Licensed under GPL, either version 3, or any later.
 * See <http://www.gnu.org/licenses/>
 */

#ifndef BAFMobiPart_h
#define BAFMobiPart_h

#import <mobi.h>

/**
 MobiPart represents a single parsed resource belonging to mobi document.
 It may be html part, image, font or other.
 Its corresponds to libmobi MOBIPart structure.
 */
@interface BAFMobiPart : NSObject

/** Wrapper for libmobi MOBIPart raw data. */
@property(readonly, nonatomic) NSData *data;
/** Resource mime type */
@property(readonly) NSString *mime;
/** Resource data size */
@property(readonly) NSUInteger size;
/** Resource raw data. */
@property(readonly, nonatomic) unsigned char *rawData;
/** Initialize with libmobi MOBIPart structure */
- (instancetype)initWithData:(MOBIPart *)part;
/** Is part HTML resource */
- (BOOL)isHTML;
/** Is part CSS resource */
- (BOOL)isCSS;
/** Is part PDF resource */
- (BOOL)isPDF;

@end

#endif /* BAFMobiPart_h */
