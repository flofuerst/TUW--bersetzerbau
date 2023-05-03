%{
 #include <stdio.h>
 #include <stdlib.h>
 #include "lexer.h"

 void yyerror(const char *s);
%}

%union {
	char *s;
	int i;
}

%start Program
%token OBJECT INT CLASS END RETURN COND CONTINUE BREAK NOT OR NEW NIL
%token SEMICOLON LPAREN COMMA RPAREN LARROW RARROW MINUS PLUS ASTERISK GT HASH
%token IDENTIFIER NUMBER

%% 

Program: Program Selector SEMICOLON
       | Program Class SEMICOLON
       | %empty
       ;

Selector: Type IDENTIFIER LPAREN OBJECT Types RPAREN
	;

Types: Types COMMA Type
     | %empty
     ;

Type: INT
    | OBJECT
    ;

Class: CLASS IDENTIFIER Members END

Members: Members Member SEMICOLON
       | %empty
       ;

Member: Type IDENTIFIER
      | Type IDENTIFIER LPAREN Pars RPAREN Stats Return END

Pars: Pars COMMA Par
    | Par
    ;

Par: Type IDENTIFIER

Stats: Stats Stat SEMICOLON
     | %empty
     ;

Stat: Return
    | Cond
    | Type IDENTIFIER LARROW Expr
    | IDENTIFIER LARROW Expr
    | Expr
    ;

Return: RETURN Expr
      ;

Cond: COND Guardeds END
    ;

Guardeds: Guardeds Guarded SEMICOLON
	| %empty
	;

Guarded: OptExpr RARROW Stats Leave
       ;

OptExpr: Expr
       | %empty
       ;

Leave: CONTINUE
     | BREAK
     ;

Expr: Term
    | Prefixes Term
    | Term PLUS AddExpr
    | Term ASTERISK MultExpr
    | Term OR OrExpr
    | Term GT Term
    | Term HASH Term
    | NEW IDENTIFIER
    ;

Prefixes: Prefixes Prefix 
	| Prefix
        ;

Prefix: NOT
      | MINUS
      ;

AddExpr: Term PLUS AddExpr
       | Term
       ;

MultExpr: Term ASTERISK MultExpr
       | Term
       ;

OrExpr: Term OR OrExpr
      | Term
      ;

Term: LPAREN Expr RPAREN
    | NUMBER
    | NIL
    | IDENTIFIER
    | IDENTIFIER LPAREN Expr Exprs RPAREN
    ;

Exprs: Exprs COMMA Expr
     | %empty
     ;

%%

int main(int argc, char **argv) {
   if (argc > 1) {
      yyin = fopen(argv[1], "r");
      if (yyin == NULL){
         fprintf(stderr, "syntax: %s filename\n", argv[0]);
      }
   }
   yyparse();

   return 0;
}

void yyerror(const char *s) {
   	fprintf(stderr, "syntax error: '%s'\n", s);
	exit(2);
}
