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
#include <vector>

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
    uint32_t curpos = 1;
    uint32_t len=getUint16((uint8_t *)(&client->buffer[0]+curpos));         curpos += 2;

    #ifdef DEBUG
    std::cout << "    Len: " << len << std::endl;
    #endif
    if(client->buffer.size()-curpos < len)
    {
      return NEED_MORE_DATA;
    }
    std::string hash(' ',32);
    
    int32_t UID=getSint16((uint8_t *)(&client->buffer[0]+curpos));          curpos += 2;
    uint8_t  chanID = client->buffer[curpos];                               curpos++;
    uint64_t timestamp = getUint64((uint8_t *)(&client->buffer[0]+curpos)); curpos += 8;
    uint8_t  adminbit = client->buffer[curpos];                             curpos++;
    memcpy((void *)hash.data(), (uint8_t *)(&client->buffer[0]+curpos),32); curpos += 32;
    uint32_t nicklen=client->buffer[curpos];                                curpos++;

    std::string nick;
    for(uint32_t i = 0; i < nicklen; i++)
    {
      nick+=(char)client->buffer[curpos]; curpos ++;
    }

    //Clear the data from the buffer
    client->eraseFromBuffer(curpos);

    //ToDo: implement configuration reader etc
    if(0)//config.check_auth)
    {
      std::string user_time;
      myItoa(timestamp,user_time,10);

      //Check the auth data
      std::string combination=user_time+"|SECRET_STRING|"+(char)('0'+adminbit)+"|"+nick;

      std::string hash2;
      MD5_CTX mdContext;

		  MD5Init (&mdContext);
		  MD5Update (&mdContext, (unsigned char *)(combination.c_str()), combination.size());
		  MD5Final (&mdContext);
    			
		  for (int iii = 0; iii < 16; iii++)
			  hash2+=toHex((unsigned int)mdContext.digest[iii]);

      if(hash2 != hash)
      {
        return DATA_ERROR;
      }
    }
    client->nick = nick;
    client->admin = (adminbit==0)?false:true;


    return DATA_OK;
}


int Drawboard::sendAll(uint8_t *data, uint32_t datalen, int exception)
{
  for(uint32_t i = 0; i < m_clients.size(); i++)
  {
    if(m_clients[i]->getFd() != exception)
    {
      send(m_clients[i]->getFd(), data, datalen);
    }
  }
  return 1;
}

int Drawboard::send(int fd,uint8_t *data, uint32_t datalen)
{
    const int written = ::send(fd, (const char *)data, datalen,0);
    #ifdef DEBUG
    std::cout << "Written " << written << " bytes to client" << std::endl;
    #endif
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
        remClient(fd);
        return -1;
      }
    }
    return 1;
}


bool Drawboard::sendUserlist(Client* client)
{
  uint8_t tempdata[2];
  std::vector<uint8_t> data;
  uint8_t users = 0;
  data.push_back(ACTION_USER_ADD);

  data.push_back(0); data.push_back(0); //Datalen

  data.push_back(0); //Add

  data.push_back(0); //Client number (fill at the end)

  for (std::vector<Client*>::iterator it = m_clients.begin(); it!=m_clients.end(); ++it)
  {
    if((*it)->UID > 0)
    {
      putUint16(&tempdata[0],(*it)->UID);
      data.insert(data.end(),&tempdata[0],&tempdata[0]+2);
      data.push_back((uint8_t)((*it)->nick).size());
      data.insert(data.end(),((*it)->nick).data(),((*it)->nick).data()+((*it)->nick).size());

      users++;
    }
  }

  data[4] = users;

  //Fill in the length information
  putUint16(&data[1], data.size()-3);

  send(client->getFd(), (uint8_t *)&data[0],data.size());

  return true;
}

int Drawboard::sendDrawdata(Client *client,std::vector<uint8_t> data, uint8_t chan)
{
  uint8_t tempdata[4];
  std::vector<uint8_t> drawdata;

  //ToDo: add compression

  //Type byte
  drawdata.push_back(ACTION_DRAW_DATA);
  
  //Msg len, allocate the space
  drawdata.insert(drawdata.end(),&tempdata[0],&tempdata[0]+2);

  //UID
  putUint16(&tempdata[0],client->UID);
  drawdata.insert(drawdata.end(),&tempdata[0],&tempdata[0]+2);

  //the data
  drawdata.insert(drawdata.end(),&data[0],&data[0]+data.size());

  //Fill in the length information
  putUint16(&drawdata[1], drawdata.size()-3);

  sendAll((uint8_t *)&drawdata[0],drawdata.size());

  return 1;
}


int Drawboard::sendChat(Client *client,std::string data, uint8_t chan)
{
  uint8_t tempdata[4];
  std::vector<uint8_t> chatdata;

  //Type byte
  chatdata.push_back(ACTION_CHAT_DATA);
  
  //Msg len, allocate the space
  chatdata.insert(chatdata.end(),&tempdata[0],&tempdata[0]+2);

  //UID
  putUint16(&tempdata[0],client->UID);
  chatdata.insert(chatdata.end(),&tempdata[0],&tempdata[0]+2);

  //Nick size
  chatdata.push_back(client->nick.size());

  //Nick
  chatdata.insert(chatdata.end(),client->nick.data(),client->nick.data()+client->nick.size());

  //Channel ID
  chatdata.push_back(0);

  //Msg size
  chatdata.push_back(data.size());

  //Nick
  chatdata.insert(chatdata.end(),data.data(), data.data()+data.size());

  //Fill in the length information
  putUint16(&chatdata[1], chatdata.size()-3);

  sendAll((uint8_t *)&chatdata[0],chatdata.size());

  return 1;
}

//Search for the cliend and remove
bool Drawboard::remClient(int m_fd)
{
  uint32_t UID = -1;
  std::string nick;
  for (std::vector<Client*>::iterator it = m_clients.begin(); it!=m_clients.end(); ++it)
  {
    if((*it)->getFd() == m_fd)
    {
      if((*it)->UID > 0)
      {
        UID = (*it)->UID;
        nick = (*it)->nick;
      }
      //Close client socket
      #ifdef WIN32
        closesocket(m_fd);
      #else
        close(m_fd);
      #endif
      
      delete *it;
      m_clients.erase(it);
      break;
    }
  }

  //ToDo: send info of removed client
  if(UID != -1)
  {
    uint8_t tempdata[2];
    std::vector<uint8_t> remdata;

    //Type byte
    remdata.push_back(ACTION_USER_REM);

    //Datalen
    putUint16(&tempdata[0],4);
    remdata.insert(remdata.end(),&tempdata[0],&tempdata[0]+2);

    remdata.push_back(1); //Rem

    remdata.push_back(1); //Number of users    

    //UID
    putUint16(&tempdata[0],UID);
    remdata.insert(remdata.end(),&tempdata[0],&tempdata[0]+2);

    sendAll((uint8_t *)&remdata[0],remdata.size());
  }

  std::cout << "Client removed" << std::endl;

  return true;
}


bool Drawboard::addClient(Client* client)
{

  //Push the new client to the list
  m_clients.push_back(client);
  return true;
}