	; |- Descripción :: contiene funciones para escribir un
	; |                 polinomio en un archivo. La lógica es la
	; |                 misma que sus equivalentes de salida en
	; |                 stdout que estan en calgra.asm y
	; |                 anlex2.asm. De hecho se puede omitir este
	; |                 archivo haciendo cambios en dichos
	; |                 equivalentes, los cuales no fueron echos
	; |                 por cuestion de tiempo.
	; |
	; |- Autor :: Wilson S. Tubín
	
%define POS_CON_MAS 7		;positivo con signo mas
section .text


	
	; ** printPol_f
	; |Imprimir polinomio en archivo
	; |+ Parametros
	; |  - [BP+6] :: handle del archivo
	; |  - [BP+4] :: puntero al inicio del arreglo que contiene la
	; |              expresion polinomica
printPol_f:
	PROLOGO 0
	push cx			;protoger p/eventual llamada dentro loop
	push di
	push bx


	mov di,[bp+4]
	mov cl,byte[di+pol.n]
	mov bl,1
.lpol:
	cmp bl,1
	jne .coefb
	; primer coeficiente y exponente
	mov ax,word[bp+6]
	push ax			;handle
	mov ax,word[di+pol.Acoef]
	push ax
	mov al,byte[di+pol.aExpo]
	xor ah,ah
	push ax
	call printCoef_f
	jmp .break
	
.coefb:
	cmp bl,2
	jne .coefc
	; segundo coeficiente y exponente
	mov ax,word[bp+6]
	push ax			;handle
	mov ax,word[di+pol.Bcoef]
	push ax
	mov al,byte[di+pol.bExpo]
	xor ah,ah
	push ax
	call printCoef_f
	jmp .break

.coefc:
	cmp bl,3
	jne .coefd
	; tercer coeficiente y exponente
	mov ax,word[bp+6]
	push ax			;handle
	mov ax,word[di+pol.Ccoef]
	push ax
	mov al,byte[di+pol.cExpo]
	xor ah,ah
	push ax
	call printCoef_f
	jmp .break

.coefd:
	cmp bl,4
	jne .coefe
	; cuarto coeficiente y exponente
	mov ax,word[bp+6]
	push ax			;handle
	mov ax,word[di+pol.Dcoef]
	push ax
	mov al,byte[di+pol.dExpo]
	xor ah,ah
	push ax
	call printCoef_f
	jmp .break

.coefe:
	; quinto coeficiente y exponente
	mov ax,word[bp+6]
	push ax			;handle
	mov ax,word[di+pol.Ecoef]
	push ax
	mov al,byte[di+pol.eExpo]
	xor ah,ah
	push ax
	call printCoef_f
	

.break:
	inc bl
	LOOP .lpol


	pop bx
	pop di
	pop cx
	EPILOGO 2

	


	; ** printCoef_f
	; |Imprimir coeficiente en archivo
	; |+ Parametros
	; |  - [PB+8] :: handle del archivo
	; |  - [BP+6] :: coeficiente en binario (word)
	; |  - [BP+4] :: exponente en binario (byte)
printCoef_f:
	PROLOGO 0
	push cx			;proteger por eventual ejecucion
	;dentro ciclo con loop
	push bx

	; ini-impresion de coeficiente --------------------
	mov ax,POS_CON_MAS
	push ax			;se imprime '+' o no
	mov ax,word[bp+8]
	push ax			;handle
	mov ax,word[bp+6]	;ax es num a imprimir
	call printNumBin_f


	; impresion de exponente --------------------
	mov al,byte[bp+4]
	xor ah,ah
	cmp ax,0		;si exponente 0 no imprimir x^0
	je .expo0
	cmp ax,1		;si exponente 1 solo imprime x
	je .expo1

	mov ax,'x'
	push ax
	ESENAR word[bp+8],1,sp
	pop ax

	mov ax,'^'
	push ax
	ESENAR word[bp+8],1,sp
	pop ax
	


	; imprimir exponente
	mov ax,POS_CON_MAS-1
	push ax			;se imprime '+' o no
	mov ax,word[bp+8]
	push ax			;handle
	mov ax,word[bp+4]	;ax es num a imprimir
	xor ah,ah
	call printNumBin_f
	
	jmp .expo0
.expo1:
	mov ax,'x'
	push ax
	ESENAR word[bp+8],1,sp
	pop ax
.expo0:	
	
	pop bx
	pop cx
	EPILOGO 3



	
	; ** printNumBin_f
	; |Imprimir numero binario en archivo
	; |+ Parametro
	; |  - [BP+6] :: valor para saber si se quiere imprimir los
	; |              positivos anteponiendo un '+'. Si tiene el
	; |              valor de POS_CON_MAS se imprime el '+'
	; |  - [BP+4] :: handle del archivo
	; |+ Entradas
	; |  - ax :: el numero binario (word) a imprimir
	; |+ Variables locales
	; |  - [BP-2] :: un temporal para ax
	; |  - [BP-4] :: un temporal para bx
	; |  - [BP-6] :: un temporal para cx
printNumBin_f:
	PROLOGO 3
	mov bx,0		;i=0
	cmp ax,0
	jl .negativo;salta si vleft <vright (considera # con signo)


	; proteger registros ax,bx,cx ya que la macro lo modifica
	mov word[bp-2],ax
	mov word[bp-4],bx
	mov word[bp-6],cx

	
	mov cx,[bp+6]
	cmp cx,POS_CON_MAS
	jne .sin_mas

	
	mov ax,'+'
	push ax
	ESENAR word[bp+4],1,sp
	pop ax

	mov ax,word[bp-2]
	mov bx,word[bp-4]
	mov cx,word[bp-6]

.sin_mas:
	
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
	; proteger registros ax,bx,cx ya que la macro lo modifica
	mov word[bp-2],ax
	mov word[bp-4],bx
	mov word[bp-6],cx
	ESENAR word[bp+4],1,sp
	mov ax,word[bp-2]
	mov bx,word[bp-4]
	mov cx,word[bp-6]
	
	pop dx			;recuperar ascii
	LOOP .for
	jmp .return

.negativo:
	; imprimir signo menos protegiendo ax,bx,cx
	mov word[bp-2],ax
	mov word[bp-4],bx
	mov word[bp-6],cx

	mov ax,'-'
	push ax
	ESENAR word[bp+4],1,sp
	pop ax

	mov ax,word[bp-2]
	mov bx,word[bp-4]
	mov cx,word[bp-6]
	neg ax			;complemento a dos
	jmp .do
.return:
	EPILOGO 2
