.model tiny
.code
org 100h

start :
  jmp loader

newInt10:
  cmp ah, 0
  je here
  cmp ah, 0f0h
  je exit
  cmp ah, 15
  ja here
  jmp dword ptr [cs:oldInt10]
here:
  pushf
  call dword ptr [cs:oldInt10]
  push ax
  push dx

  mov dx, 3dah
  in  al, dx
  mov dx, 3c0h
  
  ;mov al, 0
  ;out dx, al
  ;out dx, al
  
  ;mov al, 1
  ;out dx, al
  ;out dx, al

  ;mov al, 2
  ;out dx, al
  ;out dx, al

  ;mov al, 3
  ;out dx, al
  ;out dx, al
  
  ;mov al, 4
  ;out dx, al
  ;out dx, al
  
  ;mov al, 5
  ;out dx, al
  ;out dx, al

  mov al, 6
  out dx, al
  mov al, 20
  out dx, al

  ;mov al, 7
  ;out dx, al
  ;out dx, al

  mov al, 8
  out dx, al
  mov al, 56
  out dx, al

  mov al, 9
  out dx, al
  mov al, 57
  out dx, al
  
  mov al, 10
  out dx, al
  mov al, 58
  out dx, al

  mov al, 11
  out dx, al
  mov al, 59
  out dx, al

  mov al, 12
  out dx, al
  mov al, 60
  out dx, al

  mov al, 13
  out dx, al
  mov al, 61
  out dx, al

  mov al, 14
  out dx, al
  mov al, 62
  out dx, al

  mov al, 15
  out dx, al
  mov al, 63
  out dx, al

  mov al, 020h
  out dx, al

  pop dx
  pop ax
  iret

exit:
  ; restore original int 10h
  cli
  xor ax, ax
  mov ds, ax
  mov ax, word ptr [cs:oldInt10]
  mov [ds:40h], ax
  mov ax, word ptr [cs:oldInt10+2]
  mov [ds:40h+2], ax
  sti

  ; unload env block
  mov ax, word ptr [cs:2ch]
  mov es, ax
  mov ah, 49h
  int 21h
  
  ; unload prg
  mov ax, cs
  mov es, ax
  mov ah, 49h
  int 21h
  
  iret

oldInt10:
  dw 0, 0

loader:
  xor ax,ax
  mov ds,ax
  cli
  mov bx, [ds:40h]
  mov word ptr [cs:oldInt10], bx
  mov word ptr [ds:40h], offset newInt10
  mov ax, [ds:40h+2]
  mov word ptr [cs:oldInt10+2], ax
  mov [ds:40h+2], cs
  sti
  mov dx, offset loader
  add dx, 15
  mov cx, 4
  shr dx, cl
  mov ax, 3100h
  int 21h

end start
