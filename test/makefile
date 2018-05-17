# El fromato binario se puede utilizar cuando, el tamaño del programa,
# no es grande y se desea programar todo en un sector, es decir no
# modularlo como podria hacerse si fuera formato .EXE. Un programa
# binario (usualmente .COM en DOS) tiene una tamaño maximo de 64kb
FORMATO:=-f bin
DIR_DES:=~/a
DEPS:=anlex2.asm rep.asm ploter.asm io.mac stack_frame.mac

# REGLA DE PATRON que indica a make como obtener un archivo .com a
# partir de un .asm sin estar asociado a algun nombre en concreto. Se
# utiliza las variables automaticas $@ y $<. La primera ($@) se sustituye
# por el nombre del objetivo de la presente regla. La sengunda ($<) se
# sustituye por la primera dependencia de la presente regla.
%.com:%.asm			#regla de patro 1
	nasm $(FORMATO) -o $@ $<
%:%.com				#regla de patron 2
	mv $< $(DIR_DES)


# ini-PROGRAMA PRINCIPAL
calgra:calgra.com		#CALculadora GRAficadora
calgra.com: calgra.asm $(DEPS)
	nasm $(FORMATO) -o $@ $<
# fin-PROGRAMA PRINCIPAL

# ini-PROGRAMAS DE PRUEBA
# El orden cronológico conforme se avanza en las lineas de este
# archivo corresponde al orden en que la calculadora graficadora se
# desarrollo. Algunos archivos, una vez probados individualmente, solo
# se comento las lines finalizadas en [test] y luego se añadió con
# directiva %include de NASM hacia el archivo de codigo fuente
# principal calgra.asm

numbyte:numbyte.com		#utiliza regla de patron 1 y 2
numword:numword.com		#utiliza regla de patron 1 y 2

numword2:numword2.com
numword2.com: numword2.asm stack_frame.mac io.mac
	nasm $(FORMATO) -o $@ $<

arrStc:arrStc.com		#utiliza regla de patron 1 y 2

%:%.c
	gcc -g $< -o $@.exe	#regla de patron 3
anlex1:anlex1.c		#utiliza regla de patron 3
anlex2:anlex2.c		#utiliza regla de patron 3

anlex:anlex.com		#utiliza regla de patron 1 y 2

anlex2:anlex2.com
anlex2.com: anlex2.asm stack_frame.mac io.mac
	nasm $(FORMATO) -o $@ $<

ploter:ploter.com
muldw:muldw.com			#solo num sin signo, al final no me sirvio
# fin-PROGRAMAS DE PRUEBA

# Nombre Entregable
NE:=[Arqui1]Proyecto2_carnet
vpath %.pdf ../tec ../usu
ezip:calgra.com usu.pdf tec.pdf	#Entregable ZIP
	cp calgra.asm $(DEPS) ../src
	mkdir $(NE)
	cp $^ $(NE)
	rm calgra.com
	cp -r ../src/ $(NE)
	cp -r ../in/ $(NE)
	7z a $(NE).zip $(NE)/ -xr!g*.txt #-xr!g*.txt excluye archivos g*.txt
	mv $(NE).zip $(DIR_DES)
	rm -r $(NE)/

erar:calgra.com usu.pdf tec.pdf	#Entregable RAR
	cp calgra.asm $(DEPS) ../src
	mkdir $(NE)
	cp $^ $(NE)
	rm calgra.com
	cp -r ../src/ $(NE)
	cp -r ../in/ $(NE)
	rar a -r -xg*.txt $(NE).rar $(NE) #-r -xg*.txt excluye archivos g*.txt
	mv $(NE).rar $(DIR_DES)
	rm -r $(NE)

rmb:
	rm *~
