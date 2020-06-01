.model small
.stack 200h

.data

file_path db 200 dup(0)

string db 200 dup(0)
cmd_string db 200 dup(0)

length dw 0

handle dw 0

symbol db 0




is_need_check_end_word db 0
is_skip_word db 0
is_find_any_word db 0
answer dd 0

file_open_error_str db "ERROR: Can't open input file", 10, 13, "$"
file_close_error_str db "ERROR: Can't close input file", 10, 13, "$"

short_cmd db "ERROR: Not enough command line arguments.", 10, 13, "$"
too_many_args_str db "ERROR: Provided to many arguments", 10, 13, "$"
error_reading_data db "ERROR: Cannot read data from file.", 10, 13, "$"  
 
answer_is_OVERFLAW db "ERROR: Cannot read data from file.", 10, 13, "$"  


answer_str db  0,0,0,0,0,0,0,0,'$'

.code

output_string macro current_string
    pusha
    
    mov ah, 09h
    lea dx, current_string
    int 21h
    
    popa        
endm

input_string macro current_string
    pusha
    
    xor di, di
    lea dx, current_string
    mov ah, 0Ah
    int 21h
    
    popa   
endm


open_file proc 
    pusha
    
    mov ah, 3Dh
    mov al, 00h
    mov dx, offset file_path
    int 21h
    jnc success_open_file
    output_string file_open_error_str 
    jmp end_of_programm
    success_open_file:
    mov handle, ax
        
    popa    
    ret
endp 

strlen proc
    pusha
    
    mov si, 0
    loop_strlen:
        cmp string[si], 0
        je go_end_strlen
        inc si
        jmp loop_strlen    
    go_end_strlen:
        mov length, si
    
    popa
    ret
endp

parse_cmd proc
    cld 							
	xor cx, cx
	mov cl, es:[0080h]
	mov ax, @data
	mov es, ax 
	cmp cl, 7
	ja go_next_parse_cmd 
	
	
	
	;mov ds, ax
	output_string short_cmd 	
	jmp end_of_programm
	
	go_next_parse_cmd:
	;inc cl
	mov di, offset cmd_string
	mov si, 81h
	push ax
	push es
	push di
	mov ax, ds
	mov es, ax
	mov di, si
	mov al, ' '
	repz scasb
	dec di
	inc cx
	inc cx
	mov si,di 
	pop di
	pop es
	rep movsb
	dec cx
	pop ax
	 
	mov ax, @data
	mov ds, ax
	
	
	mov di, 0
	mov si, 0
	xor bx, bx
	
	
	skip_spaces:
		cmp cmd_string[di], ' ' 					
		jne read_file_path
		inc di
		jmp skip_spaces 					
	
	read_file_path:
		cmp cmd_string[di], byte ptr 0dh 			
		je file_path_readen
		cmp cmd_string[di], byte ptr ' ' 			
		je file_path_readen

		mov bl, cmd_string[di]					
		mov file_path[si], bl
		inc di
		inc si
		jmp read_file_path

	file_path_readen:   				
	    mov si, 0 
	
	skip_spaces1:
		cmp cmd_string[di], ' ' 					
		jne read_string
		inc di
		jmp skip_spaces1 
	
	    
	read_string:
		cmp cmd_string[di], byte ptr 0dh 			
		je check_suffix
		
		cmp cmd_string[di], byte ptr ' ' 			
		je check_suffix 

		mov al, cmd_string[di]					
		mov string[si], al
		inc di
		inc si
		jmp read_string    
	    
	 check_suffix:
        cmp string[0], 0
        jne skip_spaces2
        output_string short_cmd 	
	    jmp end_of_programm
	    skip_spaces2:
		cmp cmd_string[di], ' ' 					
		jne check_end_cmd
		inc di
		jmp skip_spaces2     
    check_end_cmd:
	    cmp cmd_string[di], byte ptr 0dh
	    jne too_many_args 
	    jmp end_parse_cmd

	    too_many_args:
		output_string too_many_args_str
		jmp end_of_programm
		
	end_parse_cmd:
     
	ret
parse_cmd endp


read_symbol proc
    mov ah, 3Fh
    mov bx, handle
    mov cx, 1
    mov dx, offset symbol
    int 21h
    jc error_reading
    jmp end_read_symbol 
    error_reading:
        output_string error_reading_data 
        jmp call_close_file 
    end_read_symbol:
    ret

endp
    
end_of_line proc
    
    
    cmp is_need_check_end_word, 1
    jne  next_check
    mov is_find_any_word, 1
    next_check:
    cmp is_find_any_word, 0
    jne end_of_check_line
    
    inc answer
    
    jno end_of_check_line
    
    output_string answer_is_OVERFLAW
    jmp call_close_file
       
    end_of_check_line:
    mov di, 0
    mov is_need_check_end_word, 0
    mov is_skip_word, 0
    mov is_find_any_word, 0 
    ret
endp    

cheking_spaces proc
    cmp is_skip_word, 1
    je enc_of_checking_spaces
    cmp is_need_check_end_word, 1
    jne enc_of_checking_spaces   
    mov is_find_any_word, 1 
     
    enc_of_checking_spaces:
    mov di, 0
    mov is_need_check_end_word, 0
    mov is_skip_word, 0
    ret
endp

checking_one_symbol proc
    cmp is_skip_word, 1
    je end_of_checking_one_symbol
    
    
    
    cmp is_need_check_end_word, 1
    je not_correct
    
     
    
    
    check_current_symbol:
    mov bl, string[di]
    cmp bl, symbol
    jne not_correct
    
    inc di
    
    cmp di, length
    jne end_of_checking_one_symbol
    mov is_need_check_end_word, 1
    
    jmp end_of_checking_one_symbol
    
     
    
    not_correct:
        mov is_skip_word, 1
        mov is_need_check_end_word, 0  
    end_of_checking_one_symbol:
    
    ret
endp

close_file proc
	mov bx, handle
	mov ah, 3eh
	int 21h
	jnc end_close_file
	output_string file_close_error_str 		
	jmp end_of_programm
	end_close_file:	
    ret
endp


add_to_answer proc
    ;si - nomer
    ;bx - chislo
    
    cmp bx, 9
    jle add_30h
    jg add_31h
    add_30h:
        add bx, 30h
        jmp go_end_add_to_answer
    add_31h:
        add bx, 37h
    go_end_add_to_answer:
    mov answer_str[si], bl
    ret
endp

 
output_answer proc
   mov cx, 8
   mov si, 7
   cycle_output:
       
       mov bl, byte ptr answer
       and bl, 0Fh  
       shr answer, 4
       call add_to_answer
       dec si
   loop cycle_output      
   ret
endp


start:
    call parse_cmd 
    call open_file
    call strlen
   
   mov di, 0
    
   cycle:
        call read_symbol
        cmp ax, 0
        je end_cycle
        
        cmp symbol, 0Ah
        je go_next_symbol
        ;0Dh
        cmp symbol, 0Dh
        jne check_space
        
        call end_of_line
        jmp go_next_symbol 
        
        check_space:
        
        cmp symbol, ' '
        jne check_one_symbol
        
        call cheking_spaces  
        jmp go_next_symbol   
        
        check_one_symbol:
        
        call checking_one_symbol
        
        go_next_symbol: 
        jmp cycle
    
   end_cycle: 
   call end_of_line
    
   call output_answer 
   output_string answer_str 
    
    
    
    call_close_file:
        call close_file
    
    end_of_programm:
    mov ax, 4c00h
    int 21h  
    

end start
