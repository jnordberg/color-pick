
color-pick:
	gcc -Wall -O3 -x objective-c -fobjc-exceptions -framework Foundation -framework AppKit -o colorpick colorpick.m

install:
	cp colorpick /usr/local/bin/

clean:
	rm colorpick
