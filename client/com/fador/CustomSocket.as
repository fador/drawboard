
package com.fador
{
  import flash.errors.*;
  import flash.events.*;
  import flash.net.Socket;
  import flash.utils.ByteArray;
  import com.fador.SocketEvent;
  
  public class CustomSocket extends Socket
  {
    private var moreData:uint = new uint(0);
    private var readType:uint = new uint(0);
    
    private var newdata:ByteArray = new ByteArray();
    private var newdata2:ByteArray = new ByteArray();
    
    public function CustomSocket(host:String = null, port:uint = 0)
    {
      super();
      configureListeners();
      if (host && port)
      {
        super.connect(host, port);
      }
    }
    
    private function configureListeners():void
    {
      addEventListener(Event.CLOSE, closeHandler);
      addEventListener(Event.CONNECT, connectHandler);
      addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
      addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
      addEventListener(ProgressEvent.SOCKET_DATA, socketDataHandler);
    }
    
    private function readResponse():void
    {
      var len:uint = new uint(0);
      var indata:ByteArray = new ByteArray();
      var incoming:uint = new uint(bytesAvailable);
      var first:uint = new uint(0);
      var i:uint = new uint(0);
      var bytes:uint = new uint(0);
      
      //trace("Incoming: "+incoming);
      
      while (bytesAvailable > 3) // || moreData)
      {
        if (moreData > 0)
        {
          //trace("moreData: "+moreData+ " bytesAvailable: "+bytesAvailable);
          //newdata2.clear();
          newdata2 = new ByteArray();
          this.readBytes(newdata2, 0, (incoming < moreData) ? incoming : moreData);
          newdata.writeBytes(newdata2);
          //bytes=newdata2.bytesAvailable;
          //for(i=0;i<bytes;i++)
          //  newdata.writeByte(newdata2[i]);
          //throw new Error("Len2:"+newdata.bytesAvailable);
          if (incoming < moreData)
          {
            moreData -= incoming;
          }
          else
          {
            moreData = 0;
            dispatchEvent(new SocketEvent(readType, newdata, "newdata"));
            //newdata.clear();
            newdata = new ByteArray();
          }
        }
        else
        {
          readType = readByte();
          //if(first==0) break;
          incoming--;
          //Drawdata
          if (readType == 0 || readType == 1 || readType == 3 || readType == 4)
          {
            len = readShort();
            incoming -= 2;
          }
          //PNGdata
          else if (readType == 2)
          {
            len = readUnsignedInt();
            incoming -= 4;
          }
          trace("type: " + readType + " Len: " + len + " bytesAvailable " + bytesAvailable);
          
          //newdata.writeByte(first);
          //newdata2.clear();
          newdata2 = new ByteArray();
          this.readBytes(newdata2, 0, (incoming < len) ? incoming : len);
          newdata.writeBytes(newdata2);
          
          if (incoming < len)
          {
            moreData = len - incoming;
          }
          else
          {
            moreData = 0;
            dispatchEvent(new SocketEvent(readType, newdata, "newdata"));
            //newdata.clear();
            newdata = new ByteArray();
            
          }
            //throw new Error("Len:"+newdata.bytesAvailable);
        }
      }
    }
    
    private function closeHandler(event:Event):void
    {
      //trace("closeHandler: " + event);
      //trace(response.toString());
      //var eventti:Event = new Event("closed");
      dispatchEvent(new Event("closed"));
    }
    
    private function connectHandler(event:Event):void
    {
      //trace("connectHandler: " + event);
      dispatchEvent(new Event("connected"));
    }
    
    private function ioErrorHandler(event:IOErrorEvent):void
    {
      //trace("ioErrorHandler: " + event);
      closeHandler(event);
    }
    
    private function securityErrorHandler(event:SecurityErrorEvent):void
    {
      //trace("securityErrorHandler: " + event);
      closeHandler(event);
    }
    
    private function socketDataHandler(event:ProgressEvent):void
    {
      //trace("socketDataHandler: " + event);
      readResponse();
    }
  }
}
