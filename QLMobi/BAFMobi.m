/** @file BAFMobi.m
 *
 * Copyright (c) 2015 Bartek Fabiszewski
 * http://www.fabiszewski.net
 *
 * This file is part of QLMobi.
 * Licensed under GPL, either version 3, or any later.
 * See <http://www.gnu.org/licenses/>
 */

#import <Foundation/Foundation.h>
#import <libxml/HTMLparser.h>
#import <libxml/HTMLtree.h>
#import <mobi.h>
#import "BAFMobi.h"
#import "debug.h"

/**
 Basic wrapper for libmobi
 */
@interface BAFMobi()

/** MOBIData */
@property(readonly, nonatomic) MOBIData *mData;
/** MOBIRawml */
@property(readonly, nonatomic) MOBIRawml *mRawml;

- (void)load:(NSURL *)url;
- (void)parse;
- (BAFMobiPart *)partForFlowLink:(NSString *)link;
- (BAFMobiPart *)partForResourceLink:(NSString *)link;
- (BAFMobiPart *)partForResourceLinkKF7:(NSString *)link;
- (BAFMobiPart *)partForCover;
- (void)enumeratePartsWithRoot:(MOBIPart *)root usingBlock:(void(^)(BAFMobiPart *curr, BOOL *stop))callback;
+ (NSString *)mimeByPartType:(MOBIFiletype)type;
@end

@implementation BAFMobi

@synthesize mData, mRawml;

- (instancetype)init {
    DebugLog(@"Mobi init");
    self = [super init];
    if (self) {
        DebugLog(@"mobi_init()");
        mData = mobi_init();
        if (mData == nil) {
            DebugLog(@"Memory allocation failed");
            return nil;
        }
        mRawml = nil;
    }
    return self;
}

- (void)dealloc {
    DebugLog(@"Mobi dealloc");
    if (mData) {
        DebugLog(@"mobi_free(mData)");
        mobi_free(mData);
    }
    if (mRawml) {
        DebugLog(@"mobi_free(mRawml)");
        mobi_free_rawml(mRawml);
    }
}

- (instancetype)initWithURL:(NSURL *)url andParse:(BOOL)withParse {
    self = [self init];
    if (self) {
        [self load:(NSURL *)(url)];
        if (withParse) {
            [self parse];
        }
        if (mData == nil) {
            return nil;
        }
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)url {
    return [self initWithURL:url andParse:NO];
}

- (void)load:(NSURL *)url {
    DebugLog(@"Loading file %@ (%@)", [url path], [NSThread currentThread]);
    // open file
    FILE *file = fopen([[url path] UTF8String], "rb");
    if (file == NULL) {
        DebugLog(@"Error opening file %@", [url path]);
        mobi_free(mData);
        mData = nil;
    }
    // load file into mobi structure
    MOBI_RET mobi_ret = mobi_load_file(mData, file);
    fclose(file);
    if (mobi_ret != MOBI_SUCCESS) {
        DebugLog(@"Error loading file (%u)", mobi_ret);
        mobi_free(mData);
        mData = nil;
    }
}

- (void)parse {
    if (mData == nil) {
        return;
    }
    DebugLog(@"mobi_init_rawml()");
    mRawml = mobi_init_rawml(mData);
    if (mRawml == nil) {
        DebugLog(@"Memory allocation failed");
        return;
    }
    // parse mobi data into rawml structure
    MOBI_RET mobi_ret = mobi_parse_rawml_opt(mRawml, mData, NO, NO, NO);
    if (mobi_ret != MOBI_SUCCESS) {
        DebugLog(@"Error parsing file (%u)", mobi_ret);
        mobi_free(mData);
        mobi_free_rawml(mRawml);
        mData = nil;
        mRawml = nil;
    }
}

- (BOOL)isKF8
{
    if (mData) {
        if (mobi_is_kf8(mData)) {
            return YES;
        }
    }
    return NO;
}

- (BAFMobiPart *)partForLink:(NSString *)link;
{
    if ([link hasPrefix:@"kindle:flow:"]) {
        return [self partForFlowLink:link];
    } else if ([link hasPrefix:@"kindle:embed:"]) {
        return [self partForResourceLink:link];
    } else if ([link hasPrefix:@"recindex:"]) {
        return [self partForResourceLinkKF7:link];
    } else {
        return nil;
    }
}

- (BAFMobiPart *)partForFlowLink:(NSString *)link;
{
    if (mRawml->markup == nil) {
        return nil;
    }
    
    NSString *prefix = @"kindle:flow:";
    if (link.length >= (prefix.length + embedLinkLength) && [link hasPrefix:prefix]) {
        NSRange needleRange = NSMakeRange(prefix.length, embedLinkLength);
        NSString *flowId = [link substringWithRange:needleRange];
        MOBIPart *flow = mobi_get_flow_by_fid(mRawml, [flowId UTF8String]);
        BAFMobiPart *part = [[BAFMobiPart alloc] initWithData:flow];
        return part;
    }
    return nil;
}

- (BAFMobiPart *)partForResourceLink:(NSString *)link;
{
    if (mRawml->resources == nil) {
        return nil;
    }
    
    NSString *prefix = @"kindle:embed:";
    if (link.length >= (prefix.length + embedLinkLength) && [link hasPrefix:prefix]) {
        NSRange needleRange = NSMakeRange(prefix.length, embedLinkLength);
        NSString *flowId = [link substringWithRange:needleRange];
        MOBIPart *flow = mobi_get_resource_by_fid(mRawml, [flowId UTF8String]);
        BAFMobiPart *part = [[BAFMobiPart alloc] initWithData:flow];
        return part;
    }
    return nil;
}

- (BAFMobiPart *)partForResourceLinkKF7:(NSString *)link;
{
    if (mRawml->resources == nil) {
        return nil;
    }
    
    NSString *prefix = @"recindex:";
    if (link.length >= (prefix.length + 1) && [link hasPrefix:prefix]) {
        NSString *flowId = [link substringFromIndex:prefix.length];
        NSInteger uid = [flowId intValue];
        if (uid > 0) {
            uid--;
        }
        MOBIPart *flow = mobi_get_resource_by_uid(mRawml, uid);
        BAFMobiPart *part = [[BAFMobiPart alloc] initWithData:flow];
        return part;
    }
    return nil;
}

- (BAFMobiPart *)partForCover;
{
    if (!mData || !mRawml) {
        return nil;
    }
    BAFMobiPart *part = nil;
    MOBIPart *resource = nil;
    MOBIExthHeader *exth = mobi_get_exthrecord_by_tag(mData, EXTH_COVEROFFSET);
    if (exth) {
        NSUInteger offset = mobi_decode_exthvalue(exth->data, exth->size);
        resource = mobi_get_resource_by_uid(mRawml, offset);
    }
    if (!resource) {
        if (mobi_exists_mobiheader(mData)) {
            if (mData->mh->image_index && *mData->mh->image_index != MOBI_NOTSET) {
                NSUInteger offset = *mData->mh->image_index;
                resource = mobi_get_resource_by_uid(mRawml, offset);
            }
        }
    }
    if (resource) {
        part = [[BAFMobiPart alloc] initWithData:resource];
    }
    return part;
}

- (NSData *)dataForCover;
{
    if (!mData) {
        return nil;
    }
    NSData *data = nil;
    MOBIPdbRecord *record = nil;
    MOBIExthHeader *exth = mobi_get_exthrecord_by_tag(mData, EXTH_COVEROFFSET);
    if (exth) {
        NSUInteger offset = mobi_decode_exthvalue(exth->data, exth->size);
        NSUInteger first_resource = mobi_get_first_resource_record(mData);
        NSUInteger uid = first_resource + offset;
        record = mobi_get_record_by_seqnumber(mData, uid);
    }
    if (record) {
        data = [NSData dataWithBytesNoCopy:record->data
                                    length:record->size
                              freeWhenDone:NO];
    }
    return data;
}


- (void)enumerateMarkupUsingBlock:(void(^)(BAFMobiPart *curr, BOOL *stop))callback
{
    [self enumeratePartsWithRoot:mRawml->markup usingBlock:callback ];
}

- (void)enumerateFlowUsingBlock:(void(^)(BAFMobiPart *curr, BOOL *stop))callback
{
    [self enumeratePartsWithRoot:mRawml->flow->next usingBlock:callback];
}

- (void)enumeratePartsWithRoot:(MOBIPart *)root usingBlock:(void(^)(BAFMobiPart *curr, BOOL *stop))callback
{
    if (root == nil) {
        return;
    }
    MOBIPart *curr = root;
    while (curr != nil) {
        @autoreleasepool {
            BOOL stop = NO;
            BAFMobiPart *part = [[BAFMobiPart alloc] initWithData:curr];
            callback(part, &stop);
            if (stop){ break; }
            curr = curr->next;
        }
    }
}

- (NSData *)coverData {
    return [self dataForCover];
}

- (NSString *)title {
    NSString *title = nil;
    if (mobi_exists_mobiheader(mData)) {
        if (mData->mh->full_name_offset && mData->mh->full_name_length) {
            size_t len = *mData->mh->full_name_length;
            char cTitle[len + 1];
            if (mobi_get_fullname(mData, cTitle, len) == MOBI_SUCCESS &&
                strlen(cTitle)) {
                title = [[NSString alloc] initWithUTF8String:cTitle];
            }
        }
    }
    return title;
}

- (NSString *)author {
    NSString *author = nil;
    MOBIExthHeader *exth = mobi_get_exthrecord_by_tag(mData, EXTH_COVEROFFSET);
    if (exth) {
        char *cAuthor = mobi_decode_exthstring(mData, exth->data, exth->size);
        if (cAuthor) {
            author = [[NSString alloc] initWithUTF8String:cAuthor];
            free(cAuthor);
        }
    }
    return author;
}

+ (NSString *)mimeByPartType:(MOBIFiletype)type {
    MOBIFileMeta meta = mobi_get_filemeta_by_type(type);
    return [NSString stringWithUTF8String:(const char *)meta.mime_type];
}

@end