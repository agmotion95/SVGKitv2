#import <Foundation/Foundation.h>

#import "SVGElement.h"
#import "SVGTransformable.h"
#import "SVGFitToViewBox.h"
#import "SVGElement_ForParser.h"
#import "ConverterSVGToCALayer.h"

/** Pattern coordinate system constants */
typedef NS_ENUM(NSInteger, SVGPatternUnits) {
    SVGPatternUnitsUserSpaceOnUse    = 0,
    SVGPatternUnitsObjectBoundingBox = 1,
};

@interface SVGPatternElement : SVGElement <SVGTransformable, SVGStylable, SVGFitToViewBox, ConverterSVGToCALayer>

@property (nonatomic, readonly) CGFloat x;
@property (nonatomic, readonly) CGFloat y;
@property (nonatomic, readonly) CGFloat width;
@property (nonatomic, readonly) CGFloat height;

@property (nonatomic, readonly) SVGPatternUnits patternUnits;
@property (nonatomic, readonly) SVGPatternUnits patternContentUnits;

@property (nonatomic, strong, readonly) NSString *href;

/**
 Renders all ConverterSVGToCALayer child elements of the <pattern> into a single
 CGImage of the given pixel size.  Caller must release via CGImageRelease().
*/
- (CGImageRef)renderChildrenIntoCGImageOfSize:(CGSize)size CF_RETURNS_RETAINED;

@end
