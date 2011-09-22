//
//  main.m
//  color-pick
//
//  Created by Johan Nordberg on 2011-09-20.
//  Copyright 2011 FFFF00 Agents AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>


@interface NSColor (NSColorHexadecimalValue)
@end

@implementation NSColor (NSColorHexadecimalValue)

// NSColorHexadecimalValue from http://developer.apple.com/library/mac/#qa/qa1576/_index.html
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

    // Concatenate the red, green, and blue components' hex strings together
    return [NSString stringWithFormat:@"%@%@%@", redHexValue, greenHexValue, blueHexValue];
  }
  return nil;
}

// color from hex found from http://www.karelia.com/cocoa_legacy/Foundation_Categories/NSColor__Instantiat.m
+ (NSColor *)colorFromHex:(NSString *)inColorString {
  NSColor *result = nil;
  unsigned int colorCode = 0;
  unsigned char redByte, greenByte, blueByte;

  if ([inColorString length] == 3) {
    NSString *newColor = [[NSString alloc] initWithFormat:@"%@%@%@%@%@%@",
      [inColorString substringWithRange: NSMakeRange(0,1)],
      [inColorString substringWithRange: NSMakeRange(0,1)],
      [inColorString substringWithRange: NSMakeRange(1,1)],
      [inColorString substringWithRange: NSMakeRange(1,1)],
      [inColorString substringWithRange: NSMakeRange(2,1)],
      [inColorString substringWithRange: NSMakeRange(2,1)]];
    inColorString = [newColor autorelease];
  }

  if (nil != inColorString) {
    NSScanner *scanner = [NSScanner scannerWithString:inColorString];
    (void) [scanner scanHexInt:&colorCode]; // ignore error
  }
  redByte   = (unsigned char) (colorCode >> 16);
  greenByte = (unsigned char) (colorCode >> 8);
  blueByte  = (unsigned char) (colorCode);  // masks off high bits
  result = [NSColor colorWithCalibratedRed:(float)redByte / 0xff
                                     green:(float)greenByte/ 0xff
                                      blue:(float)blueByte / 0xff
                                     alpha:1.0];
  return result;
}

@end

@interface Picker : NSApplication <NSWindowDelegate> {
  BOOL running;
  NSColorPanel *panel;
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

- (void)windowWillClose:(NSNotification *)notification {
  [self terminate];
}

- (void)show {
  // setup panel and it's accessory view
  NSButton *button = [[NSButton alloc] initWithFrame:(NSRect){{0, 0}, {120, 40}}];
  [button setButtonType:NSMomentaryPushInButton];
  [button setBezelStyle:NSTexturedRoundedBezelStyle];
  button.title = @"Pick!";
  button.action = @selector(writeColor);
  button.target = self;
  panel = [NSColorPanel sharedColorPanel];
  [panel setDelegate:self];
  [panel setShowsAlpha:YES];
  [panel setFloatingPanel:YES];
  [panel setHidesOnDeactivate:NO];
  [panel setShowsAlpha:YES];
  [panel setAccessoryView:button];

  // load user settings
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *color = [defaults stringForKey:@"startColor"];
  if (color != nil) {
    [panel setColor:[NSColor colorFromHex:color]];
  }
  [panel setMode:[defaults integerForKey:@"mode"]]; // will be 0 if not set, wich is NSGrayModeColorPanel

  // show panel
  [panel makeKeyAndOrderFront:nil];
}

- (void)writeColor {
  NSString *hex = [panel.color hexValue];

  // save color and current mode to defaults
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:hex forKey:@"startColor"];
  [defaults setInteger:panel.mode forKey:@"mode"];
  [defaults synchronize]; // force a save since we are exiting

  // write color to stdout
  NSFileHandle *stdOut = [NSFileHandle fileHandleWithStandardOutput];
  [stdOut writeData:[hex dataUsingEncoding:NSASCIIStringEncoding]];

  // close panel and exit
  [panel close];
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
