// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <xlog_server.h>
#include <xlog_fifo.h>
#define CUSHION_TIME 100

// bit time base on Baud rate.
#define UART_BIT_TIME            (XS1_TIMER_HZ / XLOG_UART_BAUD_RATE)

void xlog_handle_request(chanend c,request_fifo_t &request_fifo, unsigned int new_client_ch);

void  xlog_end_client_connection(chanend client_ch) ;


#define SERVER_TIMEOUT 100000
#define XLOG_POLLS 10000
//timer xlog_tmr;

int xlog_get_server_response(streaming chanend c, int &flag)
{
  int timed_out=1;
  if (flag) {
    c :> int x;
    timed_out = 0;
  }
  else {
    unsigned t;
    //    xlog_tmr :> t;
    for (int i=0;(i<XLOG_POLLS) && timed_out;i++) {
      select 
        {
        case c :> int x:
          flag = 1;
          timed_out = 0;
          break;
        default:
          break;
        }
    }
        //      case xlog_tmr when timerafter(t+SERVER_TIMEOUT) :> int:
        //        timed_out = 1;
        //        break;
    
  }
  return timed_out;
}

static void notify(chanend c) {
  outuchar(c, 0);
  outuchar(c, 0);
  outuchar(c, 0);
  outct(c, XS1_CT_END);
  return;
}

#pragma select handler
void in_ct_or_int(chanend c, int &is_data, int &datum);


void xlog_mainloop_uart(port uart_tx,
                        chanend open_server_chanend,
                        chanend ?client_chanend,
                        request_fifo_t &request_fifo,
                        msg_fifo_t &msg_fifo,
                        chanend current_dest) 
{
  timer tmr;
  int len = isnull(client_chanend)?0:-1;
  int uart_count = 0;
  unsigned int new_client_chanend;
  unsigned int uart_data = 0;
  unsigned int next_bit_time;
  static int init=1;
  int term = 0;
  int datum, is_data;

  if (init) {
    init = 0;
    uart_count = 11;
    uart_data = '.';
    tmr :> next_bit_time;
    next_bit_time += INITIAL_UART_DELAY;
  }
    

  while (uart_count != 0 || len != 0) {
    select 
      {
      case uart_count => tmr when timerafter(next_bit_time - CUSHION_TIME) :> int:        
        tmr when timerafter(next_bit_time) :> int;        
          uart_tx <: uart_data;
          uart_data >>= 1;
          uart_count--;

          if (uart_count == 0 && !isempty(msg_fifo)) {
            uart_count = 11;
            uart_data = msg_fifo_pull(msg_fifo);
            uart_tx <: 0;            
          }
          else if (uart_count == 3) {
            uart_data = 0b111;
          }
        next_bit_time += UART_BIT_TIME;            
        break;
      case inuint_byref(open_server_chanend, new_client_chanend): {
        xlog_handle_request(open_server_chanend, 
                            request_fifo, 
                            new_client_chanend);
        }
        break;
      case (len != 0) => in_ct_or_int(client_chanend, is_data, datum):
        if (is_data) {
          if (len == -1) {
            term = datum >> 16; 
            len = 1;
          }
          else {
            // get new character from client
            msg_fifo_push(msg_fifo, datum);
            if (!uart_count) {
              uart_count = 11; 
              uart_data = msg_fifo_pull(msg_fifo);
              tmr :> next_bit_time;
              uart_tx <: 0;
              next_bit_time += UART_BIT_TIME;            
            }         
          } 
        }
        else {
          xlog_end_client_connection(client_chanend);
          len = 0;
        }
        break;
      }
  }
  if (isempty(request_fifo)) {
    unsigned new_client_chanend = inuint(open_server_chanend);  
    xlog_handle_request(open_server_chanend, 
                        request_fifo, 
                        new_client_chanend);
    
  }
  return;
}

void xlog_mainloop(port ?uart_tx,
                   chanend ?c,
                   chanend open_server_chanend,
                   chanend ?client_chanend,
                   request_fifo_t &request_fifo,
                   msg_fifo_t &?msg_fifo_uart,
                   msg_fifo_t &?msg_fifo_chan,
                   chanend current_dest) 
{
  timer tmr;
  int len = isnull(client_chanend)?0:-1;
  int uart_count = 0;
  unsigned int new_client_chanend;
  unsigned int uart_data = 0;
  unsigned int next_bit_time;
  int waiting_for_ack = 0;
  static int init;
  int term = 0;
  char tok;
  int datum, is_data;


  if (init) {
    if (!isnull(uart_tx)) {
      uart_count = 11;
      uart_data = '.';
      tmr :> next_bit_time;
      next_bit_time += INITIAL_UART_DELAY;
    }
    init = 0;
  }
    
  while (uart_count != 0 || len != 0) {
    select 
      {
      case uart_count => tmr when timerafter(next_bit_time - CUSHION_TIME) :> int:        
        tmr when timerafter(next_bit_time) :> int;        
          uart_tx <: uart_data;
          uart_data >>= 1;
          uart_count--;

          if (uart_count == 0 && !isempty(msg_fifo_uart)) {
            uart_count = 11;
            uart_data = msg_fifo_pull(msg_fifo_uart);
            uart_tx <: 0;            
          }
          else if (uart_count == 3) {
            uart_data = 0b111;
          }
        next_bit_time += UART_BIT_TIME;            
        break;
      case inuint_byref(open_server_chanend, new_client_chanend): {
        xlog_handle_request(open_server_chanend, 
                            request_fifo, 
                            new_client_chanend);
        }
        break;
      case inct_byref(c,tok):
        if (!isempty(msg_fifo_chan)) {
          int d;
          d = msg_fifo_pull(msg_fifo_chan);
          outuchar(c, d);          
        }
        else
          waiting_for_ack = 0;
        break;
      case (len != 0) => in_ct_or_int(client_chanend, is_data, datum):
        if (is_data) {
          if (len == -1) {
            term = datum >> 16; 
            len = 1;
          }
          else {
            // get new character from client
            if (!isnull(uart_tx) && (term == 0 || isnull(c))) {
              msg_fifo_push(msg_fifo_uart, datum);
              if (!uart_count) {
                uart_count = 11; 
                uart_data = msg_fifo_pull(msg_fifo_uart);
                tmr :> next_bit_time;
                uart_tx <: 0;
                next_bit_time += UART_BIT_TIME;            
              }         
            } 
            else if (!isnull(c)) {
              msg_fifo_push(msg_fifo_chan, datum);
              if (!waiting_for_ack) {
                int d;
                d = msg_fifo_pull(msg_fifo_chan);
                outuchar(c, d);
                waiting_for_ack = 1;
              }
            }
          }      
        }
        else {
          xlog_end_client_connection(client_chanend);
          len = 0;
        }
        break;
      }
  }
  if (isempty(request_fifo)) {
    unsigned new_client_chanend = inuint(open_server_chanend);  
    xlog_handle_request(open_server_chanend, 
                        request_fifo, 
                        new_client_chanend);
    
  }
  return;
}






#define CHAN_SPACING_TIME 4000


void xlog_mainloop_chan(chanend c,
                        chanend open_server_chanend,
                        chanend ?client_chanend,
                        request_fifo_t &request_fifo,
                        msg_fifo_t &msg_fifo,
                        chanend current_dest,
                        int &char_available) 
{
  timer tmr;
  int len = isnull(client_chanend)?0:-1;
  unsigned int new_client_chanend;
  unsigned int next_char_time;
  char next_char;
  int term=0;
  int datum, is_data;

  tmr :> next_char_time;

  while (isempty(request_fifo) || len != 0) {
    select 
      {
      case c :> int request:        
        c <: (unsigned int) next_char;        
        if (!isempty(msg_fifo)) {         
          char_available = 1;
          next_char = msg_fifo_pull(msg_fifo);
          notify(c);
        }
        else 
          char_available = 0;
        break;
      case inuint_byref(open_server_chanend, new_client_chanend):
        xlog_handle_request(open_server_chanend, 
                            request_fifo, 
                            new_client_chanend);
        break;
      case (len != 0) => in_ct_or_int(client_chanend, is_data, datum):
        if (is_data) {
          if (len==-1) {
            term = datum >> 16;
            len = 1;
          }
          else {
            // get new character from client
            msg_fifo_push(msg_fifo, datum);
            if (!char_available) {
              char_available = 1;
              next_char = msg_fifo_pull(msg_fifo);
              notify(c);
            }
          }
        }
        else {
          xlog_end_client_connection(client_chanend);
          len = 0;
        }
        break;
      }
  }
  return;
}

