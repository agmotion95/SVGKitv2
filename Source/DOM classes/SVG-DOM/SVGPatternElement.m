/**
 SVGPatternElement.m
 SVGKit

 Renders SVG <pattern> elements.

 Strategy
 --------
 A <pattern> element defines a potentially-repeating graphic tile.  The common
 case we care most about is a single <image xlink:href="data:…"> child, which
 effectively makes the raster image the fill of another shape.

 In the CALayer world we model this as:
   • newLayer  → a plain CALayer sized to the pattern tile
   • The CALayer's `contents` is populated by rendering the child element tree
     into a CGImage via UIGraphicsImageRenderer and then setting that CGImage as
     the layer contents.  This gives correct pixel-accurate reproduction for the
     single-image case.
   • For repeating tiles SVGKImage's fill-URL handling can extend this in future.
*/

#import "SVGPatternElement.h"

#import "SVGHelperUtilities.h"
#import "CALayerWithClipRender.h"
#import "SVGKDefine_Private.h"

#if SVGKIT_UIKIT
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

@interface SVGPatternElement ()
@property (nonatomic, readwrite) CGFloat x;
@property (nonatomic, readwrite) CGFloat y;
@property (nonatomic, readwrite) CGFloat width;
@property (nonatomic, readwrite) CGFloat height;
@property (nonatomic, readwrite) SVGPatternUnits patternUnits;
@property (nonatomic, readwrite) SVGPatternUnits patternContentUnits;
@property (nonatomic, strong, readwrite) NSString *href;
@end

@implementation SVGPatternElement

// Protocol-required re-synthesises
@synthesize transform;
@synthesize viewBox;
@synthesize preserveAspectRatio;

@synthesize x = _x;
@synthesize y = _y;
@synthesize width = _width;
@synthesize height = _height;
@synthesize patternUnits = _patternUnits;
@synthesize patternContentUnits = _patternContentUnits;
@synthesize href = _href;

// -------------------------------------------------------------------------
#pragma mark - Parsing

- (void)postProcessAttributesAddingErrorsTo:(SVGKParseResult *)parseResult
{
    [super postProcessAttributesAddingErrorsTo:parseResult];

    // Geometry
    if ([[self getAttribute:@"x"] length] > 0)
        _x = [[self getAttribute:@"x"] floatValue];
    if ([[self getAttribute:@"y"] length] > 0)
        _y = [[self getAttribute:@"y"] floatValue];
    if ([[self getAttribute:@"width"] length] > 0)
        _width = [[self getAttribute:@"width"] floatValue];
    if ([[self getAttribute:@"height"] length] > 0)
        _height = [[self getAttribute:@"height"] floatValue];

    // Coordinate system for the tile position/size
    NSString *pu = [self getAttribute:@"patternUnits"];
    if ([pu isEqualToString:@"userSpaceOnUse"])
        _patternUnits = SVGPatternUnitsUserSpaceOnUse;
    else
        _patternUnits = SVGPatternUnitsObjectBoundingBox; // SVG default

    // Coordinate system for pattern content
    NSString *pcu = [self getAttribute:@"patternContentUnits"];
    if ([pcu isEqualToString:@"objectBoundingBox"])
        _patternContentUnits = SVGPatternUnitsObjectBoundingBox;
    else
        _patternContentUnits = SVGPatternUnitsUserSpaceOnUse; // SVG default

    // href / xlink:href (inherit from another pattern)
    if ([[self getAttribute:@"href"] length] > 0)
        _href = [self getAttribute:@"href"];
    else {
        NSString *xlinkHref = [self getAttributeNS:@"http://www.w3.org/1999/xlink" localName:@"href"];
        if ([xlinkHref length] > 0)
            _href = xlinkHref;
    }

    [SVGHelperUtilities parsePreserveAspectRatioFor:self];
}

// -------------------------------------------------------------------------
#pragma mark - CALayer generation

/**
 Build a CALayer representing the pattern tile.

 The layer's `contents` is a CGImage rendered from the child SVG elements
 (typically a single <image> with a base64 raster payload).  This approach
 correctly applies any transforms, viewBox scaling, and preserveAspectRatio
 that are declared inside the pattern.

 If the pattern has zero width/height we return a plain empty layer; callers
 should treat this as "no fill" rather than crash.
*/
- (CALayer *)newLayer
{
    CALayer *layer = [CALayerWithClipRender layer];
    [SVGHelperUtilities configureCALayer:layer usingElement:self];

    // Nothing to render if the tile has no size
    if (_width <= 0.0f || _height <= 0.0f)
        return layer;

    CGSize tileSize = CGSizeMake(_width, _height);
    layer.frame = CGRectMake(_x, _y, _width, _height);

    // Render child elements into a CGImage
    CGImageRef tileImage = [self renderChildrenIntoCGImageOfSize:tileSize];
    if (tileImage) {
        layer.contents = (__bridge id)tileImage;
        CGImageRelease(tileImage);
    }

    return layer;
}

/**
 Composite all ConverterSVGToCALayer children of the <pattern> element into
 a single CGImage of the given size using a cross-platform CGBitmapContext.
 The returned CGImageRef is +1 retained; caller must CGImageRelease() it.
*/
- (CGImageRef)renderChildrenIntoCGImageOfSize:(CGSize)size
{
    if (size.width <= 0 || size.height <= 0)
        return NULL;

    // RGBA8 bitmap context — works on iOS and macOS
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(
        NULL,
        (size_t)size.width,
        (size_t)size.height,
        8,
        0,
        colorSpace,
        kCGImageAlphaPremultipliedLast
    );
    CGColorSpaceRelease(colorSpace);

    if (!ctx)
        return NULL;

    // CG origin is bottom-left; SVG is top-left — flip the CTM
    CGContextTranslateCTM(ctx, 0, size.height);
    CGContextScaleCTM(ctx, 1.0, -1.0);

    for (Node *child in self.childNodes) {
        if (![child conformsToProtocol:@protocol(ConverterSVGToCALayer)])
            continue;
        SVGElement<ConverterSVGToCALayer> *childElement =
            (SVGElement<ConverterSVGToCALayer> *)child;
        CALayer *childLayer = [childElement newLayer];
        if (childLayer)
            [childLayer renderInContext:ctx];
    }

    // +1 retain — caller is responsible for CGImageRelease()
    CGImageRef result = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    return result;
}

- (void)layoutLayer:(CALayer *)layer
{
    // No additional layout needed; frame is set in newLayer
}

// -------------------------------------------------------------------------
#pragma mark - SVGFitToViewBox helpers

- (double)aspectRatioFromWidthPerHeight
{
    return (_height == 0) ? 0 : _width / _height;
}

- (double)aspectRatioFromViewBox
{
    return (self.viewBox.height == 0) ? 0 : self.viewBox.width / self.viewBox.height;
}

@end
