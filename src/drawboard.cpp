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
#include <png.h>
#include <string>
#include "md5/md5.h"
#include "drawboard.h"
#include "client.h"
#include "tools.h"

int setnonblock(int fd)
{
#ifdef _WIN32
  u_long iMode = 1;
  ioctlsocket(fd, FIONBIO, &iMode);
#else
  int flags;

  flags  = fcntl(fd, F_GETFL);
  flags |= O_NONBLOCK;
  fcntl(fd, F_SETFL, flags);
#endif

  return 1;
}


/*
 * Initialize the DrawBoard
 */
bool Drawboard::init(int port)
{
  int sd = 0;  
  struct sockaddr_in addresslisten;
  int reuse = 1;


  #ifdef _WIN32
    WSADATA wsaData;
    int iResult;
    // Initialize Winsock
    iResult = WSAStartup(MAKEWORD(2, 2), &wsaData);
    if (iResult != 0)
    {
      exit(1);
    }
  #endif


  m_eventBase = reinterpret_cast<event_base*>(event_init());
  #ifdef _WIN32
    m_socketlisten = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  #else
    m_socketlisten = socket(AF_INET, SOCK_STREAM, 0);
  #endif

  if (m_socketlisten < 0)
  {
    return false;
  }

  memset(&addresslisten, 0, sizeof(addresslisten));

  addresslisten.sin_family      = AF_INET;
  addresslisten.sin_addr.s_addr = inet_addr("0.0.0.0");
  addresslisten.sin_port        = htons(port);

  setsockopt(m_socketlisten, SOL_SOCKET, SO_REUSEADDR, (char*)&reuse, sizeof(reuse));

  // Bind to port
  if (bind(m_socketlisten, (struct sockaddr*)&addresslisten, sizeof(addresslisten)) < 0)
  {
    return false;
  }

  if (listen(m_socketlisten, 5) < 0)
  {
    return false;
  }

  setnonblock(m_socketlisten);

  event_set(&m_listenEvent, m_socketlisten, EV_WRITE | EV_READ | EV_PERSIST, accept_callback, NULL);
  event_add(&m_listenEvent, NULL);


  return true;
}

void Drawboard::cleanup()
{
  #ifdef WIN32
  closesocket(m_socketlisten);
  #else
    close(m_socketlisten);
  #endif
}


int Drawboard::authenticate(Client* client)
{
    if( (client->m_dataInBuffer - client->m_bufferPos) < 46)
    {
      return NEED_MORE_DATA;
    }
    std::string hash(' ',32);
    uint32_t curpos = 1;
    uint32_t UID=getUint16((uint8_t *)(client->buffer+client->m_bufferPos+curpos));         curpos += 2;
    uint8_t  chanID = client->buffer[client->m_bufferPos+curpos];                           curpos++;
    uint64_t timestamp = getUint64((uint8_t *)(client->buffer+client->m_bufferPos+curpos)); curpos += 8;
    uint8_t  adminbit = client->buffer[client->m_bufferPos+curpos];                         curpos++;
    memcpy((void *)hash.data(), (uint8_t *)(client->buffer+client->m_bufferPos+curpos),32);                curpos += 32;
    uint32_t nicklen=getUint16((uint8_t *)(client->buffer+client->m_bufferPos+curpos));     curpos+=2;
    if( (client->m_dataInBuffer - client->m_bufferPos - curpos) < nicklen)
    {
      return NEED_MORE_DATA;
    }
    std::string nick;
    for(uint32_t i = 0; i < nicklen; i++)
    {
      nick+=(char)client->buffer[client->m_bufferPos+curpos]; curpos ++;
    }

    //ToDo: implement configuration reader etc
    if(0)//config.check_auth)
    {
      std::string user_time;
      myItoa(timestamp,user_time,10);

      //Check the auth data
      std::string combination=user_time+"|SECRET_STRING|"+(char)('0'+adminbit)+"|"+nick;

      std::string hash2;
      MD5_CTX mdContext;
		  unsigned int len = strlen (combination.c_str());

		  MD5Init (&mdContext);
		  MD5Update (&mdContext, (unsigned char *)(combination.c_str()), len);
		  MD5Final (&mdContext);
    			
		  for (int iii = 0; iii < 16; iii++)
			  hash2+=toHex((unsigned int)mdContext.digest[iii]);

      if(hash2 != hash)
      {
        return DATA_ERROR;
      }
    }

    return DATA_OK;

}