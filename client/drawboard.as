/*
  Copyright (c) 2012, Marko Viitanen
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
  * Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.
  * Neither the name of the Drawboard Project nor the
    names of its contributors may be used to endorse or promote products
    derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE LIABLE FOR ANY
  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

package
{
  import flash.display.*;
  import flash.events.MouseEvent;
  import flash.display.MovieClip;
  import flash.geom.Point;
  import flash.geom.Matrix;
  
  import flash.errors.EOFError;
  import flash.utils.ByteArray;
  import flash.net.Socket;
  
  import flash.text.TextField;
  import flash.text.TextFieldType;
  
  import flash.utils.Timer;
  
  import flash.events.*;
  import flash.ui.Mouse;
  
  import com.fador.CustomSocket;
  import com.fador.SocketEvent;
  import com.fador.DrawBoard;
  
  import flash.display.Loader;
  

  public class drawboard extends MovieClip
  {
    
    private var bgColor:uint = new uint("0xB8DBF5");
    
    private var myNick:String = new String("");
    
    private var nickList:Array = new Array();
    
    private var written:uint = 0;
    private var delay:uint = 500;
    
    public var connected:Boolean = new Boolean(false);
    private var server:CustomSocket;
    private var dataToSocket:ByteArray;
    private var paintData:ByteArray;
    private var incomingPaint:Array = new Array();
    
    private var colorMap:BitmapData = new BitmapData(259, 40, false, 0xFFFFFF);
    private var colorDisplay:Bitmap = new Bitmap(colorMap);
    
    private var drawAreaMask:Shape = new Shape();
    
    private var colorPick:Boolean = new Boolean(false);
    
    //private var colorDisplay:ColorPicker=new ColorPicker();
    
    private var drawing:Boolean = new Boolean(false);
    private var colorSelecting:Boolean = new Boolean(false);
    
    //Ball position
    private var offsetX:Number = new Number(350);
    private var offsetY:Number = new Number(350);
    
    private var colorArray:Array = new Array(9);
    private var colorPosArray:Array = new Array(9);
    private var colorShapeArray:Array = new Array(9);
    private var currentColor:uint = new uint(0);
    
    private var vx:Number = new Number(0);
    private var vy:Number = new Number(0);
    private var startx:int = new int(0);
    private var starty:int = new int(0);
    
    private var brushPosArray:Array = new Array(11);
    private var brushShapeArray:Array = new Array(11);
    private var brush:Number = new Number(1);
    private var scrolling:Boolean = new Boolean(false);
    
    private var len:uint = new uint;
    private var i:uint = new uint();
    private var xi:uint = new uint();
    private var yi:uint = new uint();
    
    private var p0:Point = new Point();
    private var p1:Point = new Point();
    
    public var infoField:TextField = new TextField();
    private var colorField:TextField = new TextField();
    //private var brushField:TextField = new TextField();
    public var t:Timer = new Timer(delay);
    
    public var chatField:TextField = new TextField();
    public var userField:TextField = new TextField();
    public var inputField:TextField = new TextField();
    public var nickField:TextField = new TextField();
    
    //public var scrollT:Timer = new Timer(20, 0);
    
    private var loader:Loader = new Loader();
    
    private var sideLen:uint = new uint(249);
    
    private var colorMapPlaceX:uint = new uint((offsetX) - 260 / 2);
    private var colorMapPlaceY:uint = new uint(702);
    
    private var drawArea:DrawBoard = new DrawBoard();
    
    private var changedCursor:Boolean = new Boolean(false);
    private var cursor:Sprite = new Sprite();
    private var useCursor:Boolean = new Boolean(false);
    
    private var startPos:String = new String();
    
    private var paramnick:String = new String();
    private var hash:String = new String();
    private var paramtime:int = new int();
    
    public function drawboard()
    {
      startPos = root.loaderInfo.parameters.startpos;
      hash = root.loaderInfo.parameters.hash;
      paramnick = root.loaderInfo.parameters.nick;
      paramtime = root.loaderInfo.parameters.time;
      
      userField.x = 702 + 200;
      userField.y = 10;
      userField.width = 115;
      userField.height = 700;
      userField.text = "Users online:\n";
      userField.background = true;
      userField.border = true;
      userField.selectable = false;
      
      chatField.x = 702;
      chatField.y = 10;
      chatField.width = 200;
      chatField.height = 700;
      chatField.text = "Chat is open\n";
      chatField.background = true;
      chatField.border = true;
      chatField.selectable = false;
      chatField.multiline = true;
      chatField.wordWrap = true;
      
      inputField.x = 702;
      inputField.y = 10 + 700;
      inputField.height = 20;
      inputField.width = 315;
      inputField.maxChars = 128;
      inputField.addEventListener(KeyboardEvent.KEY_DOWN, chatSendMessage);
      inputField.background = true;
      inputField.border = true;
      inputField.text = "";
      inputField.selectable = true;
      inputField.type = TextFieldType.INPUT;
      
      /*
         nickField.x = 702;
         nickField.y = 10 + 700 + 30;
         nickField.height = 20;
         nickField.width = 100;
         nickField.maxChars = 30;
         nickField.text = "Nick";
         nickField.border = true;
         nickField.background = true;
         nickField.type = TextFieldType.INPUT;
         nickField.addEventListener(KeyboardEvent.KEY_DOWN, setNick);
       */
      
      //Start timer
      t.addEventListener(flash.events.TimerEvent.TIMER, timerHandler);
      t.start();
      
      //Define colors in palette (ToDo: save user specific palette?)
      colorArray[0] = uint("0xffffff");
      colorArray[1] = uint("0x000000");
      colorArray[2] = uint("0xffff00");
      colorArray[3] = uint("0x00ffff");
      colorArray[4] = uint("0xff00ff");
      colorArray[5] = uint("0xff7f00");
      colorArray[6] = uint("0xffffff");
      colorArray[7] = uint("0xffffff");
      colorArray[8] = uint("0x33aaff");
      
      //Define brush/color palette positions
      var ii:uint = new uint(0);
      var rad:Number = new Number(365);
      var detail:Number = new Number(80);
      var angle:Number = new Number(Math.PI * 2 / detail);
      for (i = 33; i >= 33 - 9; i--)
      {
        colorPosArray[ii] = new Point(Math.cos(angle * i) * rad + offsetX, Math.sin(angle * i) * rad + offsetY);
        ii++;
      }
      
      detail = 110;
      angle = (Math.PI * 2 / detail);
      ii = 0;
      for (i = 20; i >= 20 - 10; i--)
      {
        brushPosArray[ii] = new Point(Math.cos(angle * i) * rad + offsetX, Math.sin(angle * i) * rad + offsetY);
        ii++;
      }
      
      //Create brush and color shapes
      for (i = 0; i < 11; i++)
        brushShapeArray[i] = new Shape();
      
      for (i = 0; i < 9; i++)
        colorShapeArray[i] = new Shape();
      
      colorDisplay.x = colorMapPlaceX;
      colorDisplay.y = colorMapPlaceY;
      
      genColors();
      initMask();
      updateColorArray();
      updateBrushArray();
      
      infoField.x = 0;
      infoField.y = 0;
      infoField.width = 200;
      infoField.height = 18;
      infoField.background = true;
      infoField.border = true;
      infoField.selectable = false;
      
      colorField.x = 20 + 600 / 2 - 50;
      colorField.y = 740;
      colorField.width = 100;
      colorField.height = 20;
      colorField.background = true;
      colorField.border = true;
      colorField.type = TextFieldType.INPUT;
      colorField.text = "ffffff";
      colorField.restrict = "0123456789abcdefABCDEF";
      colorField.maxChars = 6;
      
      /*
         brushField.x = 200;
         brushField.y = 768;
         brushField.width = 100;
         brushField.height = 20;
         brushField.background = true;
         brushField.border = true;
         brushField.type = TextFieldType.INPUT;
         brushField.text = "1";
         brushField.restrict="0123456789";
         brushField.maxChars=2;
       */
      
      //EVENTS
      
      stage.addEventListener(MouseEvent.MOUSE_DOWN, md);
      stage.addEventListener(MouseEvent.MOUSE_UP, mu);
      stage.addEventListener(MouseEvent.MOUSE_MOVE, mm);
      stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
      stage.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
      
      colorField.addEventListener(flash.events.Event.CHANGE, colorChange);
      //brushField.addEventListener(flash.events.Event.CHANGE, brushChange);
      
      //Mask the draw area
      
      addChild(drawArea);
      addChild(drawAreaMask);
      addChild(infoField);
      addChild(colorField);
      //addChild(brushField);
      addChild(colorDisplay);
      addChild(chatField);
      addChild(userField);
      addChild(inputField);
      //addChild(nickField);
      
      for (i = 0; i < 9; i++)
        addChild(colorShapeArray[i]);
      
      for (i = 0; i < 11; i++)
        addChild(brushShapeArray[i]);
      
      infoField.text = "Connecting " + root.loaderInfo.parameters.host + ":"+ root.loaderInfo.parameters.port;
      //Initialize connection!
      server = new CustomSocket();
      
      server.addEventListener("closed", closeHandler);
      server.addEventListener("connected", connectHandler);
      server.addEventListener("newdata", dataHandler);
      
      server.connect(root.loaderInfo.parameters.host, root.loaderInfo.parameters.port);
      
      dataToSocket = new ByteArray();
      paintData = new ByteArray();
    }
    
    private function setNick( /*e:KeyboardEvent*/):void
    {
      if (1) //e.keyCode == 13)
      {
        if (1) //paramnick.length > 0)
        {
          
          /*
             UserID      2 bytes (unsigned)
             ChanID      1 byte
             Time        8 bytes
             Admin       1 byte
             MD5 Hash    32 bytes
             nickLen     1 byte
             nick        n bytes
           */
          var nickdata:ByteArray = new ByteArray;
          nickdata.writeShort(0); //ID
          nickdata.writeByte(0); //Channel
          nickdata.writeUnsignedInt(0); //Time                    
          nickdata.writeUnsignedInt(0); //Time2
          nickdata.writeByte(0); //Admin bit
          for (i = 0; i < 32; i++)
          {
            nickdata.writeByte(hash.charCodeAt(i)); //MD5                    
          }
          nickdata.writeByte(paramnick.length);
          myNick = paramnick;
          
          for (i = 0; i < myNick.length; i++)
          {
            nickdata.writeByte(uint(myNick.charCodeAt(i)));
          }
          
          server.writeByte(5); //Type
          server.writeShort(nickdata.length);
          server.writeBytes(nickdata);
          server.flush();
            //nickField.text = "";
            //removeChild(nickField);
        }
        
      }
    
    }
    
    private function chatSendMessage(e:KeyboardEvent):void
    {
      if (e.keyCode == 13)
      {
        var chatdata:ByteArray = new ByteArray();
        var chatmsg:ByteArray = new ByteArray();
        var text:String = new String();
        var mydata:ByteArray = new ByteArray;
        infoField.text = "Msg sent!";
        text = inputField.text;
        server.writeByte(4); //Type
        server.writeShort(1 + 1 + text.length); //Len
        //server.writeShort(0); //UID
        server.writeByte(0); //Chan
        server.writeByte(inputField.length);
        
        for (i = 0; i < text.length; i++)
        {
          mydata.writeByte(uint(text.charCodeAt(i)));
        }
        server.writeBytes(mydata);
        server.flush();
        
        inputField.text = "";
      }
    }
    
    private function updateBrushArray():void
    {
      var i:uint = new uint(0);
      
      //First one is shift tool!
      brushShapeArray[0].graphics.clear();
      if (brush == 0)
        brushShapeArray[0].graphics.lineStyle(2, 0, 1);
      else
        brushShapeArray[0].graphics.lineStyle(1, 0, 1);
      
      brushShapeArray[0].graphics.beginFill(uint("0xffffff"));
      brushShapeArray[0].graphics.drawCircle(brushPosArray[i].x, brushPosArray[i].y, 10);
      brushShapeArray[0].graphics.endFill();
      
      brushShapeArray[0].graphics.lineStyle(1, 0, 1);
      //First the main cross
      brushShapeArray[0].graphics.moveTo(brushPosArray[0].x - 7, brushPosArray[0].y);
      brushShapeArray[0].graphics.lineTo(brushPosArray[0].x + 7, brushPosArray[0].y);
      brushShapeArray[0].graphics.moveTo(brushPosArray[0].x, brushPosArray[0].y - 7);
      brushShapeArray[0].graphics.lineTo(brushPosArray[0].x, brushPosArray[0].y + 7);
      
      //Then the arrow heads, right
      brushShapeArray[0].graphics.moveTo(brushPosArray[0].x + 3, brushPosArray[0].y - 4);
      brushShapeArray[0].graphics.lineTo(brushPosArray[0].x, brushPosArray[0].y - 7);
      brushShapeArray[0].graphics.lineTo(brushPosArray[0].x - 3, brushPosArray[0].y - 4);
      
      //Left
      brushShapeArray[0].graphics.moveTo(brushPosArray[0].x + 3, brushPosArray[0].y + 4);
      brushShapeArray[0].graphics.lineTo(brushPosArray[0].x, brushPosArray[0].y + 7);
      brushShapeArray[0].graphics.lineTo(brushPosArray[0].x - 3, brushPosArray[0].y + 4);
      
      //Top
      brushShapeArray[0].graphics.moveTo(brushPosArray[0].x - 4, brushPosArray[0].y + 3);
      brushShapeArray[0].graphics.lineTo(brushPosArray[0].x - 7, brushPosArray[0].y);
      brushShapeArray[0].graphics.lineTo(brushPosArray[0].x - 4, brushPosArray[0].y - 3);
      
      //Bottom
      brushShapeArray[0].graphics.moveTo(brushPosArray[0].x + 4, brushPosArray[0].y + 3);
      brushShapeArray[0].graphics.lineTo(brushPosArray[0].x + 7, brushPosArray[0].y);
      brushShapeArray[0].graphics.lineTo(brushPosArray[0].x + 4, brushPosArray[0].y - 3);
      
      for (i = 1; i < 11; i++)
      {
        brushShapeArray[i].graphics.clear();
        if (brush == i)
          brushShapeArray[i].graphics.lineStyle(2, 0, 1);
        else
          brushShapeArray[i].graphics.lineStyle(1, 0, 1);
        brushShapeArray[i].graphics.beginFill(uint("0xffffff"));
        brushShapeArray[i].graphics.drawCircle(brushPosArray[i].x, brushPosArray[i].y, 10);
        brushShapeArray[i].graphics.endFill();
        
        brushShapeArray[i].graphics.beginFill(uint("0x000000"));
        brushShapeArray[i].graphics.drawCircle(brushPosArray[i].x, brushPosArray[i].y, (i + 1) / 2);
        brushShapeArray[i].graphics.endFill();
      }
      
      if (brush != 0)
      {
        cursor.graphics.clear();
        cursor.graphics.lineStyle(2, 0, 1);
        cursor.graphics.drawCircle(0, 0, 10);
        cursor.graphics.lineStyle(2, 0xffffff, 1);
        cursor.graphics.drawCircle(0, 0, 9);
        cursor.graphics.lineStyle(1, 0, 0);
        cursor.graphics.beginFill(colorArray[currentColor]);
        cursor.graphics.drawRect(Math.floor(-brush / 2), Math.floor(-brush / 2), brush, brush);
        cursor.graphics.endFill();
      }
    
    }
    
    private function updateColorArray():void
    {
      var i:uint = new uint(0);
      for (i = 0; i < 9; i++)
      {
        colorShapeArray[i].graphics.clear();
        if (currentColor == i)
          colorShapeArray[i].graphics.lineStyle(2, 0, 1);
        else
          colorShapeArray[i].graphics.lineStyle(1, 0, 1);
        colorShapeArray[i].graphics.beginFill(colorArray[i]);
        colorShapeArray[i].graphics.drawCircle(colorPosArray[i].x, colorPosArray[i].y, 10);
        colorShapeArray[i].graphics.endFill();
      }
      
      if (brush != 0)
      {
        cursor.graphics.clear();
        cursor.graphics.lineStyle(2, 0, 1);
        cursor.graphics.drawCircle(0, 0, 10);
        cursor.graphics.lineStyle(2, 0xffffff, 1);
        cursor.graphics.drawCircle(0, 0, 9);
        cursor.graphics.lineStyle(1, 0, 0);
        cursor.graphics.beginFill(colorArray[currentColor]);
        cursor.graphics.drawRect(Math.floor(-brush / 2), Math.floor(-brush / 2), brush, brush);
        cursor.graphics.endFill();
      }
    }
    
    private function isInColorChange(x:uint, y:uint):Boolean
    {
      //if (y < 710 && y > 400 && x > 10 && x < 350)
      //{
      var i:uint = new uint(0);
      
      for (i = 0; i < 9; i++)
      {
        if (Math.sqrt((x - colorPosArray[i].x) * (x - colorPosArray[i].x) + (y - colorPosArray[i].y) * (y - colorPosArray[i].y)) < 10)
        {
          currentColor = i;
          updateColorArray();
          colorField.text = dec2hex(colorArray[currentColor]);
          return true;
        }
        
      }
      //}
      
      return false;
    
    }
    
    private function isInBrushChange(x:uint, y:uint):Boolean
    {
      //if (y < 710 && y > 400 && x > 300 && x < 700)
      //{
      var i:uint = new uint(0);
      
      for (i = 0; i < 11; i++)
      {
        if (Math.sqrt((x - brushPosArray[i].x) * (x - brushPosArray[i].x) + (y - brushPosArray[i].y) * (y - brushPosArray[i].y)) < 8)
        {
          brush = i;
          updateBrushArray();
          return true;
        }
        
      }
      //}
      
      return false;
    
    }
    
    private function isInDrawArea(x:uint, y:uint):Boolean
    {
      if (Math.sqrt((x - offsetX) * (x - offsetX) + (y - offsetY) * (y - offsetY)) < 350)
        return true;
      return false;
    }
    
    private function initMask():void
    {
      //8 sides of 300px, diameter of 600px
      //var sideLen:uint = new uint(200);
      
      var rad:Number = new Number(350);
      var detail:Number = new Number(40);
      var angle:Number = new Number(Math.PI * 2 / detail);
      drawAreaMask.graphics.beginFill(bgColor);
      drawAreaMask.graphics.moveTo(rad + offsetX, offsetY);
      for (i = 1; i <= detail / 2; ++i)
      {
        //angle*i
        drawAreaMask.graphics.lineTo(Math.cos(angle * i) * rad + offsetX, Math.sin(angle * i) * rad + offsetY);
      }
      
      drawAreaMask.graphics.lineTo(1024, offsetY);
      drawAreaMask.graphics.lineTo(1024, 808);
      drawAreaMask.graphics.lineTo(0, 808);
      drawAreaMask.graphics.lineTo(0, 0);
      drawAreaMask.graphics.lineTo(1024, 0);
      drawAreaMask.graphics.lineTo(1024, offsetY);
      
      drawAreaMask.graphics.moveTo(Math.cos(angle * detail / 2) * rad + offsetX, Math.sin(angle * detail / 2) * rad + offsetY);
      for (i = detail / 2; i <= detail; ++i)
      {
        //angle*i
        drawAreaMask.graphics.lineTo(Math.cos(angle * i) * rad + offsetX, Math.sin(angle * i) * rad + offsetY);
      }
      drawAreaMask.graphics.endFill();
      
      drawAreaMask.graphics.lineStyle(2, 0, 1, true);
      for (i = 1; i <= detail; ++i)
      {
        //angle*i
        drawAreaMask.graphics.lineTo(Math.cos(angle * i) * rad + offsetX, Math.sin(angle * i) * rad + offsetY);
      }
    
    }
    
    private function keyDownHandler(event:KeyboardEvent):void
    {
      
      if (event.keyCode == 80)
      {
        colorPick = true;
      }
    }
    
    private function keyUpHandler(event:KeyboardEvent):void
    {
      
      if (event.keyCode == 80)
      {
        colorPick = false;
      }
    }
    
    private function genColors():void
    {
      //var nPalSize:Number = new Number(768);
      var nPalSize:Number = new Number(249);
      var i:uint = new uint(0);
      
      var nRed:uint = new uint(0);
      var nGreen:uint = new uint(0);
      var nBlue:uint = new uint(0);
      
      var nFactor:int = new int(0);
      //int ColorShiftArray[] = { 0, 511, 255, 383, 127, 639 };
      var nColorShift:int = new int(0);
      
      var nRadians:Number = new Number(0);
      var nColor:uint = new uint(0);
      
      var myShape:Shape = new Shape();
      var objMatrixW:Matrix = new Matrix();
      var objMatrixB:Matrix = new Matrix();
      var objMatrixC:Matrix = new Matrix();
      
      for (i = 0; i <= nPalSize; ++i)
      {
        // nFactor calculate position of n in maximized palette ( 768 total colors )
        
        nFactor = 768 * i / nPalSize; // Assure that it runs 0 to 768
        nFactor = nFactor + nColorShift;
        if (nFactor >= 768) // Adjust for color shift
          nFactor = nFactor - 768;
        
        // Color calculations include sine/cosine functions to create
        // colors at constant radius from center of color circle. This
        // creates a constant brightness level. Math not optimized, left in readable state.
        if (nFactor <= 256)
        {
          // Red increasing, no green, blue decreasing
          nRed = 255 * (Math.sin((nFactor / 256) * Math.PI / 2));
          nGreen = 0;
          nBlue = 255 * (Math.cos((nFactor / 256) * Math.PI / 2));
          
        }
        else if ((nFactor > 256) && (nFactor <= 512))
        {
          // Red decreasing, green increasing, blue 0.
          nRed = 255 * (Math.cos(((nFactor - 256) / 256) * Math.PI / 2));
          nGreen = 255 * (Math.sin(((nFactor - 256) / 256) * Math.PI / 2));
          nBlue = 0;
          
        }
        else if ((nFactor > 512))
        {
          // Red 0, green decreasing, blue increasing
          nRed = 0;
          nGreen = 255 * (Math.cos(((nFactor - 512) / 256) * Math.PI / 2));
          nBlue = 255 * (Math.sin(((nFactor - 512) / 256) * Math.PI / 2));
          
        }
        
        nColor = (nRed << 16) | (nGreen << 8) | (nBlue);
        
        objMatrixW.createGradientBox(1, 20, Math.PI * 0.5, 0, 0);
        
        objMatrixB.createGradientBox(1, 20, Math.PI * 0.5, 0, 20);
        
        myShape.graphics.lineStyle(1, 0, 1, false, LineScaleMode.NONE, CapsStyle.NONE);
        myShape.graphics.lineGradientStyle(GradientType.LINEAR, [0xFFFFFF, nColor], [100, 100], [0, 255], objMatrixW);
        myShape.graphics.moveTo(i, 0);
        myShape.graphics.lineTo(i, 20);
        myShape.graphics.lineGradientStyle(GradientType.LINEAR, [nColor, 0], [100, 100], [0, 255], objMatrixB);
        myShape.graphics.moveTo(i, 20);
        myShape.graphics.lineTo(i, 40);
        
      }
      
      objMatrixC.createGradientBox(1, 40, Math.PI * 0.5, 0, 0);
      for (i = 249; i < 260; i++)
      {
        //myShape.graphics.lineStyle(1, 0, 1, false, LineScaleMode.NONE, CapsStyle.NONE);
        //myShape.graphics.lineGradientStyle(GradientType.LINEAR, [0xFFFFFF,0xffffff], [100, 100], [0, 255], objMatrixW);
        //myShape.graphics.moveTo(i, 0);
        //myShape.graphics.lineTo(i, 10);
        myShape.graphics.lineGradientStyle(GradientType.LINEAR, [0xffffff, 0], [100, 100], [0, 255], objMatrixC);
        myShape.graphics.moveTo(i, 0);
        myShape.graphics.lineTo(i, 40);
      }
      /*
      
         myShape.graphics.beginFill(uint("0xffffff"));
         myShape.graphics.drawRect(249, -1, 260, 21);
         myShape.graphics.endFill();
      
         myShape.graphics.beginFill(0);
         myShape.graphics.drawRect(249, 21, 260, 41);
         myShape.graphics.endFill();
       */
      colorMap.draw(myShape);
      myShape.graphics.clear();
    
    }
    
    private function sendToServer(data:ByteArray, compressed:Boolean):void
    {
      var dataToSend:ByteArray = new ByteArray();
      if (compressed)
      {
        dataToSend.writeByte(1);
      }
      else
      {
        dataToSend.writeByte(0);
      }
      //dataToSend.writeByte(0); //Uncompressed
      dataToSend.writeShort(data.length);
      dataToSend.writeBytes(data);
      server.writeBytes(dataToSend);
      //infoField.text="sending.."+dataToSend.length+" bytes";
    }
    
     
    
    private function dataHandler(event:SocketEvent):void
    {
      //infoField.text="Data incoming!";
      var temptype:uint = new uint(event.etype);
      var UID:uint = new uint();
      
      //throw new Error("dataHandler! type:"+temptype);
      //Drawdata
      trace("Incoming data type: " + temptype);
      if (temptype == 0 || temptype == 1)
      {        
        if (temptype == 1)
          event.data.uncompress();
        
        //infoField.text ="drawdata incoming "+event.data.length;
        
        if (connected)
          drawArea.autodraw(event.data);
        //While not "connected", save incoming autodraw data
        else
          incomingPaint.push(event.data);
      }
      //PNG data
      else if (temptype == 2)
      {
        
        event.data.position = 0;
        //infoField.text="Image incoming!\n"+event.data.bytesAvailable+" bytes";
        infoField.text = "Canvas loaded, ready to draw!";
        //X
        event.data.readUnsignedInt();
        //Y
        event.data.readUnsignedInt();
        event.data.readByte();
        var image:ByteArray = new ByteArray();
        image.writeBytes(event.data, 9);
        
        //throw new Error("dataa:"+event.data.bytesAvailable);
        
        loader.contentLoaderInfo.addEventListener("complete", pngLoad);
        loader.loadBytes(image);
        
      }
      //Userdata from server
      else if (temptype == 3)
      {
        var ii:uint = new uint(0);
        var action:uint = new uint();
        var count:uint = new uint();
        var nickLen:uint = new uint();
        
        var tempnick:String = new String("");
        var localdata:ByteArray = new ByteArray();
        localdata.writeBytes(event.data);
        //event.data.uncompress();
        localdata.position = 0;
        
        action = localdata.readUnsignedByte();
        count = localdata.readUnsignedByte();
        
        trace("Action: " + action);
        trace("Count: " + count);
        
        //Add users
        if (action == 0)
        {
          for (i = 0; i < count; i++)
          {
            
            var temparray:Array = new Array(localdata.readUnsignedShort(), "  ");
            
            nickLen = localdata.readUnsignedByte();
            tempnick = localdata.readUTFBytes(nickLen);
            
            temparray[1] = tempnick;
            
            nickList.push(temparray);
            
          }
        }
        //Remove users from the list
        else if (action == 1)
        {
          for (i = 0; i < count; i++)
          {
            UID = localdata.readUnsignedShort();
            trace("UID: " + UID);
            for (ii = 0; ii < nickList.length; ii++)
            {
              if (nickList[ii][0] == UID)
              {
                nickList.splice(ii, 1);
                trace("Found and spliced!");
                break;
              }
            }
          }
        }
        //trace(nickList);
        updateNickList();
      }
      //Chatdata
      else if (temptype == 4)
      {
        var tempdata:ByteArray = new ByteArray();
        //var UID:uint = new uint();
        var textlen:uint = new uint();
        var nicklen:uint = new uint();
        var nick:String = new String("");
        var temptext:String = new String("");
        tempdata.writeBytes(event.data);
        tempdata.position = 0;
        UID     = tempdata.readUnsignedShort();
        nicklen = tempdata.readUnsignedByte();
        nick    = tempdata.readUTFBytes(nicklen);
        
        tempdata.readByte(); //Chan not used
        
        //tempdata.uncompress();
        
        textlen = tempdata.readUnsignedByte();
        temptext = tempdata.readUTFBytes(textlen);
        /*
        for (i = 0; i < nickList.length; i++)
        {
          if (nickList[i][0] == UID)
          {
            chatField.appendText("<" + nickList[i][1] + "> ");
            break;
          }
        }
        */
        
        chatField.appendText("<" + nick + "> ");
        //trace("Nick: " + nickList[0][1]);
        chatField.appendText(temptext + "\n");
        chatField.scrollV = chatField.maxScrollV;
      }
    }
    
    private function updateNickList():void
    {
      userField.text = "Users online:\n";
      
      for (i = 0; i < nickList.length; i++)
      {
        userField.appendText(nickList[i][1] + "\n");
      }
    }
    
    private function pngLoad(event:Event):void
    {
      drawArea.paintStage.draw(loader);
      loader.unload();
      //If there was incoming autodraw data, draw it now!
      if (incomingPaint.length)
      {
        incomingPaint.forEach(traceAutoDraw);
        function traceAutoDraw(element:*, index:int, arr:Array):void
        {
          drawArea.autodraw(element);
        }
          //incomingPaint.clear();
      }
      connected = true;
      
    }
    
    private function connectHandler(event:Event):void
    {
      sendAuth();
    }
    
    //Authentication
    private function sendAuth():void
    {
      infoField.text = "Connection success!";
      //connected=true;
      setNick();
      
      var dataToSend:ByteArray = new ByteArray();
      dataToSend.writeByte(2); //PNG request
      dataToSend.writeShort(9); //Len
      dataToSend.writeUnsignedInt(0); //X
      dataToSend.writeUnsignedInt(0); //Y
      dataToSend.writeByte(0); //Level
      server.writeBytes(dataToSend);
      
      server.flush();
    
      connected = true;
    }
    
    private function closeHandler(event:Event):void
    {
      connected = false;
      infoField.text = "Connection lost!";
    }
    
    private function colorChange(e:Event):void
    {
      colorArray[currentColor] = uint("0x" + colorField.text);
      updateColorArray();
    }
    
    private function timerHandler(e:TimerEvent):void
    {
      if (connected)
      {
        if (paintData.length)
        {
          //ToDo: check if any help from compression
          paintData.compress();
          sendToServer(paintData, true);
          //autodraw(paintData);
          //paintData.clear();
          paintData = new ByteArray();
          written = 1;
        }
        server.flush();
      }
      //infoField.text="timer";
    
    }
    
    private function d2h(d:int):String
    {
      var c:Array = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'];
      if (d > 255)
        d = 255;
      var l:int = d / 16;
      var r:int = d % 16;
      return c[l] + c[r];
    }
    
    public function dec2hex(dec:uint):String
    {
      var hex:String = "";
      hex += d2h((dec & 0xff0000) >> 16);
      hex += d2h((dec & 0xff00) >> 8);
      hex += d2h(dec & 0xff);
      return hex;
    }
    
    private function md(event:MouseEvent):void
    {
      
      if (isInColorChange(event.stageX, event.stageY))
        return;
      if (isInBrushChange(event.stageX, event.stageY))
        return;
      if (event.stageX > colorMapPlaceX && event.stageX < colorMapPlaceX + 260 && event.stageY > colorMapPlaceY && event.stageY < colorMapPlaceY + 40)
      {
        colorSelecting = true;
        colorField.text = dec2hex(colorMap.getPixel(event.stageX - colorMapPlaceX, event.stageY - colorMapPlaceY));
        colorChange(null);
        return;
      }
      
      if (connected && isInDrawArea(event.stageX, event.stageY))
      {
        if (brush == 0)
        {
          scrolling = true;
          startx = event.stageX - drawArea.shiftX;
          starty = event.stageY - drawArea.shiftY;
          
          
          return;
        }
        
        drawing = true;
        p0.x = int(event.stageX - drawArea.shiftX);
        p0.y = int(event.stageY - drawArea.shiftY);
        p1.x = p0.x;
        p1.y = p0.y;
        
        //infoField.text = "Start: "+p0.x+","+p0.y;
        for (yi = 0; yi < brush; yi++)
        {
          for (xi = 0; xi < brush; xi++)
            drawArea.paintStage.setPixel(p0.x + (xi - brush / 2), p0.y + (yi - brush / 2), colorArray[currentColor]);
        }
        paintData.writeUnsignedInt(colorArray[currentColor]);
        paintData.writeByte(brush);
        paintData.writeShort(int(p0.x));
        paintData.writeShort(int(p0.y));
        startx = int(p0.x);
        starty = int(p0.y);
      }
    
    }
    
    private function mu(event:MouseEvent):void
    {
      colorSelecting = false;
      drawing = false;
      scrolling = false;
      if (connected)
      {
        if (!written && paintData.length > 3)
        {
          //ToDo: check if any help from compression
          paintData.compress();
          //infoField.text = "Bytes: "+paintData.length;
          sendToServer(paintData, true);
          //autodraw(paintData);
          //paintData.clear();
          paintData = new ByteArray();
        }
        else
          written = 0;
        
      }
    
    }
    
    private function mm(event:MouseEvent):void
    {
      
      if (useCursor && isInDrawArea(event.stageX, event.stageY))
      {
        if (!changedCursor && brush > 0)
        {
          changedCursor = true;
          addChild(cursor);
          //cursor.x = event.stageX;
          //cursor.y = event.stageY;
          cursor.startDrag(true);
          Mouse.hide();
        }
        
      }
      else if (useCursor)
      {
        if (changedCursor)
        {
          changedCursor = false;
          cursor.stopDrag();
          removeChild(cursor);
          Mouse.show();
        }
      }
      if (scrolling)
      {
        drawArea.scrollTest(startx - event.stageX, starty - event.stageY);
        startx = event.stageX;
        starty = event.stageY;
        return;
      }
      if (colorPick && isInDrawArea(event.stageX, event.stageY))
      {
        colorField.text = dec2hex(drawArea.paintStage.getPixel(event.stageX - drawArea.shiftX, event.stageY - drawArea.shiftY));
        colorChange(null);
      }
      if (colorSelecting && event.stageX > colorMapPlaceX && event.stageX < colorMapPlaceX + 260 && event.stageY > colorMapPlaceY && event.stageY < colorMapPlaceY + 40)
      {
        colorField.text = dec2hex(colorMap.getPixel(event.stageX - colorMapPlaceX, event.stageY - colorMapPlaceY));
        colorChange(null);
      }
      if (drawing && isInDrawArea(event.stageX, event.stageY))
      {
        //If we already written the current data, insert headers again
        if (written)
        {
          paintData.writeUnsignedInt(colorArray[currentColor]);
          paintData.writeByte(brush);
          paintData.writeShort(startx);
          paintData.writeShort(starty);
          written = 0;
        }
        //Current mouse position in the draw area
        p1.x = int(event.stageX - drawArea.shiftX);
        p1.y = int(event.stageY - drawArea.shiftY);
        
        
        vx = p1.x - p0.x;
        vy = p1.y - p0.y;
        
        //If we have length more than 127, we have to split it in multiple diff bytes
        if (Math.abs(int(p1.x) - startx) > 127 || Math.abs(int(p1.y) - starty) > 127)
        {
          var x_len:int = new int(Math.abs(int(p1.x) - startx) / 127)+1;
          var y_len:int = new int(Math.abs(int(p1.y) - starty) / 127)+1;          
          
          var len:int = new int(x_len);
          if (x_len < y_len)
          {
            len = y_len;
          }
          
          for (var part:int = 1; part <= len; part++)
          {
            paintData.writeByte((int(p1.x) - startx)/len);
            paintData.writeByte((int(p1.y) - starty)/len);
          }
        }
        else
        {
          paintData.writeByte(int(p1.x) - startx);
          paintData.writeByte(int(p1.y) - starty);
        }
        startx = int(p1.x);
        starty = int(p1.y);
        
        len = Math.sqrt(vx * vx + vy * vy);
        vx /= len;
        vy /= len;
        
        for (i = 0; i < len; i++)
        {
          for (yi = 0; yi < brush; yi++)
          {
            for (xi = 0; xi < brush; xi++)
              drawArea.paintStage.setPixel(p0.x + (vx * i) + (xi - brush / 2), p0.y + (vy * i) + (yi - brush / 2), colorArray[currentColor]);
          }          
        }
        p0.x = p1.x;
        p0.y = p1.y;
      }
    }
  
  }
}