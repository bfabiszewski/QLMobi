/** @file BAFXpath.h
 *
 * Copyright (c) 2015 Bartek Fabiszewski
 * http://www.fabiszewski.net
 *
 * This file is part of QLMobi.
 * Licensed under GPL, either version 3, or any later.
 * See <http://www.gnu.org/licenses/>
 */

#ifndef BAFXpath_h
#define BAFXpath_h

#import <Foundation/Foundation.h>
#import <libxml/xpath.h>

/** Xpath query result object */
@interface BAFXpath : NSObject

/** Init with xpath pattern and given node context */
- (instancetype)init:(const xmlChar *)xpath withContext:(xmlNodePtr)context;
/** Get nodes count in the resultset */
- (NSUInteger)getNodesCount;
/** Get name of the node with given index in the resultset */
- (NSString *)getNodeNameByIndex:(NSUInteger)index;
/** Get content of the node with given index in the resultset */
- (NSString *)getNodeChildContentByIndex:(NSUInteger)index;
/** Modify name of the node with given index in the resultset */
- (void)setNodeName:(NSString *)name byIndex:(NSUInteger)index;
/** Modify content of the node with given index in the resultset */
- (void)setNodeChildContent:(NSString *)content byIndex:(NSUInteger)index;
/** Unlink node from the resultset */
- (void)unlinkNodeByIndex:(NSUInteger)index;
/** Is node with given index a namespace type? */
- (BOOL)isNamespaceNodeByIndex:(NSUInteger)index;
@end

#endif /* BAFXpath_h */
