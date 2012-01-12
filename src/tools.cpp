/*
  Copyright (c) 2011, Marko Viitanen
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
  * Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.
  * Neither the name of the The Mineserver Project nor the
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
#include <cstdint>
#ifdef _WIN32
  // This is needed for event to work on Windows.
  #define NOMINMAX
  #include <winsock2.h>
#else
  #include <arpa/inet.h>
#endif

#include <sstream>
#include <string>
#include <iomanip>
#include "tools.h"
#include "drawboard.h"


void putSint32(uint8_t* buf, int32_t value)
{
  uint32_t nval = htonl(value);
  memcpy(buf, &nval, 4);
}

void putSint16(uint8_t* buf, int16_t value)
{
  short value2 = htons(value);
  memcpy(buf, &value2, 2);
}

void putUint32(uint8_t* buf, uint32_t value)
{
  uint32_t nval = htonl(value);
  memcpy(buf, &nval, 4);
}

void putUint16(uint8_t* buf, uint16_t value)
{
  short value2 = htons(value);
  memcpy(buf, &value2, 2);
}


int32_t getSint32(uint8_t* buf)
{
  int32_t val = ntohl(*reinterpret_cast<const int32_t*>(buf));
  return val;
}

int32_t getSint16(uint8_t* buf)
{
  int16_t val = ntohs(*reinterpret_cast<const int16_t*>(buf));

  return val;
}

uint32_t getUint32(uint8_t* buf)
{
  uint32_t val = ntohl(*reinterpret_cast<const uint32_t*>(buf));
  return val;
}

uint32_t getUint16(uint8_t* buf)
{
  uint16_t val = ntohs(*reinterpret_cast<const uint16_t*>(buf));

  return val;
}

uint64_t getUint64(uint8_t* buf)
{
  uint64_t val;
  memcpy(&val, buf, 8);
  val = ntohll(val);
  return val;
}


void myItoa(uint64_t value, std::string& buf, int base)
{	
  int i = 20;
    buf="";	
    if(!value) buf="0";
  for(; value && i ; --i, value /= base) buf = "0123456789abcdef"[value % base] + buf;	
}


std::string toHex(unsigned int value)
{
  std::ostringstream oss;
  if(!(oss<<std::hex<<std::setw(2)<<std::setfill('0')<<value)) return 0;
  return oss.str();
}


uint32_t genUID()
{
  static uint32_t UID = 0;
  return ++UID;
}


inline uint64_t ntohll(uint64_t v)
{
  return (uint64_t)ntohl(v & 0x00000000ffffffff) << 32 | (uint64_t)ntohl((v >> 32) & 0x00000000ffffffff);
}