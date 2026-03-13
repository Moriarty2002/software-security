from pwn import *

context.arch='i386' # 32-bit version of x86
context.os='linux'

# First part of the payload
payload = b"711626734\n"

with open("./pat_on_back_payload", "wb") as f:
 f.write(payload)
