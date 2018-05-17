	; |- Descripcion :: Contiene la funcion 'scanner' que realiza
	; |    el analisis lexico de una funcion polinomica de grado 4 con
	; |    coeficientes de dos digitos positivos o negativos. Un
	; |    termino correcto debe iniciar con '+' o '-' seguido de cero,
	; |    uno o dos digitos. Luego puede venir o no una 'x' o bien
	; |    'x^' seguido por '2' o '3' o '4'. La expresion regular es la
	; |    siguiente:
	; |       
	; |    ER=(('+'|'-')(<d>?<d>)?[x^<expo>|x]?)+;
	; |    donde: <d>=0|1|2|3|4|5|6|7|8|9 y <expo>=2|3|4
	; |         
	; |    Estos son algunos ejemplos de cadenas lexicamente
	; |    correctas para este lenguaje (debe terminar en ';'): 
	; |                 +2x+1-99x  +29  +x +29;
	; |                 -90x^3 +5  5x^2;
	; |
	; |    los espacios en blanco los ignora    
	; |  
	; |- Autor :: Wilson S. Tubin

	; Emacs. Para probar, o dejar de probar, codigo de este
	; archivo, conmutar entre ER1 y ER2:
	;       ER1= `;\(.+\);\(\[test\]\)$´ -> ER2 = `\1;\2´
	; dependiendo el caso.

	; ==================================================
	; * i'' INCLUSIONES
	; ==================================================
;%include "stack_frame.mac"	;[test]
;%include "io.mac"		;[test]

	; ==================================================
	; * es'' ESTRUCTURAS. Definicion
	; ==================================================
struc pol			;POLinomio
.Acoef: resw 1
.aExpo: resb 1
.Bcoef: resw 1
.bExpo: resb 1
.Ccoef: resw 1
.cExpo: resb 1
.Dcoef: resw 1
.dExpo: resb 1
.Ecoef: resw 1
.eExpo: resb 1			;(1)
.sol1: resb 1			;solucion 1
.sol2: resb 1			;solucion 2
.tipo: resb 1			;si permite 3 o 5 terminos (2)
.n: resb 1			;numero de terminos llenos
.size:
endstruc
	; (1) Cuando se trata de un polinomio del cual se le encuentra
	; las soluciones, eExpo guarda el número de soluciones (1 o 2
	; o 0). Cuando el polinomio es para integrar o derivar eExpo
	; guarda el exponente del quinto termino como es normal.
	; (2) Lo determina el analizador lexico y es usado despues
	; para saber si se trata de un polinomio que se ha
	; derivado/integrado (tipo=5) o si es un polinomio del cual se
	; encontro su solución (tipo=3).

	; valores de pol.tipo
%define SOLVE 3	    ;identifica polinomio si es para resolver
%define DERINT 5    ;identifica polinomio si es para derivar/integrar
	

	

struc dein			;DErivada, INtegral
.Acoef: resw 1
.aExpo: resb 1
.Bcoef: resw 1
.bExpo: resb 1
.Ccoef: resw 1
.cExpo: resb 1
.Dcoef: resw 1
.dExpo: resb 1
.Ecoef: resw 1
.eExpo: resb 1	
.sol1: resb 1			;incluido solo por compatibilidad con pol
.sol2: resb 1			;incluido solo por compatibilidad con pol
.tipo: resb 1			;si es derivada o integral (1)
.n: resb 1			;numero de terminos llenos
.size:
endstruc
	; (1) Se determina cuando se deriva o integra y es utilizado
	; cuando se imprimen las funciones del sistema tanto en salida
	; estandar como en archivo. Si es integral
	; tipo=20=INTEGRAL. Si es derivada tipo=10=DERIVADA

	; valores de dein.tipo
%define DERIVADA 10 ;identifica polinomio es derivada de otra
%define INTEGRAL 20 ;identifica polinomio es integral de otra
%define NINGUNO -1  ;identifica cuando en la estructura actual no
	;existe ni derivada ni integral de otra. Es utilizado cuando
	;se resuelve una ecuación ya que, cuando esto ocurre, no es
	;utilizada dein.
	
	
	

	; ==================================================
	; * mml'' MACROS MULTI LINEA
	; ==================================================

	; mapeo lexicografico para tablaDeTransiciones
	; llamar asi: TB i, j
	; la respuesta en AL
%macro TB 2
	mov al, 7		;ancho de la tabla (# columnas)
	mov ah, %1		;i
	mul ah
	add al, %2		;j

	mov bx,ax
	mov al, [tablaTransiciones+bx]
%endmacro


	; ==================================================
	; * mdl'' MACROS DE LINEA
	; ==================================================
	
	; columnas de TB
%define SIGNO_MAS 0
%define SIGNO_MENOS 1
%define DIGITO 2
%define X 3
%define POW 4
%define EXPONENTE 5
%define FDC 6

	; filas de TB
%define A 0
%define B 1
%define C 2
%define D 3
%define E 4
%define F 5

	; constantes para identificar error y aceptar cadena
%define ERROR 20
%define ACEPTAR 21


	; ==================================================
	; * se'' SEGMENTO EXTRA (ES)
	; ==================================================
section .bss
polArr: resb pol.size*15  ; reservar espacio para 15 estructuras
.len:	equ ($ - polArr) / pol.size ; polArr.len=15
p: resw 1;apuntador al arreglo de polinomios (polArr)
	;justo donde toca llenar

deinArr: resb dein.size*15  ; reservar espacio para 15 estructuras
.len:	equ ($ - deinArr) / dein.size ; deinArr.len=15
s: resw 1;apuntador al arreglo de derivada/integral (deinArr)
	;justo donde toca llenar
	

	
c: resw 1;para guardar caracter leido de archivo
	
	; ==================================================
	; * sdd'' SEGMENTO DE DATOS
	; ==================================================
section .data
;ej: db '+34x-99x^3-4+x;';[test]
msj1: db PUNTOM,'Error lexico',PUNTOM,' caracter no reconocido:',R,N,'$'
msj2: db PUNTOM,'Error lexico',PUNTOM,' mal posicionado:',R,N,'$'
msj3: db 'Expresion polinomica reconocida$'
msjFil: db T,T,T,CUADRITO,SPC,'Fila: $'
msjCol: db R,N,T,T,T,CUADRITO,SPC,'Columna: $'
msjCaracter: db R,N,T,T,T,CUADRITO,SPC,'Caracter: ',BACKTICK,'$'
msjFinArchivo: db `Fin del archivo.$`

	
tablaTransiciones: db \
	  B,     B,   ERROR, ERROR, ERROR, ERROR, ERROR,\
	ERROR, ERROR,   C,     D,   ERROR, ERROR, ERROR,\
	  B,     B,     E,     D,   ERROR, ERROR, ACEPTAR,\
	  B,     B,   ERROR, ERROR,   F,   ERROR, ACEPTAR,\
	  B,     B,   ERROR,   D,   ERROR, ERROR, ACEPTAR,\
	ERROR, ERROR, ERROR, ERROR, ERROR,   D,   ERROR

n_pol: db 0			;polinomios actuales en el sistema
n_ter: db SOLVE			;numero de terminos permitidos por funcion

fila:	db 1			;para guarda la fila que actualmente
				;se esta leyendo y mantenerla guardada
				;entre llamadas de scanner_f
	
msjNumTermIncorrecto: db R,N,T,T,'Se excedio en el numero de terminos.'
	              db R,N,T,T,'Maximo son ','$'

msjNumPolIncorrecto: db R,N,T,T,'Ya se llenaron los 15 espacios$'

	; ==================================================
	; * sdc'' SEGMENTO DE CODIGO
	; ==================================================
;[bits 16]			;[test]
;[cpu 8086]			;[test]
;org 100h			;[test]
section .text
;	mov ax,ej		;[test]
;	push ax			;[test]
;	mov ax,polArr		;[test]
;	push ax			;[test]
;	call scanner		;[test]

;	TERMINAR_PROGRAMA	;[test]

	
	; --------------------------------------------------
	; ** scanner
	; --------------------------------------------------
	; |Realiza un analisis lexico de la cadena terminada en ';'. Muestra fila
	; |y columna si ocurre error. Muestra exito si se reconoce la
	; |cadena. Guarda los exponentes y coeficientes en una arreglo de
       	; |estructuras.
       	; |+ Parametro
  	; |  - [BP+6] :: puntero al primer elemento del arreglo de chars a
  	; |              analizar
	; |  - [BP+4] :: puntero a estructura que guarda coeficientes y
	; |              exponentes y otros datos de la funcion.
  	; |+ Variables Locales
  	; |  1. [BP-2]  fila
  	; |  2. [BP-4]  columna
  	; |  3. [BP-6]  entrada
  	; |  4. [BP-8]  estado
  	; |  5. [BP-0xA]  exponente
	; |  6. [BP-0xC]  primer char ascii de un coeficiente
	; |  7. [BP-0xE]  segundo char ascii de un coeficiente
	; |  8. [BP-0x10]  tercer char ascii de un coeficiente
	; |  9. [BP-0x12]  numero de chars que forman el coeficiente
	; | 10. [BP-0x14] contador de terminos por funcion
scanner:
	PROLOGO 10

	; parametros
	mov si,[bp+6]		;SI = apuntador arreglo de chars

	mov di, [bp+4]
	mov dl, byte[n_ter]
	xor dh, dh
	mov [di+pol.tipo],dl

	; inicializacion de variables locales
	mov word[bp-2],1	;fila=1
	mov word[bp-4],0	;columa=0
	mov word[bp-6],0	;entrada=0
	mov word[bp-8],0	;estado=0
	mov word[bp-0xA],0 	;exponente=0
	mov word[bp-0xC],0 	;coeficiente[0]=0
	mov word[bp-0xE],0 	;coeficiente[1]=0
	mov word[bp-0x10],0 	;coeficiente[2]=0
	mov word[bp-0x12],0 	;n=0
	mov word[bp-0x14],0	;como n_ter pero temporal


	; validar maximo de ecuaciones (quince)
	mov dl, byte[n_pol]
	cmp dl,polArr.len
	jnae .num_pol_correcto 	;salta si vleft <vright
	PRINT msjNumPolIncorrecto
	jmp .exit

.num_pol_correcto:	
	
	cld			;conteo ascendente de SI
.do:
	lodsb 			;AL=[DS:SI] y SI=SI+1 esta ins-
	;truccion carga en AL el siguiente caracter de SI
	
	cmp al,0x0d		;c=='\r'
	jne .colfil_t
	mov word[bp-4],0x00	;columna=0
	inc byte[bp-2]		;fila++
	jmp .do
.colfil_t:
	cmp al,SPC		;c==' '
	jne .colfil_t_t
	inc byte[bp-4]		;columna++
	jmp .do
.colfil_t_t:
	inc byte[bp-4]		;columna++


.switch:
	cmp al,'0'
	je short .digito
	cmp al,'1'
	je short .digito
	cmp al,'5'
	je short .digito
	cmp al,'6'
	je short .digito
	cmp al,'7'
	je short .digito
	cmp al,'8'
	je short .digito
	cmp al,'9'
	je short .digito
	jne .caso2
.digito:
	; ini-manejarCoeficiente1
	cmp byte[bp-6],SIGNO_MAS ;if(Entrada==SIGNO_MAS)
	jne .mcif_e
	mov byte[bp-0xC],'+'	;coeficiente[0]='+'
	mov byte[bp-0xE],al	;coeficiente[1]=c
	mov byte[bp-0x12],2	;n=2
	mov byte[bp-0xA],0	;exponente=0
	jmp .mcif_fin	
.mcif_e:
	cmp byte[bp-6],SIGNO_MENOS ;if(Entrada==SIGNO_MENOS)
	jne .mcif_e_e
	mov byte[bp-0xC],'-'	;poner signo menos
	mov byte[bp-0xE],al	;coeficiente[0]=c
	mov byte[bp-0x12],2	;n=2
	mov byte[bp-0xA],0	;exponente=0
	jmp .mcif_fin
.mcif_e_e:
	mov byte[bp-0x10],al	;coeficiente[2]
	mov byte[bp-0x12],3	;n=3
	mov byte[bp-0xA],0	;exponente=0
.mcif_fin:
	; fin-manejarCoeficiente1
	mov byte[bp-6],DIGITO	;entrada=DIGITO
	jmp .break
.caso2:
	cmp al,'2'
	je short .expo
	cmp al,'3'
	je short .expo
	cmp al,'4'
	je short .expo
	jne .caso3
.expo:
	cmp byte[bp-6],POW	;if(entrada==POW)
	jne .powif_e
	sub al,30h
	mov [bp-0xA],al		 ;exponente=c
	mov byte[bp-6],EXPONENTE ;entrada=EXPONENTE
	jmp .break
.powif_e:			 ;else
	; ini-manejarCoeficiente2
	cmp byte[bp-6],SIGNO_MAS ;if(Entrada==SIGNO_MAS)
	jne .mcif2_e
	mov byte[bp-0xC],'+'	;coeficiente[0]='+'
	mov byte[bp-0xE],al	;coeficiente[1]=c
	mov byte[bp-0x12],2	;n=2
	mov byte[bp-0xA],0	;exponente=0
	jmp .mcif2_fin	
.mcif2_e:
	cmp byte[bp-6],SIGNO_MENOS ;if(Entrada==SIGNO_MENOS)
	jne .mcif2_e_e
	mov byte[bp-0xC],'-'	;poner signo menos
	mov byte[bp-0xE],al	;coeficiente[0]=c
	mov byte[bp-0x12],2	;n=2
	mov byte[bp-0xA],0	;exponente=0
	jmp .mcif2_fin
.mcif2_e_e:
	mov byte[bp-0x10],al	;coeficiente[2]
	mov byte[bp-0x12],3	;n=3
	mov byte[bp-0xA],0	;exponente=0
.mcif2_fin:
	; fin-manejarCoeficiente2
	mov byte[bp-6],DIGITO	;entrada=DIGITO
	jmp .break
.caso3:
	cmp al,';'
	jne .caso4
	mov byte[bp-6],FDC	;entrada=FDC
	jmp .break
.caso4:
	cmp al,'+'
	jne .caso5
	; ini-terminoCompleto2
	cmp byte[bp-8],C	;estado==C
	je .procesar_termino2
	cmp byte[bp-8],E	;estado==E
	je .procesar_termino2
	cmp byte[bp-8],D	;estado==D
	je .procesar_termino2
	jne .no_procesar_termino2
.procesar_termino2:	
	inc byte[bp-0x14]
	mov dl,byte[n_ter]
	cmp byte[bp-0x14],dl
	jbe .num_ter_correcto2	;salta si vleft ≤ vright (unsigned)
	PRINT msjNumTermIncorrecto
	mov al,byte[n_ter]
	xor ah,ah
	call printNumBin
	jmp .exit
.num_ter_correcto2:
	mov cl,byte[bp-0x12]	;# chars coef
	mov di, bp
	sub di,12		;mover 12 bytes donde empieza cadena
	call convNumStrParaNumBin ;num bin en AX

	; ESTRUCTURA
	mov di,[bp+4]		;di=puntero a estructura
	
	cmp byte[bp-0x14],1
	jne .term22
	mov [di+pol.Acoef],ax	;guardar numero binario
	mov dl,byte[bp-0xA]
	mov [di+pol.aExpo],dl ;exponente
	jmp .no_procesar_termino2
.term22:
	cmp byte[bp-0x14],2
	jne .term32
	mov [di+pol.Bcoef],ax	;guardar numero binario
	mov dl,byte[bp-0xA]
	mov [di+pol.bExpo],dl ;exponente
	jmp .no_procesar_termino2
.term32:
	cmp byte[bp-0x14],3
	jne .term42
	mov [di+pol.Ccoef],ax	;guardar numero binario
	mov dl,byte[bp-0xA]
	mov [di+pol.cExpo],dl ;exponente
	jmp .no_procesar_termino2
.term42:
	cmp byte[bp-0x14],4
	jne .term52
	mov [di+pol.Dcoef],ax	;guardar numero binario
	mov dl,byte[bp-0xA]
	mov [di+pol.dExpo],dl ;exponente
	jmp .no_procesar_termino2
.term52:
	mov [di+pol.Ecoef],ax	;guardar numero binario
	mov dl,byte[bp-0xA]
	mov [di+pol.eExpo],dl ;exponente
.no_procesar_termino2:	
	; fin-terminoCompleto2
	mov byte[bp-6],SIGNO_MAS ;entrada=SIGNO_MAS
	jmp .break
.caso5:
	cmp al,'-'
	jne .caso6
	; ini-terminoCompleto
	cmp byte[bp-8],C	;estado==C
	je .procesar_termino
	cmp byte[bp-8],E	;estado==E
	je .procesar_termino
	cmp byte[bp-8],D	;estado==D
	je .procesar_termino
	jne .no_procesar_termino
.procesar_termino:
	inc byte[bp-0x14]
	mov dl,byte[n_ter]
	cmp byte[bp-0x14],dl
	jbe .num_ter_correcto	;salta si vleft ≤ vright (unsigned)
	PRINT msjNumTermIncorrecto
	mov al,byte[n_ter]
	xor ah,ah
	call printNumBin
	jmp .exit
.num_ter_correcto:
; 	mov dl, byte[n_pol]
; 	cmp dx,polArr.len
; 	jb .num_pol_correcto 	;salta si vleft <vright
; 	PRINT msjNumPolIncorrecto
; 	jmp .exit
; .num_pol_correcto:
	;CORRECTO TODO ---------
	mov cl,byte[bp-0x12]	;# chars coef
	mov di, bp
	sub di,12		;mover 12 bytes donde empieza cadena
	call convNumStrParaNumBin ;num bin en AX

; 	mov di, polArr
; 	mov dl,byte[n_pol]
; .while:
; 	cmp dx, 0
; 	je .endwhile
; 	add di,pol.size
; 	dec dx
; 	jmp .while
	; .endwhile:

	mov di,[bp+4]		;di=puntero a estructura
	
	cmp byte[bp-0x14],1
	jne .term2
	mov [di+pol.Acoef],ax	;guardar numero binario
	mov dl,byte[bp-0xA]
	mov [di+pol.aExpo],dl ;exponente
	jmp .no_procesar_termino
.term2:
	cmp byte[bp-0x14],2
	jne .term3
	mov [di+pol.Bcoef],ax	;guardar numero binario
	mov dl,byte[bp-0xA]
	mov [di+pol.bExpo],dl ;exponente
	jmp .no_procesar_termino
.term3:
	cmp byte[bp-0x14],3
	jne .term4
	mov [di+pol.Ccoef],ax	;guardar numero binario
	mov dl,byte[bp-0xA]
	mov [di+pol.cExpo],dl ;exponente
	jmp .no_procesar_termino
.term4:
	cmp byte[bp-0x14],4
	jne .term5
	mov [di+pol.Dcoef],ax	;guardar numero binario
	mov dl,byte[bp-0xA]
	mov [di+pol.dExpo],dl ;exponente
	jmp .no_procesar_termino
.term5:
	mov [di+pol.Ecoef],ax	;guardar numero binario
	mov dl,byte[bp-0xA]
	mov [di+pol.eExpo],dl ;exponente
.no_procesar_termino:	
	; fin-terminoCompleto
	mov byte[bp-6],SIGNO_MENOS ;entrada=SIGNO_MENOS
	jmp .break
.caso6:
	cmp al,'x'
	jne .caso7
	; ini-x
	cmp byte[bp-6],SIGNO_MAS
	jne .xif_e
	mov byte[bp-0xC],'1'	;coeficiente[0]='1'
	mov byte[bp-0x12],1	;n=1
	mov byte[bp-0xA],1	;exponente=1
.xif_e:
	cmp byte[bp-6],SIGNO_MENOS
	jne .xif_e_e
	mov byte[bp-0xC],'-'	;coeficiente[0]='-'
	mov byte[bp-0xE],'1'	;coeficiente[1]='1'
	mov byte[bp-0x12],2	;n=2
	mov byte[bp-0xA],1	;exponente=1
.xif_e_e:
	cmp byte[bp-6],DIGITO
	jne .xif_fin
	mov byte[bp-0xA],1	;exponente=1
.xif_fin:
	; fin-x
	mov byte[bp-6],X ;entrada=X
	jmp .break
.caso7:
	cmp al,'^'
	jne .default
	mov byte[bp-6],POW ;entrada=SIGNO_MAS
	jmp .break
.default:

	mov bx, [bp-2]		;fila
	push bx
	mov bx, [bp-4]		;columna
	push bx
	push ax			;caracter
	mov bx, msj1
	call rutinaDeError
	
	jmp .exit

.break:				;fin del switch
	mov dx, ax		;guardar ax (1)
	
	TB [bp-8],[bp-6]	;AL=TB[estado][entrada]
	mov byte[bp-8],al	;estado=AL

	cmp byte[bp-8],ERROR
	jne .errif_e


	; rutina error
	mov bx, [bp-2]		;fila
	push bx
	mov bx, [bp-4]		;columna
	push bx
	mov ax,dx		;recuperar ax de dx (1)
	push ax			;caracter
	mov bx, msj2
	call rutinaDeError


	jmp .exit
.errif_e:
	cmp byte[bp-8],ACEPTAR
	jne .do

	; ini-terminoCompleto3
	inc byte[bp-0x14]
	mov dl,byte[n_ter]
	cmp byte[bp-0x14],dl
	jbe .num_ter_correcto3;salta si vleft ≤ vright (unsigned)
	PRINT msjNumTermIncorrecto
	mov al,byte[n_ter]
	xor ah,ah
	call printNumBin
	jmp .exit
.num_ter_correcto3:
	mov cl,byte[bp-0x12]	;# chars coef
	mov di, bp
	sub di,12;mover 12 bytes donde empieza cadena
	call convNumStrParaNumBin ;num bin en AX

	; ESTRUCTURA
	mov di,[bp+4]		;di=puntero a estructura
	
	cmp byte[bp-0x14],1
	jne .term23
	mov [di+pol.Acoef],ax	;guardar numero binario
	mov dl,byte[bp-0xA]
	mov [di+pol.aExpo],dl ;exponente
	jmp .ex_polin_term
.term23:
	cmp byte[bp-0x14],2
	jne .term33
	mov [di+pol.Bcoef],ax	;guardar numero binario
	mov dl,byte[bp-0xA]
	mov [di+pol.bExpo],dl ;exponente
	jmp .ex_polin_term
.term33:
	cmp byte[bp-0x14],3
	jne .term43
	mov [di+pol.Ccoef],ax	;guardar numero binario
	mov dl,byte[bp-0xA]
	mov [di+pol.cExpo],dl ;exponente
	jmp .ex_polin_term
.term43:
	cmp byte[bp-0x14],4
	jne .term53
	mov [di+pol.Dcoef],ax	;guardar numero binario
	mov dl,byte[bp-0xA]
	mov [di+pol.dExpo],dl ;exponente
	jmp .ex_polin_term
.term53:
	mov [di+pol.Ecoef],ax	;guardar numero binario
	mov dl,byte[bp-0xA]
	mov [di+pol.eExpo],dl ;exponente
.ex_polin_term:
	; fin-terminoCompleto3
	
	PRINT msj3
	inc byte[n_pol]
	mov di,[bp+4]
	mov dl,byte[bp-0x14]	;dl=numero de terminos
	mov [di+pol.n],dl	;guardar dl
.exit:
	EPILOGO 2



	; --------------------------------------------------
	; ** scanner_f
	; --------------------------------------------------
	; |Lo mismo que scanner solo que trabaja con un archivo.
       	; |+ Parametro
  	; |  - [BP+6] :: handle del archivo de donde lee
	; |  - [BP+4] :: puntero a estructura que guarda coeficientes y
	; |              exponentes y otros datos de la funcion.
  	; |+ Variables Locales
  	; |  1. [BP-2]  fila
  	; |  2. [BP-4]  columna
  	; |  3. [BP-6]  entrada
  	; |  4. [BP-8]  estado
  	; |  5. [BP-0xA]  exponente
	; |  6. [BP-0xC]  primer char ascii de un coeficiente
	; |  7. [BP-0xE]  segundo char ascii de un coeficiente
	; |  8. [BP-0x10]  tercer char ascii de un coeficiente
	; |  9. [BP-0x12]  numero de chars que forman el coeficiente
	; | 10. [BP-0x14] contador de terminos por funcion
scanner_f:
	PROLOGO 10

	mov di, [bp+4]
	mov dl, byte[n_ter]
	xor dh, dh
	mov [di+pol.tipo],dl

	; inicializacion de variables locales
	mov dl,byte[fila]
	mov dh,dh
	mov word[bp-2],dx	;fila=inicia con 1
	mov word[bp-4],0	;columa=0
	mov word[bp-6],0	;entrada=0
	mov word[bp-8],0	;estado=0
	mov word[bp-0xA],0 	;exponente=0
	mov word[bp-0xC],0 	;coeficiente[0]=0
	mov word[bp-0xE],0 	;coeficiente[1]=0
	mov word[bp-0x10],0 	;coeficiente[2]=0
	mov word[bp-0x12],0 	;n=0
	mov word[bp-0x14],0	;como n_ter pero temporal


	; validar maximo de ecuaciones (quince)
	mov dl, byte[n_pol]
	cmp dl,polArr.len
	jnae .num_pol_correcto 	;salta si vleft <vright
	PRINT msjNumPolIncorrecto
	jmp .exit

.num_pol_correcto:	
	
.do:
	LEER_ARCHIVO [bp+6],1,c
	jc .exit
	; es EOF si AX = 0 o AX < CX
	cmp ax, cx		;EOF?
	jge .no_esEOF		;salta si vleft >= vright
	PRINT 9,25, msjFinArchivo
	UBICAR_CURSOR 5,70
	CERRAR_ARCHIVO word[bp+6]
	jc .noCerroArchivo
	PRINT_CHAR 'C'		;C en esquina si cerro archivo
	jmp .exit
.noCerroArchivo:
	PRINT_CHAR 'N'		;N en esquina si no cerro archivo
	jmp .exit
.no_esEOF:
	mov al,byte[c]
	
	cmp al,0x0d		;c=='\r'
	jne .colfil_t
	mov word[bp-4],0x00	;columna=0
	inc byte[bp-2]		;fila++
	mov dx,word[bp-2]
	mov byte[fila],dl
	LEER_ARCHIVO [bp+6],1,c	;leer '\n' solo para saltarlo
	jmp .do
.colfil_t:
	cmp al,SPC		;c==' '
	jne .colfil_t_t
	inc byte[bp-4]		;columna++
	jmp .do
.colfil_t_t:
	inc byte[bp-4]		;columna++


.switch:
	cmp al,'0'
	je short .digito
	cmp al,'1'
	je short .digito
	cmp al,'5'
	je short .digito
	cmp al,'6'
	je short .digito
	cmp al,'7'
	je short .digito
	cmp al,'8'
	je short .digito
	cmp al,'9'
	je short .digito
	jne .caso2
.digito:
	; ini-manejarCoeficiente1
	cmp byte[bp-6],SIGNO_MAS ;if(Entrada==SIGNO_MAS)
	jne .mcif_e
	mov byte[bp-0xC],'+'	;coeficiente[0]='+'
	mov byte[bp-0xE],al	;coeficiente[1]=c
	mov byte[bp-0x12],2	;n=2
	mov byte[bp-0xA],0	;exponente=0
	jmp .mcif_fin	
.mcif_e:
	cmp byte[bp-6],SIGNO_MENOS ;if(Entrada==SIGNO_MENOS)
	jne .mcif_e_e
	mov byte[bp-0xC],'-'	;poner signo menos
	mov byte[bp-0xE],al	;coeficiente[0]=c
	mov byte[bp-0x12],2	;n=2
	mov byte[bp-0xA],0	;exponente=0
	jmp .mcif_fin
.mcif_e_e:
	mov byte[bp-0x10],al	;coeficiente[2]
	mov byte[bp-0x12],3	;n=3
	mov byte[bp-0xA],0	;exponente=0
.mcif_fin:
	; fin-manejarCoeficiente1
	mov byte[bp-6],DIGITO	;entrada=DIGITO
	jmp .break
.caso2:
	cmp al,'2'
	je short .expo
	cmp al,'3'
	je short .expo
	cmp al,'4'
	je short .expo
	jne .caso3
.expo:
	cmp byte[bp-6],POW	;if(entrada==POW)
	jne .powif_e
	sub al,30h
	mov [bp-0xA],al		 ;exponente=c
	mov byte[bp-6],EXPONENTE ;entrada=EXPONENTE
	jmp .break
.powif_e:			 ;else
	; ini-manejarCoeficiente2
	cmp byte[bp-6],SIGNO_MAS ;if(Entrada==SIGNO_MAS)
	jne .mcif2_e
	mov byte[bp-0xC],'+'	;coeficiente[0]='+'
	mov byte[bp-0xE],al	;coeficiente[1]=c
	mov byte[bp-0x12],2	;n=2
	mov byte[bp-0xA],0	;exponente=0
	jmp .mcif2_fin	
.mcif2_e:
	cmp byte[bp-6],SIGNO_MENOS ;if(Entrada==SIGNO_MENOS)
	jne .mcif2_e_e
	mov byte[bp-0xC],'-'	;poner signo menos
	mov byte[bp-0xE],al	;coeficiente[0]=c
	mov byte[bp-0x12],2	;n=2
	mov byte[bp-0xA],0	;exponente=0
	jmp .mcif2_fin
.mcif2_e_e:
	mov byte[bp-0x10],al	;coeficiente[2]
	mov byte[bp-0x12],3	;n=3
	mov byte[bp-0xA],0	;exponente=0
.mcif2_fin:
	; fin-manejarCoeficiente2
	mov byte[bp-6],DIGITO	;entrada=DIGITO
	jmp .break
.caso3:
	cmp al,';'
	jne .caso4
	mov byte[bp-6],FDC	;entrada=FDC
	jmp .break
.caso4:
	cmp al,'+'
	jne .caso5
	; ini-terminoCompleto2
	cmp byte[bp-8],C	;estado==C
	je .procesar_termino2
	cmp byte[bp-8],E	;estado==E
	je .procesar_termino2
	cmp byte[bp-8],D	;estado==D
	je .procesar_termino2
	jne .no_procesar_termino2
.procesar_termino2:	
	inc byte[bp-0x14]
	mov dl,byte[n_ter]
	cmp byte[bp-0x14],dl
	jbe .num_ter_correcto2	;salta si vleft ≤ vright (unsigned)
	PRINT msjNumTermIncorrecto
	mov al,byte[n_ter]
	xor ah,ah
	call printNumBin
	jmp .exit
.num_ter_correcto2:
	mov cl,byte[bp-0x12]	;# chars coef
	mov di, bp
	sub di,12		;mover 12 bytes donde empieza cadena
	call convNumStrParaNumBin ;num bin en AX

	; ESTRUCTURA
	mov di,[bp+4]		;di=puntero a estructura
	
	cmp byte[bp-0x14],1
	jne .term22
	mov [di+pol.Acoef],ax	;guardar numero binario
	mov dl,byte[bp-0xA]
	mov [di+pol.aExpo],dl ;exponente
	jmp .no_procesar_termino2
.term22:
	cmp byte[bp-0x14],2
	jne .term32
	mov [di+pol.Bcoef],ax	;guardar numero binario
	mov dl,byte[bp-0xA]
	mov [di+pol.bExpo],dl ;exponente
	jmp .no_procesar_termino2
.term32:
	cmp byte[bp-0x14],3
	jne .term42
	mov [di+pol.Ccoef],ax	;guardar numero binario
	mov dl,byte[bp-0xA]
	mov [di+pol.cExpo],dl ;exponente
	jmp .no_procesar_termino2
.term42:
	cmp byte[bp-0x14],4
	jne .term52
	mov [di+pol.Dcoef],ax	;guardar numero binario
	mov dl,byte[bp-0xA]
	mov [di+pol.dExpo],dl ;exponente
	jmp .no_procesar_termino2
.term52:
	mov [di+pol.Ecoef],ax	;guardar numero binario
	mov dl,byte[bp-0xA]
	mov [di+pol.eExpo],dl ;exponente
.no_procesar_termino2:	
	; fin-terminoCompleto2
	mov byte[bp-6],SIGNO_MAS ;entrada=SIGNO_MAS
	jmp .break
.caso5:
	cmp al,'-'
	jne .caso6
	; ini-terminoCompleto
	cmp byte[bp-8],C	;estado==C
	je .procesar_termino
	cmp byte[bp-8],E	;estado==E
	je .procesar_termino
	cmp byte[bp-8],D	;estado==D
	je .procesar_termino
	jne .no_procesar_termino
.procesar_termino:
	inc byte[bp-0x14]
	mov dl,byte[n_ter]
	cmp byte[bp-0x14],dl
	jbe .num_ter_correcto	;salta si vleft ≤ vright (unsigned)
	PRINT msjNumTermIncorrecto
	mov al,byte[n_ter]
	xor ah,ah
	call printNumBin
	jmp .exit
.num_ter_correcto:
	;CORRECTO TODO ---------
	mov cl,byte[bp-0x12]	;# chars coef
	mov di, bp
	sub di,12		;mover 12 bytes donde empieza cadena
	call convNumStrParaNumBin ;num bin en AX

	mov di,[bp+4]		;di=puntero a estructura
	
	cmp byte[bp-0x14],1
	jne .term2
	mov [di+pol.Acoef],ax	;guardar numero binario
	mov dl,byte[bp-0xA]
	mov [di+pol.aExpo],dl ;exponente
	jmp .no_procesar_termino
.term2:
	cmp byte[bp-0x14],2
	jne .term3
	mov [di+pol.Bcoef],ax	;guardar numero binario
	mov dl,byte[bp-0xA]
	mov [di+pol.bExpo],dl ;exponente
	jmp .no_procesar_termino
.term3:
	cmp byte[bp-0x14],3
	jne .term4
	mov [di+pol.Ccoef],ax	;guardar numero binario
	mov dl,byte[bp-0xA]
	mov [di+pol.cExpo],dl ;exponente
	jmp .no_procesar_termino
.term4:
	cmp byte[bp-0x14],4
	jne .term5
	mov [di+pol.Dcoef],ax	;guardar numero binario
	mov dl,byte[bp-0xA]
	mov [di+pol.dExpo],dl ;exponente
	jmp .no_procesar_termino
.term5:
	mov [di+pol.Ecoef],ax	;guardar numero binario
	mov dl,byte[bp-0xA]
	mov [di+pol.eExpo],dl ;exponente
.no_procesar_termino:	
	; fin-terminoCompleto
	mov byte[bp-6],SIGNO_MENOS ;entrada=SIGNO_MENOS
	jmp .break
.caso6:
	cmp al,'x'
	jne .caso7
	; ini-x
	cmp byte[bp-6],SIGNO_MAS
	jne .xif_e
	mov byte[bp-0xC],'1'	;coeficiente[0]='1'
	mov byte[bp-0x12],1	;n=1
	mov byte[bp-0xA],1	;exponente=1
.xif_e:
	cmp byte[bp-6],SIGNO_MENOS
	jne .xif_e_e
	mov byte[bp-0xC],'-'	;coeficiente[0]='-'
	mov byte[bp-0xE],'1'	;coeficiente[1]='1'
	mov byte[bp-0x12],2	;n=2
	mov byte[bp-0xA],1	;exponente=1
.xif_e_e:
	cmp byte[bp-6],DIGITO
	jne .xif_fin
	mov byte[bp-0xA],1	;exponente=1
.xif_fin:
	; fin-x
	mov byte[bp-6],X ;entrada=X
	jmp .break
.caso7:
	cmp al,'^'
	jne .default
	mov byte[bp-6],POW ;entrada=SIGNO_MAS
	jmp .break
.default:

	mov bx, [bp-2]		;fila
	push bx
	mov bx, [bp-4]		;columna
	push bx
	push ax			;caracter
	mov bx, msj1
	call rutinaDeError
	
	jmp .exit

.break:				;fin del switch
	mov dx, ax		;guardar ax (1)
	
	TB [bp-8],[bp-6]	;AL=TB[estado][entrada]
	mov byte[bp-8],al	;estado=AL

	cmp byte[bp-8],ERROR
	jne .errif_e


	; rutina error
	mov bx, [bp-2]		;fila
	push bx
	mov bx, [bp-4]		;columna
	push bx
	mov ax,dx		;recuperar ax de dx (1)
	push ax			;caracter
	mov bx, msj2
	call rutinaDeError


	jmp .exit
.errif_e:
	cmp byte[bp-8],ACEPTAR
	jne .do

	; ini-terminoCompleto3
	inc byte[bp-0x14]
	mov dl,byte[n_ter]
	cmp byte[bp-0x14],dl
	jbe .num_ter_correcto3;salta si vleft ≤ vright (unsigned)
	PRINT msjNumTermIncorrecto
	mov al,byte[n_ter]
	xor ah,ah
	call printNumBin
	jmp .exit
.num_ter_correcto3:
	mov cl,byte[bp-0x12]	;# chars coef
	mov di, bp
	sub di,12;mover 12 bytes donde empieza cadena
	call convNumStrParaNumBin ;num bin en AX

	; ESTRUCTURA
	mov di,[bp+4]		;di=puntero a estructura
	
	cmp byte[bp-0x14],1
	jne .term23
	mov [di+pol.Acoef],ax	;guardar numero binario
	mov dl,byte[bp-0xA]
	mov [di+pol.aExpo],dl ;exponente
	jmp .ex_polin_term
.term23:
	cmp byte[bp-0x14],2
	jne .term33
	mov [di+pol.Bcoef],ax	;guardar numero binario
	mov dl,byte[bp-0xA]
	mov [di+pol.bExpo],dl ;exponente
	jmp .ex_polin_term
.term33:
	cmp byte[bp-0x14],3
	jne .term43
	mov [di+pol.Ccoef],ax	;guardar numero binario
	mov dl,byte[bp-0xA]
	mov [di+pol.cExpo],dl ;exponente
	jmp .ex_polin_term
.term43:
	cmp byte[bp-0x14],4
	jne .term53
	mov [di+pol.Dcoef],ax	;guardar numero binario
	mov dl,byte[bp-0xA]
	mov [di+pol.dExpo],dl ;exponente
	jmp .ex_polin_term
.term53:
	mov [di+pol.Ecoef],ax	;guardar numero binario
	mov dl,byte[bp-0xA]
	mov [di+pol.eExpo],dl ;exponente
.ex_polin_term:
	; fin-terminoCompleto3
	
	PRINT msj3
	inc byte[n_pol]
	mov di,[bp+4]
	mov dl,byte[bp-0x14]	;dl=numero de terminos
	mov [di+pol.n],dl	;guardar dl
.exit:
	EPILOGO 2
	

	
	; ** rutinaDeError
	; |Imprime un mensaje de error lexico.
	; |+ Parametros
	; |  - [bp+8] :: Fila en binario
	; |  - [bp+6] :: Columna en binario
	; |  - [bp+4] :: El caracter ascii que causo el error
	; |+ Entrada
	; |  - bx :: puntero a cadena que describe el error
	; |+ Salidas
	; |  - vacio :: nada	
rutinaDeError:
	PROLOGO 0

	PRINT bx
	
	PRINT msjFil
	mov ax, [bp+8]		;fila en binario
	call printNumBin	
	PRINT_CHAR T
	
	PRINT msjCol
	mov ax, [bp+6]		;columna en binario
	call printNumBin
	PRINT_CHAR T


	PRINT msjCaracter
	PRINT_CHAR [bp+4]	;caracter
	PRINT_CHAR APOS
	PRINT_CHAR R
	PRINT_CHAR N
	
	EPILOGO 3
	

	; ** convNumStrParaNumBin
	; |Convertir numero en string a numero en binario para el
	; |manejo interno como cantidad de la representacion numerica
	; |de la cadena. Se utilizó para leer la cadena directamente
	; |de la pila.
	; |+ Entradas
	; |  - di :: puntero al primer elemento del arreglo de
	; |          caracteres (cadena) a convertir. Cada caracter
	; |          debe estar a cada dos bytes. Esto es porque se
	; |          utilizó para leer de la pila cuyos elementos son
	; |          de 2 bytes. 
	; 
	; |  - cl :: tamaño de la cadena apuntada por bx
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

	; parrafo siguiente es equivalente a: mov al, byte[di-2*bx]
	; no se utizo esta notacion porque daba error
	mov al,2
	mul bl
	push di
	sub di,ax
	mov al, byte[di]
	pop di
	
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


	; ** convNumStrParaNumBin_arr
	; |Igual que 'convNumStrParaNumBin' solo que el array de
	; |caracteres deben estar a cada byte no a cada dos, esto
	; |para que no necesariamente deba leerse desde la pila.
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
convNumStrParaNumBin_arr:
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

	; ** printNumBin_mas
	; |Lo mismo que printNumBin solo que los positivos les
	; |antepone el signo positivo '+'
	; |+ Entradas
	; |  - ax :: el numero binario (word) a imprimir
	; |+ Salidas
	; |  - vacio :: nada
printNumBin_mas:
	mov bx,0		;i=0
	cmp ax,0
	jl .negativo;salta si vleft <vright (considera # con signo)

	; imprimir signo mas protegiendo ax pues guarda el numero
	; binario a imprimir
	push ax	    ;p
	PRINT_CHAR '+'
	pop ax

	
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
	
