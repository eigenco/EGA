.model tiny
.code
  org 0100h
start:
  
  jmp loader

notMode:
  jmp dword ptr [cs:oldInt10]

oldInt10:
  dw 0, 0

skip:
  iret

newInt10:
  cmp ax, 0dh
  pushf
  call dword ptr [cs:oldInt10]

  push ax
  push dx
  
  mov al, 10100011b
  mov dx, 03c2h
  out dx, al

  pop dx
  pop ax
  iret

loader:
  xor ax, ax
  mov ds, ax
  cli
  mov bx, [ds:10h*4]
  mov word ptr [cs:oldInt10], bx
  mov word ptr [ds:10h*4], offset newInt10
  mov ax, [ds:10h*4+2]
  mov word ptr [cs:oldInt10+2], ax
  mov [ds:10h*4+2], cs
  sti
  mov dx, 32
  mov ax, 3100h
  int 21h

end start
