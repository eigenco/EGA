.model tiny
.code
org 100h

start :
  mov ah, 0f0h
  int 10h
  int 20h

end start
