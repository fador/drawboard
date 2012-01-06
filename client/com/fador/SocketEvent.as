package com.fador
{
  import flash.events.Event;
  import flash.utils.ByteArray;
  
  public class SocketEvent extends Event
  {
    public var data:ByteArray = new ByteArray();
    public var etype:uint;
    
    public function SocketEvent(newtype:uint, newdata:ByteArray, type:String, bubbles:Boolean = false, cancelable:Boolean = false)
    {
      super(type, bubbles, cancelable);
      data.writeBytes(newdata);
      etype = newtype;
      //trace("Data length: "+data.length);
    }
  }

}