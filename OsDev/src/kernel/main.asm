org 0x7C00
bits 16

%define ENDL 0x0D,0x0A

start:
    jmp main

;
;Prnt a message to the screen
;params:
;   - ds:si pointer to the string
;

puts:
    ;save registers we will modify
    push si
    push ax


.loop:
    lodsb       ;load byte at ds:si into al
    or al,al    ;verify if al is 0
    jz .done
    mov ah,0x0e
    ;mov bh,0   ;a if thing if the program doesnt work
    int 0x10
    jmp .loop 

.done
    pop ax
    popsi
    ret



main:


    ;Set up data segments
    mov ax,0    ;can't write to ds/es directly
    mov ds,ax
    mov es,ax

    ;Set up stack
    mov ss,ax
    mov sp,0x7C00   ;stack grow downwards from where we are located in the memory
   
    ;print messahe
    mov si,msg_hello
    call puts

    hlt

.halt:
    jmp .halt

msg_hello: db 'Hello_worrld!',ENDL,0

times 510 - ($ - $$) db 0
dw 0AA55h