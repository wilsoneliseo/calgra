	; |- Descripcion :: Contiene la funcion 'scanner' que realiza
	; |                 el analisis lexico de una funcion
	; |                 polinomica de grado 4 con coeficientes de
	; |                 dos digitos positivos o negativos. Un
	; |                 termino correcto debe iniciar con '+' o
	; |                 '-' seguido de cero, uno o dos
	; |                 digitos. Luego puede venir o no una 'x' o
	; |                 bien 'x^' seguido por '2' o '3' o '4'. La
	; |                 expresion regular es la siguiente: 
	; |                 
	; |                 ER=(('+'|'-')(<d>?<d>)?[x^<expo>|x]?)+;
	; |                 donde: <d>=0|1|2|3|4|5|6|7|8|9 y <expo>=2|3|4
	; |         
	; |                 Estos son algunos ejemplos de cadenas
	; |                 lexicamente correctas para este lenguaje
	; |                 (debe terminar en ';'): 
	; |                         +2x+1-99x  +29  +x +29;
	; |                         -90x^3 +5  5x^2;
	; |
	; |                 los espacios en blanco los ignora    
	; |  
	; |- Compilacion :: Se trato de que este archivo se pudiera
	; |                 probar independientemente de si es
	; |                 agregado al codigo fuente principal o
	; |                 no. Por lo tanto si se quiere probar el
	; |                 funcionamiento de 'scanner' hay que
	; |                 DESCOMENTAR las lineas terminadas en
	; |                 ;[test]. En el editor emacs se puede hacer
	; |                 esto mediante la sustitucion de ER1 por
	; |                 ER2 (C-M-%):
	; |                 ER1= `;\(.+\);\(\[test\]\)$´ -> ER2 = `\1;\2´
	; |
	; |                 para volver a COMENTAR estas lineas,
	; |                 sustituir ER3 por ER4:
	; |                 ER3= `\(.+\);\[test\]$´ -> ER4 = `;\1;[test]´
	; |
	; |                 luego de descomentar compilar con:
	; |                 =nasm -f bin -o anlex.com anlex.asm=
	; |
	; |                 o con make: =make anlex=
	; |
	; |                 ejecutar en DOSBox con:
	; |                 => ANLEX.COM=
	; |
	; |- Autor :: Wilson S. Tubin

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

%ifndef PARA_RUTINA_TIPO_FUNCION
    %define PARA_RUTINA_TIPO_FUNCION
	    ; recibe el numero de variables locales a utilizar
    %macro PROLOGO 1
	    push bp
	    mov bp, sp
	    sub sp,%1*2
    %endmacro

	    ; recibe el numero de parametros a utilizar
    %macro EPILOGO 1
	    mov sp, bp
	    pop bp
	    ret %1*2;ret recibe la cantidad de bytes a retirar de la pila
    %endmacro
%endif	

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
	; * sdd'' SEGMENTO DE DATOS
	; ==================================================
section .data
ej: db '+ 34 x-22 x^3-4+x;';[test]
msj1: db 13,10,'[Error Lexico] Caracter no reconocido:',13,10,'$'
msj2: db 13,10,'[Error Lexico] Caracter no debe ir en esta posicion:',13,10,'$'
msj3: db 13,10,'[Exito] Expresion polinomica reconocida',13,10,'$'	

tablaTransiciones: db \
	  B,     B,   ERROR, ERROR, ERROR, ERROR, ERROR,\
	ERROR, ERROR,   C,     D,   ERROR, ERROR, ERROR,\
	  B,     B,     E,     D,   ERROR, ERROR, ACEPTAR,\
	  B,     B,   ERROR, ERROR,   F,   ERROR, ACEPTAR,\
	  B,     B,   ERROR,   D,   ERROR, ERROR, ACEPTAR,\
	ERROR, ERROR, ERROR, ERROR, ERROR,   D,   ERROR

	; ==================================================
	; * sdc'' SEGMENTO DE CODIGO
	; ==================================================
; [bits 16]
; [cpu 8086]
 org 100h ;[test]
section .text
 mov ax,ej;[test]
 push ax;[test]
 call scanner;[test]
 mov ah, 4Ch;[test]
 int 21h;[test]


	
	; --------------------------------------------------
	; ** scanner
	; --------------------------------------------------
	; |realiza un analisis lexico de la cadena terminada en ';'
	; |
	; |#+BEGIN_EXAMPLE
       	; |	  MARCO DE PILA (stack frame)
       	; |	      +-------------+
  	; |	 BP+4 |	 arr chars  |  SP+12
  	; |	      +-------------+
  	; |	 BP+2 |  dir retor  |  SP+10
  	; |	      +-------------+
  	; |	 BP   |     BP      |  SP+8
  	; |	      +-------------+
  	; |	 BP-2 |    fila     |  SP+6
  	; |	      +-------------+
  	; |	 BP-4 |   columna   |  SP+4
  	; |	      +-------------+
  	; |	 BP-6 |   entrada   |  SP+2
  	; |	      +-------------+
  	; |	 BP-8 |   estado    |  SP
  	; |	      +-------------+
	; |#+END_EXAMPLE
scanner:
	PROLOGO 4

	; parametro
	mov si,[bp+4]		;SI = apuntador arreglo de chars	

	; inicializacion de variables locales
	mov word[bp-2],1	;fila=1
	mov word[bp-4],0	;columa=0
	mov word[bp-6],0	;entrada=0
	mov word[bp-8],0	;estado=0
	
	
	
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
	cmp al,0x20		;c==' '
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
	mov byte[bp-6],EXPONENTE ;entrada=EXPONENTE
	jmp .break
.powif_e:			 ;else
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
	mov byte[bp-6],SIGNO_MAS ;entrada=SIGNO_MAS
	jmp .break
.caso5:
	cmp al,'-'
	jne .caso6
	mov byte[bp-6],SIGNO_MENOS ;entrada=SIGNO_MENOS
	jmp .break
.caso6:
	cmp al,'x'
	jne .caso7
	mov byte[bp-6],X ;entrada=X
	jmp .break
.caso7:
	cmp al,'^'
	jne .default
	mov byte[bp-6],POW ;entrada=SIGNO_MAS
	jmp .break
.default:
	; rutina error
	mov ax,msj1
	push ax
	call print
	jmp .exit

.break:				;fin del switch
	TB [bp-8],[bp-6]	;AL=TB[estado][entrada]
	mov byte[bp-8],al	;estado=AL

	cmp byte[bp-8],ERROR
	jne .errif_e
	; rutina error
	mov ax,msj2
	push ax
	call print
	jmp .exit
.errif_e:
	; mov byte[bp-8],ACEPTAR
	cmp byte[bp-8],ACEPTAR
	jne .do

	mov ax,msj3
	push ax
	call print
.exit:
	EPILOGO 1


	; imprimir cadena
	; 
	; [bp + 4] puntero a cadena que termina en '$'
	; Salida: nada
print:;[test]
	PROLOGO 0;[test]
	mov dx, [bp+4];[test]
    	mov ah,09h;[test]
    	int 21h;[test]
	EPILOGO 1;[test]
	
	
