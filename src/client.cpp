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


#ifdef WIN32
#include <cstdlib>
typedef int socklen_t;
#endif
#include <cstdint>
#include <cerrno>
#include <ctime>

#include "drawboard.h"
#include "client.h"
#include "tools.h"

static const size_t BUFSIZE = 2048;
static char* const clientBuf = new char[BUFSIZE];

#ifndef WIN32
#define SOCKET_ERROR -1
#endif

extern "C" void client_callback(int fd, short ev, void* arg)
{
  Client* client = reinterpret_cast<Client*>(arg);
  std::vector<char> outBuf;

  if (ev & EV_READ)
  {
    int read = 1;

    read = recv(fd, clientBuf, BUFSIZE, 0);
    #ifdef DEBUG
    std::cout << "Read from socket " << read << std::endl;
    #endif
    if (read == 0)
    {
      #ifdef DEBUG
      std::cout << "Socket closed properly" << std::endl;
      #endif
      Drawboard::get()->remClient(fd);
      
      return;
    }

    if (read == SOCKET_ERROR)
    {
      #ifdef DEBUG
      std::cout << "Socket had no data to read" << std::endl;
      #endif
      Drawboard::get()->remClient(fd);

      return;
    }

    //Store the time
    //client->lastData = time(NULL);

    //Check for buffer overflow
    if(client->m_dataInBuffer + read > BUFSIZE)
    {
      Drawboard::get()->remClient(fd);
      return;
    }

    memcpy((void *)client->buffer[client->m_dataInBuffer], clientBuf, read);
    client->m_dataInBuffer += read;

    
    //Handle the data
    while (client->m_dataInBuffer)
    {
      //If user has not authenticated and tries to send other data
      if(client->buffer[client->m_bufferPos] != 0x05 && client->UID == -1)
      {
        Drawboard::get()->remClient(fd);
        return;
      }
      switch(client->buffer[client->m_bufferPos])
      {
        //uncompressed draw data
        case 0x00:
        break;
        //compressed draw data
        case 0x01:
        break;
        //Chat data
        case 0x04:
        break;
        //Authentication
        case 0x05:
        {
          int response = Drawboard::get()->authenticate(client);

          if(response == NEED_MORE_DATA)
          {
            event_set(&client->m_event, fd, EV_READ, client_callback, client);
            event_add(&client->m_event, NULL);          
            return;
          }
          else if(response == DATA_ERROR)
          {
            Drawboard::get()->remClient(fd);
            return;
          }

          client->UID = Drawboard::get()->generateUID();
        }
        break;

        //If something else, remove the client
        default:
          Drawboard::get()->remClient(fd);
          return;
          break;
      }

      /*
      event_set(&client->m_event, fd, EV_READ, client_callback, client);
      event_add(&client->m_event, NULL);
      return;
      */
    } // while(user->buffer)
    
    if(outBuf.size())
    {
      const int written = send(fd, outBuf.data(), outBuf.size(), 0);

      if (written == SOCKET_ERROR)
      {
  #ifdef WIN32
  #define ERROR_NUMBER WSAGetLastError()
        if ((ERROR_NUMBER != WSATRY_AGAIN && ERROR_NUMBER != WSAEINTR && ERROR_NUMBER != WSAEWOULDBLOCK))
  #else
  #define ERROR_NUMBER errno
        if ((errno != EAGAIN && errno != EINTR))
  #endif
        {
          #ifdef DEBUG
          std::cout << "Error writing to client, tried to write " << std::endl;
          #endif
          Drawboard::get()->remClient(fd);
          return;
        }

      }
    }

  }
 
  event_set(&client->m_event, fd, EV_READ, client_callback, client);
  event_add(&client->m_event, NULL);
}

extern "C" void accept_callback(int fd, short ev, void* arg)
{
  sockaddr_in client_addr;
  socklen_t client_len = sizeof(client_addr);

  const int client_fd = accept(fd, reinterpret_cast<sockaddr*>(&client_addr), &client_len);

  if (client_fd < 0)
  {
    #ifdef DEBUG
    std::cout << "Client: accept() failed" << std::endl;
    #endif
    return;
  }

  Client* const client = new Client(client_fd);

  Drawboard::get()->addClient(client);
  std::cout << "New Client" << std::endl;
  setnonblock(client_fd);

  event_set(&client->m_event, client_fd, EV_WRITE | EV_READ, client_callback, client);
  event_add(&client->m_event, NULL);
}