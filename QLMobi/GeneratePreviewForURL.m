/** @file GeneratePreviewForURL.m
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
#import "BAFHtml.h"
#import "debug.h"

/** max size of parsed html */
static const NSUInteger maxSize = (1024 * 1024);

/** Replace links to resources in html part with cid scheme and add resources as attachments */
Status processHTML(BAFMobi *mobi, BAFHtml *partHTML, NSMutableDictionary *attachments, QLPreviewRequestRef preview) {
    if (!partHTML) {
        return ERROR;
    }
    NSString *pattern;
    if ([mobi isKF8] == YES) {
        /** for kf8 mobi document get all links with src attribute and "kindle" target */
//        pattern = @"//*[name(.) != 'a']/@href[starts-with(., 'kindle:')]"
//                  @"|//@src[starts-with(., 'kindle:')]";
        pattern = @"//@src[starts-with(., 'kindle:')]";
    } else {
        /** for older documents find all recindex attributes with numeric target */
        pattern = @"//@recindex";
    }
    /** get xpath query result */
    BAFXpath *result = [partHTML findNodesInBodyByXPath:pattern];
    NSUInteger size = [result getNodesCount];
    /** iterate result set in reverse order in order to modify nodes */
    for (NSInteger i = size - 1; i >= 0; i--) {
        @autoreleasepool {
            NSString *linkAttribute = [result getNodeNameByIndex:i];
            NSString *linkTarget = [result getNodeChildContentByIndex:i];
            if ([linkAttribute isEqualToString:@"recindex"]) {
                /** replace mobi recindex attribute with valid html src attribute */
                NSString *prefix = @"recindex:";
                linkTarget = [prefix stringByAppendingString:linkTarget];
                [result setNodeName:@"src" byIndex:i];
            }
            /** get resource from mobi document for given link target */
            BAFMobiPart *media = [mobi partForLink:linkTarget];
            if (!media) {
                /** skip if resource is missing */
                continue;
            }
            NSString *mime = media.mime;
            NSData *data = media.data;
            /** prepend link target with cid scheme */
            NSString *stringValue = [NSString stringWithFormat:@"cid:%@", linkTarget];
            /** modify link target */
            [result setNodeChildContent:stringValue byIndex:i];
            /** add linked resource as attachment */
            NSDictionary *attachment = @{(__bridge NSString *)kQLPreviewPropertyMIMETypeKey : mime,
                                         (__bridge NSString *)kQLPreviewPropertyAttachmentDataKey : data};
            attachments[linkTarget] = attachment;
            
            if (QLPreviewRequestIsCancelled(preview)) {
                /** exit loop if preview request was cancelled */
                return ERROR;
            }
            if (![result isNamespaceNodeByIndex:i]) {
                /** Elements returned by an xpath query are pointers to
                    elements from the tree *except* namespace nodes.
                    Unlink modified node from result set to avoid access to freed data.
                 */
                [result unlinkNodeByIndex:i];
            }
        }
    }
    return SUCCESS;
}

/** Replace links to resources in css part with cid scheme and add resources as attachments */
NSString *processCSS(BAFMobi *mobi, NSData *css, NSMutableDictionary *attachments, QLPreviewRequestRef preview) {
    if (!css) {
        return nil;
    }
    /** get css part as string */
    NSString *str = [[NSMutableString alloc] initWithData:css encoding:NSUTF8StringEncoding];
    if (!str) {
        return nil;
    }
    /** find all "kindle:embed" links in the css */
    NSUInteger length = str.length;
    NSRange range = NSMakeRange(0, length);
    NSString *targetAttr = @"kindle:embed:";
    NSString *pattern = [NSString stringWithFormat:@"%@(....)(?:\\?mime=\\w+/\\w+)?", targetAttr];
    /** initialize new string to hold modified document */
    NSMutableString *modifiedString = [[NSMutableString alloc] initWithCapacity:str.length];
    NSUInteger lastPosition = 0;
    /** iterate found occurences */
    while (range.location != NSNotFound) {
        @autoreleasepool {
            range = [str rangeOfString:pattern options:NSRegularExpressionSearch range:range];
            if (range.location != NSNotFound) {
                if (range.location + embedLinkLength < str.length) {
                    NSRange targetRange = NSMakeRange(range.location, targetAttr.length + embedLinkLength);
                    NSString *linkTarget = [str substringWithRange:targetRange];
                    /** get resource part for given link target */
                    BAFMobiPart *media = [mobi partForLink:linkTarget];
                    if (media) {
                        /** add linked resource part as attachment */
                        NSString *mime = media.mime;
                        NSData *data = media.data;
                        NSDictionary *attachment = @{(__bridge NSString *)kQLPreviewPropertyMIMETypeKey : mime,
                                                     (__bridge NSString *)kQLPreviewPropertyAttachmentDataKey : data};
                        attachments[linkTarget] = attachment;
                    }
                    
                    if (QLPreviewRequestIsCancelled(preview)) {
                        /** exit loop if preview request was cancelled */
                        return nil;
                    }
                    /** copy substring (from end of the last found link to beginning of the current one) to new css */
                    [modifiedString appendString:[str substringWithRange:NSMakeRange(lastPosition,
                                                                                     range.location - lastPosition)]];
                    /** prepend link target with cid scheme and append to new css */
                    [modifiedString appendFormat:@"cid:%@", linkTarget];
                    lastPosition = range.location + range.length;
                }
                range = NSMakeRange(range.location + range.length, length - (range.location + range.length));
            }
        }
    }
    /** copy remaining part of the original css string */
    [modifiedString appendString:[str substringWithRange:NSMakeRange(lastPosition, length - lastPosition)]];
    return modifiedString;
}

/** generate preview */
OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview,
                               CFURLRef url, CFStringRef contentTypeUTI,
                               CFDictionaryRef options) {
    DebugLog(@"Starting QLMobi Preview Generator: %@", [NSThread currentThread]);
#ifdef MOBI_DEBUG
    NSDate *startTime = [NSDate date];
#endif
    /** initialze mobi structure with url */
    BAFMobi *mobi = [[BAFMobi alloc] initWithURL:(__bridge NSURL *)url];
    if (!mobi) {
        return noErr;
    }
    /** initialize empty html document, which will hold parsed and concatenated html parts */
    BAFHtml *document = [[BAFHtml alloc] initEmpty];
    /** initialize dictionary container for attached resources, like images, fonts etc */
    NSMutableDictionary *attachments = [NSMutableDictionary dictionary];
    __block NSUInteger size = 0;
    __block NSData *pdf = nil;
    /** iterate main markup parts of the mobi document, usually html, also pdf */
    [mobi enumerateMarkupUsingBlock:^(BAFMobiPart *currentPart, BOOL *stop) {
        if ([currentPart isHTML]) {
            NSUInteger partSize = ((size + currentPart.size) < maxSize) ? currentPart.size : (maxSize - size);
            /** parse html part */
            BAFHtml *partHTML = [[BAFHtml alloc] initWithData:(char *)currentPart.rawData length:partSize];
            /** process links in parsed html */
            Status status = processHTML(mobi, partHTML, attachments, preview);
            if (status == SUCCESS) {
                /** append body of the parsed html (renamed as div) to new document */
                [document appendCopyToBody:partHTML.body asDiv:YES];

                size += partSize;
                /** exit loop if parsed html size is over quota */
                if (size > maxSize) {
                    *stop = YES;
                    return;
                }
            }
        } else if ([currentPart isPDF]) {
            /** in case of pdf, extrace pdf part and exit loop */
            pdf = [NSData dataWithBytesNoCopy:currentPart.rawData length:currentPart.size freeWhenDone:NO];
            *stop = YES;
            return;
        }
        /** exit loop if preview request was cancelled */
        if (QLPreviewRequestIsCancelled(preview)) {
            *stop = YES;
            return;
        }
    }];

    if (pdf) {
        /** set request for pdf data */
        QLPreviewRequestSetDataRepresentation(preview, (__bridge CFDataRef)(pdf), kUTTypePDF, nil);
    } else {
        /** iterate supplementary text parts, mostly css */
        [mobi enumerateFlowUsingBlock:^(BAFMobiPart *currentPart, BOOL *stop) {
            NSData *data = [NSData dataWithBytesNoCopy:currentPart.rawData length:currentPart.size freeWhenDone:NO];
            if ([currentPart isCSS]) {
                /* process links */
                NSString *css = processCSS(mobi, data, attachments, preview);
                if (css.length) {
                    /** and inline css into <style> element inside <head> node */
                    [document appendElementToHead:@"style" withValue:css];
                }
            }
            /** exit loop if preview request was cancelled */
            if (QLPreviewRequestIsCancelled(preview)) {
                *stop = YES;
                return;
            }
        }];
        /** add some custom styles */
        NSString *customCss = @"body { padding: 20px 5% !important; } \n"
                              @"img { max-width: 95% !important; }";
        [document appendElementToHead:@"style" withValue:customCss];
        if ([mobi isKF8] == NO) {
            /** avoid images distorsion in old documents format */
            customCss = @"img { height: auto !important; width: auto !important; }";
            [document appendElementToHead:@"style" withValue:customCss];
        }
        /** get new html data */
        NSData *htmlData = [document documentData];
        /** and attachments */
        NSMutableDictionary *properties = [NSMutableDictionary dictionary];
        properties[(__bridge NSString *)kQLPreviewPropertyMIMETypeKey] = @"text/html";
        properties[(__bridge NSString *)kQLPreviewPropertyTextEncodingNameKey] = @"UTF-8";
        properties[(__bridge NSString *)kQLPreviewPropertyAttachmentsKey] = attachments;
        /** get mobi document title */
        NSString *title = [mobi title];
        if (title) {
            properties[(__bridge NSString *)kQLPreviewPropertyDisplayNameKey] = title;
        }
        /** set multipart html document for preview */
        QLPreviewRequestSetDataRepresentation(preview, (__bridge CFDataRef)(htmlData), kUTTypeHTML,
                                              (__bridge CFDictionaryRef)(properties));
    }
#ifdef MOBI_DEBUG
    NSDate *endTime = [NSDate date];
    NSTimeInterval executionTime = [endTime timeIntervalSinceDate:startTime];
    DebugLog(@"execution time: %f sec", executionTime);
#endif
    return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview) {
}