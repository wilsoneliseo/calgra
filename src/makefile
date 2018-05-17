FORMATO:=-f bin
DIR_DES:=~/a

%.com:%.asm
	nasm $(FORMATO) -o $@ $<
%:%.com
	mv $< $(DIR_DES)


calgra:calgra.com
calgra.com: calgra.asm anlex2.asm rep.asm ploter.asm \
	    io.mac stack_frame.mac
	nasm $(FORMATO) -o $@ $<


rmb:
	rm *~
