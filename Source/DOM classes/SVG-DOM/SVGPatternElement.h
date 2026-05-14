/**
 SVGPatternElement.h
 SVGKit

 Implements the SVG <pattern> element as defined in:
 https://www.w3.org/TR/SVG11/patternsAndGradients.html#PatternElement

 A <pattern> defines a tiled graphic that can be used as a fill or stroke on
 other shapes.  The most common real-world use is an <image> child inside the
 pattern, making the image appear as a raster fill.

 This class stores the pattern's geometry attributes.  The actual CALayer
 rendering of the pattern's contents is driven by SVGKImage newLayerWithElement:.
*/

#import "SVGElement.h"
#import "SVGTransformable.h"
#import "SVGFitToViewBox.h"
#import "SVGElement_ForParser.h"

/** Pattern coordinate system constants (mirrors SVGUnitTypes) */
typedef NS_ENUM(NSInteger, SVGPatternUnits) {
    SVGPatternUnitsUserSpaceOnUse   = 0,   ///< x/y/width/height are in the current user coordinate system
    SVGPatternUnitsObjectBoundingBox = 1,  ///< x/y/width/height are fractions of the referencing element's bounding box
};

@interface SVGPatternElement : SVGElement <SVGTransformable, SVGStylable, SVGFitToViewBox, ConverterSVGToCALayer>

/** Pattern placement and tile size in the coordinate system indicated by patternUnits */
@property (nonatomic, readonly) CGFloat x;
@property (nonatomic, readonly) CGFloat y;
@property (nonatomic, readonly) CGFloat width;
@property (nonatomic, readonly) CGFloat height;

/** Which coordinate system x/y/width/height use */
@property (nonatomic, readonly) SVGPatternUnits patternUnits;

/** Which coordinate system the pattern content uses */
@property (nonatomic, readonly) SVGPatternUnits patternContentUnits;

/** Optional xlink:href pointing to another pattern to inherit attributes from */
@property (nonatomic, strong, readonly) NSString *href;

/**
 Renders all ConverterSVGToCALayer child elements of the <pattern> into a single
 CGImage of the given pixel size.  The caller is responsible for releasing the
 returned CGImageRef via CGImageRelease().

 This is the primary entry point used by SVGHelperUtilities when a shape's fill
 resolves to a <pattern> element.
*/
- (CGImageRef)renderChildrenIntoCGImageOfSize:(CGSize)size CF_RETURNS_RETAINED;

@end
