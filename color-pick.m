//
//  main.m
//  color-pick
//
//  Created by Johan Nordberg on 2011-09-20.
//  Copyright 2011 FFFF00 Agents AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

// NSColorHexadecimalValue from http://developer.apple.com/library/mac/#qa/qa1576/_index.html
@interface NSColor (NSColorHexadecimalValue)
@end

@implementation NSColor (NSColorHexadecimalValue)

-(NSString *)hexValue {
  CGFloat redFloatValue, greenFloatValue, blueFloatValue;
  int redIntValue, greenIntValue, blueIntValue;
  NSString *redHexValue, *greenHexValue, *blueHexValue;

  // Convert the NSColor to the RGB color space before we can access its components
  NSColor *convertedColor = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];

  if(convertedColor) {
    // Get the red, green, and blue components of the color
    [convertedColor getRed:&redFloatValue green:&greenFloatValue blue:&blueFloatValue alpha:NULL];

    // Convert the components to numbers (unsigned decimal integer) between 0 and 255
    redIntValue=redFloatValue*255.99999f;
    greenIntValue=greenFloatValue*255.99999f;
    blueIntValue=blueFloatValue*255.99999f;

    // Convert the numbers to hex strings
    redHexValue=[NSString stringWithFormat:@"%02x", redIntValue];
    greenHexValue=[NSString stringWithFormat:@"%02x", greenIntValue];
    blueHexValue=[NSString stringWithFormat:@"%02x", blueIntValue];

    // Concatenate the red, green, and blue components' hex strings together with a "#"
    return [NSString stringWithFormat:@"#%@%@%@", redHexValue, greenHexValue, blueHexValue];
  }
  return nil;
}
@end

@interface Picker : NSApplication <NSWindowDelegate> {
  NSColorPanel *colorPanel;
  BOOL running;
}

- (void)show;
- (void)writeColor;

@end

@implementation Picker

- (void)run {
  // setting up our own runloop since i dont want all the info.plists and whatnot
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  running = YES;

  [self show];

  do {
    [pool release];
    pool = [[NSAutoreleasePool alloc] init];

    NSEvent *event = [self nextEventMatchingMask:NSAnyEventMask
                                       untilDate:[NSDate distantFuture]
                                          inMode:NSDefaultRunLoopMode
                                         dequeue:YES];
    [self sendEvent:event];
    [self updateWindows];
  } while (running);

  [pool release];
}

- (void)terminate {
  running = NO;
}

- (void)show {
  NSButton *button = [[NSButton alloc] initWithFrame:(NSRect){{0, 0}, {120, 40}}];
  [button setButtonType:NSMomentaryPushInButton];
  [button setBezelStyle:NSTexturedRoundedBezelStyle];
  button.title = @"Pick!";
  button.action = @selector(writeColor);
  button.target = self;

  colorPanel = [NSColorPanel sharedColorPanel];
  [colorPanel setShowsAlpha:YES];
  [colorPanel setFloatingPanel:YES];
  [colorPanel setHidesOnDeactivate:NO];
  [colorPanel setShowsAlpha:YES];
  [colorPanel setAccessoryView:button];
  [colorPanel makeKeyAndOrderFront:nil];
}

- (void)writeColor {
  NSFileHandle *stdOut = [NSFileHandle fileHandleWithStandardOutput];
  NSString *hex = [colorPanel.color hexValue];
  [stdOut writeData:[hex dataUsingEncoding:NSASCIIStringEncoding]];
  [colorPanel close];
  [self terminate];
}

@end

int main (int argc, const char * argv[]) {
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
  Picker *picker = (Picker *)[Picker sharedApplication];

  [picker performSelectorOnMainThread:@selector(run) withObject:nil waitUntilDone:YES];

  [pool drain];
  return 0;
}
