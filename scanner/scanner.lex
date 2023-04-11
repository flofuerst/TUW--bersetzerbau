%{
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

Digit		[0-9]
Alpha		[a-zA-Z]
HexDigit    ({Digit}|[a-fA-F])
Hextail		"_"*{HexDigit}({HexDigit}|"_")*
Hex		    "0x"{Hextail}
Decimal     {Digit}({Digit}|"_")*

Identifier  {Alpha}({Digit}|{Alpha}|"_")* 

Keyword             ("object"|"int"|"class"|"end"|"return"|"cond"|"continue"|"break"|"not"|"or"|"new"|"null")
SpecialCharacter    (";"|"("|","|")"|"<-"|"->"|"-"|"+"|"*"|">"|"#")
Whitespace          (" "|"\t"|"\n")
Comment             "(*"([^*]|("*"[^)]))*"*)"
Ignore              {Whitespace}|{Comment}

%%

{Keyword}             { printf("%s\n", yytext); }
{SpecialCharacter}    { printf("%s\n", yytext); }
{Ignore}              { }

{Decimal}             { printf("num %ld\n", readDecimal(yytext)); }
{Hex}                 { printf("num %ld\n", readHexadecimal(yytext+2)); } // +2 to skip '0x'

{Identifier}          { printf("id %s\n", yytext); }
.                     { printf("%s\n", yytext); exit(1);}

%%


int main()
{
  yylex();
}
