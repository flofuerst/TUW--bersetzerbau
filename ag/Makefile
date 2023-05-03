ag: types.c oxout_lex.c oxout_parse.c
	gcc -lfl $^ -o $@

oxout_parse.y oxout_lex.l: parser.y lexer.l
	ox --lex-prefix=oxout_lex --parse-prefix=oxout_parse $^

oxout_lex.h oxout_lex.c: oxout_lex.l
	flex --header-file=oxout_lex.h -o oxout_lex.c $<

oxout_parse.h oxout_parse.c: oxout_parse.y
	bison -d -v -o oxout_parse.c $<

clean:
	rm -f ag *.o oxout_parse.* oxout_lex.* *.output