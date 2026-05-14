//
//  SVGKParserPatternsAndGradients.m
//  SVGKit
//
//  Created by adam applecansuckmybigtodger on 28/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVGKParserPatternsAndGradients.h"

#import "SVGSVGElement.h"
#import "SVGCircleElement.h"
#import "SVGDefsElement.h"
#import "SVGDescriptionElement.h"
//#import "SVGKSource.h"
#import "SVGEllipseElement.h"
#import "SVGImageElement.h"
#import "SVGLineElement.h"
#import "SVGPathElement.h"
#import "SVGPolygonElement.h"
#import "SVGPolylineElement.h"
#import "SVGRectElement.h"
#import "SVGTitleElement.h"
#import "SVGPatternElement.h"

@implementation SVGKParserPatternsAndGradients


-(NSArray*) supportedNamespaces
{
	return [NSArray arrayWithObjects:
			@"http://www.w3.org/2000/svg",
			nil];
}

/** "tags supported" is exactly the set of all SVGElement subclasses that already exist */
-(NSArray*) supportedTags
{
	return [NSMutableArray arrayWithObjects:@"pattern", nil];
}

- (Node*)handleStartElement:(NSString *)name document:(SVGKSource*) document namePrefix:(NSString*)prefix namespaceURI:(NSString*) XMLNSURI attributes:(NSMutableDictionary *)attributes parseResult:(SVGKParseResult*) parseResult parentNode:(Node*) parentNode
{
    if (![[self supportedNamespaces] containsObject:XMLNSURI])
        return nil;

    if ([name isEqualToString:@"pattern"]) {
        NSString *qualifiedName = (prefix == nil) ? name : [NSString stringWithFormat:@"%@:%@", prefix, name];
        SVGPatternElement *element = [[SVGPatternElement alloc] initWithQualifiedName:qualifiedName
                                                                        inNameSpaceURI:XMLNSURI
                                                                            attributes:attributes];
        [element postProcessAttributesAddingErrorsTo:parseResult];
        return element;
    }

    return nil;
}

-(void)handleEndElement:(Node *)newNode document:(SVGKSource *)document parseResult:(SVGKParseResult *)parseResult
{
	
}

@end
