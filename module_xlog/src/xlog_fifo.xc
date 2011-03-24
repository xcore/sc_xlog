// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xccompat.h>
#include "xlog_fifo.h"
#include "xs1.h"

void msg_fifo_init(REFERENCE_PARAM(msg_fifo_t, x))
{
  x.rdIndex = 0;
  x.wrIndex = 0;

}

void msg_fifo_push(REFERENCE_PARAM(msg_fifo_t, x), char c)
{
  int new_wrIndex = x.wrIndex+1;
  
  new_wrIndex *= (new_wrIndex < XLOG_MSG_FIFO_LEN);
   
  // throw away on overflow
  if (new_wrIndex == x.rdIndex)
    return;

  x.msg_fifo[x.wrIndex] = c;
  x.wrIndex = new_wrIndex;
  return;
}


char  msg_fifo_pull(REFERENCE_PARAM(msg_fifo_t, x)) {
  char c;
  int new_rdIndex;
  // assume non-empty!!!
  c = x.msg_fifo[x.rdIndex];
  new_rdIndex = x.rdIndex+1;
  new_rdIndex *= (new_rdIndex < XLOG_MSG_FIFO_LEN);
  x.rdIndex = new_rdIndex;
  return c;
}


void request_fifo_init(REFERENCE_PARAM(request_fifo_t, x))
{
  x.rdIndex = 0;
  x.wrIndex = 0;
  for (int i=0;i<XLOG_REQUEST_FIFO_LEN;i++)
    x.request_fifo[i] = 0;

}

int request_fifo_push(REFERENCE_PARAM(request_fifo_t, x), unsigned int d)
{
  int new_wrIndex = x.wrIndex+1;
  
  new_wrIndex *= (new_wrIndex != XLOG_REQUEST_FIFO_LEN);
   
  // throw away on overflow
  if (new_wrIndex == x.rdIndex)
    return 0;

  x.request_fifo[x.wrIndex] = d;
  x.wrIndex = new_wrIndex;
  return 1;
}


unsigned int  request_fifo_pull(REFERENCE_PARAM(request_fifo_t, x)) {
  unsigned int d;
  // assume non-empty!!!
  d = x.request_fifo[x.rdIndex];
  x.rdIndex++;
  x.rdIndex *= (x.rdIndex != XLOG_REQUEST_FIFO_LEN);
  return d;
}


#pragma select handler
void in_ct_or_int(chanend c, int &is_data, int &datum)
{
  if (testct(c)) {
    datum = inct(c);
    is_data = 0;
  }
  else {
    datum = inuint(c);
    is_data = 1;
  }
  return;
}
