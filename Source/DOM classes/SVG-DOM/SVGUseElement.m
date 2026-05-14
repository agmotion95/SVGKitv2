#import "SVGUseElement.h"
#import "SVGUseElement_Mutable.h"
#import "SVGHelperUtilities.h"
#import "CALayerWithClipRender.h"

@implementation SVGUseElement

@synthesize x;
@synthesize y;
@synthesize width;
@synthesize height;
@synthesize instanceRoot;
@synthesize animatedInstanceRoot;

@synthesize transform; // each SVGElement subclass that conforms to protocol "SVGTransformable" has to re-synthesize this to work around bugs in Apple's Objective-C 2.0 design that don't allow @properties to be extended by categories / protocols

/**
 Build a container layer for the <use> element.

 The SVG spec says a <use> element inserts a deep clone of the referenced element
 into the document at the position specified by the use's own x/y attributes.
 We model this by:
   1. Creating a plain CALayer as the container (SVGKImage.newLayerWithElement: will
      populate it with the referenced element's sublayers).
   2. Applying the use element's x/y as a position translation so the instanced
      content is placed at the correct coordinates in its parent coordinate space.
   3. Applying the accumulated absolute transform (including any parent transforms)
      so that matrix(), translate() etc. on ancestor elements are honoured.

 If x/y are both zero (the common default case), this is a no-op and behaviour is
 identical to the previous implementation.
*/
-(CALayer *)newLayer
{
    CALayer *layer = [CALayerWithClipRender layer];

    // Configure identifier so the layer can be found by id later
    layer.name = self.identifier;
    if (self.identifier.length > 0)
        [layer setValue:self.identifier forKey:@"id"];

    // Derive x/y pixel values from SVGLength (handles px, %, em etc.)
    CGFloat xVal = (self.x != nil) ? [self.x pixelsValue] : 0.0f;
    CGFloat yVal = (self.y != nil) ? [self.y pixelsValue] : 0.0f;

    if (xVal != 0.0f || yVal != 0.0f) {
        // Apply the use element's own positional offset as a sublayer transform.
        // SVGKImage.newLayerWithElement: will then offset child frames on top of this.
        layer.sublayerTransform = CATransform3DMakeTranslation(xVal, yVal, 0);
    }

    return layer;
}

-(void)layoutLayer:(CALayer *)layer
{
	if( [instanceRoot.correspondingElement respondsToSelector:@selector(layoutLayer:)])
		[((SVGElement<ConverterSVGToCALayer>*)instanceRoot.correspondingElement) layoutLayer:layer];
}

@end
