/** @file BAFXpath.m
 *
 * Copyright (c) 2015 Bartek Fabiszewski
 * http://www.fabiszewski.net
 *
 * This file is part of QLMobi.
 * Licensed under GPL, either version 3, or any later.
 * See <http://www.gnu.org/licenses/>
 */

#import "BAFXpath.h"
#import "BAFHtml.h"

@interface BAFXpath()

@property(nonatomic, readonly) xmlNodeSetPtr nodeSet;
@property(nonatomic, readonly) xmlXPathObjectPtr xpathObject;
@property(nonatomic, readonly) xmlXPathContextPtr xpathContext;

- (xmlNodePtr)getNodeByIndex:(NSUInteger)index;
- (void)setNodeContent:(NSString *)content byIndex:(NSUInteger)index;

@end

@implementation BAFXpath

@synthesize nodeSet, xpathObject, xpathContext;

- (instancetype)init:(const xmlChar *)xpath withContext:(xmlNodePtr)context {
    if (context == nil) {
        return nil;
    }
    xpathContext = xmlXPathNewContext((xmlDocPtr)context);
    if (xpathContext == nil) {
        return nil;
    }
    xpathObject = xmlXPathEvalExpression(xpath, xpathContext);
    if (xpathObject == nil) {
        xmlXPathFreeContext(xpathContext);
        xpathContext = nil;
        return nil;
    }
    nodeSet = xpathObject->nodesetval;
    if (nodeSet == nil) {
        xmlXPathFreeObject(xpathObject);
        xpathObject = nil;
        xmlXPathFreeContext(xpathContext);
        xpathContext = nil;
        return nil;
    }
    self = [super init];
    return self;
}

- (void)dealloc {
    if (xpathObject) {
        xmlXPathFreeObject(xpathObject);
    }
    if (xpathContext) {
        xmlXPathFreeContext(xpathContext);
    }
}

- (NSUInteger)getNodesCount {
    return (nodeSet) ? nodeSet->nodeNr : 0;
}

- (xmlNodePtr)getNodeByIndex:(NSUInteger)index {
    if (nodeSet == nil || index > nodeSet->nodeNr - 1) {
        return nil;
    }
    return nodeSet->nodeTab[index];
}

- (NSString *)getNodeNameByIndex:(NSUInteger)index {
    NSString *name = @"";
    xmlNodePtr currentNode = [self getNodeByIndex:index];
    if (currentNode) {
        const xmlChar *cname = currentNode->name;
        if (cname) {
            name = [NSString stringWithUTF8String:(const char *)cname];
        }
    }
    return name;
}

- (NSString *)getNodeChildContentByIndex:(NSUInteger)index {
    NSString *content = @"";
    xmlNodePtr currentNode = [self getNodeByIndex:index];
    if (currentNode && currentNode->children) {
        const xmlChar *cname = currentNode->children->content;
        if (cname) {
            content = [NSString stringWithUTF8String:(const char *)cname];
        }
    }
    return content;
}

- (void)setNodeName:(NSString *)name byIndex:(NSUInteger)index {
    xmlNodePtr currentNode = [self getNodeByIndex:index];
    [BAFHtml node:currentNode setName:name];
}

- (void)setNodeContent:(NSString *)content byIndex:(NSUInteger)index {
    xmlNodePtr currentNode = [self getNodeByIndex:index];
    [BAFHtml node:currentNode setContent:content];
}

- (void)setNodeChildContent:(NSString *)content byIndex:(NSUInteger)index {
    xmlNodePtr currentNode = [self getNodeByIndex:index];
    [BAFHtml node:currentNode->children setContent:content];
}

- (void)unlinkNodeByIndex:(NSUInteger)index {
    xmlNodePtr currentNode = [self getNodeByIndex:index];
    [BAFHtml unlinkNode:currentNode];
}

- (BOOL)isNamespaceNodeByIndex:(NSUInteger)index {
    xmlNodePtr currentNode = [self getNodeByIndex:index];
    return [BAFHtml isNamespaceNode:currentNode];
}

@end
