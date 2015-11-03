/** @file BAFMobi.h
 *
 * Copyright (c) 2015 Bartek Fabiszewski
 * http://www.fabiszewski.net
 *
 * This file is part of QLMobi.
 * Licensed under GPL, either version 3, or any later.
 * See <http://www.gnu.org/licenses/>
 */

#ifndef BAFMobi_h
#define BAFMobi_h

/** kindle:embed:xxxx target length */
static const NSUInteger embedLinkLength = 4;

#import <Foundation/Foundation.h>
#import "BAFMobiPart.h"

typedef enum { SUCCESS, ERROR } Status;

/**
 Basic wrapper for libmobi
 */
@interface BAFMobi : NSObject

/** init with url */
- (instancetype)initWithURL:(NSURL *)url;
/** get resource (part) for given link target */
- (BAFMobiPart *)partForLink:(NSString *)link;
/** iterate markup parts and call block callback on each part */
- (void)enumerateMarkupUsingBlock:(void(^)(BAFMobiPart *curr, BOOL *stop))callback;
/** iterate flow parts and call block callback on each part */
- (void)enumerateFlowUsingBlock:(void(^)(BAFMobiPart *curr, BOOL *stop))callback;
/** get cover image data */
- (NSData *)coverData;
/** get title */
- (NSString *)title;
/** get author */
- (NSString *)author;
/** is document version greater than 8 */
- (BOOL)isKF8;

@end

#endif /* BAFMobi_h */
