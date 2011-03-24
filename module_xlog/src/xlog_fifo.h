// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef _xlog_fifo_h_
#define _xlog_fifo_h_
#include <xccompat.h>
#ifdef __xlog_conf_h_exists__
#include "xlog_conf.h"
#endif

#ifndef XLOG_MSG_FIFO_LEN
#define XLOG_MSG_FIFO_LEN 256
#endif

#define XLOG_REQUEST_FIFO_LEN 32

typedef struct msg_fifo_t {
  int rdIndex;
  int wrIndex;
  char msg_fifo[XLOG_MSG_FIFO_LEN];
} msg_fifo_t;


typedef struct request_fifo_t {
  int rdIndex;
  int wrIndex;
  int request_fifo[XLOG_REQUEST_FIFO_LEN];
} request_fifo_t;

#define isempty(x) (x.rdIndex == x.wrIndex)

void msg_fifo_init(REFERENCE_PARAM(msg_fifo_t, x));
void msg_fifo_push(REFERENCE_PARAM(msg_fifo_t, x), char c);
char  msg_fifo_pull(REFERENCE_PARAM(msg_fifo_t, x));

void request_fifo_init(REFERENCE_PARAM(request_fifo_t, x));
int request_fifo_push(REFERENCE_PARAM(request_fifo_t, x), unsigned int d);
unsigned int  request_fifo_pull(REFERENCE_PARAM(request_fifo_t, x));

#endif //_xlog_fifo_h_
