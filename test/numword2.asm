	; |- descripcion :: contiene funciones para entrada y salida
	; |- comando :: tiene dependencias, verificar makefile
	; |- comando make :: =make numword2=
	; |- autor :: Wilson S. Tubín


	; |Para emacs.
	; |- Ver estructura del codigo ::
	; |  + De nasm-mode a org-mode. Con `C-M-%´ hacer:
	; |    1. `[[:blank:]]*;[[:blank:]]*\(\*+\)´ -> `\1´
	; |    2. activar el modo con `M-x org-mode´
	; |  + De org-mode a nasm-mode. Con `C-M-%´ hacer:
	; |    1. `^\(\*+\)´ -> `	; \1´
	; |    2. activar modo nasm con `M-x nasm-mode´
	; |
	; |- Probar este archivo :: DESCOMENTAR las lineas terminadas en
	; |          con `;[test]´. En el editor emacs puede hacerse
	; |          esto sustituyendo (C-M-%) ER1 por ER2
	; |          ER1= `;\(.+\);\(\[test\]\)$´ -> ER2 = `\1;\2´
	; |
	; |          para volver a COMENTAR estas lineas,
	; |          sustituir ER3 por ER4:
	; |          ER3= `\(.+\);\(\[test\]\)$´ -> ER4 = `;\1;\2´



	; ==================================================
	; * i'' INCLUSIONES
	; ==================================================
%include "stack_frame.mac"
%include "io.mac"
	
	; ==================================================
	; * se'' SEGMENTO EXTRA (ES)
	; ==================================================
section .bss
SZ_BUFF_INPUT_TEXT: equ 40	;acepta 40 caracteres como maximo


	; ==================================================
	; * sdd'' SEGMENTO DE DATOS
	; ==================================================
section .data

buffInput: db SZ_BUFF_INPUT_TEXT+1
	times SZ_BUFF_INPUT_TEXT+1 db '$'
	
	; ==================================================
	; * sdc'' SEGMENTO DE CODIGO
	; ==================================================
[bits 16]			;[test]
[cpu 8086]			;[test]
org 100h 			;[test]
section .text
	
	; leer cadena y luego imprimirlo en pantalla
	LIMPIAR_PANTALLA	;[test]
	READ_FOR_BUFF_INPUT 1,2, buffInput ;[test]

	UBICAR_CURSOR 3,2	  ;[test]
	mov di,buffInput	  ;[test]
	inc di			  ;[test]
	mov cl,[di]		  ;[test]
	inc di			  ;[test]
	call convNumStrParaNumBin ;[test]
	add ax,10		  ;[test]
	call printNumBin	  ;[test]

	GETCHAR			;[test]
	TERMINAR_PROGRAMA	;[test]



	
	; ** convNumStrParaNumBin
	; |Convertir numero en string a numero en binario para el
	; |manejo interno como cantidad de la representacion numerica
	; |de la cadena.
	; |+ Entradas
	; |  - di :: puntero al primer elemento del arreglo de
	; |          caracteres (cadena) a convertir
	; |  - cl :: tamaño de la cadena apuntada por di
	; |
	; |+ Salida
	; |  - ax :: el numero de 1 word en binario. En complemento a
	; |          dos si es negativo.
	; |
	; |+ Variable local
	; |  - [BP-2] :: variable temporal (temp) que guarda la cantidad que
	; |              finalmente se guarda en ax al terminar el
	; |              proceso 
convNumStrParaNumBin:
	PROLOGO 1		;|n es numero de caracteres del string
	cmp cl,0		;|if(n==0)
	je .return		;|   return;

	mov word[bp-2],0	;|temp=0
	mov bx,0		;|i=0

	; ignorar signo positivo
	cmp byte[di],'+'	;|if(di[0]=='+')
	jne .continuar		;|  i=1;  n--;
	mov bx,1		;|else
	dec cl			;|  jmp .num
.continuar:
	
	; ignorar signo negativo	
	cmp byte[di],'-'	;|if(di[0]=='-')
	jne .num		;|  i=1;  n--;
	mov bx,1		;|else
	dec cl			;|  jmp .num
.num:
	mov ax,10		;|temp=temp*10
	mov dx,word[bp-2]
	mul dx			;DX:AX=DX*AX
	mov word[bp-2],ax       ;guardar resultado multiplicacion

	mov al, byte[di+bx]	;al=di[i]
	and ax,000Fh		;cambiar de valor ascii a numero
	mov dx,word[bp-2]
	add ax,dx
	mov [bp-2],ax
.next:
	inc bx			;i++
	LOOP .num

	mov bl,byte[di]		;ver si cadena es negativa
	cmp bl,'-'
	jne .return		;salta si bl distinto a '-'
	neg ax			;complemento a dos
	mov word[bp-2],ax
.return:
	EPILOGO 0


	
	; ** printNumBin
	; |Imprimir numero binario en la salida estandar
	; |+ Entradas
	; |  - ax :: el numero binario (word) a imprimir
	; |+ Salidas
	; |  - vacio :: nada
printNumBin:
	mov bx,0		;i=0
	cmp ax,0
	jl .negativo;salta si vleft <vright (considera # con signo)
	
	; ---- colocar en pila los ascii (# positivo) ----
.do:
	mov cx,10
	xor dx,dx		;DX=0
	div cx			;AX=(DX:AX)/CX=(DX:AX)/10 | DX=residuo
	or dx,0x0030		;poner residuo en ascii
	push dx			;meter a pila el ascii
	inc bx			;i++
	cmp ax,0		;si cociente es cero finaliza conversion
	JNE .do

	; ---- sacar los ascii de la pila e ir imprimiendo ----
	mov cl,bl		;bl aun contiene el tamaño
.for:
	pop dx			;recuperar ascii
	PRINT_CHAR dl
	LOOP .for
	jmp .return

.negativo:
	; imprimir signo menos protegiendo ax pues guarda el numero
	; binario a imprimir
	push ax
	PRINT_CHAR '-'
	pop ax
	neg ax			;complemento a dos
	jmp .do
.return:
	ret
