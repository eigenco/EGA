org 0x100

  jmp loader

newInt10:
  cmp ax,0x90
  jne notMode
  mov ax,0x8e
  pushf
  call far[cs:oldInt10]
  push ax
  push dx

  ; change video memory layout such that every other line is skipped
  ; i.e. scanline offset is 1280 pixels rather than 640
  ; (otherwise screen doesn't fit into regular NTSC display)
  mov al, 0x13
  mov dx, 0x3d4
  out dx, al
  mov al, 0x50
  mov dx, 0x3d5
  out dx, al

  ; set VSYNC- so 6 bit colors are available in capable monitors
  mov al, 10100011b
  mov dx, 03c2h
  out dx, al

  pop dx
  pop ax
  iret

notMode:
  jmp far[cs:oldInt10]

oldInt10:
  dw 0, 0

loader:
  xor ax,ax
  mov ds,ax
  cli
  mov bx,[0x10*4]
  mov [cs:oldInt10],bx
  mov word[0x10*4],newInt10
  mov ax,word[0x10*4+2]
  mov word[cs:oldInt10+2],ax
  mov [0x10*4+2],cs
  sti
  mov dx,loader
  add dx,0x0f
  mov cx,4
  shr dx,cl
  mov ax,0x3100
  int 0x21
