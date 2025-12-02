org 0x7C00
bits 16

%define ENDL 0x0D,0x0A

jmp short start
nop

bdb_oem: db 'MSWIN4.1' ;8bytes
bdb_bytes_per_sector: dw 512  ;512 bytes per sector
bdb_sectors_per_cluster: db 1 ;1 sector per cluster
bdb_reserved_sectors: dw 1 ;1 reserved sector
bdb_fats: db 2 
bdb_dir_entries_count: dw 0E0
bdb_total_sectors: dw 2880
bdb_media_descriptor: db 0F0h
bdb_sectors_per_fat: dw 9
bdb_sectors_per_track: dw 18
bdb_heads: dw 2
bdb_hidden_sectors: dd 0
bdb_large_sectors_count: dd 0

ebr_drive_number: db 0
                  db 0 ;reserved
ebr_signature: db 29h
ebr_volume_id: db 12h, 34h, 56h, 78h
ebr_volome_label: db 'NANOBYTE OS'
ebr_system_id: db 'FAT12   '



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
   
    ;read something from the diskfrom floppy disk
    mov[ebr_drive_number],dl
    mov ax,1 ;LBA=1
    mov cl,1 ;number of sectors
    mov bx,0x7E00   ;data transfer from bootloader
    call_disk_read

    ;print messahe
    mov si,msg_hello
    call puts

    cli
    hlt

;Error handlers
floppy_error:
    mov si,msg_read_failed
    call puts
    jmp wait_key_and_reboot

wait_key_and_reboot:
    mov ah,0
    int 16h ;wait for the keypress
    jmp 0FFFFh:0 ;jump to the BIOS reset vector

.halt:
    cli ;disable interrupts
    hlt



;disk routines

;Converts LBA addsress to CHS
;params:
;   - ax: LBA address
;Returns:
;   - cx: [0-5]head 
;   - cx: [6-15]
;   -dh.head
lba_to_chs:
    push ax 
    push dx


    xor dx,dx       ;dx=0
    div word [bdb_sectors_per_track] ; ax=dx=LBA

    inc dx
    mov cx,dx


    xor dx,dx
    div word [bdb_heads] ; ax=dx=LBA
    mov dh,dl 
    mov ch,al
    shl ax,6
    or cl,ah

    pop ax
    mov dl,al
    pop ax
    ret

;Reads from a disk
;params:
;   - ax: LBA address
;   - cl :number of sectors
;   - dl: drive number
;   - ex:bl:

disk_read:

    push ax ;save all the registerswill modify
    push bx
    push cx
    push dx 
    push di

    push cx        ;temporarily save cl
    call lba_to_chs ;compute CHS
    pop ax ;al
    mov ah, 02h
    mov di,3    ;retry count


.retry:
    pusha  ;save all of them to the stack
    stc ;carry flag

    int 13h     ;carry flag clear==sucess
                ;floppy disks arnt reliable in real world
    jnc .done

    ;failed
    popa
    call disk_reset

    dec di
    test di,di
    jnz .retry

.fail:
    jmp floppy_error

.done:
    popa

    pop ax 
    pop bx
    pop cx
    pop dx 
    pop di ;restore register modified
    ret

;disk_reset:
;params:
;   - dl: drive number

disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc floppy_error
    popa
    ret



msg_hello: db 'Hello_worrld!',ENDL,0
msg_read_failed db'Read failed!',ENDL,0


times 510 - ($ - $$) db 0
dw 0AA55h