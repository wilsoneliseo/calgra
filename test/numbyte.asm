	;; descripcion:
	;; 
	;;      Opera dos numeros (+,-,/,*), positivos o negativos,de
	;;      un byte utilizando internamente el complemento a dos
	;;      para la representacion de números negativos. Por lo
	;;      tanto solo maneja numeros entre -128 a 127. Para
	;;      probar alguna operacion (+,-,/,*), descomentarla en el
	;;      paso 4, compilar y luego correr el ejecutable.
	;;      
	;; comando:
	;; 	nasm -f bin -o numbyte.com numbyte.asm
	;; comando make:
	;; 	make numbyte

%macro PRINT 1
	mov ax, %1
	push ax
	call print
%endmacro	

%macro UBICAR_CURSOR 2
	mov ax, %1
	push ax
	mov ax, %2
	push ax
	call ubicarCursor
%endmacro	
	
section .bss	
SZ_BUFF_INPUT_TEXT: equ 40	;acepta 40 caracteres como maximo
SZ_BUFF_INPUT_REAL: equ SZ_BUFF_INPUT_TEXT+2 ;2 porque la cadena comienza
	;en el tercer byte
buffInput: resb SZ_BUFF_INPUT_REAL

SZ_NUM_STRI: equ 6
numStr: resb SZ_NUM_STRI+3	;p/capacidad, p/num leidos y p/fin de cadena '$'
	
section .data
msjInicio: db 'OPERACION DE DOS NUMEROS A y B','$'
msjNumA: db 'Ingrese numero A (puede ser negativo): ','$'
msjNumB: db 'Ingrese numero B (puede ser negativo): ','$'
msjRes: db 'Resultado: ','$'

numeroA: db 0			;numero A de un byte
numeroB: db 0			;numero B de un byte

[bits 16]
[cpu 8086]
org 0x100	
section .text
	mov byte[numStr],SZ_NUM_STRI

	call limpiarPantalla
	UBICAR_CURSOR 2,2
	PRINT msjInicio

	; Paso 1.Se guardarán en los byte's numeroA y numeroB de el
	; numero ingresado por teclado pero en formato binario o
	; hexadecimal como se quiera entender. Esto se consuma cuando
	; se llama a 'readNum'.
	UBICAR_CURSOR 5,5
	PRINT msjNumA
	mov ax,5
	mov bx,45
	mov si,numeroA
	call readNum

	UBICAR_CURSOR 10,5
	PRINT msjNumB
	mov ax,10
	mov bx,45
	mov si, numeroB
	call readNum

	
	; Paso 2. Ahora se recuperan de memoria numeroA y numeroB
	; para, posteriormente, realizar la operacion deseada.
	mov al,byte[numeroA]
	cbw;extender registro AL a AX considerando signo
	mov bl,byte[numeroB]

	; ============================================================
	; Paso 3. Realizando la operacion deseada. Hay nemonicos
	; especiales para que consideran el signo de los numeros. Para
	; la multiplicacion es IMUL. Para la divicion es IDIV. Para la
	; suma es el normal SUM. Para la resta es el normal
	; SUB. Descomentar solo una operacion para probar:

	add al,bl
	; sub al,bl
	; imul bl ; AX=AL*BL
	; idiv bl ; AL=AX/BL | residuo en AH
	; ============================================================

	; paso 4. Convertir el resultado anterior, guardado en AL, en
	; caracteres ascii. A continuacion se mete a la pila (primer
	; parametro) como AX ya que la pila solo admite cifras de 16
	; bits.
	xor ah,ah
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

	UBICAR_CURSOR 15,5
	PRINT msjRes
	UBICAR_CURSOR 15,25
	mov si,numStr
	inc si 			;mover puntero al segundo elemento
	inc si			;mover puntero al tercer elemento		
	PRINT si		;imprimir
	
	call getChar		;esperara que se teclee algo
	
terminarPrograma:
	mov ah, 4Ch
	int 21h
	
	




	; Leer numero de la entrada estandar
	; 
	; entradas:
	;    - ax :: fila
	;    - bx :: columna
	;    - si :: direccion de 1 byte p/guardar el num
readNum:
	UBICAR_CURSOR ax,bx
	call readToInputBuff
	mov di,buffInput
	mov cl,[di+1]		;cl=buffInput[1]

	cmp cl,0
	je .return		;salta si se ingreso nada

	mov byte[si],0		;colocar a 0 el num
	mov bx,0		;i
.num:
	mov al,10
	mov dl,[si]		;dl=arrNumBin[0]
	mul dl
	mov [si],ax

	mov al,byte[di+2+bx]	;al=buffInput[2+i]
	cmp al,'-'
	je .next		;a proximo char ssi al='-'
	and al,0Fh
	mov dl,byte[si]		;dl=arrNumBin[0]
	add al,dl
	mov [si],al
.next:
	inc bx			;i++
	loop .num

	mov bl,byte[di+2]	;bl=buffInput[2]
	cmp bl,'-'
	jne .return		;salta si bl distinto a '-'
	neg al			;complemento a dos
	mov [si],al		;arrNumBin[0]=al
.return:
	ret

	

	; convertir numero binario en arreglo de chars ascii
	; entradas:
	;    - [bp+6] :: el numero binario (byte) a convertir
	;    - [bp+4] :: puntero al arreglo que guarda los chars
numToStr:;mov di,ax | mov si,numStr
	push bp
	mov bp,sp

	mov ax, [bp+6]		;ax=# a convertir
	cmp al,0
	jl .negativo		;salta si vleft <vright (considera # c/signo)
	
	; -------------------- colocar en pila los ascii (# positivo)
	mov bx,0
.do:
	mov cl,10
	div cl			;AL=AX/CX=AX/10 | AH=residuo
	or ah,30h
	push ax			;meter a pila el ascii
	xor ah,ah
	inc bx
	cmp al,0		;cociente=0 -> fin conversion
	jne .do

	mov si, [bp+4]		;puntero al arreglo q guarda los chars
	inc si			;mover hacia tamaño leido 	
	mov byte[si],bl		;guardar tamaño de cadena

	
	; ------------ sacar en la pila los ascii y ponerlo en SI
	inc si			;mover hacia donde inicia cadena
	mov cl,bl		;bl aun contiene el tamaño
	mov bx,0
.for:
	pop ax			;recuperar ascii
	mov byte[si+bx], ah
	inc bx
	loop .for
	mov byte[si+bx],'$'	;colocar para fin de cadena
	jmp .return


	
.negativo:
	; -------------------- colocar en pila los ascii (# negativo)
	; mov bx,255
	; sub bx, ax
	; inc bx
	; mov ax,bx
	neg al
	mov bx,0
.do2:
	mov cl,10
	div cl			;AL=AX/CX=AX/10 | AH=residuo
	or ah,30h
	push ax			;meter a pila el ascii
	xor ah,ah
	inc bx
	cmp al,0		;cociente=0 -> fin conversion
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
	pop ax			;recuperar ascii
	mov byte[si+bx], ah
	inc bx
	loop .for2
	mov byte[si+bx],'$'	;colocar para fin de cadena
.return:

	pop bp
	ret 4

	
	; lee cadena de entrada estandar y lo guarda en buffInput
	;
	; altera: ax,dx
readToInputBuff:
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
	
