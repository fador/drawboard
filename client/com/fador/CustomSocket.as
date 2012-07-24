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
      
      while (bytesAvailable > 3)
      {
        if (moreData > 0)
        {
          newdata2 = new ByteArray();
          this.readBytes(newdata2, 0, (incoming < moreData) ? incoming : moreData);
          newdata.writeBytes(newdata2);
          if (incoming < moreData)
          {
            moreData -= incoming;
          }
          else
          {
            moreData = 0;
            dispatchEvent(new SocketEvent(readType, newdata, "newdata"));
            newdata = new ByteArray();
          }
        }
        else
        {
          readType = readByte();
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
            newdata = new ByteArray();            
          }

        }
      }
    }
    
    private function closeHandler(event:Event):void
    {
      dispatchEvent(new Event("closed"));
    }
    
    private function connectHandler(event:Event):void
    {
      dispatchEvent(new Event("connected"));
    }
    
    private function ioErrorHandler(event:IOErrorEvent):void
    {
      closeHandler(event);
    }
    
    private function securityErrorHandler(event:SecurityErrorEvent):void
    {
      closeHandler(event);
    }
    
    private function socketDataHandler(event:ProgressEvent):void
    {
      readResponse();
    }
  }
}
