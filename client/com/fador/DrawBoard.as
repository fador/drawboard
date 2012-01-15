
package com.fador
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
  
  import com.fador.CustomSocket;
  
  public class DrawBoard extends MovieClip
  {
    public var paintStage:BitmapData = new BitmapData(700, 700, false, 0xFFFFFF);
    
    private var i:uint = new uint(0);
    private var ii:uint = new uint(0);
    public var paintStages:Array = new Array();
    private var paintDisplay:Bitmap = new Bitmap(paintStage);
    
    private var countL2:Point = new Point(12, 12);
    private var countL1:Point = new Point(3, 3);
    
    private var imageArrayL0:Array = new Array();
    private var imageArrayL1:Array = new Array();
    private var imageArrayL2:Array = new Array();
    
    private var shiftLimitL0:Point = new Point(0, 0);
    private var shiftLimitL1:Point = new Point((countL1.x - 1) * 700, (countL1.y - 1) * 700);
    private var shiftLimitL2:Point = new Point((countL2.x - 1) * 700, (countL2.y - 1) * 700);
    
    private var curLevel:uint = new uint(0);
    
    public var shiftX:int = new int(0);
    public var shiftY:int = new int(0);
    
    public function DrawBoard():void
    {
      
      //Initialize XxY Array for bitmapdata and state
      /*
         for (i = 0; i < countL1.y; i++)
         {
         var temparray:Array = new Array();
         for (ii = 0; ii < countL1.x; i++)
         {
         temparray.push(new Array([new BitmapData(700, 700, false, 0),new uint(0)]));
         }
         paintStages.push(temparray);
         }
       */
      
      paintDisplay.x = shiftX;
      paintDisplay.y = shiftY;
      //paintDisplay.pixelSnapping="always";
      //paintDisplay.smoothing=true;
      //paintDisplay.width=600;
      
      addChild(paintDisplay);
    }
    
    public function zoomOut():Boolean
    {
      
      return false;
    }
    
    public function zoomIn():Boolean
    {
      
      return false;
    }
    
    public function scrollTest(x:int, y:int):Boolean
    {
      
      if (shiftX - x < 150 && shiftX - x > -500)
        shiftX -= x;
      if (shiftY - y < 150 && shiftY - y > -300)
        shiftY -= y;
      paintDisplay.x = shiftX;
      paintDisplay.y = shiftY;
      
      return true;
    }
    
    //Draws inputted data from other users
    public function autodraw(drawdata:ByteArray):void
    {
      

      var sx:int = new int(0);
      var sy:int = new int(0);
      var endx:int = new int(0);
      //var drawtype:uint = new uint(0);
      var endy:int = new int(0);
      var drawColor:uint = new uint(0);
      var drawBrush:uint = new uint(1);
      var drawUID:int = new int(0);
      var xi:uint = new uint(0);
      var yi:uint = new uint(0);
      var i:uint = new uint(0);
      var vx:Number = new Number(0);
      var vy:Number = new Number(0);
      var len:Number = new Number(0);

      //Clear the data position
      drawdata.position = 0;
      
      //drawtype=drawdata.readByte();
      
      drawUID = drawdata.readShort();      
      drawColor = drawdata.readUnsignedInt();
      drawBrush = drawdata.readByte();

      

      //Starting point
      sx = drawdata.readShort();
      sy = drawdata.readShort();
      
      for (yi = 0; yi < drawBrush; yi++)
      {
        for (xi = 0; xi < drawBrush; xi++)
          paintStage.setPixel(sx + (xi - drawBrush / 2), sy + (yi - drawBrush / 2), drawColor);
      }
      try
      {
        while (1)
        {
          endx = drawdata.readByte();
          endy = drawdata.readByte();
          
          vx = endx;
          vy = endy;
          
          //Interpolate from start to end
          len = Math.sqrt(vx * vx + vy * vy);
          vx /= len;
          vy /= len;
          for (i = 0; i < len; i++)
          {
            for (yi = 0; yi < drawBrush; yi++)
            {
              for (xi = 0; xi < drawBrush; xi++)
                paintStage.setPixel(sx + (vx * i) + (xi - drawBrush / 2), sy + (vy * i) + (yi - drawBrush / 2), drawColor);
            }
            
          }
          
          sx = sx + endx;
          sy = sy + endy;
          //infoField.text ="start "+sy+" "+sx+" End "+endx+" "+endy;
        }
      }
      catch (e:EOFError)
      {
        trace("error in draw data!");
        
      }
    
    }
  
  }

}