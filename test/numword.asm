	; |- descripcion :: Opera dos numeros (+,-,/,*), positivos o
	; |                 negativos,de un word utilizando
	; |                 internamente el complemento a dos para la
	; |                 representacion de números negativos. Por
	; |                 lo tanto solo maneja numeros entre -32768
	; |                 a 32767. Para probar alguna operacion
	; |                 (+,-,/,*), descomentarla en el paso 4,
	; |                 compilar y luego correr el ejecutable.
	; |- comando :: =nasm -f bin -o numword.com numword.asm=
	; |- comando make :: =make numword=
	; |- autor :: Wilson S. Tubín


	; |Para emacs.
	; |- Ver estructura del codigo:
	; |  + De nasm-mode a org-mode. Con `C-M-%´ hacer:
	; |    1. `[[:blank:]]*;[[:blank:]]*\(\*+\)´ -> `\1´
	; |    2. activar el modo con `M-x org-mode´
	; |  + De org-mode a nasm-mode. Con `C-M-%´ hacer:
	; |    1. `^\(\*+\)´ -> `	; \1´
	; |    2. activar modo nasm con `M-x nasm-mode´


	; ==================================================
	; * mml'' MACROS MULTI LINEA
	; ==================================================
%macro PRINT 3
	mov ax, %1		;fila
	push ax
	mov ax, %2		;columna
	push ax
	call ubicarCursor

	
	mov ax, %3		;puntero a cadena a imprimir
	push ax
	call print
%endmacro	

%macro READ_NUM 3
	mov ax,%1		;fila
	mov bx,%2		;columna
	mov si,%3		;direccion de 1 word
	call readNum
%endmacro	


	; ==================================================
	; * se'' SEGMENTO EXTRA (ES)
	; ==================================================
section .bss	
SZ_BUFF_INPUT_TEXT: equ 40	;acepta 40 caracteres como maximo
SZ_BUFF_INPUT_REAL: equ SZ_BUFF_INPUT_TEXT+2 ;2 porque la cadena comienza
	;en el tercer word
buffInput: resb SZ_BUFF_INPUT_REAL

SZ_NUM_STRI: equ 6
numStr: resb SZ_NUM_STRI+3	;p/capacidad, p/num leidos y p/fin de cadena '$'

	
	; ==================================================
	; * sdd'' SEGMENTO DE DATOS
	; ==================================================
section .data
msjInicio: db 'OPERACION DE DOS NUMEROS A y B','$'
msjNumA: db 'Ingrese numero A (puede ser negativo): ','$'
msjNumB: db 'Ingrese numero B (puede ser negativo): ','$'
msjRes: db 'Resultado: ','$'

numeroA: dw 0			;numero A de un word
numeroB: dw 0			;numero B de un word


	; ==================================================
	; * sdc'' SEGMENTO DE CODIGO
	; ==================================================
[bits 16]
[cpu 8086]
org 0x100	
section .text
	mov byte[numStr],SZ_NUM_STRI

	call limpiarPantalla
	PRINT 2,2, msjInicio

	; Paso 1.Se guardarán en los word's numeroA y numeroB de el
	; numero ingresado por teclado pero en formato binario o
	; hexadecimal como se quiera entender. Esto se consuma cuando
	; se llama a 'readNum'.
	PRINT 5,5, msjNumA
	READ_NUM 5,45,numeroA

	PRINT 10,5, msjNumB
	READ_NUM 10,45,numeroB
	
	; Paso 2. Ahora se recuperan de memoria numeroA y numeroB
	; para, posteriormente, realizar la operacion deseada.
	mov ax,word[numeroA]
	cwd;extiende AX en DX:AX considerando el signo
	mov bx,word[numeroB]

	; ============================================================
	; Paso 3. Realizando la operacion deseada. Hay nemonicos
	; especiales para que consideran el signo de los numeros. Para
	; la multiplicacion es IMUL. Para la divicion es IDIV. Para la
	; suma es el normal SUM. Para la resta es el normal
	; SUB. Descomentar solo una operacion para probar:

	add ax,bx
	; sub ax,bx
	; imul bx ; DX:AX=BX*AX
	; idiv bx ; AX=(DX:AX)/BX | residuo en DX
	; ============================================================

	; paso 4. Convertir el resultado anterior, guardado en AL, en
	; caracteres ascii. A continuacion se mete a la pila (primer
	; parametro) como AX ya que la pila solo admite cifras de 16
	; bits.
	push ax
	
	mov ax, numStr		;se mete a la pila (segundo
	;paramentro) el puntero al arreglo que guardara la cadena.
	push ax
	
	call numToStr		;llamar a rutina que convierte el
	;numero binario en arreglo de caracteres.


	; paso 5. Imprimir el arreglo de caracteres (cadena). Para
	; entender es preciso mostrar el formato de este arreglo de
	; caracteres (numStr). La llamada a 'numToStr' lo deja con el
	; siguiente formato:
	;
	;
;	      [numStr+1]
;		   /		  [numStr+2]
;  [numStr]	  /		       |
;      |      	 /   +-----------------+
;      | 	/    |
;      | 0     1     2	   3	 4     5     6	   7	 8
;     +-----+-----+-----+-----+-----+-----+-----+-----+-----+
;     |  6  |  3  |  1  |  2  |	 7  |  $  |     |     |	    |
;     |     |  	  |     |     |	    | 	  |     |     |	    |
;     +-----+-----+-----+-----+-----+-----+-----+-----+-----+
;
	; El PRIMER ELEMENTO del arreglo guarda la capacidad de digitos
	; que puede almacenar el arreglo sin tomar en cuenta el fin de
	; cadena '$'
	;
	; El SEGUNDO ELEMENTO tiene el tamaño de la cadena
	;
	; A partir del TERCER ELEMENTO inicia la cadena en si y
	; finaliza con el fin de cadena '$'
	;
	; De la ilustracion anterior se puede decir que: se puede
	; guardar un numero de 6 digitos (primer elemento). El tamaño
	; de la cadena es de 3 (segundo elemento). El numero
	; almacenado actualmente es 127 (puntero de inicio de cadena
	; en el tercer elemento)
	;
	; Ahora si, a imprimir la cadena del resultado.


	PRINT 15,5,msjRes
	mov si,numStr
	inc si 			;mover puntero al segundo elemento
	inc si			;mover puntero al tercer elemento		
	PRINT 15,25,si		;imprimir
	
	call getChar		;esperara que se teclee algo
	
terminarPrograma:
	mov ah, 4Ch
	int 21h
	
	




	; Leer numero de la entrada estandar
	; 
	; entradas:
	;    - ax :: fila
	;    - bx :: columna
	;    - si :: direccion de 1 word p/guardar el num
readNum:
	call readToInputBuff
	mov di,buffInput
	mov cl,[di+1]		;cl=buffInput[1]=tamaño cadena

	cmp cl,0
	je .return		;salta si se ingreso nada

	mov word[si],0		;colocar a 0 el num
	mov bx,0		;i
.num:
	mov ax,10
	mov dx,word[si]		;dx=numero a binario objetivo
	mul dx			;DX:AX=DX*AX
	mov word[si],ax		;guardar resultado multip en binario obj

	mov al,byte[di+2+bx]	;al=buffInput[2+i]
	cmp al,'-'
	je .next		;a proximo char ssi al='-'
	and ax,000Fh
	mov dx,word[si]
	add ax,dx
	mov [si],ax
.next:
	inc bx			;i++
	loop .num

	mov bl,byte[di+2]	;bl=buffInput[2]
	cmp bl,'-'
	jne .return		;salta si bl distinto a '-'
	neg ax			;complemento a dos
	mov word[si],ax		;arrNumBin[0]=al
.return:
	ret

	

	; convertir numero binario en un arreglo de chars ascii
	; 
	; entradas:
	;    - [bp+6] :: el numero binario (word) a convertir
	;    - [bp+4] :: puntero al arreglo que guarda los chars
numToStr:;mov di,ax | mov si,numStr
	push bp
	mov bp,sp

	mov ax, [bp+6]		;ax=# a convertir
	cmp ax,0
	jl .negativo		;salta si vleft <vright (considera # c/signo)
	
	; -------------------- colocar en pila los ascii (# positivo)
	mov bx,0
.do:
	mov cx,10
	xor dx,dx		;DX=0
	div cx			;AX=(DX:AX)/CX=(DX:AX)/10 | DX=residuo
	or dx,0x0030		;poner residuo en ascii
	push dx			;meter a pila el ascii
	inc bx
	cmp ax,0		;si cociente=0 -> fin conversion
	jne .do

	mov si, [bp+4]		;puntero al arreglo q guarda los chars
	inc si			;mover hacia tamaño leido 	
	mov byte[si],bl		;guardar tamaño de cadena

	
	; ------------ sacar en la pila los ascii y ponerlo en SI
	inc si			;mover hacia donde inicia cadena
	mov cl,bl		;bl aun contiene el tamaño
	mov bx,0
.for:
	pop dx			;recuperar ascii
	mov byte[si+bx], dl
	inc bx
	loop .for
	mov byte[si+bx],'$'	;colocar para fin de cadena
	jmp .return


	
.negativo:
	; -------------------- colocar en pila los ascii (# negativo)
	neg ax
	mov bx,0
.do2:
	mov cx,10
	xor dx,dx		;DX=0
	div cx			;AL=AX/CX=AX/10 | AH=residuo
	or dx,0x0030		;poner residuo en ascii
	push dx			;meter a pila el ascii
	inc bx
	cmp ax,0		;si cociente=0 -> fin conversion
	jne .do2

	mov si, [bp+4]		;puntero al arreglo q guarda los chars
	inc si			;mover hacia tamaño leido 	
	mov byte[si],bl		;guardar tamaño de cadena

	
	; ------------ sacar en la pila los ascii y ponerlo en SI (# positivo)	
	inc si			;mover hacia donde inicia cadena
	mov cl,bl		;bl aun contiene el tamaño
	mov byte[si],'-'	;colocar signo
	mov bx,1	
.for2:
	pop dx			;recuperar ascii
	mov byte[si+bx], dl
	inc bx
	loop .for2
	mov byte[si+bx],'$'	;colocar para fin de cadena
.return:

	pop bp
	ret 4

	
	; lee cadena de entrada estandar y lo guarda en buffInput
	; entradas:
	;    - ax :: fila
	;    - bx :: columna

readToInputBuff:
	push ax
	push bx
	call ubicarCursor

	mov byte[buffInput],SZ_BUFF_INPUT_REAL-1 ;-1 p/omitir retorno de carro
	; mov ah,0Ch ;limpiar buffer antes de llamar a 0Ah
	; mov al,0Ah
	mov ah,0Ah
	mov dx,buffInput
	int 21h
	ret

	

	
	; [bp+6] fila
	; [bp+4] columna
ubicarCursor:
	push bp
	mov bp, sp
	
        mov ah,02h              ;func. de ubic. del cursor
        mov dh,[bp+6]		;fila
        mov dl,[bp+4]		;columna
        mov bh,0                ;pag. #0
        int 10h

	pop bp
	ret 4

	; imprimir cadena
	; 
	; [bp + 4] puntero a cadena que termina en '$'
	; Salida: nada
print:
	push bp
	mov bp,sp

	mov dx, [bp+4]
    	mov ah,09h      	; funcion 9, imprimir en pantalla
    	int 21h         	; interrupcion dos
	
	pop bp
	ret 2

	; limpia la pantalla
limpiarPantalla:  
        mov ax,0600h         ;toda la pantalla
        mov bh,7             ;sigue video color normal
        mov cx,0000          ;vÇrtice superior izq.
        mov dx,184Fh         ;vÇrtice inferior derecho
        int 10h              ;llamada a BIOS
        ret


	; obtiene ascii de tecla resionada sin eco, via BIOS.
	; En AL se almacena el caracter leido 
getChar: 
	xor ah,ah		;colocar ah a 0
	int 16h
	ret
	
