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

#ifdef _WIN32
#include <process.h>
#include <direct.h>
#pragma comment (lib, "Ws2_32.lib")
#else
#include <netdb.h>  // for gethostbyname()
#endif

#include <cstdint>
#include <sys/stat.h>
#include <fcntl.h>
#include <signal.h>
#include <errno.h>

#include <sstream>
#include <fstream>


#include "drawboard.h"


bool running = true;
// Handle signals
void sighandler(int sig_num)
{

}


int main(int argc, char* argv[])
{
  signal(SIGTERM, sighandler);
  signal(SIGINT, sighandler);

#ifndef WIN32
  signal(SIGPIPE,  sighandler);
#else
  signal(SIGBREAK, sighandler);
#endif

  Drawboard *db = Drawboard::get();

  int32_t endiantestint = 1;
  int8_t* endiantestchar = (int8_t*)&endiantestint;
  if (*endiantestchar != 1)
  {
    db->littleEndian = false;
  }

  db->init(2089);

  timeval loopTime;
  loopTime.tv_sec  = 0;
  loopTime.tv_usec = 200000; // 200ms

  running = true;
  event_base_loopexit(db->m_eventBase, &loopTime);

  // Create our Server Console user so we can issue commands

//  time_t timeNow = time(NULL);
  while (running && event_base_loop(db->m_eventBase, 0) == 0)
  {
    event_base_loopexit(db->m_eventBase, &loopTime);
    //Kick out idle users etc
  }
    

  db->cleanup();

  event_base_free(db->m_eventBase);
  
  return EXIT_SUCCESS;
}
