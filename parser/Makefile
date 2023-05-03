.PHONY: counter

parser: lexer.c parser.c 
	gcc -lfl $^ -o $@

lexer.h lexer.c: lexer.l
	flex --header-file=lexer.h -o lexer.c lexer.l 

parser.h parser.c: parser.y
	bison -d -v -o parser.c parser.y

conflicts: parser.y
	bison -Wcounterexamples -d -v -p parser.c parser.y

clean:
	rm -f *.o *.h *.c parser *.output
