
color-pick:
	gcc -Wall -O3 -x objective-c -fobjc-exceptions -framework Foundation -framework AppKit -o color-pick color-pick.m

install:
	cp color-pick /usr/local/bin

clean:
	rm color-pick
