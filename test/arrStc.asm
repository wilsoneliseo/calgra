	; descripcion:
	;        Utilizacion de estructuras en NASM. Se guarda, en un
	;        array de estructuras, 5 puntos (x,y)=(1,2). Luego
	;        estos 5 puntos se imprimen en pantalla. Los valores
	;        (x,y) debe ser de un byte ya que se guarda en un
	;        buffer de dos bytes. El primer byte contiene el valor
	;        de la coordenada (ascii) en si y el otro guarda el
	;        caracter '$'. Esto es para formar una cadena que
	;        luego se imprime en pantalla.
	; comando:
	;        nasm -f bin -o arrStc.com arrStc.asm
	;        
	; comando make:
	;        make arrStc
	;
	;
struc Point                         ; definicion de estructura
.x: resb 1 
.y: resb 1
.size:
endstruc

; macro que coloca el argumento que se le pasa en el primer byte de
; 'buff'. Esto es para formar una cadena. Antes de imprimir, el
; segundo byte de 'buff' debe tener el caracter '$'.
%macro print_string 1
	mov byte[buff], %1	;buff[0]=%1
	mov dx, buff
	call print
%endmacro
	

section .data
	
p:				;declarar una instancia de Point e
istruc Point			;inicializar los campos 
at Point.x, db 5
at Point.y, db 7
iend   

	
section .bss
pArr: 	resb Point.size*5           ; reservar espacio para 5 estructuras
.len:	equ ($ - pArr) / Point.size ; pArr.len=5
buff: resb 2

[bits 16]
[cpu 8086]
org 100h	
section .text
	mov byte[buff+1],'$'	;buff[1]='$'
	
	; --------------------------------------------------
	;  ESCRIBIENDO LOS CINCO PUNTOS EN LAS ESTRUCTURAS
	; --------------------------------------------------
	mov  cx, pArr.len
	mov  si, pArr 
L1:     mov al,'1'		;x
	mov  [si + Point.x], al	;alamacenar en STRUC
	mov al,'2'		;y
	mov  [si + Point.y], al	;alamacenar en STRUC
	add  si, Point.size	;avanzar, el registro SI, para el
				;proximo punto
	loop L1			;realizar esto pArr.len=5 veces 


	; --------------------------------------------------
	; IMPRIMIR LAS CINCO ESTRUCTURAS EN LA PANTALLA
	; --------------------------------------------------
	mov  cx, pArr.len
	mov  si, pArr
L2:     mov  al, [si + Point.x]	;obtener x-coord
	print_string al		;imprimir x-coord
	print_string ' '	;espacio entre valores x/y
	mov  al, [si + Point.y]	;obtener y-coord
	print_string al		;imprimir y-coord
	print_string 13		;imprimir retorno de carro
	print_string 10		;imprimir nueva linea
	add si, Point.size	;obtener el proximo punto
	loop L2			;realizar esto pArr.len=5 veces
	
	ret

print: ; imprime la cadena a la que apunta dx y que termina en '$'
	push ax			; preservar ax 
    	mov ah,09h      	; funcion 9, imprimir en pantalla
    	int 21h         	; interrupcion dos
	pop ax			; restaurar ax
	ret             	; return
	
