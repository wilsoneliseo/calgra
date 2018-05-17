	; |- Probar este archivo :: DESCOMENTAR las lineas terminadas en
	; |          con `;[test]´. En el editor emacs puede hacerse
	; |          esto sustituyendo (C-M-%) ER1 por ER2
	; |          ER1= `;\(.+\);\(\[test\]\)$´ -> ER2 = `\1;\2´
	; |
	; |          para volver a COMENTAR estas lineas,
	; |          sustituir ER3 por ER4:
	; |          ER3= `\(.+\);\(\[test\]\)$´ -> ER4 = `;\1;\2´

	; | ** MULDW
	; |+ Parámetros
	; |  - ax,%1 :: palabra más significativa del multiplicando
	; |  - ax,%2 :: palabra menos significativa del multiplicando
	; |  - ax,%3 :: el multiplicador (word)
%macro MULDW 3
	mov dx,%1
	push dx
	mov ax,%2
	push ax
	mov ax,%3
	push ax
	call muldw	
%endmacro
	
%include "io.mac"		;[test]
%include "stack_frame.mac"	;[test]


[bits 16]			;[test]
[cpu 8086]			;[test]
org 0x100			;[test]
section .text
	; multiplicar 33,000 por dos -------------------------
	; -33,000=0x FFFF 7F18
	mov ax,0xFFFF		;[test]
	push ax			;[test]
	mov ax,0xFFE0		;[test]
	push ax			;[test]
	mov ax,0xFFE0		;[test]
	push ax			;[test]
	call muldw		;[test]
	TERMINAR_PROGRAMA	;[test]

	; ** muldw
	; |Multiplica doble palabra (multiplicando)  por una palabra
	; |(multiplicador). Considera el signo.
	; |+ Parámetros
	; |  - [BP+8] :: palabra más significativa del multiplicando
	; |  - [BP+6] :: palabra menos significativa del multiplicando
	; |  - [BP+4] :: el multiplicador (word)
	; |+ Variables locales
	; |  - [BP-2] :: temp (word)
	; |  - [BP-4] :: resp0 (word)
	; |  - [BP-6] :: resp1 (word)
	; |+ Salida
	; |  - BX:CX:AX :: resultado de la multiplicación. 48 bits,
	; |                tres palabras, 6 bytes.
muldw:
	PROLOGO 3
	; DX:AX=AX*opword
	mov ax,[bp+6]		;multiplicando menos significativo
	imul word[bp+4]		;multiplicador
	mov [bp-4],ax 		;resp0
	mov [BP-2],dx		;temp

	mov ax,[bp+8]		;multiplicando más significativo
	imul word[bp+4]		;multiplicador

	add ax,[bp-2]		;ax+temp
	mov [bp-6],ax		;resp1

	; respuestas
	mov bx,dx
	mov dx,[bp-6]		;dx=resp1
	mov ax,[bp-4]		;ax=resp0	
	EPILOGO 3
