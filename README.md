# Drawboard
*by Fador*

Multi-user drawing board written in Flash AS3 with C++ server software. Started ages ago and now it's time to upgrade ;)
Has been in use with older server software (not included, you don't want to see it.. ;) ).
Draw area has been quite small and I was suppose to add support for larger area.

Has been made only for Finnish users so sorry for everything being in finnish..I'm going to fix that =)

### NOTICE

Does not work with included server software!


### Features (which used to work)

 * User chat
 * Color palette 
 * Brush selection
 * External login support
 
 
### ToDo
 * Reconnect button
 * Better color picker
 * Larger area
 * Zoom levels
 
### Protocol (from doc/communication.txt)
 
 
Type:
  0 = uncompressed draw data
  1 = compressed draw data
  2 = PNG picture
  3 = User add/remove request
  4 = Chat data
  5 = Authentication
  
Format:
  Type:                   1 byte  (unsigned)
  Datalen                 2 bytes (unsigned)
  
   //Draw data (1=zlib compressed)
  IF Type == 0x00/0x01
    UserID              2 bytes //Only from server! Not used yet!
    Color RGB           3 bytes //writeByte (unsigned)
    Brush               1 byte (unsigned)
    Start X         2 bytes (Absolute) //writeShort (Signed)
    Start Y         2 bytes (Absolute) //writeShort (Signed)
    for each step
      End X       1 byte (Relative to previous point) (Signed)
      End Y       1 byte (Relative to previous point) (Signed)
    end for
  end IF
  
  //PNG image
  //Data from server
  IF Type == 0x02
    Datalen     2 bytes ( << 16) PNG pictures can be quite large
    X           4 bytes  (unsigned) Position on the "map"        
    Y           4 bytes  (unsigned)
    level       1 byte   (unsigned)
    PNGdata     n bytes
  end IF
  
  //PNG image
  //Request from client
  IF Type == 0x02
    X           4 bytes
    Y           4 bytes
    level       1 byte (unsigned)
  end IF
  
  //Userdata From server
  if Type == 0x03 
    Action      1 byte (0=add, 1=remove)
    Count       1 byte  //Count of users in this batch
    for every user
      UserID  2 bytes (unsigned)
      NameLen 1 byte //Only in add
      Name    n bytes //Only in add
    end if
  end IF
  
  //Chat data
  if Type == 0x04
    UserID      2 bytes (unsigned) (Only from server!)
    ChanID      1 byte        
    TextLen     1 byte (255 max len)
    Text        n bytes
  end IF
  
  //Authenticate
  if Type == 0x05
    UserID      2 bytes (unsigned)
    ChanID      1 byte
    Time        8 bytes
    Admin       1 byte
    MD5 Hash    32 bytes
    nickLen     1 byte
    nick        n bytes
  end IF   
    
    
    
