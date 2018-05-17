	; |- Descripción: define algunas macros y rutinas para
	; |  utilizar el modo de video 13h. Esto con el fin de
	; |  realizar el ploter de la opción 5 del menú principal de
	; |  la aplicación.
	; |
	; |- Probar este archivo :: DESCOMENTAR las lineas terminadas en
	; |          con `;[test]´. En el editor emacs puede hacerse
	; |          esto sustituyendo (C-M-%) ER1 por ER2
	; |          ER1= `;\(.+\);\(\[test\]\)$´ -> ER2 = `\1;\2´
	; |
	; |          para volver a COMENTAR estas lineas,
	; |          sustituir ER3 por ER4:
	; |          ER3= `\(.+\);\(\[test\]\)$´ -> ER4 = `;\1;\2´
	; |
	; |          Para compilar: =nasm -f bin -o ploter.com ploter.asm=
	; |          o con make: =make ploter=
	; |- Autor:
	; |  Wilson S. Tubín

	
;%include "io.mac"		;[test]
;%include "stack_frame.mac"	;[test]

	; ==================================================
	; * mdl'' MACROS DE LINEA
	; ==================================================
%define POL_POSITIVO 1		;identifica si la grafica es positiva
	;y negativo. Esto para ubicar el origen del plano en la parte
	; superior o inferior

	
	; ==================================================
	; * mml'' MACROS MULTI LINEA
	; ==================================================
%macro MODO_TEXTO 0
	mov ax,0003h
	int 10h
%endmacro

%macro MODO_VIDEO 0
	mov ah,0
	mov al, 13h
	int 10h			;establecer modo grafico 13h

	mov ax, 0xA000
	mov es, ax
%endmacro


	; ==================================================
	; * ddc'' DEFINICION DE CONSTANTES
	; ==================================================
BLACK: equ 0x0
BLUE: equ 0x1
GREEN: equ 0x2
CYAN: equ 0x3
RED: equ 0x4
MAGENTA: equ 0x5
BROWN: equ 0x6
LIGHT_GRAY: equ 0x7
DARK_GRAY: equ 0x8
LIGHT_BLUE: equ 0x9
LIGHT_GREEN: equ 0xa
LIGHT_CYAN: equ 0xb
LIGHT_RED: equ 0xc
LIGHT_MAGENTA: equ 0xd
YELLOW: equ 0xe
WHITE: equ 0xf
	
	; ini-configuracion plano
ANCHO_CUADRO: equ 200
ALTO_CUADRO: equ 199
X_CUADRO: equ 118		;algunos valores: 60,118
Y_CUADRO: equ 0
Y_SUP_INF: equ 10 		;distancia que se le suma a la parte
	;superior o resta a la parte inferior en el eje Y para mover
	;el origen arriba o abajo.
COLOR_ORILLA: equ GREEN
COLOR_FONDO: equ BLACK
COLOR_EJES: equ CYAN
	; fin-configuracion plano
	
	
	; parametros para funcion constante	
X_ORIGEN_CONSTANTE: equ X_CUADRO+ ANCHO_CUADRO/2
Y_ORIGEN_CONSTANTE: equ Y_CUADRO+ALTO_CUADRO/2
FACTOR_CONSTANTE: equ 1

	; parametros para funcion grado 1 o recta
X_ORIGEN_RECTA: equ X_CUADRO+ ANCHO_CUADRO/2
Y_ORIGEN_RECTA: equ Y_CUADRO+ALTO_CUADRO/2
FACTOR_RECTA: equ 3

	; parametros para funcion grado 2 o parabola
X_ORIGEN_PARABOLA_POS: equ X_CUADRO+ ANCHO_CUADRO/2
Y_ORIGEN_PARABOLA_POS: equ Y_CUADRO+ALTO_CUADRO-Y_SUP_INF
X_ORIGEN_PARABOLA_NEGA: equ X_CUADRO+ ANCHO_CUADRO/2
Y_ORIGEN_PARABOLA_NEGA: equ Y_CUADRO+Y_SUP_INF
	; El máximo valor numérico signado que puede representarse con
	; 16 bits es (2^16-1)/2=32767.5, esto se considera para
	; calcular el factor por el cual se divide la evaluación
	; cuando la funcion es un polinomio grado 2 considerando que
	; el origen esta ya se arriba o abajo del cuadro dependiendo
	; si la grafica es positiva o negativa. A continuación una
	; sesion en maxima que muestra el cálculo:
	; 
	; (%i1) ANCHO_CUADRO: 200;
	; (%i2) ALTO_CUADRO: 199;
	; (%i3) f(x):=x^2;
	; (%i4) f(ANCHO_CUADRO/2);  /*10000 perfectamente representable con 16 bits*/
	; (%o4) 10000
	; (%i5) %/ALTO_CUADRO;
	; (%o5) 50
FACTOR_PARABOLA: equ 50
	

	; parametros para funcion grado 3
X_ORIGEN_GRADO3: equ X_CUADRO+ ANCHO_CUADRO/2
Y_ORIGEN_GRADO3: equ Y_CUADRO+ALTO_CUADRO/2
	; El máximo valor numérico signado que puede representarse con
	; 16 bits es (2^16-1)/2=32767.5, esto se considera para
	; calcular el factor por el cual se divide la evaluación
	; cuando la funcion es un polinomio grado 3 considerando que
	; el origen esta al centro del cuadro. A continuación una
	; sesion en maxima que muestra el cálculo:
	; 
	; (%i1) ANCHO_CUADRO: 200;
	; (%i2) ALTO_CUADRO: 199;
	; (%i3) ANCHO_CUADRO/4-18;
	; (%o3) 32
	; (%i4) f(x):=x^3;
	; (%i5) f(%o3); /*maximo valor con 16 bits signado*/
	; (%o5) 32768   
	; (%i6) ALTO_CUADRO/2,numer;
	; (%o6) 99.5
	; (%i7) %o5/%o6,numer;
	; (%o7) 329.3266331658292
FACTOR_GRADO3: equ 329 
	
	; parametros para funcion grado 4
X_ORIGEN_GRADO4_POS: equ X_CUADRO+ ANCHO_CUADRO/2
Y_ORIGEN_GRADO4_POS: equ Y_CUADRO+ALTO_CUADRO-Y_SUP_INF
X_ORIGEN_GRADO4_NEGA: equ X_CUADRO+ ANCHO_CUADRO/2
Y_ORIGEN_GRADO4_NEGA: equ Y_CUADRO+Y_SUP_INF
	; El máximo valor numérico signado que puede representarse con
	; 16 bits es (2^16-1)/2=32767.5, esto se considera para
	; calcular el factor por el cual se divide la evaluación
	; cuando la funcion es un polinomio grado 4 considerando que
	; el origen esta en la parte inferior o superior del cuadro. A
	; continuación una sesion en maxima que muestra el cálculo:
	; 
	; (%i1) ANCHO_CUADRO: 200;
	; (%i2) ALTO_CUADRO: 199;
	; (%i3) (ANCHO_CUADRO+10)/15;
	; (%o3) 14
	; (%i4) f(x):=x^4;
	; (%i5) f(%o3); /*maximo valor con 16 bits signado*/
	; (%o5) 38416
	; (%i6) %/ALTO_CUADRO,numer;
	; (%o6) 193.0452261306533
FACTOR_GRADO4: equ 193

	
	
	; ==================================================
	; * se'' SEGMENTO EXTRA (ES)
	; ==================================================

section .bss
origen_x: resw 1
origen_y: resw 1

;[bits 16]			;[test]
;[cpu 8086]			;[test]
;org 0x100			;[test]
section .text
;	MODO_VIDEO		;[test]
;	mov ax,160		;[test]
;	push ax			;[test]
;	mov ax,100		;[test]
;	push ax			;[test]
;	call dibujar_plano	;[test]

;	mov bx, -100		;[test]
;	mov ax, -7		;[test]
;	mov dl,WHITE		;[test]
;	call putPixel		;[test]
	
;	GETCHAR		       ;[test]
;	MODO_TEXTO	       ;[test]
;	TERMINAR_PROGRAMA      ;[test]


	; ** dibujar_plano
	; |dibuja los ejes X y Y del plano cartesiano
	; |+ Parámetros
	; |  - [BP+6] :: posición x del origen
	; |  - [BP+4] :: posición y del origen
dibujar_plano:
	PROLOGO 0


	; fondo -----------------------------------------------
	mov ax, BLACK
	push ax,
	mov ax, 320
	push ax
	mov ax, 200
	push ax
	mov ax, 0
	push ax
	mov ax, 0
	push ax
	call dibujar_rectangulo
	

	; dibujando orilla --------------------------------------
	mov ax, COLOR_ORILLA
	push ax
	mov ax, ANCHO_CUADRO+1
	push ax
	mov ax, X_CUADRO
	push ax
	mov ax, Y_CUADRO
	push ax
	call dibujar_linea_horizontal

	mov ax, COLOR_ORILLA
	push ax
	mov ax, ANCHO_CUADRO+1
	push ax
	mov ax, X_CUADRO
	push ax
	mov ax, Y_CUADRO+ALTO_CUADRO
	push ax
	call dibujar_linea_horizontal

	
	
	mov ax, COLOR_ORILLA
	push ax
	mov ax, ALTO_CUADRO-1
	push ax
	mov ax, X_CUADRO
	push ax
	mov ax, Y_CUADRO+1
	push ax
	call dibujar_linea_vertical

	mov ax, COLOR_ORILLA
	push ax
	mov ax, ALTO_CUADRO-1
	push ax
	mov ax, X_CUADRO+ANCHO_CUADRO
	push ax
	mov ax, Y_CUADRO+1
	push ax
	call dibujar_linea_vertical
	


	; dibujando ejes ---------------------------------------
	; eje x
	mov ax, COLOR_EJES
	push ax
	mov ax, ANCHO_CUADRO+1
	push ax
	mov ax, X_CUADRO
	push ax
	mov ax, Y_CUADRO
	add ax,[bp+4]		;y origen
	push ax
	call dibujar_linea_horizontal

	; eje y
	mov ax, COLOR_EJES
	push ax
	mov ax, ALTO_CUADRO-1
	push ax
	mov ax, [bp+6]		;x origen
	push ax
	mov ax, Y_CUADRO+1
	push ax
	call dibujar_linea_vertical

	; inicializar variables de coordenadas del origen
	mov ax,[bp+6]
	mov [origen_x], ax
	mov ax,[bp+4]
	mov [origen_y], ax
	
	EPILOGO 2




	; ** putPixel
	; |Pinta un pixel en cordenada y color dado. Las coordenadas
	; |son con respecto al origen del plano establecido durante la
	; |llamada ha 'dibujar_plano'.
	; |+ Entradas
	; |  - dl :: color
	; |  - bx :: coordenada x
	; |  - ax :: coordenada y
putPixel:
	push cx
	
	add bx, [origen_x]
	mov cx,[origen_y]
	sub cx,ax
	mov ax,cx
	mov cx,320		;320 ancho de pantalla
	push dx			;guardar color
	mul cx			;AX=AX*CX
	pop dx			;restaurar color	
	add ax,bx		;DX:AX=AX+BX
	mov si,ax		;guarda el desplazamiento
	mov [es:si],dl		;color

	pop cx
	ret
	


	; ** dibujar_linea_horizontal
	; |dibuja una linea horizontal
	; |+ Parámetros
	; |  - [BP+10] :: color
	; |  - [BP+8] :: ancho
	; |  - [BP+6] :: x
	; |  - [BP+4] :: y
dibujar_linea_horizontal:
	PROLOGO 0
	mov dx, [bp+4]		;y
	mov ax, 320
	mul dx			;DX:AX=320*y
	mov cx,0
.pixel:
	cmp cx, [bp+8]		;ancho
	jae .return		;salta si vleft >= vright
	mov si, ax
	add si, [bp+6]	;BX=AX+x=320*y+x
	add si, cx
	mov dl, [bp+10]  ; color
	mov [es:si], dl
	inc cx
	jmp .pixel
.return:
	EPILOGO 4


	; ** dibujar_linea_vertical
	; |Dibuja una linea vertical
	; |+ Parámetros
	; |  - [BP+10] :: color
	; |  - [BP+8] :: alto
	; |  - [BP+6] :: x
	; |  - [BP+4] :: y
dibujar_linea_vertical:
	PROLOGO 0
	mov cx,0
.pixel:
	cmp cx, [bp + 8]	;alto
	jae .break		;salta si vleft >= vright
	mov ax, 320
	mov dx, [bp + 4]	;y
	add dx, cx        	;y + 'y
	mul dx            	;DX:AX=AX*(y+'y)=320*(y+'y)
	mov si, [bp + 6]	;x
	add si, ax		;BX=320*(y+y')+x
	mov dl, [bp + 10]  	;color
	xor dh,dh
	mov [es:si], dx
	inc cx
	jmp .pixel
.break:
	EPILOGO 4



	; ** dibujar_rectangulo
	; |Dibuja un rectangulo relleno de un color dado.
	; |+ Parámetros
	; |  - [BP+12] :: color
	; |  - [BP+10] :: ancho
	; |  - [BP+8] :: alto
	; |  - [BP+6] :: x
	; |  - [BP+4] :: y
dibujar_rectangulo:
	PROLOGO 0
	mov cx,0		;y'
.abajo:
	cmp cx, [bp + 8]	;alto
	jae .return
	mov bx, 0 		;x'
.derecha:
	cmp bx, [bp + 10]	;ancho
	jae .horizontal
	mov ax, cx
	add ax, [bp + 4]	;y
	mov si, 320
	mul si
	add ax, [bp + 6]	;x
	add ax, bx
	mov si, ax
	mov al, [bp + 12]	;color
	mov [es:si], al
	inc bx
	jmp .derecha
.horizontal:
	inc cx
	jmp .abajo
.return:
	EPILOGO 5
