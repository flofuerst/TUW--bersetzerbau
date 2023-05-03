%{
 #include <stdio.h>
 #include <stdlib.h>
 
 #include "types.h"
 #include "oxout_lex.h"

 void yyerror(const char *s);
%}

%start RootProgram
%token OBJECT INT CLASS END RETURN COND CONTINUE BREAK NOT OR NEW NIL
%token SEMICOLON LPAREN COMMA RPAREN LARROW RARROW MINUS PLUS ASTERISK GT HASH
%token IDENTIFIER NUMBER


// Ox attributes
@traversal @postorder enter 

@attributes { char *string; } IDENTIFIER;
@attributes { long value; } NUMBER

@attributes { Scope *scopeAcc; 
              Scope *finalScope; } Program
@attributes { Scope *scopeAcc; 
              @autosyn Scope *finalScope; } Members
@attributes { Type *type;
              @autoinh Scope *finalScope; } Class
@attributes { Type *type;
              @autoinh Scope *classScope; } Member

@attributes { Selector *selector; } Selector

@attributes { Types *typesAcc; 
              @autosyn Types *finalTypes; } Types
@attributes { PrimitiveType primType; } Type

/* Method Parameters */
@attributes { Scope *scopeAcc;
              @autosyn Scope *finalScope;
              Types *typesAcc;
              @autosyn Types *finalTypes; } Pars
@attributes { Type *type; } Par

/* Method Statements */
@attributes { Scope *scopeAcc;                                                          
              @autoinh Scope *initialScope;                                             
              @autoinh PrimitiveType returnType; } Stats
@attributes { Scope *scope;
              Type *type;
              PrimitiveType returnType; } Stat

@attributes { Scope *scope;                                                         
              PrimitiveType returnType; } Return Expr Cond Guarded Term
              
@attributes { @autoinh Scope *scope;
              @autoinh PrimitiveType returnType; } Guardeds

@attributes { @autoinh Scope *scope; } PrefixExpr AddExpr MultExpr OrExpr

@attributes { @autoinh Scope *scope; 
              Types *typeAcc;
              @autosyn Types *finalTypes; } Exprs

%% 


RootProgram: Program
        @{ @i @Program.scopeAcc@ = createScope(); @}
;


Program: Program Selector SEMICOLON
        @{ @i exitIfError(appendSelectorToScope(&@Program.1.scopeAcc@, @Program.0.scopeAcc@, @Selector.selector@)); 
           @i @Program.0.finalScope@ = @Program.1.finalScope@;
        @}
    | Program Class SEMICOLON
        @{ @i exitIfError(appendTypeToScope(&@Program.1.scopeAcc@, @Program.0.scopeAcc@, @Class.type@)); 
           @i @Class.finalScope@ = @Program.0.finalScope@;
           @i @Program.0.finalScope@ = @Program.1.finalScope@;
        @}
    | 
        @{ @i @Program.finalScope@ = @Program.scopeAcc@; @}
;


Selector: Type IDENTIFIER LPAREN OBJECT Types RPAREN
        @{ @i @Selector.selector@ = createSelector(@IDENTIFIER.string@, 
                getCorrespondingSelectorPrimType(@Type.primType@), appendTypeWithoutCheck(@Types.finalTypes@, createType(NULL, OBJECT_SELECTOR))); 
           @i @Types.typesAcc@ = NULL;  /* Base case for the first type */
        @}
;


Types: Types COMMA Type
        @{ @i exitIfError(appendType(&@Types.1.typesAcc@, @Types.0.typesAcc@, createType(NULL, @Type.primType@))); @}
     |  
        @{ @i @Types.finalTypes@ = @Types.typesAcc@; @}
;


Type: INT
        @{ @i @Type.primType@ = INT_VAR; @}
    | OBJECT
        @{ @i @Type.primType@ = OBJECT_VAR; @}
;


Class: CLASS IDENTIFIER Members END
        @{ @i @Class.type@ = createType(@IDENTIFIER.string@, CLAZZ); 
           @i @Members.scopeAcc@ = @Class.finalScope@;
        @}
;


Members: Members Member SEMICOLON
        @{ @i exitIfError(appendTypeToScope(&@Members.1.scopeAcc@, @Members.0.scopeAcc@, @Member.type@)); 
           @i @Member.classScope@ = @Members.0.finalScope@;
        @}
    | 
        @{ @i @Members.finalScope@ = @Members.scopeAcc@; @}
;


Member: Type IDENTIFIER
        @{ @i @Member.type@ = createType(@IDENTIFIER.string@, @Type.primType@); @}
    | Type IDENTIFIER LPAREN Pars RPAREN Stats Return END
        @{ @i @Member.type@ = NULL;

           @i @Pars.scopeAcc@ = @Member.classScope@;
           @i @Pars.typesAcc@ = NULL;

           @i @Stats.initialScope@ = @Pars.finalScope@;
           @i @Stats.returnType@ = @Type.primType@;

           @i @Return.scope@ = @Stats.scopeAcc@;
           @i @Return.returnType@ = @Type.primType@;
        
           @enter exitIfError(implHasSelector(@Member.classScope@, 
                                createType(@IDENTIFIER.string@, getCorrespondingSelectorPrimType(@Type.primType@)), @Pars.finalTypes@));
        @}
;

Pars: Pars COMMA Par
        @{ @i exitIfError(appendType(&@Pars.1.typesAcc@, @Pars.0.typesAcc@, @Par.type@)); 
           @i exitIfError(appendTypeToScope(&@Pars.1.scopeAcc@, @Pars.0.scopeAcc@, @Par.type@));
        @}
    | Par
        @{ @i exitIfError(appendType(&@Pars.finalTypes@, @Pars.0.typesAcc@, @Par.type@));
           @i exitIfError(appendTypeToScope(&@Pars.finalScope@, @Pars.scopeAcc@, @Par.type@));
        @}
;

Par: Type IDENTIFIER
        @{ @i @Par.type@ = createType(@IDENTIFIER.string@, @Type.primType@); @}
;

Stats: Stats Stat SEMICOLON
        @{ @i exitIfError(appendTypeToScope(&@Stats.0.scopeAcc@, @Stats.1.scopeAcc@, @Stat.type@));             
           @i @Stat.scope@ = @Stats.1.scopeAcc@;
           @i @Stat.returnType@ = @Stats.0.returnType@;
        @}
    |
        @{ @i @Stats.scopeAcc@ = @Stats.initialScope@; @}
;


Stat: Return
        @{ @i @Stat.type@ = NULL;
           @i @Return.scope@ = @Stat.scope@;
           @i @Return.returnType@ = @Stat.returnType@;
        @}
    /* Conditional statement */
    | Cond
        @{ @i @Stat.type@ = NULL;
           @i @Cond.scope@ = @Stat.scope@;
           @i @Cond.returnType@ = @Stat.returnType@;
        @}
    /* Local variable declaration */
    | Type IDENTIFIER LARROW Expr
        @{ @i @Stat.type@ = createType(@IDENTIFIER.string@, @Type.primType@);
           @i @Expr.scope@ = @Stat.scope@;

           @enter exitIfError(compareVariableAssignmentTypes(@Type.primType@, @Expr.returnType@));
        @}
    /* Variable assignment */
    | IDENTIFIER LARROW Expr
        @{ @i @Stat.type@ = NULL;
           @i @Expr.scope@ = @Stat.scope@;

           @enter exitIfError(varExistsWithType(@Stat.scope@, @IDENTIFIER.string@, @Expr.returnType@));
        @}
    /* Expression eg. method call */
    | Expr
        @{ @i @Stat.type@ = NULL;
           @i @Expr.scope@ = @Stat.scope@;
        @}
;


Return: RETURN Expr
        @{ @i @Expr.scope@ = @Return.scope@;

           @enter exitIfError(compareReturnTypes(@Return.returnType@, @Expr.returnType@));
        @}
;


Cond: COND Guardeds END
        @{ @i @Guardeds.scope@ = @Cond.scope@;
           @i @Guardeds.returnType@ = @Cond.returnType@;
        @}
;


Guardeds: Guardeds Guarded SEMICOLON
        @{ @i @Guarded.scope@ = @Guardeds.scope@;
           @i @Guarded.returnType@ = @Guardeds.returnType@;
        @}
	| /* Nothing to do here */
;


Guarded: Expr RARROW Stats Leave
        @{ @i @Expr.scope@ = @Guarded.scope@;
           @i @Stats.initialScope@ = @Guarded.scope@;
           @i @Stats.returnType@ = @Guarded.returnType@;

           @enter exitIfError(checkConditionType(@Expr.returnType@));
        @}
    | RARROW Stats Leave
        @{ @i @Stats.initialScope@ = @Guarded.scope@;
           @i @Stats.returnType@ = @Guarded.returnType@;
        @}
;


Leave: CONTINUE
    | BREAK
;


Expr: Term
        @{ @i @Term.scope@ = @Expr.scope@;
           @i @Expr.returnType@ = @Term.returnType@;
        @}
    | PrefixExpr
        @{ @i @PrefixExpr.scope@ = @Expr.scope@;
           @i @Expr.returnType@ = INT_VAR;
        @}
    | AddExpr
        @{ @i @AddExpr.scope@ = @Expr.scope@;
           @i @Expr.returnType@ = INT_VAR;
        @}
    | MultExpr
        @{ @i @MultExpr.scope@ = @Expr.scope@;
           @i @Expr.returnType@ = INT_VAR; 
        @}
    | OrExpr
        @{ @i @OrExpr.scope@ = @Expr.scope@;
           @i @Expr.returnType@ = INT_VAR; 
        @}
    | Term GT Term
        @{ @i @Term.0.scope@ = @Expr.scope@;
           @i @Term.1.scope@ = @Expr.scope@; 
           @i @Expr.returnType@ = INT_VAR;

           @enter exitIfError(checkTermType(@Term.0.returnType@));
           @enter exitIfError(checkTermType(@Term.1.returnType@));
        @}
    | Term HASH Term
        @{ @i @Term.0.scope@ = @Expr.scope@;
           @i @Term.1.scope@ = @Expr.scope@;
           @i @Expr.returnType@ = INT_VAR;
            
           @enter exitIfError(compareTypesForHash(@Term.0.returnType@, @Term.1.returnType@));
        @}
    | NEW IDENTIFIER
        @{ @i @Expr.returnType@ = OBJECT_VAR;
           
           @enter exitIfError(varExistsWithType(@Expr.scope@, @IDENTIFIER.string@, CLAZZ));
        @}
;


PrefixExpr: NOT PrefixExpr
    | MINUS PrefixExpr
    | NOT Term
        @{ @i @Term.scope@ = @PrefixExpr.scope@;
           @enter exitIfError(checkTermType(@Term.returnType@));
        @}
    | MINUS Term
        @{ @i @Term.scope@ = @PrefixExpr.scope@;
           @enter exitIfError(checkTermType(@Term.returnType@));
        @}
;


AddExpr: Term PLUS Term
        @{ @i @Term.0.scope@ = @AddExpr.scope@;
           @i @Term.1.scope@ = @AddExpr.scope@;

           @enter exitIfError(checkTermType(@Term.0.returnType@));
           @enter exitIfError(checkTermType(@Term.1.returnType@));
        @}
    | AddExpr PLUS Term
        @{ @i @Term.scope@ = @AddExpr.0.scope@;

           @enter exitIfError(checkTermType(@Term.returnType@));
        @}
;


MultExpr: Term ASTERISK Term
        @{ @i @Term.0.scope@ = @MultExpr.scope@;
           @i @Term.1.scope@ = @MultExpr.scope@;

           @enter exitIfError(checkTermType(@Term.0.returnType@));
           @enter exitIfError(checkTermType(@Term.1.returnType@));
        @}
    | MultExpr ASTERISK Term
        @{ @i @Term.scope@ = @MultExpr.0.scope@;

           @enter exitIfError(checkTermType(@Term.returnType@));
        @}
;


OrExpr: Term OR Term
        @{ @i @Term.0.scope@ = @OrExpr.scope@;
           @i @Term.1.scope@ = @OrExpr.scope@;

           @enter exitIfError(checkTermType(@Term.0.returnType@));
           @enter exitIfError(checkTermType(@Term.1.returnType@));
        @}
    | OrExpr OR Term
        @{ @i @Term.scope@ = @OrExpr.0.scope@;

           @enter exitIfError(checkTermType(@Term.returnType@));
        @}
;


Term: LPAREN Expr RPAREN
        @{ @i @Term.returnType@ = @Expr.returnType@;
           @i @Expr.scope@ = @Term.scope@;
        @}
    | NUMBER
        @{ @i @Term.returnType@ = INT_VAR; @}
    | NIL
        @{ @i @Term.returnType@ = OBJECT_VAR; @}
    /* Read access to variable */
    | IDENTIFIER
        @{ @i exitIfError(searchPrimTypeOfVar(&@Term.returnType@, @Term.scope@, @IDENTIFIER.string@));
        @}
    /* Method call */
    | IDENTIFIER LPAREN Exprs RPAREN
        @{ @i exitIfError(getSelectorPrimTypeWithParams(&@Term.returnType@, @Term.scope@, @IDENTIFIER.string@ , @Exprs.finalTypes@));
           @i @Exprs.scope@ = @Term.scope@;
           @i @Exprs.typeAcc@ = NULL;
        @}
;


Exprs: Exprs COMMA Expr
        @{ @i exitIfError(appendType(&@Exprs.1.typeAcc@, @Exprs.0.typeAcc@, createType(NULL, @Expr.returnType@))); 
           @i @Expr.scope@ = @Exprs.scope@;
        @}
    | Expr 
        @{ @i exitIfError(appendType(&@Exprs.finalTypes@, @Exprs.typeAcc@, createType(NULL, @Expr.returnType@)));
           @i @Expr.scope@ = @Exprs.scope@;
        @}
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
   	fprintf(stderr, "error: '%s'\n", s);
	exit(2);
}
