// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <print.h>
#include <platform.h>
#include "xlog_server.h"

#ifdef PORT_UART_TX
on stdcore[0] : port uart_tx = PORT_UART_TX;
#else
#ifdef PORT_UART_TXD
on stdcore[0] : port uart_tx = PORT_UART_TXD;
#endif
#endif


int main() {
  par {
    on stdcore[0] : xlog_server_uart(uart_tx);
    on stdcore[1] : {
      timer tmr;
      unsigned int t;
      int i=0;
      printstr("message A\n");
      tmr :> t;
      while (1) {
        tmr when timerafter(t+6000000) :> t;
        printstr("message A\n");
        printintln(i);
        i++;
      }
    }
    on stdcore[2] : {
      timer tmr;
      unsigned int t;
      int i=0;
      tmr :> t;
      while (1) {
        tmr when timerafter(t+6000000) :> t;
        printstr("message B\n");
        printintln(i);
        i++;
      }
    }
    on stdcore[3] : {
      timer tmr;
      unsigned int t;
      int i=0;
      tmr :> t;
      while (1) {
        tmr when timerafter(t+6000000) :> t;
        printstr("message C\n");
        printintln(i);
        i++;
      }
    }
    on stdcore[2] : {
      timer tmr;
      unsigned int t;
      tmr :> t;
      while (1) {
        tmr when timerafter(t+15000000) :> t;
        printstr("message D\n");
      }
    }
  }
  return 0;
}
