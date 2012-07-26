// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xccompat.h>
#include "xlog_server.h"
#include "xlog_fifo.h"
#include "xlog_support.h"
#define MAX_CHANEND_COUNT 32

#define RES_TYPE_LOCK 5
#define QUOTEAUX(x) #x
#define QUOTE(x) QUOTEAUX(x)


static unsigned lock;

static void allocate_lock() __attribute__ ((constructor));

static void allocate_lock() {
  __asm__ __volatile__ ("getr %0, " QUOTE(RES_TYPE_LOCK)
                        : "=r" (lock));
}

static unsigned client_chanend;

static void allocate_client_chanend() __attribute__ ((constructor));

static void allocate_client_chanend() {
  client_chanend = _getChanEnd();
}


static int grab_chanend(int c)
{
  unsigned int grabbed[MAX_CHANEND_COUNT];
  int i;
  int init_success = 0;
  int curCount;

   // clear the temp version.
   for (i = 0; i < MAX_CHANEND_COUNT; i++)
   {
      grabbed[i] = 0;
   }

   // get all channelEnd(s).
   for (i = 0; i < MAX_CHANEND_COUNT; i++)
   {
      grabbed[i] = _getChanEnd();
      if (grabbed[i] == 0)
      {
         break;
      }
   }
   curCount = i;
   
   // release all of them again
   for (i = 0; i < curCount; i++)
   {
      if (grabbed[i] == c) {      
         init_success = 1;
      } else {
         _freeChanEnd(grabbed[i]);         
      }
   }

   return init_success;
}

void xlog_mainloop(port uart_tx,
                   chanend c,
                   chanend open_server_chanend,
                   chanend client_chanend,
                   request_fifo_t *request_fifo,
                   msg_fifo_t *msg_fifo_uart,
                   msg_fifo_t *msg_fifo_chan,
                   chanend current_dest);


void xlog_mainloop_uart(port uart_tx,
                   chanend open_server_chanend,
                   chanend client_chanend,
                   request_fifo_t *request_fifo,
                   msg_fifo_t *msg_fifo,
                   chanend current_dest);

void xlog_mainloop_chan(chanend c,
                        chanend open_server_chanend,
                        chanend client_chanend,
                        request_fifo_t *request_fifo,
                        msg_fifo_t *msg_fifo,
                        chanend current_dest,
                        int *char_available);

void xlog_server_uart(port uart_tx) 
{
  request_fifo_t request_fifo;
  msg_fifo_t msg_fifo;
  chanend client_ch=_getChanEnd();
  chanend current_dest;

  int clobber;
  __asm__ __volatile__ ("in %0, res[%1]"
                        : "=r" (clobber)
                        : "r" (lock)
                        : "r0");
  int init_success = grab_chanend(XLOG_SERVER_CHANEND);
  __asm__ __volatile__ ("out res[%0], %0"
                        : /* no output */
                        : "r" (lock));

  if (!init_success)
    return;  

  request_fifo_init(&request_fifo);
  msg_fifo_init(&msg_fifo);

  while (1) {
    int connected;
    if (isempty(request_fifo))
      connected = 0;
    else {
      // set destination of client channel to remote chanend that made 
      // the request      
      connected = 1;
      current_dest = request_fifo_pull(&request_fifo);
      _setChanEndDest(client_ch, current_dest);      
      _outInt(client_ch, client_ch);
      _outCT(client_ch, XS1_CT_END);
    }
    xlog_mainloop_uart(uart_tx, 
                       XLOG_SERVER_CHANEND, 
                       connected ? client_ch : 0,
                       &request_fifo,
                       &msg_fifo,
                       current_dest);

  }
}


void xlog_server_uart_chan(port uart_tx, chanend c) 
{
  request_fifo_t request_fifo;
  msg_fifo_t msg_fifo_uart;
  msg_fifo_t msg_fifo_chan;
  chanend client_ch=_getChanEnd();
  chanend current_dest;

  int clobber;
  __asm__ __volatile__ ("in %0, res[%1]"
                        : "=r" (clobber)
                        : "r" (lock)
                        : "r0");
  int init_success = grab_chanend(XLOG_SERVER_CHANEND);
  __asm__ __volatile__ ("out res[%0], %0"
                        : /* no output */
                        : "r" (lock));

  if (!init_success)
    return;  

  request_fifo_init(&request_fifo);
  msg_fifo_init(&msg_fifo_uart);
  msg_fifo_init(&msg_fifo_chan);

  while (1) {
    int connected;
    if (isempty(request_fifo))
      connected = 0;
    else {
      // set destination of client channel to remote chanend that made 
      // the request      
      connected = 1;
      current_dest = request_fifo_pull(&request_fifo);
      _setChanEndDest(client_ch, current_dest);      
      _outInt(client_ch, client_ch);
      _outCT(client_ch, XS1_CT_END);
    }
    xlog_mainloop(uart_tx, 
                  c,
                  XLOG_SERVER_CHANEND, 
                  connected ? client_ch : 0,
                  &request_fifo,
                  &msg_fifo_uart,
                  &msg_fifo_chan,
                  current_dest);

  }
}


void xlog_server_chan(chanend c) 
{
  request_fifo_t request_fifo;
  msg_fifo_t msg_fifo;
  chanend client_ch= _getChanEnd(); 
  chanend current_dest;
  int init_success = grab_chanend(XLOG_SERVER_CHANEND);
  int char_available = 0;

  if (!init_success)
    return;  

  request_fifo_init(&request_fifo);
  msg_fifo_init(&msg_fifo);

  while (1) {
    int connected;
    if (isempty(request_fifo))
      connected = 0;
    else {
      // set destination of client channel to remote chanend that made 
      // the request      
      connected = 1;
      current_dest = request_fifo_pull(&request_fifo);
      _setChanEndDest(client_ch, current_dest);
      _outInt(client_ch, client_ch);
      _outCT(client_ch, XS1_CT_END);
    }
    xlog_mainloop_chan(c, 
                       XLOG_SERVER_CHANEND, 
                       connected ? client_ch : 0,
                       &request_fifo,
                       &msg_fifo,
                       current_dest,
                       &char_available);

  }
}


static int server_up_flag = 0;

int xlog_get_server_response(chanend c,
                             int *server_up_flag);

int xlog(int term, const char buf[], unsigned count)
{
  int clobber;
  __asm__ __volatile__ ("in %0, res[%1]"
                        : "=r" (clobber)
                        : "r" (lock)
                        : "r0");
   {
  int c1 = client_chanend;
  int remote_end;
  int i;
  int timed_out = 0;
  _setChanEndDest(c1, XLOG_SERVER_CHANEND);
  _outInt(c1, c1);
  _outCT(c1, XS1_CT_END);

  timed_out = xlog_get_server_response(c1, &server_up_flag);

  if (!timed_out) {
    (void) _inCT(c1);
    remote_end = _inInt(c1);
    (void) _inCT(c1);
    if (remote_end != 0) {
      _setChanEndDest(c1, remote_end);
      _outInt(c1, (count & 0xffff) | (term << 16));
      for(i=0;i<count;i++)
        _outInt(c1, buf[i]);
      _outCT(c1, XS1_CT_END);
      (void) _inCT(c1);
    }
  }
  }
  __asm__ __volatile__ ("out res[%0], %0"
                        : /* no output */
                        : "r" (lock));

  return 0;

}

int _write(int fd, const char buf[], unsigned count)
{
  return xlog(0, buf, count);
}


void  xlog_end_client_connection(chanend client_ch) 
{
  //  (void) _inCT(client_ch);
  _outCT(client_ch, XS1_CT_END);    
}

void xlog_handle_request(chanend open_server_chanend, 
                         request_fifo_t *request_fifo, 
                         chanend new_client_chanend) {
  int push_success = request_fifo_push(request_fifo, new_client_chanend);
  (void) _inCT(open_server_chanend);
  _setChanEndDest(open_server_chanend, new_client_chanend);
  _outInt(open_server_chanend, 0);
  _outCT(open_server_chanend, XS1_CT_END);
  if (!push_success) {
    _outInt(open_server_chanend, 0);
    _outCT(open_server_chanend, XS1_CT_END);
  }  
}
