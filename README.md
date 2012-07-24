# Drawboard
*by Fador*

Multi-user drawing board written in Flash AS3 with C++ server software. Started ages ago and now it's time to upgrade ;)
Has been in use with older server software (not included, you don't want to see it.. ;) ).
Draw area has been quite small and I was suppose to add support for larger area.

Has been made only for Finnish users so sorry for everything being in finnish..I'm going to fix that soon =)

Screenshot:
http://fador.be/kama/drawball.png

### License
3-clause BSD license also known as the New BSD License (see /LICENSE )
Allows unlimited redistribution for any purpose as long as its copyright notices and the license's disclaimers of warranty are maintained.
Flash policy server is not made by me and it has its own license /policy/LICENSE

### Usage

 * Run [Flash policy server](http://www.adobe.com/devnet/flashplayer/articles/socket_policy_files.html) ( included /policy/flashpolicyd.pl ), remember to edit flashpolicy.xml to match your server
 * Run the drawball server
 * Edit the flash params in drawball.html to match your server (host and port at least)
 * Open the drawball.html file in browser and it should connect to the server
 * Have fun drawing

### Required libs

 * libEvent (1.4.14)
 * zlib
 * libpng 

### NOTICE

Developed in VS2010, linux make files will be provided later.
Flash requires policy server running on the server which it tries to connect.

### Features
 * User chat
 * Color palette 
 * Brush selection 
 * Basic multiuser drawing
 
### ToDo
 * Saving the draw area and send to connecting users
 * External login support 
 * Reconnect button
 * Better color picker
 * Larger area
 * Zoom levels
 
### Protocol

see doc/communication.txt
 