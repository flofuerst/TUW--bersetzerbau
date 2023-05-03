%{
#include <stdlib.h>
#include <ctype.h>
#include <assert.h>


#include "types.h"
#include "oxout_parse.h"


int readDecimal(char* dec) {
    int len = strlen(dec);
    int val = 0;
    for (int i = 0; i < len; i++) {
        if (dec[i] == '_') {
            continue;
        }
        val *= 10;
        val += dec[i] - '0';
    }
    return val;
}
int readHexadecimal(char* hex) {
    int len = strlen(hex);
    long long int val = 0;
    for (int i = 0; i < len; i++) {
        if (hex[i] == '_') {
            continue;
        }
        val *= 16;
        if (hex[i] >= '0' && hex[i] <= '9') {
            val += hex[i] - '0';
        } else if (hex[i] >= 'a' && hex[i] <= 'f') {
            val += hex[i] - 'a' + 10;
        } else if (hex[i] >= 'A' && hex[i] <= 'F') {
            val += hex[i] - 'A' + 10;
        }
    }
    return val;
}
%}

DIGIT		[0-9]
ALPHA		[a-zA-Z]
HEXDIGIT    ({DIGIT}|[a-fA-F])
HEXTAIL		"_"*{HEXDIGIT}({HEXDIGIT}|"_")*
HEX		    "0x"{HEXTAIL}
DECIMAL     {DIGIT}({DIGIT}|"_")*

IDENTIFIER  {ALPHA}({DIGIT}|{ALPHA}|"_")* 

WHITESPACE          (" "|"\t"|"\n")
COMMENT             "(*"([^*]|("*"[^)]))*[*]?"*)"
IGNORE              {WHITESPACE}|{COMMENT}

%%
"object"	{ return OBJECT; }
"int"		{ return INT; }
"class"		{ return CLASS; }
"end"		{ return END; }
"return"	{ return RETURN; }
"cond"		{ return COND; }
"continue"	{ return CONTINUE; }
"break"		{ return BREAK; }
"not"		{ return NOT; }
"or"		{ return OR; }
"new"		{ return NEW; }
"null"		{ return NIL; }
";"		{ return SEMICOLON; }
"("		{ return LPAREN; }
","		{ return COMMA; }
")"		{ return RPAREN; }
"<-"		{ return LARROW; }
"->"		{ return RARROW; }
"-"		{ return MINUS; }
"+"		{ return PLUS; }
"*"		{ return ASTERISK; }
">"		{ return GT; }
"#"		{ return HASH; }

{IGNORE}	{ }

{IDENTIFIER}	return IDENTIFIER; 	@{ @IDENTIFIER.string@ = strdup(yytext); @}

{DECIMAL}		return NUMBER; 		@{ @NUMBER.value@ = readDecimal(yytext); @}
{HEX}	return NUMBER;		@{ @NUMBER.value@ = readHexadecimal(yytext + 2); @}

.		{ printf("%s\n", yytext); exit(1); }
%%



