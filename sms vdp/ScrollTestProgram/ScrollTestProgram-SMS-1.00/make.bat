@echo off
tasm -80 -f00 -b test.asm test.sms
del *.lst
