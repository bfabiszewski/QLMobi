/** @file BAFHtml.h
 *
 * Copyright (c) 2015 Bartek Fabiszewski
 * http://www.fabiszewski.net
 *
 * This file is part of QLMobi.
 * Licensed under GPL, either version 3, or any later.
 * See <http://www.gnu.org/licenses/>
 */

#ifndef BAFHtml_h
#define BAFHtml_h

#import <Foundation/Foundation.h>
#import <libxml/HTMLparser.h>
#import <libxml/HTMLtree.h>
#import "BAFXpath.h"

/** Basic parsed html handler */
@interface BAFHtml : NSObject

/** HTML document */
@property(nonatomic, readonly) htmlDocPtr document;
/** document body tag */
@property(nonatomic, readonly) xmlNodePtr body;
/** document head tag */
@property(nonatomic, readonly) xmlNodePtr head;

/** Create empty document */
- (instancetype)initEmpty;
/** Create document from parsed data */
- (instancetype)initWithData:(const char *)data length:(NSUInteger)length;
/** Append element with given name and value to document head tag */
- (void)appendElementToHead:(NSString *)name withValue:(NSString *)value;
/** Append copy of the node (with children) to document body, optionally rename node to div */
- (void)appendCopyToBody:(xmlNodePtr)node asDiv:(BOOL)renameToDiv;
/** Run xpath query on document body, and return result object */
- (BAFXpath *)findNodesInBodyByXPath:(NSString *)xpath;
/** Get dumped document data */
- (NSData *)documentData;
/** Set node's name */
+ (void)node:(xmlNodePtr)node setName:(NSString *)name;
/** Set node's content */
+ (void)node:(xmlNodePtr)node setContent:(NSString *)content;
/** Unlink node */
+ (void)unlinkNode:(xmlNodePtr)node;
/** Is the node a namespace type? */
+ (BOOL)isNamespaceNode:(xmlNodePtr)node;

@end

#endif /* BAFHtml_h */