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

#pragma once

const int NEED_MORE_DATA = -2;
const int DATA_ERROR = -1;
const int DATA_OK = 1;

const char ACTION_DRAW_DATA             = 0x00;
const char ACTION_COMPRESSED_DRAW_DATA  = 0x01;
const char ACTION_PNG_REQUEST           = 0x02;
const char ACTION_USER_ADD              = 0x03;
const char ACTION_USER_REM              = 0x03;
const char ACTION_CHAT_DATA             = 0x04;
const char ACTION_AUTH                  = 0x05;

#ifdef _WIN32
// This is needed for event to work on Windows.
#define NOMINMAX
#include <winsock2.h>
#endif

#include <cstdint>
#include <iostream>
#include <event.h>
#include <vector>
#include "client.h"
#include "tools.h"

class Drawboard
{
  public:
    Drawboard():littleEndian(true) { };
    ~Drawboard() { };

  struct event m_listenEvent;
  event_base* m_eventBase;

  bool init(int port);
  int authenticate(Client* client);

  //Singleton structure
  static Drawboard* get()
  {
    static Drawboard* m_instance = NULL;

    if (!m_instance)
    {
      m_instance = new Drawboard;
    }

    return m_instance;
  }

  bool addClient(Client* client)
  {    
    m_clients.push_back(client);
    return true;
  }

  //Search for the cliend and remove
  bool remClient(int m_fd);

  int sendAll(uint8_t *data, uint32_t datalen, int exception=0);
  int send(int fd,uint8_t *data, uint32_t datalen);

  int sendChat(Client *client,std::string data, uint8_t chan);
  std::vector<uint8_t> getUserlist();

  int getClientCount() { return m_clients.size(); };

  void cleanup();

  uint32_t generateUID()
  {
    return genUID();
  }

  bool littleEndian;

private:

  int m_socketlisten;
  time_t m_lastSave;
  std::vector<Client*> m_clients;

};

