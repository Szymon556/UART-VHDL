# UART VHDL Implementation

A configurable UART controller implemented in VHDL for FPGA-based systems.  
The design supports selectable data width, parity bits, stop bits, and multiple baud rates.

## Features

- Written in VHDL (RTL level)
- Selectable data width:
  - 7-bit
  - 8-bit
- Configurable parity:
  - none
  - even
  - odd
- Configurable stop bits
- Supported baud rates:
  - 9600
  - 115200
- Designed for FPGA integration

## Architecture

The design is divided into several modules:

- `uart_tx.vhd` – UART transmitter
- `uart_rx.vhd` – UART receiver
- `baud_gen.vhd` – baud rate generator
- `top.vhd` – top-level integration module

## Frame format

The UART frame supports configurable parameters:

- Start bit
- 7 or 8 data bits
- Optional parity bit
- Configurable stop bits

## Usage

The module can be integrated into FPGA projects requiring serial communication.  
Configuration parameters such as baud rate, data width, parity, and stop bits can be selected during synthesis.


