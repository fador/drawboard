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

#ifdef _WIN32
#include <process.h>
#include <direct.h>
#include <WinSock.h>
#pragma comment (lib, "Ws2_32.lib")
#else
#include <netdb.h>  // for gethostbyname()
#endif

#include <sys/stat.h>
#include <fcntl.h>
#include <signal.h>
#include <errno.h>

#include <sstream>
#include <fstream>


#include "drawboard.h"

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

// Handle signals
void sighandler(int sig_num)
{

}


int main(int argc, char* argv[])
{
  signal(SIGTERM, sighandler);
  signal(SIGINT, sighandler);

#ifndef WIN32
  signal(SIGPIPE, pipehandler);
#else
  signal(SIGBREAK, sighandler);
#endif

  Drawboard *db = Drawboard::get();


  return EXIT_SUCCESS;
}
