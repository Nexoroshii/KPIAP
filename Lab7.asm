.model tiny
.code
    org 80h						;смещение 80h от начала PSP
    cmd_length db ?				;длина командной строки
    cmd_line db ?				;командная строка
    org 100h					;смещение сегмента кода на 100h, СОМ-программа
start:


	
	mov ah,9
    lea dx, work[2]
    int 21h

    cld
    mov bp, sp
    mov cl, cmd_length
    cmp cl, 1         			;проверка длины командной строки
    jle dotcha         			;выход из программы


	
    mov cx, -1
    mov di, offset cmd_line    	;начало командной строки

;получаем второй параметр - кол-во раз, кот-е нужно запустить
next_param:           			;пропускаем первые пробелы
    mov al,' '
    repe scasb
    dec di
    inc word ptr argc
    mov si, di        			;устанавливаем в si текущее смещение командной строки
    mov di, offset number
scan_param:
    cmp [si],0Dh      			;проверяем на конец строки
    je param_ended
    cmp [si],20h      			;проверяем на пробел
    je param_ended
    movsb
    jmp scan_param
param_ended:
    mov byte ptr [si],0     	;устанавливаем в конец строки 0

    mov si, offset number
string_to_num:
    xor dx,dx   
loop_:    
    xor ax,ax
    lodsb       
    test al,al 
    jz  ex
	cmp al, '-'
	je errorNumber
    cmp al,'9'  
    jnbe  loop_
    cmp al,'0'       
    jb    loop_
    sub ax,'0' 
    
    push ax
    mov ax, dx
    mov dx, 10
    mul dx
    mov dx, ax
    pop ax 
    add dx, ax  
    jmp  loop_
ex:     
    mov ax,dx  

	
    mov num, ax
    
	cmp num, 0
	je errorNumber

	cmp num, 255
	ja errorNumber
    
    ;перемещение стека на 200h после окончания сегмента программы
    mov sp, program_length+100H+200H ; перемещение стека на 200h
    ; после конца программы (дополнительные 100h - для PSP)

    
    mov ah, 4Ah
    stack_offset = program_length+ 100h + 200h
    mov bx, stack_offset shr 4 + 1     	; размер в параграфах + 1
    int 21h ; освободим всю память после конца программы и стека

    ; заполняем поля структуры EPB которые содержат сегментные адреса    
    mov ax,cs
    mov word ptr EPB+4,ax   			; сегмент командной строки
    mov word ptr EPB+8,ax     			; сегмент первого FCB
    mov word ptr EPB+0Ch,ax    			; сегмент второго FCB

    mov cx, num    						; количество запусков программы
	
cycle:
    call incNumber
	call printNumber
	
    mov ax,4B00h						; функция DOS 4Bh
    mov dx, offset comand_name[2]		; начало командной строки, путь к файлу
    
    mov bx, offset EPB					; блок EPB
    int 21h             				; запустить программу
    jnc next							; в случае ошибки – вывод сообщения
    mov ah,9
    lea dx, error
    int 21h
	
next:
    call printNumber
    loop cycle



exit:
    int 20h								; выход из программы 20 прерывание, т.к. стек перемещен, ret нельзя - стек перемещен


errorNumber:
	
	mov ah, 09h
	lea dx, errorNumberStr[2]
	int 21h
dotcha:	
	mov ah, 4Ch
	int 21h

incNumber PROC

    
    push ax 
	push bx
	push cx
	push dx
	
    
	inc print_number[10]
	inc buffer
	cmp buffer, 10
	jne enpProc
	mov buffer, 0
	mov print_number[10], '0'
	inc print_number[9]
	mov ah, print_number[9]
	cmp ah, ':'
	jne enpProc
	mov print_number[9], '0'
	inc print_number[8]
	
enpProc:	
	
	pop dx 
	pop cx
	pop bx
	pop ax
	
	ret
ENDP

printNumber PROC
    push ax 
	push bx
	push cx
	push dx
	

    mov ah, 9                                 
    mov dx,offset print_number[2]
    int 21h

		pop dx 
	pop cx
	pop bx
	pop ax
	ret
ENDP


error db "error",10,13,'$'     ;сообщение об ошибке
EPB dw 0000                    ;текущее окружение
dw offset commandline,0        ;адрес командной строки
dw 005Ch,0,006Ch,0             ;адреса FCB программы
commandline db 125             ;длина командной строки
db " /?"                       ; командная строка (3)
print_number db "Proc: 000", 0Dh, 0Ah, '$' 
command_text db 122 dup(?)     ; командная строки (122)
work db "Work     ",10,13,'$'
errorNumberStr db "Error command line",10,13,'$'
programm db 80 dup(0)  
number db 80 dup(0)
num dw 0
argc dw 0
buffer       db 0
;
comand_name db "LR7.com"
program_length equ $-start     ; длина программы
end start
