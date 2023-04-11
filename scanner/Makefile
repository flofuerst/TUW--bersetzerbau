scanner: lex.yy.c 
	gcc lex.yy.c -lfl -o scanner

lex.yy.c: scanner.lex
	flex scanner.lex

clean:
	rm -f *.c scanner

