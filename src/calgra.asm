	; |- descripcion :: Calculadora graficadora con modo video 13h
	; |- comando :: tiene dependencias mejor consulte el makefile
	; |             de este directorio.
	; |- comando make :: =make=
	; |- autor :: Wilson S. Tubin


	; |Para emacs.
	; |- Ver estructura del codigo:
	; |  + De nasm-mode a org-mode. Con `C-M-%´ hacer:
	; |    1. `[[:blank:]]*;[[:blank:]]*\(\*+\)´ -> `\1´
	; |    2. activar el modo con `M-x org-mode´
	; |  + De org-mode a nasm-mode. Con `C-M-%´ hacer:
	; |    1. `^\(\*+\)´ -> `	; \1´
	; |    2. activar modo nasm con `M-x nasm-mode´


	; ==================================================
	; * i'' INCLUSIONES
	; ==================================================
%include "stack_frame.mac"
%include "io.mac"
	
	
	; ==================================================
	; * se'' SEGMENTO EXTRA (ES)
	; ==================================================
section .bss
SZ_BUFF_INPUT_TEXT: equ 40	;inputBuff max 40 chars

	
	; ==================================================
	; * sdd'' SEGMENTO DE DATOS
	; ==================================================
section .data	
buffInput: db SZ_BUFF_INPUT_TEXT+1
	times SZ_BUFF_INPUT_TEXT+1 db '$'


strMenu:db 'UNIVERSIDAD DE SAN CARLOS DE GUATEMALA',R,N
        db 'FACULTAD DE INGENIERIA',R,N
        db 'ESCUELA DE CIENCIAS Y SISTEMAS',R,N
        db 'ARQUITECTURA DE COMPUTADORES Y ENSAMBLADORES 1 A',R,N
        db 'Wilson Eliseo Sajbochol Tubin',R,N
        db 'Calculadora Graficadora',R,N,N
	db '               MENU PRINCIPAL',R,N
	db '  +--------------------------------------------+',R,N
	db '  |   (1) Derivar funcion                      |',R,N
	db '  |   (2) Integrar funcion                     |',R,N
	db '  |   (3) Ingresar funciones                   |',R,N
	db '  |   (4) Imprimir funciones ingresadas        |',R,N
	db '  |   (5) Graficar                             |',R,N
	db '  |   (6) Resolver ecuacion                    |',R,N
	db '  |   (7) Reportes                             |',R,N
	db '  |   (8) Salir                                |',R,N
	db '  +--------------------------------------------+'
	db '$'
str1Der: db 'Derivar.$'
str1Intro: db 'Ingrese polinomio de grado no mayor a cuatro.$'
	
str2Int: db 'Integrar.',R,N,N,'$'
	
str3Ing: db 'Ingresar funciones.',R,N,N,'$'
str3nomArch: db 'Ingrese el nombre del archivo: $'
str3DerInOSolve:
	db `Escoja operacion:\r\n`
	db `\t\t(1) Derivar e integrar\r\n`
	db `\t\t(2) Resolver$`
str3PresioneParaSeguir: db `Presione tecla..$`
str3NoAbrioArch: db 'No se pudo abrir el archivo.$'
str3deoin: db `derivar(d) o integrar(i)?: $`
str3seguir: db 'seguir leyedo archivo si(s) o no(n)?: $'
	
str4Imp: db 'Imprimir funciones ingresadas.',R,N,N,'$'
str4Intro: db 'Polinomios en el sistema:$'
str4NoPol: db 'No hay polinomios en el sistema.$'
.len:equ $-str4NoPol
	
str5Gra: db 'Graficar.',R,N,N,'$'
str5x0: db `\r\n\n\n\n\t\tIngrese limite INFERIOR para x(0,-100): $`
str5x1: db `\r\n\n\t\tIngrese limite SUPERIOR para x(1,100): $`
str5dis:
	db `Funciones a graficar:\r\n`
	db `\t\t(1) Polinomios\r\n`
	db `\t\t(2) Derivadas e integrales$`

	
str6Res: db 'Resolver Ecuacion.',R,N,N,'$'
str6Intro: db 'Ingrese polinomio de grado no mayor a dos.$'
str6NoCuadratico: db 'La ecuacion ingresada no es cuadratica.$'
str6SinSolucion: db 'Sin solucion$'
.len:equ $-str6SinSolucion
str6Sol1: db 'Solucion uno: $'
.len:equ $-str6Sol1
str6Sol2: db 'Solucion dos: $'
.len:equ $-str6Sol2
	
str7Rep: db 'Reportes.',R,N,N,'$'
str7Menu:
	db `+------------------------------------+\r\n`
	db `\t\t     |   (1) De polinomios del sistema    |\r\n`
	db `\t\t     |   (2) De ecuaciones resueltas      |\r\n`
	db `\t\t     |   (3) Regresar a menu principal    |\r\n`
	db `\t\t     +------------------------------------+$`
str7Op: db `Que opcion de uno a tres ?: $`
str7repCreado: db `Reporte creado. Se llama $`
str7polsis_print: db 'POLSIS.TXT$'
str7polsis: db 'POLSIS.txt',0
str7ecures_print: db 'ECURES.TXT$'
str7ecures: db 'ECURES.TXT',0
str7NoCreadoRep: db 'No se pudo crear reporte.$'
str7Encab:
	db `POLINOMIOS DEL SISTEMA\r\n`
	db `Wilson S. Tubin\r\n\r\n`
.len:equ $-str7Encab
str7Encab2:
	db `ECUACIONES RESUELTAS\r\n`
	db `Wilson S. Tubin\r\n\r\n`
.len:equ $-str7Encab2
str7Ptn: db `\r\n\tPuntos del polinomio:\r\n\tx,y\r\n\t`
.len:equ $-str7Ptn

str7NewLine: db `\r\n`
.len:equ $-str7NewLine

str7T: db `\t`
.len:equ $-str7T

	
strVolver: db 'Presione tecla para volver...$'
strOpcion: db R,N,N,'  Que opcion de uno a ocho ?: $'
strLinEnc: db '==================================================$'
strPoli: db 'funciones$'



	
	; ==================================================
	; * sdc'' SEGMENTO DE CODIGO
	; ==================================================
[bits 16]
[cpu 8086]
org 0x100	
section .text

	; el apuntador(polArr) al arreglo de polinomios y el
	; apuntador(p) que se va moviendo a travez de él, conforme se
	; agregan polinomios, comienzan con el mismo valor. Lo mismo
	; para deinArr.
	mov word[p],polArr
	mov word[s],deinArr

	
	; --------------------------------------------------
	; ** Menu Principal
	; --------------------------------------------------

inicio:

	LIMPIAR_PANTALLA
	call printInfoEsquina
	UBICAR_CURSOR 1,0
	PRINT strMenu
	PRINT strOpcion	
opcion:
	GETCHAR
	cmp al, '8'		; si se ingreso 8, termina el programa
	je salir

	cmp al, '1'		;es ASCII 1?
	jne op2			;saltar si no es igual
	call derivar
	jmp inicio		;repetir el ciclo

op2:
	cmp al, '2'		;es ASCII 2?
	jne op3			;saltar si no es igual
	call integrar
	jmp inicio		;repetir el ciclo
	
op3:
	cmp al, '3'		; es ASCII 3?
	jne op4			;saltar si no es igual
	call ingresar
	jmp inicio		;repetir el ciclo

op4:
	cmp al, '4'		; es ASCII 4?
	jne op5			;saltar si no es igual
	call imprimir
	jmp inicio		; repetir el ciclo

op5:
	cmp al, '5'		; es ASCII 5?
	jne op6			;saltar si no es igual
	call graficar
	jmp inicio		; repetir el ciclo

op6:
	cmp al, '6'		; es ASCII 6?
	jne op7			;saltar si no es igual
	call resolver
	jmp inicio		; repetir el ciclo	
	
op7:
	cmp al, '7'		; es ASCII 4
	jne opcion		; si no repetir el ingreso de caracter
	call reportes
	jmp inicio		; repetir ciclo

salir:
	TERMINAR_PROGRAMA
	

%include "anlex2.asm"	 ;analisis lexico
%include "rep.asm"	 ;para reporte
%include "ploter.asm"	 ;para graficar
	

	; --------------------------------------------------
	; ** der''
	; --------------------------------------------------
derivar:
	mov byte[n_ter],DERINT	;cinco terminos permitidos

	LIMPIAR_PANTALLA
	PRINT 2,14,strLinEnc
	PRINT 3,35,str1Der
	PRINT 4,14,strLinEnc
	PRINT 7,14,str1Intro

	call printInfoEsquina

	UBICAR_CURSOR 9,14
	mov al, byte[n_pol]
	add al,65
	PRINT_CHAR al
	PRINT_CHAR '('
	PRINT_CHAR 'x'
	PRINT_CHAR ')'
	PRINT_CHAR BARRA
	READ_FOR_BUFF_INPUT buffInput
	
	UBICAR_CURSOR 12,14

	mov di, buffInput
	inc di
	mov bl, [di]		;bx=tamaño cadena ingresada
	inc di
	mov byte[di+bx],';'	;fin de cadena p/analisis lexico

	
	mov al, byte[n_pol]
	xor ah,ah
	push ax

	push di			;cadena
	mov di,word[p]
	push di			;estructura en donde guardar
	call scanner


	pop ax
	cmp al, byte[n_pol]
	je .noAumentoN_pol

	; derivando
	mov di,word[p]
	mov si,word[s]
	call derivarPol
	UBICAR_CURSOR 14,14	;imprimir la derivada
	call printDerivada

	
	; imprimir nuevamente cantidad de funciones en el sistema
	call printInfoEsquina
	
	; aumentar p para que apunte a la siguiente estructura
	mov di,word[p]
	add di,pol.size
	mov word[p],di


	; aumentar s para que apunte a la siguiente estructura
	mov di,word[s]
	add di,dein.size
	mov word[s],di

.noAumentoN_pol:


	UBICAR_CURSOR 19,14
	GETCHAR strVolver
	ret

	; ** integrarPol
	; |Integra una polinomio de 5 terminos como maximo
	; |+ Entrada:
	; |  - di :: puntero a estructura que contiene el polinomio a
	; |          derivar.
	; |  - si :: puntero a estructura donde guardar la derivación.
derivarPol:
	mov al,byte[di+pol.n]	;copiar tamaño
	mov byte[si+dein.n],al

	; primer termino
	mov ax, [di+pol.Acoef]
	mov bl, byte[di+pol.aExpo]
	xor bh,bh
	imul bx			;DX:AX=BX*AX
	cmp bx,0
	je .term_constA
	sub bx,1		
	mov word[si+dein.Acoef],ax
	mov byte[si+dein.aExpo],bl
	jmp .no_const_A
.term_constA:
	mov word[si+dein.Acoef],ax
	mov byte[si+dein.aExpo],0
.no_const_A:


	; segundo termino
	mov ax, [di+pol.Bcoef]
	mov bl, byte[di+pol.bExpo]
	xor bh,bh
	imul bx			;DX:AX=BX*AX
	cmp bx,0
	je .term_constB
	sub bx,1		
	mov word[si+dein.Bcoef],ax
	mov byte[si+dein.bExpo],bl
	jmp .no_const_B
.term_constB:	
	mov word[si+dein.Bcoef],ax
	mov byte[si+dein.bExpo],0
.no_const_B:


	
	; tercer termino
	mov ax, [di+pol.Ccoef]
	mov bl, byte[di+pol.cExpo]
	xor bh,bh
	imul bx			;DX:AX=BX*AX
	cmp bx, 0
	je .term_constC
	sub bx,1		
	mov word[si+dein.Ccoef],ax
	mov byte[si+dein.cExpo],bl
	jmp .no_const_C
.term_constC:
	mov word[si+dein.Ccoef],ax
	mov byte[si+dein.cExpo],0
.no_const_C:
	

	; cuarto termino
	mov ax, [di+pol.Dcoef]
	mov bl, byte[di+pol.dExpo]
	xor bh,bh
	imul bx			;DX:AX=BX*AX
	cmp bx,0
	je .term_constD
	sub bx,1		
	mov word[si+dein.Dcoef],ax
	mov byte[si+dein.dExpo],bl
	jmp .no_const_D
.term_constD:
	mov word[si+dein.Dcoef],ax
	mov byte[si+dein.dExpo],0
.no_const_D:

	

	; quinto termino
	mov ax, [di+pol.Ecoef]
	mov bl, byte[di+pol.eExpo]
	xor bh,bh
	imul bx			;DX:AX=BX*AX
	cmp bx,0
	je .term_constE
	sub bx,1		
	mov word[si+dein.Ecoef],ax
	mov byte[si+dein.eExpo],bl
	jmp .no_const_E
.term_constE:
	mov word[si+dein.Ecoef],ax
	mov byte[si+dein.eExpo],0
.no_const_E:

	mov byte[si+dein.tipo], DERIVADA	
	ret
	

	; --------------------------------------------------
	; ** int''
	; --------------------------------------------------
integrar:
	mov byte[n_ter],DERINT	;cinco terminos permitidos

	LIMPIAR_PANTALLA
	PRINT 2,14,strLinEnc
	PRINT 3,35,str2Int
	PRINT 4,14,strLinEnc
	PRINT 7,14,str1Intro

	call printInfoEsquina

	UBICAR_CURSOR 9,14
	mov al, byte[n_pol]
	add al,65
	PRINT_CHAR al
	PRINT_CHAR '('
	PRINT_CHAR 'x'
	PRINT_CHAR ')'
	PRINT_CHAR BARRA
	READ_FOR_BUFF_INPUT buffInput
	
	UBICAR_CURSOR 12,14

	mov di, buffInput
	inc di
	mov bl, [di]		;bx=tamaño cadena ingresada
	inc di
	mov byte[di+bx],';'	;fin de cadena p/analisis lexico

	
	mov al, byte[n_pol]
	xor ah,ah
	push ax

	push di			;cadena
	mov di,word[p]
	push di			;estructura en donde guardar
	call scanner


	pop ax
	cmp al, byte[n_pol]
	je .noAumentoN_pol

	; integrar e imprimir polinomio ingresado por el usuario
	mov di,word[p]		;polinomio ingresado por el usuario.
	mov si,word[s]		;estructura donde se guarda la derivada
	call integrarPol	
	UBICAR_CURSOR 14,14	;imprimir la integral
	call printIntegral
	
	; imprimir nuevamente cantidad de funciones en el sistema
	call printInfoEsquina
	
	; aumentar p para que apunte a la siguiente estructura
	mov di,word[p]
	add di,pol.size
	mov word[p],di

	; aumentar s para que apunte a la siguiente estructura
	mov di,word[s]
	add di,dein.size
	mov word[s],di

.noAumentoN_pol:


	UBICAR_CURSOR 19,14
	GETCHAR strVolver
	ret

	; ** integrarPol
	; |Integra una polinomio de 5 terminos como maximo
	; |+ Entrada:
	; |  - di :: puntero a estructura que contiene el polinomio a
	; |          integrar.
	; |  - si :: puntero a estructura donde guardar la integración.
integrarPol:
	mov al,byte[di+pol.n]	;copiar tamaño
	mov byte[si+dein.n],al

	; primer termino
	mov ax, [di+pol.Acoef]
	mov bl, byte[di+pol.aExpo]
	add bl,1
	cmp bl,0
	je .return
	idiv bl 		;AL=AX/BL   residuo=AH
	CBW 			;AX = signo-extendido de AL
	mov word[si+dein.Acoef],ax
	mov byte[si+dein.aExpo],bl

	; segundo termino
	mov ax, [di+pol.Bcoef]
	mov bl, byte[di+pol.bExpo]
	add bl,1
	cmp bl,0
	je .return
	idiv bl 		;AL=AX/BL   residuo=AH
	CBW 			;AX = signo-extendido de AL
	mov word[si+dein.Bcoef],ax
	mov byte[si+dein.bExpo],bl

	
	; tercer termino
	mov ax, [di+pol.Ccoef]
	mov bl, byte[di+pol.cExpo]
	add bl,1
	cmp bl,0
	je .return
	idiv bl 		;AL=AX/BL   residuo=AH
	CBW 			;AX = signo-extendido de AL
	mov word[si+dein.Ccoef],ax
	mov byte[si+dein.cExpo],bl	


	; cuarto termino
	mov ax, [di+pol.Dcoef]
	mov bl, byte[di+pol.dExpo]
	add bl,1
	cmp bl,0
	je .return
	idiv bl 		;AL=AX/BL   residuo=AH
	CBW 			;AX = signo-extendido de AL
	mov word[si+dein.Dcoef],ax
	mov byte[si+dein.dExpo],bl


	; quinto termino
	mov ax, [di+pol.Ecoef]
	mov bl, byte[di+pol.eExpo]
	add bl,1
	cmp bl,0
	je .return
	idiv bl 		;AL=AX/BL   residuo=AH
	CBW 			;AX = signo-extendido de AL
	mov word[si+dein.Ecoef],ax
	mov byte[si+dein.eExpo],bl

	mov byte[si+dein.tipo], INTEGRAL
.return:
	ret


	; --------------------------------------------------
	; ** ing''
	; --------------------------------------------------
	; |Opcion "ingresar" del menú principal, cuyo objetivo es
	; |cargar un archivo con expresiones polinómicas terminadas en
	; |';'
	; |+ Variables Locales
	; |  - [BP-2] :: guarda el handle del archivo abierto.
	; |  - [BP-4] :: guarda operacion elegida por el usuario para
	; |              con el archivo, ya sea DErivar o INtegrar o
	; |              bien reSOLVEr.
%define OP_DERIN 0
%define OP_SOLVE 1
ingresar:
	PROLOGO 2
	LIMPIAR_PANTALLA
	call printInfoEsquina
	PRINT 1,14,strLinEnc
	PRINT 2,29,str3Ing
	PRINT 3,14,strLinEnc

	PRINT 5,14, str3nomArch
	READ_FOR_BUFF_INPUT buffInput
		

	mov di, buffInput
	inc di
	mov bl, [di]		;bx=tamaño cadena ingresada
	inc di
	mov byte[di+bx],0 ;nombre de archivo debe terminar en 0
	ABRIR_ARCHIVO di
	jc .noAbrioArchivo ;salta solo si CF=1
	mov word[bp-2],ax  ;guardar handle
	jmp .siAbrioArchivo
.noAbrioArchivo:
	PRINT 8,14,str3NoAbrioArch
	jmp .return

.siAbrioArchivo:

	mov byte[fila], 1 ;para inicializar contador de filas del
	;analizador lexico
	
	; si se abre archivo mostrar una A en la esquina
	UBICAR_CURSOR 5,70
	PRINT_CHAR 'A'

	PRINT 9,14,str3DerInOSolve
	UBICAR_CURSOR 9,32
.derin_solve:
	GETCHAR
	cmp al,'1'
	jne .solve
	; DerIn: Derivar o integrar
	mov byte[n_ter],DERINT	;cinco terminos permitidos
	mov word[BP-4],OP_DERIN
	jmp .fin_derin_solve
.solve:	
	cmp al,'2'
	jne .derin_solve
	; reSOLVEr	
	mov byte[n_ter],SOLVE	;tres terminos permitidos	
	mov word[BP-4],OP_SOLVE

.fin_derin_solve:
	DESPLAZAR_ARRIBA 9,14,12,60,3	
	UBICAR_CURSOR 7,14
	mov al, byte[n_pol]
	xor ah,ah
	push ax			;guardar n_pol para comparar despues
	
	push word[bp-2]
	mov di,word[p]
	push di
	call scanner_f

	pop ax
	cmp al, byte[n_pol]
	je .noAumentoN_pol

	; imprimir nuevamente cantidad de funciones en el sistema
	call printInfoEsquina

	; imprimir ecuacion leida de archivo
	UBICAR_CURSOR 8,14
	mov di,word[p]
	call printPolinomio


	cmp word[bp-4],OP_DERIN
	jne .derin_e
	; ini-derivando o integrando
	; el usuario ESCOJE si quiere integrar o derivar
	PRINT 10,14, str3deoin	
.escoje:
	GETCHAR
	cmp al,'d'
	jne .integrar
	UBICAR_CURSOR 11,14
	; en di aun esta la entrada del usuario
	mov si,word[s]
	call derivarPol
	call printDerivada
	jmp .fin_escoje
.integrar:	
	cmp al,'i'
	jne .escoje
	UBICAR_CURSOR 11,14
	;en di aun esta la entrada del usuario
	mov si,word[s]
	call integrarPol
	call printIntegral
.fin_escoje:
	jmp .next
	; fin-derivando o integrando

.derin_e:
	; ini-resolviendo ecuacion -----------------------------
	mov ax,10
	push ax
	mov di,word[p]
	call resolver_ecuacion
	jc .noCuadratico	;salta solo si CF=1

	mov di,word[s]
	mov byte[di+dein.tipo],NINGUNO ;para identificar desde una
	;estructura dein si en la posicion actual se resolvio ecuacion.

	; fin-resolviendo ecuacion -----------------------------
.next:
	; aumentar p para que apunte a la siguiente estructura
	mov di,word[p]
	add di,pol.size
	mov word[p],di

	; aumentar s para que apunte a la siguiente estructura
	mov di,word[s]
	add di,dein.size
	mov word[s],di


.noCuadratico:
	
	; preguntar al usuario si quiere SEGUIR leyendo el archivo
	PRINT 13,14, str3seguir
.seguir:
	GETCHAR
	cmp al,'s'
	jne .dejar
	DESPLAZAR_ARRIBA 7,14,13,50,7
	jmp .fin_derin_solve
.dejar:	
	cmp al,'n'
	jne .seguir
	UBICAR_CURSOR 5,70
	CERRAR_ARCHIVO word[bp-2]
	jc .noCerroArchivo1
	PRINT_CHAR 'C'		;C en esquina si cerro archivo
	jmp .return
        .noCerroArchivo1:
	PRINT_CHAR 'N'		;N en esquina si no cerro archivo
	jmp .return
.noAumentoN_pol:

	; ini-ocurrio error lexico
	PRINT 13,14,str3PresioneParaSeguir
	GETCHAR
	DESPLAZAR_ARRIBA 7,1,14,55,8
	
.do:
	LEER_ARCHIVO [bp-2],1,c
	jc .return

	; si el caracter guardado en 'c' es retorno de carro
	cmp byte[c],0x0d		;c=='\r'
	jne .noNuevaLinea
	inc byte[fila]		;fila++
	LEER_ARCHIVO [bp-2],1,c	;leer '\n' solo para saltarlo
	jmp .do
.noNuevaLinea:

	; si se encontro fin de archivo
	; es EOF si AX = 0 o AX < CX
	cmp ax, cx		;EOF?
	jge .no_esEOF		;salta si vleft >= vright
	PRINT msjFinArchivo
	UBICAR_CURSOR 5,70
	CERRAR_ARCHIVO word[bp-2]
	jc .noCerroArchivo2
	PRINT_CHAR 'C'		;C en esquina si cerro archivo
	jmp .return
        .noCerroArchivo2:
	PRINT_CHAR 'N'		;N en esquina si no cerro archivo
	jmp .return
.no_esEOF:

	; avanzar hasta ';' y saltar hacia nueva expresion 
	cmp byte[c],';'
	je .fin_derin_solve
	jne .do
	; fin-ocurrio error lexico
	
.return:
	UBICAR_CURSOR 18,14
	GETCHAR strVolver
	EPILOGO 0

	; --------------------------------------------------
	; ** imp''
	; --------------------------------------------------
imprimir:
	LIMPIAR_PANTALLA
	PRINT 1,14,strLinEnc
	PRINT 2,25,str4Imp
	PRINT 3,14,strLinEnc
	UBICAR_CURSOR 5,1
	PRINT_CHAR T
	PRINT str4Intro

	mov cl,byte[n_pol]
	cmp cl,0
	jne .sihaypoli
	PRINT 10,14, str4NoPol
	UBICAR_CURSOR 16,14
	GETCHAR strVolver
	jmp .return
.sihaypoli:

	UBICAR_CURSOR 6,1
	mov bl,65
	PRINT_CHAR T
	mov di,polArr		;arr de estruc de polms originales
	mov si,deinArr		;arr de estruc de polms deriv/integ
.llistpol:

	; imprimir polinomio
	PRINT_CHAR bl
	PRINT_CHAR '('
	PRINT_CHAR 'x'
	PRINT_CHAR ')'
	PRINT_CHAR '='
	push di
	call printPol

	; imprimir la derivada o integral o solucion----------
	PRINT_CHAR T
	mov al,byte[di+pol.tipo]
	cmp al,SOLVE
	jne .esdein_e

	; ini-ecuacion resuelta
	push cx
	push bx
	cmp byte[di+pol.eExpo],0
	jne .sol1
	PRINT str6SinSolucion
	jmp .fin_sol
.sol1:
	cmp byte[di+pol.eExpo],1
	jne .sol2
	PRINT str6Sol1
	mov al,byte[di+pol.sol1]
	cbw			;convertir AL a AX con signo
	call printNumBin
	jmp .fin_sol
.sol2:
	PRINT str6Sol1	
	mov al,byte[di+pol.sol1]
	cbw			;convertir AL a AX con signo
	call printNumBin
	PRINT_CHAR SPC		;imprimir espac. entre sol1 y sol2
	PRINT str6Sol2	
	mov al,byte[di+pol.sol2]
	cbw			;convertir AL a AX con signo
	call printNumBin
.fin_sol:
	pop bx
	pop cx
	; fin-ecuacion resuelta
	jmp .esdein_fin
.esdein_e:
	; ini-ES DErivada o INtegral
	mov al,byte[si+dein.tipo]
	cmp al,DERIVADA
	jne .esder_e
	PRINT_CHAR 'd'
	PRINT_CHAR bl
	PRINT_CHAR '/'
	PRINT_CHAR 'd'
	PRINT_CHAR 'x'
	PRINT_CHAR SPC
	PRINT_CHAR '='
	PRINT_CHAR SPC
	push si
	call printPol
	jmp .esder_fin
.esder_e:			;ES DERivada Else
	PRINT_CHAR CINT
	PRINT_CHAR bl
	PRINT_CHAR 'd'
	PRINT_CHAR 'x'
	PRINT_CHAR SPC
	PRINT_CHAR '='
	PRINT_CHAR SPC
	push si
	call printPol
	PRINT_CHAR '+'		;imprimir constante C
	PRINT_CHAR 'C'
.esder_fin:
	
	
	
.esdein_fin:
	; fin-ES DErivada o INtegral
	

	PRINT_CHAR R		;retorno de carro
	PRINT_CHAR N		;nueva linea
	PRINT_CHAR T		;tabulacion

	inc bl			;aumentar letra
	add di,pol.size		;mover sig. estruc de pol origin
	add si,dein.size	;mover sig. estruc de deriv/integ
	dec cx
	JNZ .llistpol		;bucle
	
	
	UBICAR_CURSOR 22,14
	GETCHAR strVolver
.return:
	ret


	
	
	; ** printPol
	; |Imprimir polinomio en salida estandar
	; |+ Parametros
	; |  - [BP+4] :: puntero al inicio del arreglo que contiene la
	; |              expresion polinomica
printPol:
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
	mov ax,word[di+pol.Acoef]
	push ax
	mov al,byte[di+pol.aExpo]
	xor ah,ah
	push ax
	call printCoef
	jmp .break
	
.coefb:
	cmp bl,2
	jne .coefc
	; segundo coeficiente y exponente
	mov ax,word[di+pol.Bcoef]
	push ax
	mov al,byte[di+pol.bExpo]
	xor ah,ah
	push ax
	call printCoef
	jmp .break

.coefc:
	cmp bl,3
	jne .coefd
	; tercer coeficiente y exponente
	mov ax,word[di+pol.Ccoef]
	push ax
	mov al,byte[di+pol.cExpo]
	xor ah,ah
	push ax
	call printCoef
	jmp .break

.coefd:
	cmp bl,4
	jne .coefe
	; cuarto coeficiente y exponente
	mov ax,word[di+pol.Dcoef]
	push ax
	mov al,byte[di+pol.dExpo]
	xor ah,ah
	push ax
	call printCoef
	jmp .break

.coefe:
	; quinto coeficiente y exponente
	mov ax,word[di+pol.Ecoef]
	push ax
	mov al,byte[di+pol.eExpo]
	xor ah,ah
	push ax
	call printCoef
	

.break:
	inc bl
	LOOP .lpol


	pop bx
	pop di
	pop cx
	EPILOGO 1


	
	; ** printCoef
	; |Imprimir coeficiente en la salida estandar
	; |+ Parametros
	; |  - [BP+6] :: coeficiente en binario (word)
	; |  - [BP+4] :: exponente en binario (byte)
printCoef:
	PROLOGO 0
	push cx			;proteger por eventual ejecucion
	;dentro ciclo con loop
	push bx

	; ini-impresion de coeficiente --------------------
	mov ax, word[bp+6]
	call printNumBin_mas

	; impresion de exponente --------------------
	mov al,byte[bp+4]
	xor ah,ah
	cmp ax,0		;si exponente 0 no imprimir x^0
	je .expo0
	cmp ax,1		;si exponente 1 solo imprime x
	je .expo1
	PRINT_CHAR 'x'
	PRINT_CHAR '^'
	mov al,byte[bp+4]
	xor ah,ah
	call printNumBin
	jmp .expo0
.expo1:
	PRINT_CHAR 'x'
.expo0:	
	
	pop bx
	pop cx
	EPILOGO 2


	; ** printPolinomio
	; |Imprime una integral en salida estandar. Basicamente es lo
	; |mismo que printPol, la diferencia es que antes de hacer la
	; |llamada a printPol imprime la notacion de funcion
	; |identificandola con una letra mayuscula.
	; |+ Entrada
	; |  - di :: polinomio original que no es derivada ni integral
	; |          de otro polinomio
printPolinomio:
	mov al, byte[n_pol]
	add al,64
	PRINT_CHAR al
	PRINT_CHAR '('
	PRINT_CHAR 'x'
	PRINT_CHAR ')'
	PRINT_CHAR BARRA
	push di
	call printPol
	ret

	; ** printDerivada
	; |Imprime una derivada en salida estandar. Basicamente es lo
	; |mismo que printPol, la diferencia es que antes de hacer la
	; |llamada a printPol imprime la notacion de derivadas.
	; |+ Entrada
	; |  - si :: polinomio derivado de otro polinomio
printDerivada:
	PRINT_CHAR 'd'
	mov al, byte[n_pol]
	add al,64
	PRINT_CHAR al
	PRINT_CHAR '/'
	PRINT_CHAR 'd'
	PRINT_CHAR 'x'
	PRINT_CHAR SPC
	PRINT_CHAR '='
	PRINT_CHAR SPC
	push si
	call printPol
	ret

	; ** printIntegral
	; |Imprime una integral en salida estandar. Basicamente es lo
	; |mismo que printPol, la diferencia es que antes de hacer la
	; |llamada a printPol imprime la notacion de integrales.
	; |+ Entrada
	; |  - si :: polinomio integrado
printIntegral:
	PRINT_CHAR CINT
	mov al, byte[n_pol]
	add al,64
	PRINT_CHAR al
	PRINT_CHAR 'd'
	PRINT_CHAR 'x'
	PRINT_CHAR SPC
	PRINT_CHAR '='
	PRINT_CHAR SPC
	push si
	call printPol	
	PRINT_CHAR '+'		;imprimir constante C
	PRINT_CHAR 'C'
	ret

	
	
	; --------------------------------------------------
	; ** gra''
	; --------------------------------------------------	
	; |Graficar polinomios
	; |+ Variables locales
	; |  - [bp-2] :: contador temporal para bucle mayor
	; |  - [bp-4] :: limite inferior del rango a graficar (x0)
	; |  - [bp-6] :: limite superior del rango a graficar (x1)
	; |  - [bp-8] :: factor por el cual se dividen los puntos en
	; |              el eje Y, dependiendo si se trata de un
	; |              polinomio de 1,2,3 o 4 grado, esto para que
	; |              se logre la visualización más adecuada de la
	; |              gráfica considerando que se tiene solo 200
	; |              pixeles del modo de video para el eje Y.
	; |  - [bp-10] :: guarda la opcion elegida de la disyuntiva
	; |               graficar polinomios, graficar derivadas e
	; |               integrales.
%define GRAFICAR_DERIN 1
%define GRAFICAR_POL 2
graficar:
	PROLOGO 5
	; inicializando variables locales
	mov word[bp-2],1;
	mov word[bp-4],-100;
	mov word[bp-6],100;
	mov word[bp-8],3;
	
	LIMPIAR_PANTALLA
	PRINT 2,14,strLinEnc
	PRINT 3,35,str5Gra
	PRINT 4,14,strLinEnc
	
	mov cl,byte[n_pol]
	cmp cl,0
	jne .sihaypoli
	PRINT 10,14, str4NoPol
	UBICAR_CURSOR 16,14
	GETCHAR strVolver
	jmp .return
.sihaypoli:


	PRINT str5x0
	READ_FOR_BUFF_INPUT buffInput
	mov di, buffInput
	inc di
	mov cl, [di]		;cl=tamaño cadena ingresada
	inc di
	call convNumStrParaNumBin_arr
	mov [bp-4],ax ;guardar x0

	PRINT str5x1
	READ_FOR_BUFF_INPUT buffInput
	mov di, buffInput
	inc di
	mov cl, [di]		;cl=tamaño cadena ingresada
	inc di
	call convNumStrParaNumBin_arr
	mov [bp-6],ax ;guardar x1

	
	PRINT 12,16,str5dis
	UBICAR_CURSOR 12,38
.escoje:
	GETCHAR
	cmp al,'1'
	jne .polinomio_e
	; graficar polinomios
	mov word[bp-10],GRAFICAR_POL
	; poner en di el apuntador al arreglo de estructuras de
	; polinomios
	mov di,polArr
	jmp .fin_escoje
.polinomio_e:
	cmp al,'2'
	jne .escoje
	; graficar derivadas e integrales
	mov word[bp-10],GRAFICAR_DERIN
	; poner en di el apuntador al arreglo de estructuras de
	; derivadas e integrales
	mov di,deinArr
.fin_escoje:
	
	MODO_VIDEO
	mov byte[bp-2],0 ;contador bucle mayor a 0

	
.llistpol:

	cmp word[bp-10],GRAFICAR_POL
	je .correcto		;si se estan graficando polinomios del
	;sistema y no derivadas e integrales, es correcto ya que esto
	;quiere decir que se esta iterando sobre polArr y en polArr se
	;grafican todas las funciones.

	; si llega ha este punto quiere decir que se estan graficando
	; derivadas e integrales y se valida que di tenga ya sea una
	; integral o una derivada para continuar con el dibujo del
	; plano. Si no es NINGUNO de estos quiere decir que en di no hay
	; almacenado ninguno ya que en esta posicion de memoria se
	; resolvio ecuacion.
	cmp byte[di+dein.tipo],NINGUNO
	jne .correcto

	jmp .getNextPol
	
.correcto:
	
	; ini-dibujar plano adecuado ----------------------------
	call conocerGrado
	cmp al,0
	jne .recta
	; constante
	mov ax,X_ORIGEN_CONSTANTE		;x=160=0xA0
	push ax
	mov ax,Y_ORIGEN_CONSTANTE		;y=100=0x64
	push ax
	call dibujar_plano
	mov word[bp-8],FACTOR_CONSTANTE ;factor
	jmp .fin_plano
.recta:
	cmp al,1
	jne .parabola
	; recta
	mov ax,X_ORIGEN_RECTA		;x=160=0xA0
	push ax
	mov ax,Y_ORIGEN_RECTA		;y=100=0x64
	push ax
	call dibujar_plano
	mov word[bp-8],FACTOR_RECTA ;factor
	jmp .fin_plano


.parabola:
	cmp al,2
	jne .gradotres
	; parabola
	mov word[bp-8],FACTOR_PARABOLA ;factor

	cmp ah,POL_POSITIVO
	jne .pol_pos_e
	mov ax,X_ORIGEN_PARABOLA_POS		;x
	push ax
	mov ax,Y_ORIGEN_PARABOLA_POS		;y
	push ax
	call dibujar_plano
	jmp .fin_plano
.pol_pos_e:	
	mov ax,X_ORIGEN_PARABOLA_NEGA		;x
	push ax
	mov ax,Y_ORIGEN_PARABOLA_NEGA		;y
	push ax
	call dibujar_plano
	jmp .fin_plano


.gradotres:
	cmp al,3
	jne .gradocuatro
	; grado tres
	mov word[bp-8],FACTOR_GRADO3 ;factor
	mov ax,X_ORIGEN_GRADO3		;x=160=0xA0
	push ax
	mov ax,Y_ORIGEN_GRADO3		;y=100=0x64
	push ax
	call dibujar_plano
	jmp .fin_plano
	

.gradocuatro:
	; grado cuatro
	mov word[bp-8],FACTOR_GRADO4 ;factor

	cmp ah,POL_POSITIVO
	jne .pol_pos_e4
	mov ax,X_ORIGEN_GRADO4_POS		;x
	push ax
	mov ax,Y_ORIGEN_GRADO4_POS		;y
	push ax
	call dibujar_plano
	jmp .fin_plano
.pol_pos_e4:	
	mov ax,X_ORIGEN_GRADO4_NEGA		;x
	push ax
	mov ax,Y_ORIGEN_GRADO4_NEGA		;y
	push ax
	call dibujar_plano
	jmp .fin_plano
	
	
.fin_plano:
	; fin-dibujar plano adecuado ----------------------------


	
	; ini-escribir funcion a graficar
	UBICAR_CURSOR 1,1

	mov bl,byte[bp-2]
	add bl,65
	
	cmp word[bp-10],GRAFICAR_DERIN
	jne .polinomio

	; ini-escribir derivada o integral
	cmp byte[di+dein.tipo],DERIVADA
	jne .integral
	PRINT_CHAR 'd'
	PRINT_CHAR bl
	PRINT_CHAR '/'
	PRINT_CHAR 'd'
	PRINT_CHAR 'x'
	PRINT_CHAR SPC
	PRINT_CHAR '='
	PRINT_CHAR SPC
	push di
	call printPol
	jmp .fefu ;Fin Escribir FUncion
.integral:
	PRINT_CHAR CINT
	PRINT_CHAR bl
	PRINT_CHAR 'd'
	PRINT_CHAR 'x'
	PRINT_CHAR SPC
	PRINT_CHAR '='
	PRINT_CHAR SPC
	push di
	call printPol
	PRINT_CHAR '+'		;imprimir constante C
	PRINT_CHAR 'C'
	; fin-escribir derivada o integral
	jmp .fefu ;Fin Escribir FUncion
.polinomio:
	PRINT_CHAR bl
	PRINT_CHAR '('
	PRINT_CHAR 'x'
	PRINT_CHAR ')'
	PRINT_CHAR '='
	push di
	call printPol

.fefu: ;Fin Escribir FUncion
	
	UBICAR_CURSOR 2,1
	PRINT_CHAR 'x'
	PRINT_CHAR '['
	mov ax,[bp-4] ;limite inferior
	call printNumBin
	PRINT_CHAR ','
	mov ax,[bp-6] ;limite superior
	call printNumBin
	PRINT_CHAR ']'
	; fin-escribir funcion a graficar


	mov cx,[bp-4] ;cx = limite inferior (x0)
.loop_eval:

	
	; di contiene ecuacion original
	push cx			;# a evaluar
	call evalPol		;resultado en ax
	jo .next		;si hubo desborde hacia DX cuando se
	;hizo la evaluacion. Esto es porque se manejan solo un numero
	;signado de 16 bist como maximo (AX).

	; se debe iniciar DX correctamente porque lo considera idiv
	xor dx,dx
	cmp ax,0
	jg .axPos ;salta si vleft >vright
	mov dx,0xFFFF 
.axPos:
	mov bx,[bp-8] ;factor
	idiv bx	      ;AX=DX:AX/BX  ; DX=residuo
	
	cmp ax,0
	jge .neg_e    ;salta si vleft > vright (signed)
	; ini-ax negativo
	mov bx,Y_CUADRO+ALTO_CUADRO
	sub bx,[origen_y]
	mov dx,ax ;ax es el resultado de la evaluacion
	neg dx
	cmp dx,bx
	jge .next ;salta si vleft > vright (signed)
	; fin-ax negativo
	jmp .neg_fin
.neg_e:
	; ini-ax positivo
	mov bx,[origen_y]
	sub bx,Y_CUADRO
	mov dx,ax ;ax es el resultado de la evaluacion
	cmp dx,bx
	jge .next ;salta si vleft > vright (signed)
	; fin-ax positivo
.neg_fin:
	
	mov bx, cx ;x
	mov ax, ax ;y
	mov dl,WHITE
	call putPixel

.next:
	inc cx
	cmp cx,[bp-6] ; [bp-6] = x1
	jne .loop_eval		;fin bucle --------------------	

.getNextPol:
	GETCHAR
	cmp ah,F_IZ
	jne .fder
	; si se pulso flecha izquierda
.sigizq:			;SIGuiente a la IZQuierda

	; evitar que vaya a direccion desconcida si el contador es 0
	cmp byte[bp-2],0
	je .getNextPol_fin
	
	sub di,pol.size		;mover sig. estruc de pol origin
	dec byte[bp-2]

	cmp word[bp-10],GRAFICAR_POL
	je .getNextPol_fin	;si graficando polinomios, eso es todo
	
	cmp byte[di+dein.tipo],NINGUNO
	je .sigizq
	
	jmp .getNextPol_fin
.fder:
	cmp ah,F_DE
	jne .getNextPol
	; si se pulso flecha derecha
.sigder:			;SIGuiente a la DERecha
	add di,pol.size		;mover sig. estruc de pol origin
	inc byte[bp-2]

	cmp word[bp-10],GRAFICAR_POL
	je .getNextPol_fin	;si graficando polinomios, eso es todo
	
	cmp byte[di+dein.tipo],NINGUNO
	je .sigder

.getNextPol_fin:
	
	
	mov cl,byte[bp-2]
	cmp cl,byte[n_pol]
	jne .llistpol		;fin bucle MAYOR --------------

	MODO_TEXTO
.return:
	EPILOGO 0

	
	; ** conocerGrado
	; |Saber el grado de un polinomio
	; |+ Entradas
	; |  - di :: puntero a estructura que contiene el polinomio
	; |+ Salidas
	; |  - al :: grado del polinomio
	; |  - ah :: POL_POSITIVO si positivo y POL_POSITIVO-1 si
	; |          negativo 	
conocerGrado:
	push cx
	mov cl,byte[di+pol.n]

	; un termino
	cmp cl,1
	jne .term2
	mov al,byte[di+pol.aExpo]
	mov bx,word[di+pol.Acoef]
	call setOrientacionPol
	jmp .break


	; dos terminos
.term2:
	cmp cl,2
	jne .term3
	mov al, byte[di+pol.aExpo]
	mov bl, byte[di+pol.bExpo]
	cmp al,bl
	jl .alMenor2 ;salta si vleft <vright (signed)
	mov bx,word[di+pol.Acoef]
	call setOrientacionPol
	jmp .break
.alMenor2:
	mov al, byte[di+pol.bExpo]	
	mov bx,word[di+pol.Bcoef]
	call setOrientacionPol
	jmp .break


	; tres terminos
.term3:
	cmp cl,3
	jne .term4
	mov al, byte[di+pol.aExpo]
	mov bl, byte[di+pol.bExpo]
	cmp al,bl		; aExpo < bExpo
	jl .bExpoMayor3 ;salta si vleft <vright (signed)
	; aExpo mayor que bExpo
	mov bl,byte[di+pol.cExpo]
	cmp al,bl		;aExpo < cExpo
	jl .cExpoMayor3		;salta si vleft <vright (signed)
	; aExpo mayor que cExpo
	mov bx,word[di+pol.Acoef]
	call setOrientacionPol
	jmp .break
.bExpoMayor3:
	; bExpo mayor que aExpo	
	mov al,byte[di+pol.cExpo]
	cmp bl,al		;bExpo < cExpo
	jl .cExpoMayor3		;salta si vleft <vright (signed)
	; bExpo mayor que cExpo
	mov al, byte[di+pol.bExpo]	
	mov bx,word[di+pol.Bcoef]
	call setOrientacionPol
	jmp .break
.cExpoMayor3:
	mov al, byte[di+pol.cExpo]
	mov bx,word[di+pol.Ccoef]
	call setOrientacionPol
	jmp .break

	
	; cuatro terminos
.term4:
	cmp cl,4
	jne .term5
	mov al, byte[di+pol.aExpo]
	mov bl, byte[di+pol.bExpo]
	cmp al,bl		; aExpo < bExpo
	jl .bExpoMayor4 ;salta si vleft <vright (signed)
	; aExpo mayor que bExpo
	mov bl,byte[di+pol.cExpo]
	cmp al,bl		;aExpo < cExpo
	jl .cExpoMayor4		;salta si vleft <vright (signed)
	; aExpo mayor que cExpo
	mov bl,byte[di+pol.dExpo]
	cmp al,bl
	jl .dExpoMayor4		;salta si vleft <vright (signed)
	; aExpo mayor que dExpo	
	mov bx,word[di+pol.Acoef]
	call setOrientacionPol
	jmp .break
.bExpoMayor4:
	; bExpo mayor que aExpo	
	mov al,byte[di+pol.cExpo]
	cmp bl,al		;bExpo < cExpo
	jl .cExpoMayor4		;salta si vleft <vright (signed)
	; bExpo mayor que cExpo
	mov al,byte[di+pol.dExpo]
	cmp bl,al		;bExpo < dExpo
	jl .dExpoMayor4		;salta si vleft <vright (signed)
	; bExpo mayor que dExpo
	mov al, byte[di+pol.bExpo]	
	mov bx,word[di+pol.Bcoef]
	call setOrientacionPol
	jmp .break
.cExpoMayor4:
	; cExpo mayor que bExpo
	mov bl, byte[di+pol.dExpo]
	cmp al,bl		;cExpo < dExpo
	jl .dExpoMayor4		;salta si vleft <vright (signed)	
	; cExpo mayor que dExpo
	mov al, byte[di+pol.cExpo]
	mov bx,word[di+pol.Ccoef]
	call setOrientacionPol
	jmp .break
.dExpoMayor4:
	; dExpo mayor que todos
	mov al, byte[di+pol.dExpo]
	mov bx,word[di+pol.Dcoef]
	call setOrientacionPol
	jmp .break


	
	; cinco terminos
.term5:
	mov al, byte[di+pol.aExpo]
	mov bl, byte[di+pol.bExpo]
	cmp al,bl		; aExpo < bExpo
	jl .bExpoMayor5 ;salta si vleft <vright (signed)
	; aExpo mayor que bExpo
	mov bl,byte[di+pol.cExpo]
	cmp al,bl		;aExpo < cExpo
	jl .cExpoMayor5		;salta si vleft <vright (signed)
	; aExpo mayor que cExpo
	mov bl,byte[di+pol.dExpo]
	cmp al,bl		;aExpo < dExpo
	jl .dExpoMayor5		;salta si vleft <vright (signed)
	; aExpo mayor que dExpo
	mov bl,byte[di+pol.eExpo]
	cmp al,bl		;aExpo < eExpo
	jl .eExpoMayor5		;salta si vleft <vright (signed)
	; aExpo mayor que eExpo
	mov bx,word[di+pol.Acoef]
	call setOrientacionPol
	jmp .break
.bExpoMayor5:
	; bExpo mayor que aExpo	
	mov al,byte[di+pol.cExpo]
	cmp bl,al		;bExpo < cExpo
	jl .cExpoMayor5		;salta si vleft <vright (signed)
	; bExpo mayor que cExpo
	mov al,byte[di+pol.dExpo]
	cmp bl,al		;bExpo < dExpo
	jl .dExpoMayor5		;salta si vleft <vright (signed)
	; bExpo mayor que dExpo
	mov al,byte[di+pol.eExpo]
	cmp bl,al		;bExpo < eExpo
	jl .eExpoMayor5		;salta si vleft <vright (signed)
	; bExpo mayor que eExpo
	mov al, byte[di+pol.bExpo]	
	mov bx,word[di+pol.Bcoef]
	call setOrientacionPol
	jmp .break
.cExpoMayor5:
	; cExpo mayor que bExpo
	mov bl, byte[di+pol.dExpo]
	cmp al,bl		;cExpo < dExpo
	jl .dExpoMayor5		;salta si vleft <vright (signed)
	; cExpo mayor que dExpo
	mov bl, byte[di+pol.eExpo]
	cmp al,bl		;cExpo < eExpo
	jl .eExpoMayor5		;salta si vleft <vright (signed)
	; cExpo mayor que eExpo
	mov al, byte[di+pol.cExpo]
	mov bx,word[di+pol.Ccoef]
	call setOrientacionPol
	jmp .break
.dExpoMayor5:
	; dExpo mayor que cExpo
	mov al, byte[di+pol.eExpo]
	cmp bl,al		;dExpo < eExpo
	jl .eExpoMayor5		;salta si vleft <vright (signed)
	; dExpo mayor que eExpo
	mov al, byte[di+pol.dExpo]
	mov bx,word[di+pol.Dcoef]
	call setOrientacionPol	
	jmp .break
.eExpoMayor5:
	; eExpo mayor que todos
	mov al, byte[di+pol.eExpo]
	mov bx,word[di+pol.Ecoef]
	call setOrientacionPol	

	
.break:
	pop cx
	ret



	; ** setOrientacionPol
	; |Establecer si un polinomio de grado 1,2,3 o 4, es positivo
	; |o negativo. Para uso exclusivo de rutina =conocerGrado=.
	; |+ Entradas
	; |  - bx :: coeficiente del termino de exponenete mayor
	; |+ Salidas
	; |  - ah :: POL_POSITIVO si positivo y POL_POSITIVO-1 si
	; |          negativo 
setOrientacionPol:
	cmp bx,0
	jl .positivo_e ;salta si vleft <vright (signed)
	mov ah, POL_POSITIVO
	jmp .return
.positivo_e:
	mov ah, POL_POSITIVO-1
.return:
	ret

	; --------------------------------------------------
	; ** re''
	; --------------------------------------------------
resolver:
	mov byte[n_ter],SOLVE	;tres terminos permitidos (n_ter lo
	;utiliza el analizador lexico)

	LIMPIAR_PANTALLA
	PRINT 2,14,strLinEnc
	PRINT 3,30,str6Res
	PRINT 4,14,strLinEnc
	PRINT 7,14,str6Intro

	call printInfoEsquina

	UBICAR_CURSOR 9,14
	mov al, byte[n_pol]
	add al,65
	PRINT_CHAR al
	PRINT_CHAR '('
	PRINT_CHAR 'x'
	PRINT_CHAR ')'
	PRINT_CHAR BARRA
	READ_FOR_BUFF_INPUT buffInput
	
	UBICAR_CURSOR 12,14

	mov di, buffInput
	inc di
	mov bl, [di]		;bx=tamaño cadena ingresada
	inc di
	mov byte[di+bx],';'	;fin de cadena p/analisis lexico


	mov al, byte[n_pol]
	xor ah,ah		;este parrafo para comparar despues si
	push ax; aumento el numero de polinomios y asi saber si fue aceptado

	push di
	mov di,word[p]
	push di
	call scanner

	pop ax
	cmp al, byte[n_pol]
	je .noAumentoN_pol

	; ini-resolviendo ecuacion -----------------------------
	mov ax,14
	push ax
	mov di,word[p]
	call resolver_ecuacion
	jc .noAumentoN_pol	;salta solo si CF=1
	; fin-resolviendo ecuacion -----------------------------
	
	
	; imprimir nuevamente cantidad de funciones en el sistema
	call printInfoEsquina

	
	; aumentar p para que apunte a la siguiente estructura
	mov di,word[p]
	add di,pol.size
	mov word[p],di

	; aumentar s para que apunte a la siguiente estructura
	mov di,word[s]
	mov byte[di+dein.tipo],NINGUNO ;para identificar desde una
	;estructura dein si en la posicion actual se resolvio ecuacion.
	add di,dein.size
	mov word[s],di

.noAumentoN_pol:
	

	UBICAR_CURSOR 18,14
	GETCHAR strVolver
	ret

	; ** resolver_ecuacion
	; |Resuelve una ecuación polinómica de grado dos como
	; |máximo. Encuentra raíces reales (enteros). Raices que son
	; |raccionales (fraccion) o irracionales no los encuentra.
	; |+ Parametros
	; |  - [BP+4] :: fila en que se muestran los mensajes
	; |+ Entrada
	; |  - di :: puntero a estructura que contiene el polinomio a
	; |          resolver.
	; |+ Salida
	; |  - CF=1 :: si la ecuacion no es cuadrática
resolver_ecuacion:
	PROLOGO 0
	; en di debe estar el polinomio a resolver
	call conocerGrado
	cmp al,2		; grado > 2
	ja .noCuadratico	;salta si vleft >vright

	mov byte[di+pol.eExpo],0 ;eExpo utilizada para contar las
	                         ;soluciones 

	mov byte[di+pol.tipo],SOLVE
	; -----encontrado soluciones
	mov cx,-100	
.loop_eval:

	; di contiene ecuacion original
	push cx			;# a evaluar
	call evalPol		;resultado en ax
	jo .next		;si hubo desborde hacia DX cuando se
	;hizo la evaluacion. Esto es porque se manejan solo un numero
	;signado de 16 bist como maximo (AX).

	; cx=x
	; ax=f(x)
	cmp ax,0
	jne .next		;if(ax=0) cx=solucion
	push cx
	inc byte[di+pol.eExpo]
.next:	
	inc cx
	cmp cx, 100
	jne .loop_eval

	; -----sacando soluciones de la pila, guardandolo en pol.sol1 y
	; pol.sol2

	cmp byte[di+pol.eExpo],0
	jne .sol1
	PRINT [bp+4],18, str6SinSolucion
	jmp .fin_sol
.sol1:
	cmp byte[di+pol.eExpo],1
	jne .sol2
	PRINT [bp+4],18, str6Sol1
	pop ax
	mov byte[di+pol.sol1],al
	call printNumBin
	jmp .fin_sol
.sol2:
	PRINT [bp+4],18, str6Sol1	
	pop ax
	mov byte[di+pol.sol2],al
	call printNumBin
	mov dh,[bp+4]
	add dh,1
	PRINT dh,18, str6Sol2	
	pop ax
	mov byte[di+pol.sol1],al
	call printNumBin
	
.fin_sol:

	jmp .fin_resoviendo
.noCuadratico:
	PRINT [bp+4],14, str6NoCuadratico
	dec byte[n_pol]
	stc 			;pone CF=1
.fin_resoviendo:
	EPILOGO 1

	
	; --------------------------------------------------
	; ** rep''
	; --------------------------------------------------
	; |Crear reportes.
	; |+ Variables locales
	; |  - [BP-2] :: handle de archivo ya sea el creado para
	; |              polinomios del sistema o bien el creado para
	; |              ecuaciones resueltas. Es uno o el otro nunca
	; |              ámbos.
	; |  - [BP-4] :: contador del bucle
	; |  - [BP-6] :: para llevar la letra de cada funcion
	; |  - [BP-8] :: temporal para la evaluacion de puntos
	; |  - [BP-10] :: igual que el anterior
reportes:
	PROLOGO 5
	LIMPIAR_PANTALLA
	PRINT 2,14,strLinEnc
	PRINT 3,35,str7Rep
	PRINT 4,14,strLinEnc
	
	PRINT 8,21,str7Menu

	; el usuario ESCOJE opcion 1,2 o 3
	PRINT 14,21, str7Op
.escoje:
	GETCHAR
	cmp al,'1'
	jne .resueltas

	; ini-polinomios del sistema ---------------------------
	
	CREAR_ARCHIVO str7polsis
	jc .noSeCreo		;salta solo si CF=1
	mov word[bp-2],ax	;guardar handle

	
	ESENAR word[bp-2],str7Encab.len,str7Encab

	mov cl,byte[n_pol]
	xor ch,ch
	mov [bp-4],cx
	cmp byte[bp-4],0
	jne .sihaypoli

	ESENAR word[bp-2],str7NewLine.len,str7NewLine
	ESENAR word[bp-2],str4NoPol.len-1,str4NoPol

	jmp .deNuevo
.sihaypoli:

	ESENAR word[bp-2],str7T.len,str7T
	mov cl,65
	mov ch,ch
	mov [bp-6],cx
	mov di,polArr		;arr de estruc de polms originales
	mov si,deinArr		;arr de estruc de polms deriv/integ
.llistpol:

	mov al,byte[di+pol.tipo]
	cmp al,SOLVE
	je .esdein_fin
	; ini-ES DErivada o INtegral

	
	; imprimir polinomio
	mov bx,[bp-6]
	push bx
	ESENAR word[bp-2],1,sp
	pop bx

	mov bx,'('
	push bx
	ESENAR word[bp-2],1,sp
	pop bx

	mov bx,'x'
	push bx               
	ESENAR word[bp-2],1,sp
	pop bx

	mov bx,')'
	push bx               
	ESENAR word[bp-2],1,sp
	pop bx                

	mov bx,'='
	push bx               
	ESENAR word[bp-2],1,sp
	pop bx                


	mov ax,word[bp-2]
	push ax
	push di
	call printPol_f
	
		
	; imprimir la derivada o integral  ---------------
	ESENAR word[bp-2],str7T.len,str7T

	mov al,byte[si+dein.tipo]
	cmp al,DERIVADA
	jne .esder_e

	mov bx,'d'
	push bx               
	ESENAR word[bp-2],1,sp
	pop bx                

	mov bx,[bp-6]
	push bx
	ESENAR word[bp-2],1,sp
	pop bx

	mov bx,'/'
	push bx               
	ESENAR word[bp-2],1,sp
	pop bx                

	mov bx,'d'
	push bx               
	ESENAR word[bp-2],1,sp
	pop bx                

	mov bx,'x'
	push bx               
	ESENAR word[bp-2],1,sp
	pop bx                	

	mov bx,SPC
	push bx               
	ESENAR word[bp-2],1,sp
	pop bx                

	mov bx,'='
	push bx               
	ESENAR word[bp-2],1,sp
	pop bx                

	mov bx,SPC
	push bx               
	ESENAR word[bp-2],1,sp
	pop bx
	
        mov ax,word[bp-2]
	push ax

	push si
	call printPol_f

	jmp .esder_fin
.esder_e:			;ES DERivada Else

	mov bx, ANSI_INT    ;simbolo de integral
	push bx               
	ESENAR word[bp-2],1,sp
	pop bx                

	mov bx,[bp-6]
	push bx               
	ESENAR word[bp-2],1,sp
	pop bx                

	mov bx,'d'
	push bx               
	ESENAR word[bp-2],1,sp
	pop bx                

	mov bx,'x'
	push bx               
	ESENAR word[bp-2],1,sp
	pop bx

	mov bx,SPC
	push bx               
	ESENAR word[bp-2],1,sp
	pop bx                

	mov bx,'='
	push bx               
	ESENAR word[bp-2],1,sp
	pop bx                

	mov bx,SPC
	push bx               
	ESENAR word[bp-2],1,sp
	pop bx

        mov ax,word[bp-2]
	push ax

	push si
	call printPol_f

	mov bx,'+'		;imprimir constante C
	push bx               
	ESENAR word[bp-2],1,sp
	pop bx

	mov bx,'C'
	push bx               
	ESENAR word[bp-2],1,sp
	pop bx
.esder_fin:
	; ini-evaluar puntos
	ESENAR word[bp-2],str7Ptn.len,str7Ptn

	mov cx,5
	mov [bp-8],cx	
	mov bx,0
	mov [bp-10],bx
.eval:
	mov bx,POS_CON_MAS-1
	push bx
	mov bx, [bp-2]		;handle
	push bx
	mov ax,[bp-10]
	call printNumBin_f	;en ax num a imprimir
	

	mov bx,','
	push bx               
	ESENAR word[bp-2],1,sp
	pop bx                

	
	; di contiene ecuacion original
	mov ax,[bp-10]
	push ax
	call evalPol		;resultado en ax

	mov bx,POS_CON_MAS-1
	push bx
	mov bx, [bp-2]		;handle
	push bx
	call printNumBin_f	;en ax num a imprimir

	ESENAR word[bp-2],str7NewLine.len,str7NewLine
	ESENAR word[bp-2],str7NewLine.len,str7NewLine
	ESENAR word[bp-2],str7T.len,str7T

	inc word[bp-10]
	dec word[bp-8]
	jnz .eval		;bucle
	; fin-evaluar puntos

.esdein_fin:
	; fin-ES DErivada o INtegral
	


	inc byte[bp-6]		;aumentar letra
	add di,pol.size		;mover sig. estruc de pol origin
	add si,dein.size	;mover sig. estruc de deriv/integ
	dec byte[bp-4]
	JNZ .llistpol		;bucle
	

.deNuevo:
	PRINT 17,21, str7repCreado
	PRINT str7polsis_print
	PRINT_CHAR SPC
	PRINT_CHAR '.'
	PRINT_CHAR '.'
	CERRAR_ARCHIVO word[bp-2]
	GETCHAR
	DESPLAZAR_ARRIBA 17,21,18,58,1
	UBICAR_CURSOR 14,49
	jmp .escoje
.noSeCreo:
	PRINT 17,21, str7NoCreadoRep
	PRINT_CHAR SPC
	PRINT_CHAR '.'
	PRINT_CHAR '.'
	GETCHAR
	DESPLAZAR_ARRIBA 17,21,18,58,1
	UBICAR_CURSOR 14,49
	; fin-polinomios del sistema --------------------------	

	jmp .escoje
.resueltas:	
	cmp al,'2'
	jne .menu_principal

	; ini-ecuaciones resueltas -----------------------------
	
	CREAR_ARCHIVO str7ecures ;ECURES.TXT
	jc .noSeCreo2		;salta solo si CF=1
	mov word[bp-2],ax	;guardar handle

	ESENAR word[bp-2],str7Encab2.len,str7Encab2

	mov cl,byte[n_pol]
	xor ch,ch
	mov [bp-4],cx
	cmp byte[bp-4],0
	jne .sihaypoli2

	ESENAR word[bp-2],str7NewLine.len,str7NewLine
	ESENAR word[bp-2],str4NoPol.len-1,str4NoPol

	jmp .deNuevo2
.sihaypoli2:

	ESENAR word[bp-2],str7T.len,str7T
	mov cl,65
	mov ch,ch
	mov [bp-6],cx
	mov di,polArr		;arr de estruc de polms originales
	mov si,deinArr		;arr de estruc de polms deriv/integ
.llistpol2:
	
	mov al,byte[di+pol.tipo]
	cmp al,SOLVE
	jne .next

	; imprimir polinomio
	mov bx,[bp-6]
	push bx
	ESENAR word[bp-2],1,sp
	pop bx

	mov bx,'('
	push bx
	ESENAR word[bp-2],1,sp
	pop bx

	mov bx,'x'
	push bx               
	ESENAR word[bp-2],1,sp
	pop bx

	mov bx,')'
	push bx               
	ESENAR word[bp-2],1,sp
	pop bx                

	mov bx,'='
	push bx               
	ESENAR word[bp-2],1,sp
	pop bx                


	mov ax,word[bp-2]
	push ax
	push di
	call printPol_f


	; ini-imprimir soluciones
	ESENAR word[bp-2],str7T.len,str7T

	cmp byte[di+pol.eExpo],0
	jne .sol1
	ESENAR word[bp-2],str6SinSolucion.len-1,str6SinSolucion
	jmp .fin_sol
.sol1:
	cmp byte[di+pol.eExpo],1
	jne .sol2

	ESENAR word[bp-2],str6Sol1.len-1,str6Sol1

	mov al,byte[di+pol.sol1]
	cbw			;convertir AL a AX con signo
	
	mov bx,POS_CON_MAS-1
	push bx
	mov bx, [bp-2]		;handle
	push bx
	call printNumBin_f	;en ax num a imprimir

	jmp .fin_sol
.sol2:
	; primera solucion
	ESENAR word[bp-2],str6Sol1.len-1,str6Sol1

	mov al,byte[di+pol.sol1]
	cbw			;convertir AL a AX con signo
	
	mov bx,POS_CON_MAS-1
	push bx
	mov bx, [bp-2]		;handle
	push bx
	call printNumBin_f	;en ax num a imprimir

	mov bx,SPC
	push bx               
	ESENAR  word[bp-2],1,sp
	pop bx                

	; segunda solucion
	ESENAR word[bp-2],str6Sol2.len-1,str6Sol2
	
	mov al,byte[di+pol.sol2]
	cbw			;convertir AL a AX con signo

	mov bx,POS_CON_MAS-1
	push bx
	mov bx, [bp-2]		;handle
	push bx
	call printNumBin_f	;en ax num a imprimir
	
.fin_sol:

	ESENAR word[bp-2],str7NewLine.len,str7NewLine
	ESENAR word[bp-2],str7NewLine.len,str7NewLine
	ESENAR word[bp-2],str7T.len,str7T

	; fin-imprimir soluciones
	
	
.next:
	inc byte[bp-6]		;aumentar letra
	add di,pol.size		;mover sig. estruc de pol origin
	add si,dein.size	;mover sig. estruc de deriv/integ
	dec byte[bp-4]
	JNZ .llistpol2		;bucle
	
.deNuevo2:
	PRINT 17,21, str7repCreado
	PRINT str7ecures_print
	PRINT_CHAR SPC
	PRINT_CHAR '.'
	PRINT_CHAR '.'
	CERRAR_ARCHIVO word[bp-2]
	GETCHAR
	DESPLAZAR_ARRIBA 17,21,18,58,1
	UBICAR_CURSOR 14,49	
	jmp .escoje
	
.noSeCreo2:
	PRINT 17,21, str7NoCreadoRep
	PRINT_CHAR SPC
	PRINT_CHAR '.'
	PRINT_CHAR '.'
	GETCHAR
	DESPLAZAR_ARRIBA 17,21,18,58,1
	UBICAR_CURSOR 14,49
	; fin-ecuaciones resueltas -----------------------------

	jmp .escoje
	
.menu_principal:
	cmp al,'3'
	jne .escoje

.return:
	EPILOGO 0


	; =======================================================
	; LAS RUTINAS UBICADAS AL FINAL DEL ARCHIVO SON INVOCADAS POR
	; OTRAS EN DISTINTAS PARTES. POR LO QUE PUEDE DECIRSE QUE LAS
	; QUE VIENEN A CONTINUACION, SON GENERALES.
	; =======================================================

	
	; ** printInfoEsquina
	; |imprimir cantidad de polinomios actuales en el sistema y
	; |cuanto es el maximo que puede ingresarse. Esto en la
	; |esquina inferior derecha.
printInfoEsquina:
	UBICAR_CURSOR 21,45
	PRINT_CHAR FLECHA_DER
	PRINT_CHAR SPC
	mov al, byte[n_pol]
	xor ah,ah
	call printNumBin
	PRINT_CHAR '/'
	mov al, polArr.len
	xor ah,ah
	call printNumBin
	PRINT_CHAR SPC
	PRINT strPoli
	PRINT_CHAR SPC
	PRINT_CHAR FLECHA_IZQ
	ret


	; ** evalPol
	; |Evaluar polinomio de 5 terminos como maximo
	; |+ Entradas:
	; |  - di :: puntero a estructura que contiene el
	; |          polinomio a evaluar
	; |+ Parámetros
	; |  - [PB+4] :: número a evaluar de un word (x)
	; |+ Variables locales
	; |  - [BP-2] :: temporal que al final será ax
	; |  - [BP-4] :: contador para bucle mayor
	; |+ Salidas
	; |  - ax :: el resultado de la evaluación (y)
	; 
evalPol:
	PROLOGO 2
	push cx			;protoger p/eventual llamada dentro loop
	push bx
	
	mov word[bp-4],0 ;contador bucle mayor
	
	cmp byte[di+pol.n],0
	je .return

.lpol:
	cmp word[bp-4],0
	jne .coefb

	; primer termino ---------------
	mov ax,1
	mov cl,byte[di+pol.aExpo] ;exponente
	xor ch,ch
	cmp cx,0
	je .expocero1		;si exponenete=0 ax mantiene el 1
.t1:
	imul word[bp+4] ;[bp+4] num a eval
	jo .return	;retornar si hay desborde hacia DX
	loop .t1

.expocero1:
	mov cx,word[di+pol.Acoef]
	imul cx			;exponente*coeficiente
	jo .return
	mov [bp-2],ax
	; AX=AL*opbyte
	; DX:AX=AX*opword
	
	jmp .break	

.coefb:
	cmp word[bp-4],1
	jne .coefc

	; segundo termino ---------------
	mov ax,1
	mov cl,byte[di+pol.bExpo] ;exponente
	xor ch,ch
	cmp cl,0
	je .expocero2		;si exponenete=0 ax mantiene el 1	
.t2:	
	imul word[bp+4] ;[bp+4] num a eval
	jo .return	;retornar si hay desborde hacia DX
	loop .t2

.expocero2:
	mov cx,word[di+pol.Bcoef]
	imul cx			;exponente*coeficiente
	jo .return
	mov cx,[bp-2]
	add ax,cx
	mov [bp-2],ax
	; AX=AL*opbyte
	; DX:AX=AX*opword
	
	jmp .break


.coefc:
	cmp word[bp-4],2
	jne .coefd

	; tercer termino
	mov ax,1
	mov cl,byte[di+pol.cExpo] ;exponente
	xor ch,ch
	cmp cl,0
	je .expocero3		;si exponenete=0 ax mantiene el 1
.t3:	
	imul word[bp+4] ;[bp+4] num a eval
	jo .return	;retornar si hay desborde hacia DX	
	loop .t3

.expocero3:	
	mov cx,word[di+pol.Ccoef]
	imul cx			;exponente*coeficiente
	jo .return
	mov cx,[bp-2]
	add ax,cx
	mov [bp-2],ax
	; AX=AL*opbyte
	; DX:AX=AX*opword
	
	jmp .break

.coefd:
	cmp word[bp-4],3
	jne .coefe

	; cuarto termino
	mov ax,1
	mov cl,byte[di+pol.dExpo] ;exponente
	xor ch,ch	
	cmp cl,0
	je .expocero4		;si exponenete=0 ax mantiene el 1
.t4:	
	imul word[bp+4] ;[bp+4] num a eval
	jo .return	;retornar si hay desborde hacia DX	
	loop .t4

.expocero4:	
	mov cx,word[di+pol.Dcoef]
	imul cx			;exponente*coeficiente
	jo .return
	mov cx,[bp-2]
	add ax,cx
	mov [bp-2],ax
	; AX=AL*opbyte
	; DX:AX=AX*opword

	jmp .break

.coefe:
	; quinto termino
	mov ax,1
	mov cl,byte[di+pol.eExpo] ;exponente
	xor ch,ch	
	cmp cl,0
	je .expocero5		;si exponenete=0 ax mantiene el 1
.t5:	
	imul word[bp+4] ;[bp+4] num a eval
	jo .return	;retornar si hay desborde hacia DX	
	loop .t5

.expocero5:	
	mov cx,word[di+pol.Dcoef]
	imul cx			;exponente*coeficiente
	jo .return
	mov cx,[bp-2]
	add ax,cx
	mov [bp-2],ax
	; AX=AL*opbyte
	; DX:AX=AX*opword

.break:

	inc byte[bp-4]
	mov cl,byte[di+pol.n]
	cmp byte[bp-4],cl
	jne .lpol		;bucle mayor
	
	mov ax,[bp-2]		;retorno
.return:	
	pop bx
	pop cx
	EPILOGO 1
	
	
