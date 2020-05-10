;5
.model small
.stack 100h
.data
    first_number db 7,0,7 dup('$') 
    second_number db 7,0,7 dup('$')
    
    first_num dw 0
    second_num dw 0 
    
    summa dw 0
    raznost dw 0 
    proizved dw 0
    chastnoe dw 0 
    ostatok dw 0
    and_num dw 0
    or_num dw 0
    xor_num dw 0
    
    string db 'Enter number:',0dh,0ah,'$' 
    string_of db 'Overflow',0dh,0ah,'$'
    string_of_sum db 'Summa is Overflow',0dh,0ah,'$'
    string_of_raz db 'Raznost is Overflow',0dh,0ah,'$'
    string_of_pro db 'Proizved is Overflow',0dh,0ah,'$'
    string_new db 'Please enter new',0dh,0ah,'$' 
    string_div_zero db 'Dividing by zero impossible',0dh,0ah,'$'
    string_ne_cifra db 'V stroke sodersh ne cifra',0dh,0ah,'$'    
    string_n db 0dh,0ah,'$'
    
    string_s db 'SUMMA=$'
    string_r db 'RAZNOST=$'
    string_p db 'PROIZVEDENIE=$'
    string_ch db 'CHASTNOE=$'
    string_os db 'OSTATOK=$'
    string_and db 'AND=$'
    string_or db 'OR=$'
    string_xor db 'XOR=$' 
    string_not db 'NOT=$'
.code
;;;;;;;;;;;;;;;;;;INPUT;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
input proc
st_new:    
    mov ah,0ah;schitivaem stroku
    mov dx,bx;adres dx-kuda zapisivaem
    int 21h
    
    xor cx,cx
    mov cl,[bx+1];v cl nasha dlina
    
    push bx;bx - ukazivaet na nchalo nashego chisla
    add bx,2
    add bx,cx
    mov [bx],36;zapisivaem vmesto 0dh v poslednii simvol '$'
    pop bx
    
    call atoi;perevodim stroku v chislo
    cmp cx,13;esli 13 znachit v atoi bilo perepolnenie ili  e cifra->vvod znogo
    je st_new
    ret
input endp 
;;;;;;;;;;;;;;;;;;ATOI;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
atoi proc
    ;bx=10,dx-cifra,ax-result,
    ;di - ukazivaet na nachalo stroki
    push bx
    mov di,bx
    add di,2
    
    xor ax,ax
    xor bx,bx
    xor cx,cx
    
    mov bx,10
    
    cmp [di],'-'      ;soxranayem znak v cx i v konce sdelaen neg esli nado budet
    jne positive
    
otric:
    mov cx,1
    push cx  
    inc di
    jmp my_loop  
      
positive:
    mov cx,0;positive
    push cx
    jmp my_loop
        
my_loop:
    imul bx;ax=ax*10
    
    jo pere;proverka na perepolnenie pri umnoshenii
    
    xor dx,dx;v dx pomeshaem cifru
    mov dl,[di]
    call cifra;proverka yavlaetsa simvol cifroi
    ;esli posle etogo cx=1 to znacit v stroke bila ne cifra
    cmp cx,1
    je ne_cifra_end
    sub dl,'0'
    add ax,dx
    jo pere;proverka na perepolnenie pri add
    
    inc di
    cmp [di],'$';proverka na konec stroku
    je gotovo
jmp my_loop
;;
ne_cifra_end:
    pop cx
    mov cx,13   
    pop bx
    output string_n
    output string_ne_cifra
    ret
pere: 
    pop cx
    mov cx,13
    pop bx
    output string_n
    output string_of 
    output string_new
    ret   
gotovo:
    pop cx
    cmp cx,1
    jne return
    neg ax; ax=-ax   
return:
    pop bx
    ret   
atoi endp
;;;;;;;;;;;;;;;;;;PROVERKA NA CIFRU;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
cifra proc
    ;v dl nasha cifra
    cmp dl,30h;-|
    jb ne_cifra;-|proverka simvola chtobi popadal ot [30h;39h]
    cmp dl,39h;-|
    ja ne_cifra
    mov cx,0
    ret
ne_cifra:
    mov cx,1        
    ret
cifra endp 
;;;;;;;;;;;;;;;;;;;;TO_STRING;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to_string proc ;v ax nashe chislo
    xor cx,cx
    mov bx,10

    test ah,80h
    js out_minus
    jmp again
out_minus: 
    push ax
    mov ah,02h
    mov dl,'-'
    int 21h
    pop ax
    neg ax
again:
    sub dx,dx
    div bx
    inc cx
    push dx
    cmp ax,0
    jne again
loop_output:
    pop dx
    add dx,30h
    cmp dx,39h
    jle no_more_9
    add dx,7
no_more_9:
    mov ah,2
    int 21h
    loop loop_output:
      
    ret
to_string endp
;;;;;;;;;;;;;;;;;ADD PROC;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
add_proc proc
    xor ax,ax
    mov ax,first_num
    add ax,second_num
    ;flag SF vsegda raven starshemy bitu result
    ;flag OF za perepolnenie  
    jo over
    mov summa,ax
    ret
over:
    ;output string_n
    output string_of_sum    
    ret
add_proc endp
;;;;;;;;;;;;;;;;;;SUB PROC;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
sub_proc proc
    xor ax,ax
    mov ax,first_num
    sub ax,second_num
    jo over_s
    mov raznost,ax
    ret
over_s:
    output string_n
    output string_of_raz
    ret   
sub_proc endp  
;;;;;;;;;;;;;;;;;;;;MUL PROC;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mul_proc proc 
    xor ax,ax
    mov ax,first_num
    mov bx,second_num
    imul bx
    jo pro_o
    mov proizved,ax
    ret            
pro_o:
    output string_of_pro
    ret   
mul_proc endp  
;;;;;;;;;;;;;;;DIV PROC;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
div_proc proc 
    xor ax,ax
    xor cx,cx
    
    mov ax,first_num;to chislo kotoroe delim(delimoe)
    cwd;raschiraem dw do dd
    mov cx,second_num ;delitel 
    cmp cx,0;sravnenie delitela s nulem
    je zero
    idiv cx;delim v ax celoe dx ostatok
    mov chastnoe,ax
    mov ostatok,dx    
    ret
zero:
    output string_div_zero
    ret
div_proc endp
;;;;;;;;;;;;;;;;;AND PROC;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
and_proc proc
    xor ax,ax
    xor bx,bx
    
    mov ax,first_num
    mov bx,second_num
    
    and ax,bx
    
    mov and_num,ax
       
    ret
and_proc endp
;;;;;;;;;;;;;;;;OR PROC;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
or_proc proc
    xor ax,ax
    xor bx,bx
    
    mov ax,first_num
    mov bx,second_num
    
    or ax,bx
    
    mov or_num,ax
        
    ret
or_proc endp 
;;;;;;;;;;;;;;;;;;;XOR PROC;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   
xor_proc proc
    xor ax,ax
    xor bx,bx
    
    mov ax,first_num
    mov bx,second_num
    
    xor ax,bx
    
    mov xor_num,ax
    
    ret
xor_proc endp    
;;;;;;;;;;;;;;;;;;;NOT PROC;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
not_proc proc    
    not ax    
    ret
not_proc endp
;;;;;;;;;;;;;;;;;;;OUTPUT macro;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
output macro str
    mov ah,9 
    mov dx,offset str
    int 21h
    xor ax,ax
endm   
;;;;;;;;;;;;;;;;;;;START;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
start:
    mov ax,@data
    mov ds,ax    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
    output string    
    lea bx,first_number
    call input
    mov first_num,ax        
    output string_n    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    output string        
    lea bx,second_number
    call input
    mov second_num,ax
    output string_n      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;        
call add_proc    
    mov ax,summa
    push ax
    output string_s 
    pop ax
    call to_string     
    output string_n        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;         
call sub_proc
    mov ax,raznost 
    push ax         
    output string_r
    pop ax
    call to_string
    output string_n  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;         
call mul_proc
    mov ax,proizved 
    push ax
    output string_p
    pop ax      
    call to_string     
    output string_n 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
call div_proc
    mov ax,chastnoe 
    push ax
    output string_ch
    pop ax      
    call to_string
    output string_n
    mov ax,ostatok
    push ax
    output string_os  
    pop ax
    call to_string
    output string_n 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
call and_proc
    mov ax,and_num
    push ax
    output string_and
    pop ax
    call to_string
    output string_n 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
call or_proc
    mov ax,or_num
    push ax
    output string_or
    pop ax
    call to_string
    output string_n 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
call xor_proc 
    mov ax,xor_num
    push ax
    output string_xor
    pop ax
    call to_string
    output string_n
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    output string_not
    mov ax,first_num
    call not_proc
    call to_string
    output string_n  
    
    output string_not
    mov ax,second_num
    call not_proc
    call to_string
    output string_n 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to_end:    
    mov ah,4ch
    int 21h   
end start
