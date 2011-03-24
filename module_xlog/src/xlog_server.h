// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef _xlog_server_h_
#define _xlog_server_h_

#include <xs1.h>
#include "xlog_fifo.h"
/**
 * Change this define if you want to run the server on a different
 * core to node_id 0, core 0
 */
#define XLOG_NODECOREID 0
#define XLOG_CHANID 0x1F
#define XLOG_SERVER_CHANEND ((XLOG_NODECOREID << 16) | XLOG_CHANID << 8 | 0x02)

// supported UART Baud Rates
#define UART_2400   2400
#define UART_4800   4800
#define UART_9600   9600
#define UART_14400  14400
#define UART_19200  19200
#define UART_38400  38400
#define UART_57600  57600
#define UART_115200 115200
#define UART_230400 230400
#define UART_460800 460800
#define UART_921600 921600

// UART Baud rate.
#define XLOG_UART_BAUD_RATE   (UART_115200)

/**
 *  This value determines how long after startup the server will delay
 *  output over uart. During this period messages will be buffered.
 */ 
#define INITIAL_UART_DELAY 100000000

/**  The xlog uart server. 
 *
 *    \param uart_tx the uart output port
 *
 *   If the server is running on the correct core. It will redirect
 *   all i/o functions to go over the uart connection.
 **/
void xlog_server_uart(port uart_tx);


/** The xlog server (outputting over a channel).
 *
 *  \param c the channel to output chars on
 *
 *  If the server is running on the correct core. It will redirect
 *  all i/o functions to go over the given channel. Outputting characters
 *  one at a time as integers.
 **/
void xlog_server_chan(chanend c);


/**  The xlog uart and channel server. 
 *
 *    \param uart_tx the uart output port
 *
 *   If the server is running on the correct core. It will redirect
 *   all i/o functions to go over the uart connection.
 **/
void xlog_server_uart_chan(port uart_tx, chanend c);


#endif // _xlog_server_h_
