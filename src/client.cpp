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


#ifdef WIN32
#include <cstdlib>
typedef int socklen_t;
#endif
#include <cstdint>
#include <cerrno>
#include <ctime>
#include <zlib.h>

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
  std::vector<uint8_t> outBuf;

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
        
    client->buffer.insert(client->buffer.end(), clientBuf,clientBuf+read);
        
    //Handle the data
    while (client->buffer.size()>2)
    {
      //If user has not authenticated and tries to send other data
      if(client->buffer[0] != 0x05 && client->UID == -1)
      {
        #ifdef DEBUG
        std::cout << "First data was not auth, closing" << std::endl;
        #endif
        Drawboard::get()->remClient(fd);
        return;
      }
      int curpos = 1;
      switch(client->buffer[0])
      {
        //uncompressed draw data
        case ACTION_DRAW_DATA:
        case ACTION_COMPRESSED_DRAW_DATA:
          {
            //Datalen
            uint32_t len=getUint16((uint8_t *)(&client->buffer[0]+curpos));  curpos += 2;


            #ifdef DEBUG
            std::cout << "  Draw data " << len << std::endl;
            #endif
            //Wait for more data
            if( (client->buffer.size() - curpos) < len)
            {
              event_set(&client->m_event, fd, EV_READ, client_callback, client);
              event_add(&client->m_event, NULL);
              return;
            }

            std::vector<uint8_t> drawdata;
            drawdata.insert(drawdata.begin(),&client->buffer[0]+curpos, &client->buffer[0]+curpos+len);

            //If compressed, uncompress
            if(client->buffer[0] == ACTION_COMPRESSED_DRAW_DATA)
            {
              uint32_t read=2000;
              uint8_t *out=(uint8_t *)malloc(2000);

              //Uncompress the data, kick client if invalid
              if(uncompress((Bytef *)out, (uLongf *)&read, (Bytef *)&drawdata[0], drawdata.size())!=0)
              {
                free(out);
                Drawboard::get()->remClient(fd);
                return;
              }
              drawdata.clear();
              drawdata.insert(drawdata.begin(),out, out+read);
            }
            //Echo to others
            if(drawdata.size())
            {
              Drawboard::get()->sendDrawdata(client,drawdata,0);
            }

            client->eraseFromBuffer(curpos+len);
          }
          break;

          //compressed draw data
        case ACTION_PNG_REQUEST:
          {
            //Datalen
            uint32_t len=getUint16((uint8_t *)(&client->buffer[0]+curpos));  curpos += 2;

            #ifdef DEBUG
            std::cout << "  PNG request " << len << std::endl;
            #endif
            //Wait for more data
            if( (client->buffer.size() - curpos) < len)
            {
              event_set(&client->m_event, fd, EV_READ, client_callback, client);
              event_add(&client->m_event, NULL);
              return;
            }

            //Clear the data from buffer
            client->eraseFromBuffer(curpos+len);
          }
          break;
          
        //Chat data
        case ACTION_CHAT_DATA:
          {

            //Datalen
            uint32_t len=getUint16((uint8_t *)(&client->buffer[0]+curpos));  curpos += 2;

            #ifdef DEBUG
            std::cout << "  Got chat data with length " << len << std::endl;
            #endif
            //Wait for more data
            if( (client->buffer.size() - curpos) < len)
            {
              event_set(&client->m_event, fd, EV_READ, client_callback, client);
              event_add(&client->m_event, NULL);
              return;
            }

            //ToDo: maybe check the data, now we just echo everything
            uint8_t chan = client->buffer[curpos];    curpos++;
            uint8_t datalen=client->buffer[curpos];   curpos++;

            if(datalen)
            {
              std::string chatdata(&client->buffer[curpos], &client->buffer[curpos]+datalen);
            
              #ifdef DEBUG
              std::cout << "    Repeating chat data" << std::endl;
              #endif
              Drawboard::get()->sendChat(client, chatdata, chan);
            }

            //Clear the data from the buffer
            client->eraseFromBuffer(curpos+datalen);


          }
          break;
        //Authentication
        case ACTION_AUTH:
        {
          #ifdef DEBUG
            std::cout << "  Got auth " << std::endl;
          #endif
          int response = Drawboard::get()->authenticate(client);

          if(response == NEED_MORE_DATA)
          {
            #ifdef DEBUG
            std::cout << "    NEED_MORE_DATA" << std::endl;
            #endif
            event_set(&client->m_event, fd, EV_READ, client_callback, client);
            event_add(&client->m_event, NULL);          
            return;
          }
          else if(response == DATA_ERROR)
          {
            Drawboard::get()->remClient(fd);
            return;
          }

          //Send userlist to the new client

          //Generate uid for the user
          client->UID = Drawboard::get()->generateUID();

          {
            //Send others info about this client
            uint8_t tempdata[2];
            std::vector<uint8_t> data;

            //Type byte
            data.push_back(ACTION_USER_REM);

            //Datalen
            putUint16(&tempdata[0],5+client->nick.size());
            data.insert(data.end(),&tempdata[0],&tempdata[0]+2);

            data.push_back(0); //Add
            data.push_back(1); //Number of users    

            //UID
            putUint16(&tempdata[0],client->UID);
            data.insert(data.end(),&tempdata[0],&tempdata[0]+2);

            data.push_back((uint8_t)client->nick.size());
            data.insert(data.end(),(client->nick).data(),(client->nick).data()+(client->nick).size());

            Drawboard::get()->sendAll((uint8_t *)&data[0],data.size(), client->getFd());
          }
          //Send userlist to the new client
          Drawboard::get()->sendUserlist(client);
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
      if(Drawboard::get()->send(fd,(uint8_t *)outBuf.data(), outBuf.size()) == -1)
      {
        return;
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