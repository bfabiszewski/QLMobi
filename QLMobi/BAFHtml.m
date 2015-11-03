/** @file BAFHtml.m
 *
 * Copyright (c) 2015 Bartek Fabiszewski
 * http://www.fabiszewski.net
 *
 * This file is part of QLMobi.
 * Licensed under GPL, either version 3, or any later.
 * See <http://www.gnu.org/licenses/>
 */

#import "BAFHtml.h"
#import "debug.h"

static volatile int32_t instancesCount = 0;

@interface BAFHtml()

- (void)addLinkToHead:(NSString *)target withMime:(NSString *)mime;
- (BAFXpath *)findNodesByXPath:(const xmlChar *)xpath withContext:(xmlNodePtr)context;
- (void)bodyNodeSetName:(NSString *)name;
- (void)dumpDocumentToLog;

@end

@implementation BAFHtml

@synthesize document, body, head;

- (instancetype)init {
    DebugLog(@"HTML init (%li)", (long)instancesCount);
    self = [super init];
    if (self) {
        static dispatch_once_t once;
        OSAtomicIncrement32(&instancesCount);
        dispatch_once(&once, ^{
            DebugLog(@"xmlInitParser()");
            xmlInitParser();
            LIBXML_TEST_VERSION
        });
    }
    return self;
}

- (instancetype)initEmpty {
    self = [self init];
    if (self) {
        document = htmlNewDoc(NULL, NULL);
        if (!document) {
            return nil;
        }
        xmlNodePtr html = xmlNewNode(NULL, BAD_CAST "html");
        xmlDocSetRootElement(document, html);
        head = xmlNewNode(NULL, BAD_CAST "head");
        xmlAddChild(html, head);
        body = xmlNewNode(NULL, BAD_CAST "body");
        xmlAddChild(html, body);
        xmlNodePtr meta = xmlNewNode(NULL, BAD_CAST "meta");
        xmlAddChild(head, meta);
        xmlNewProp(meta, BAD_CAST "http-equiv", BAD_CAST "content-type");
        xmlNewProp(meta, BAD_CAST "content", BAD_CAST "text/html; charset=utf-8");
    }
    return self;
}

- (instancetype)initWithData:(const char *)data length:(NSUInteger)length;
{
    self = [self init];
    if (self) {
        document = htmlReadMemory(data, (int)length, nil, "utf-8",
                                  HTML_PARSE_RECOVER | HTML_PARSE_NOERROR |
                                  HTML_PARSE_NOWARNING);
        if (!document) {
            return nil;
        }
        xmlNodePtr root = xmlDocGetRootElement(document);
        body = [self findFirstElementByName:BAD_CAST "body" withContext:root];
    }
    return self;
}

- (void)dealloc {
    DebugLog(@"HTML dealloc (%li)", (long)instancesCount - 1);
    /* Free the document */
    if (document) {
        DebugLog(@"xmlFreeDoc()");
        xmlFreeDoc(document);
    }
    OSAtomicDecrement32(&instancesCount);
    if (instancesCount == 0) {
        DebugLog(@"xmlCleanupParser()");
        xmlCleanupParser();
    }
}

- (void)appendElementToHead:(NSString *)name withValue:(NSString *)value {
    xmlNodePtr newNode = xmlNewNode(NULL, BAD_CAST[name UTF8String]);
    xmlNodeAddContent(newNode, BAD_CAST[value UTF8String]);
    xmlAddChild(head, newNode);
}

- (void)addLinkToHead:(NSString *)target withMime:(NSString *)mime {
    xmlNodePtr link = xmlNewNode(NULL, BAD_CAST "link");
    xmlSetProp(link, BAD_CAST "type", BAD_CAST[mime UTF8String]);
    xmlSetProp(link, BAD_CAST "href", BAD_CAST[target UTF8String]);
    xmlAddChild(head, link);
}

- (void)appendCopyToBody:(xmlNodePtr)node asDiv:(BOOL)renameToDiv {
    if (body) {
        xmlNodePtr copy = xmlCopyNode(node, 1);
        if (renameToDiv) {
            xmlNodeSetName(copy, BAD_CAST "div");
        }
        if (copy) {
            xmlAddChild(body, copy);
        }
    }
}

- (xmlNodePtr)findFirstElementByName:(xmlChar *)name
                         withContext:(xmlNodePtr)context {
    xmlNode *cur_node = nil;
    
    for (cur_node = context; cur_node; cur_node = cur_node->next) {
        if (cur_node->type == XML_ELEMENT_NODE &&
            xmlStrcasecmp(cur_node->name, name) == 0) {
            return cur_node;
        }
        xmlNodePtr found =
        [self findFirstElementByName:name withContext:cur_node->children];
        if (found) {
            return found;
        }
    }
    return nil;
}

- (BAFXpath *)findNodesByXPath:(const xmlChar *)xpath withContext:(xmlNodePtr)context {
    if (!context) {
        context = xmlDocGetRootElement(document);
    }
    return [[BAFXpath alloc] init:xpath withContext:context];
}

- (BAFXpath *)findNodesInBodyByXPath:(NSString *)xpath {
    return [self findNodesByXPath:BAD_CAST[xpath UTF8String] withContext:body];
}

- (void)bodyNodeSetName:(NSString *)name {
    if (body) {
        [BAFHtml node:body setName:name];
    }
}

- (void)dumpDocumentToLog {
#if defined(MOBI_DEBUG)
    xmlBufferPtr buffer = xmlBufferCreate();
    int bufSize = htmlNodeDump(buffer, document, body);
    DebugLog(@"Document size: %i", bufSize);
    DebugLog(@"Document content: %s", buffer->content);
#endif
}

- (NSData *)documentData {
    NSData *htmlData = nil;
    xmlChar *buffer = nil;
    int bufferSize = 0;
    htmlDocDumpMemory(document, &buffer, &bufferSize);
    if (buffer) {
        htmlData =
        [NSData dataWithBytesNoCopy:buffer length:bufferSize freeWhenDone:YES];
    }
    return htmlData;
}

+ (void)node:(xmlNodePtr)node setName:(NSString *)name {
    if (node) {
        xmlNodeSetName(node, BAD_CAST[name UTF8String]);
    }
}

+ (void)node:(xmlNodePtr)node setContent:(NSString *)content {
    if (node) {
        xmlNodeSetContent(node, BAD_CAST[content UTF8String]);
    }
}

+ (void)unlinkNode:(xmlNodePtr)node {
    node = nil;
}

+ (BOOL)isNamespaceNode:(xmlNodePtr)node {
    return (node) ? (node->type == XML_NAMESPACE_DECL) : NO;
}

@end