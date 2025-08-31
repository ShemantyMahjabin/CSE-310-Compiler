%option noyywrap
%x STRINGSTATE
%x CHAR_START
%x CHAR_END
%x ESCAPE_START
%x MULTICHAR_START


%{
#include<bits/stdc++.h>
#include<string>
#include<iostream>
#include<fstream>
#include "2105091_st.cpp"
using namespace std;

int line_count=1;
bool isMultiLine=false;
int total_error;
string current_string;
int string_start_line = 0;
int comment_start_line=0;
string log_char="";
string token_char="";

ofstream logout;
ofstream tokenout;

SymbolTable s(7);




string Escape_seq(string str){
	if(str[1]=='t')
		return "\t";
	else if (str[1] =='n'||str[1] == '0')
		return "\n";
	else if (str[1] =='a')
		return "\a";
	else if (str[1] =='r')
		return "\r";
	else if (str[1] =='f')
		return "\f";
	else if (str[1] =='b')
		return "\b";
	else if (str[1] =='v')
		return "\v";
	else if (str[1] =='\'')
		return "\'";
	else if (str[1] =='\\')
		return "\\";
	else if (str[1] =='\"')
		return "\"";
	else return "x";
 }

int count_newlines(const char* text) {
    int count = 0;
    for(int i = 0; text[i] != '\0'; i++) {
        if(text[i] == '\n') count++;
    }
    return count;
}




string parse_string_content(const string& raw){
	string result;
	for(int i=0;i<raw.size();i++){
		if(raw[i]=='\\' && i+1<raw.size()){
			if(raw[i+1]=='\n'){
				i++;
				continue;
			}
			if(i+2<raw.size() && raw[i+1]=='\r' && raw[i+2]=='\n'){
				i+=2;
				continue;
			}
			
			
			string temptok(1, raw[i]);
            temptok+= raw[i+1];

			string converted = Escape_seq(temptok);
			
			if(converted != "x"){
				result += converted;
				i++;
			} else {
				result += raw[i];
			}
		} else {
			result += raw[i];
		}
	}

	if(result.size()>=2 && result.front()=='"' && result.back()=='"'){
		return result.substr(1,result.size()-2);
	}
	return result;
}

void reset_char(){
	log_char = "";
	token_char = "";
}
void log_error(const char* type){
	const char* str=log_char.c_str();
	logout << "Error at line no " << line_count << ": " << type << " " << str << " \n"<<endl<<endl;
	total_error++;
}



%}

WHITESPACE [ \t\f\r\v]+ 
LETTER [a-zA-Z]
DIGIT [0-9]
Digits {DIGIT}+
INTEGER {Digits}
NEWLINE \n
INCOP ("++"|"--")
RELOP ("<"|"<="|">"|">="|"=="|"!=")
LOGICOP("&&"|"||")
FLOATING_POINT_LITERALS {DIGIT}*(\.{DIGIT}+)?([Ee][+-]?{DIGIT}+)?
TO_MANY_DECIMAL_POINT {DIGIT}*(\.{DIGIT}*)(\.{DIGIT}*)+([Ee][+-]?{DIGIT}*(\.{DIGIT}*)*)?
ILL_FORMED_NUMBER {DIGIT}*(\.{DIGIT}*)?([Ee][+-]?{DIGIT}*(\.{DIGIT}*)*)
SPECIAL_CHARACTER_LITERALS [ntafrbv0]
IDENTIFIER [a-zA-Z_][a-zA-Z0-9_]*
SINGLELINE_COMMENT [/][/](([\\][\n])|(.))*
MULTILINE_COMMENT (\/\*)([^\*]|\*[^\/])*(\*\/)
UNFINISHED_COMMENT ([/][*])([^\*]|\*[^\/])*



%%

{NEWLINE} {line_count++;}
{WHITESPACE} {}
"if" {
    tokenout << "<IF> ";
    logout << "Line no " << line_count << ": Token <IF> Lexeme " << yytext << " found\n"<<endl;
}

"else" {
    tokenout << "<ELSE> ";
    logout << "Line no " << line_count << ": Token <ELSE> Lexeme " << yytext << " found\n"<<endl;
}

"goto" {
    tokenout << "<GOTO> ";
    logout << "Line no " << line_count << ": Token <GOTO> Lexeme " << yytext << " found\n"<<endl;
}

"for" {
    tokenout << "<FOR> ";
    logout << "Line no " << line_count << ": Token <FOR> Lexeme " << yytext << " found\n"<<endl;
}

"while" {
    tokenout << "<WHILE> ";
    logout << "Line no " << line_count << ": Token <WHILE> Lexeme " << yytext << " found\n"<<endl;
}

"do" {
    tokenout << "<DO> ";
    logout << "Line no " << line_count << ": Token <DO> Lexeme " << yytext << " found\n"<<endl;
}

"break" {
    tokenout << "<BREAK> ";
    logout << "Line no " << line_count << ": Token <BREAK> Lexeme " << yytext << " found\n"<<endl;
}

"int" {
    tokenout << "<INT> ";
    logout << "Line no " << line_count << ": Token <INT> Lexeme " << yytext << " found\n"<<endl;
}

"char" {
    tokenout << "<CHAR> ";
    logout << "Line no " << line_count << ": Token <CHAR> Lexeme " << yytext << " found\n"<<endl;
}

"long" {
    tokenout << "<LONG> ";
    logout << "Line no " << line_count << ": Token <LONG> Lexeme " << yytext << " found\n"<<endl;
}

"short" {
    tokenout << "<SHORT> ";
    logout << "Line no " << line_count << ": Token <SHORT> Lexeme " << yytext << " found\n"<<endl;
}

"static" {
    tokenout << "<STATIC> ";
    logout << "Line no " << line_count << ": Token <STATIC> Lexeme " << yytext << " found\n"<<endl;
}

"float" {
    tokenout << "<FLOAT> ";
    logout << "Line no " << line_count << ": Token <FLOAT> Lexeme " << yytext << " found\n"<<endl;
}

"double" {
    tokenout << "<DOUBLE> ";
    logout << "Line no " << line_count << ": Token <DOUBLE> Lexeme " << yytext << " found\n"<<endl;
}

"unsigned" {
    tokenout << "<UNSIGNED> ";
    logout << "Line no " << line_count << ": Token <UNSIGNED> Lexeme " << yytext << " found\n"<<endl;
}

"void" {
    tokenout << "<VOID> ";
    logout << "Line no " << line_count << ": Token <VOID> Lexeme " << yytext << " found\n"<<endl;
}

"return" {
    tokenout << "<RETURN> ";
    logout << "Line no " << line_count << ": Token <RETURN> Lexeme " << yytext << " found\n"<<endl;
}

"switch" {
    tokenout << "<SWITCH> ";
    logout << "Line no " << line_count << ": Token <SWITCH> Lexeme " << yytext << " found\n"<<endl;
}

"case" {
    tokenout << "<CASE> ";
    logout << "Line no " << line_count << ": Token <CASE> Lexeme " << yytext << " found\n"<<endl;
}

"default" {
    tokenout << "<DEFAULT> ";
    logout << "Line no " << line_count << ": Token <DEFAULT> Lexeme " << yytext << " found\n"<<endl;
}

"continue" {
    tokenout << "<CONTINUE> ";
    logout << "Line no " << line_count << ": Token <CONTINUE> Lexeme " << yytext << " found\n"<<endl;
}

{INCOP} {
    tokenout << "<INCOP> ";
    logout << "Line no " << line_count << ": Token <INCOP> Lexeme " << yytext << " found\n"<<endl;
}

{IDENTIFIER} {
    tokenout << "<ID," << yytext << "> ";
    logout << "Line no " << line_count << ": Token <ID> Lexeme " << yytext << " found\n"<<endl;
    bool check = s.insert(yytext, "ID");
    if (check) {
        s.printAllScopeTable(logout);
    } else {
        logout << s.getErrorMessage(yytext, "ID") <<"\n"<<endl;
    }
}

{INTEGER} {
    tokenout << "<CONST_INT," << yytext << "> ";
    logout << "Line no " << line_count << ": Token <CONST_INT> Lexeme " << yytext << " found\n"<<endl;
    bool check = s.insert(yytext, "CONST_INT");
    if(check) {
        s.printAllScopeTable(logout);
    } else {
        logout << s.getErrorMessage(yytext, "CONST_INT") <<"\n"<<endl;
    }
}

{FLOATING_POINT_LITERALS} {
    tokenout << "<CONST_FLOAT," << yytext << "> ";
    logout << "Line no " << line_count << ": Token <CONST_FLOAT> Lexeme " << yytext << " found\n"<<endl;
    bool check = s.insert(yytext, "CONST_FLOAT");
    if(check) {
        s.printAllScopeTable(logout);
    } else {
        logout << s.getErrorMessage(yytext, "CONST_FLOAT") <<"\n"<<endl;
    }
}
{TO_MANY_DECIMAL_POINT} {
    int current_line = line_count;
    line_count += count_newlines(yytext);
    logout << "Error at line no " << current_line << ": Too many decimal points " << yytext << "\n"<<endl<<endl;
    total_error++;
}
{ILL_FORMED_NUMBER} {
    int current_line = line_count;
    line_count += count_newlines(yytext);
    logout << "Error at line no " << current_line << ": Ill formed number " << yytext << "\n"<<endl<<endl;
    total_error++;
}


({DIGIT}+{IDENTIFIER}+)+ {
    int current_line = line_count;
    line_count += count_newlines(yytext);
    logout << "Error at line no " << current_line << ": Invalid prefix on ID or invalid suffix on Number " << yytext << "\n"<<endl<<endl;
    total_error++;
}

{DIGIT}+(\.[^{DIGIT}]) {
    int current_line = line_count;
    line_count += count_newlines(yytext);
    logout << "Error at line no " << current_line << ": Ill formed number " << yytext << "\n"<<endl<<endl;
    total_error++;
}



"+"|"-" {
    tokenout << "<ADDOP," << yytext << "> ";
    logout << "Line no " << line_count << ": Token <ADDOP> Lexeme " << yytext << " found\n"<<endl;
}

"*"|"/"|"%" {
    tokenout << "<MULOP," << yytext << "> ";
    logout << "Line no " << line_count << ": Token <MULOP> Lexeme " << yytext << " found\n"<<endl;
}



{RELOP} {
    tokenout << "<RELOP," << yytext << "> ";
    logout << "Line no " << line_count << ": Token <RELOP> Lexeme " << yytext << " found\n"<<endl;
}

"=" {
    tokenout << "<ASSIGNOP," << yytext << "> ";
    logout << "Line no " << line_count << ": Token <ASSIGNOP> Lexeme " << yytext << " found\n"<<endl;
}

{LOGICOP} {
    tokenout << "<LOGICOP," << yytext << "> ";
    logout << "Line no " << line_count << ": Token <LOGICOP> Lexeme " << yytext << " found\n"<<endl;
}

"!" {
    tokenout << "<NOT," << yytext << "> ";
    logout << "Line no " << line_count << ": Token <NOT> Lexeme " << yytext << " found\n"<<endl;
}

"(" {
    tokenout << "<LPAREN," << yytext << "> ";
    logout << "Line no " << line_count << ": Token <LPAREN> Lexeme " << yytext << " found\n"<<endl;
}

")" {
    tokenout << "<RPAREN," << yytext << "> ";
    logout << "Line no " << line_count << ": Token <RPAREN> Lexeme " << yytext << " found\n"<<endl;
}

"{" {
    tokenout << "<LCURL," << yytext << "> ";
    logout << "Line no " << line_count << ": Token <LCURL> Lexeme " << yytext << " found\n"<<endl;
    s.enterscope();
}

"}" {
    tokenout << "<RCURL," << yytext << "> ";
    logout << "Line no " << line_count << ": Token <RCURL> Lexeme " << yytext << " found\n"<<endl;
    s.exitscope();
}

"[" {
    tokenout << "<LTHIRD," << yytext << "> ";
    logout << "Line no " << line_count << ": Token <LTHIRD> Lexeme " << yytext << " found\n"<<endl;
}

"]" {
    tokenout << "<RTHIRD," << yytext << "> ";
    logout << "Line no " << line_count << ": Token <RTHIRD> Lexeme " << yytext << " found\n"<<endl;
}

"," {
    tokenout << "<COMMA," << yytext << "> ";
    logout << "Line no " << line_count << ": Token <COMMA> Lexeme " << yytext << " found\n"<<endl;
}

";" {
    tokenout << "<SEMICOLON," << yytext << "> ";
    logout << "Line no " << line_count << ": Token <SEMICOLON> Lexeme " << yytext << " found\n"<<endl;
}


"'"			{
				log_char += yytext;
				BEGIN CHAR_START;
			}

"\""		{
				current_string = "";
				current_string += yytext;
				string_start_line = line_count;
				BEGIN STRINGSTATE;
			}

{UNFINISHED_COMMENT} {
    comment_start_line = line_count;
    for (int i = 0; i < strlen(yytext); i++) {
        if (yytext[i] == '\n') line_count++;
    }
    logout << "Error at line no " << comment_start_line << ": Unterminated comment " << yytext << "\n"<<endl<<endl;
    total_error++;
}

{MULTILINE_COMMENT} {
    int startingline = line_count;
    for (int i = 0; i < strlen(yytext); i++) {
        if (yytext[i] == '\n') line_count++;
    }
    logout << "Line no " << line_count << ": Token <COMMENT> Lexeme " << yytext << " found\n"<<endl;
}

{SINGLELINE_COMMENT} {
    int startingline = line_count;
    for (int i = 0; i < strlen(yytext); i++) {
        if (yytext[i] == '\n') line_count++;
    }
    logout << "Line no " << line_count << ": Token <COMMENT> Lexeme " << yytext << " found\n"<<endl;
}



<STRINGSTATE>"\\\"" {
				current_string += yytext;
			}
			  

<STRINGSTATE>"\\\n"|"\\\r\n" {
				current_string += yytext;
				line_count++;
				isMultiLine=true;
			}


<STRINGSTATE>"\"" {
    current_string += yytext;
    string clean = parse_string_content(current_string);
    const char* raw = current_string.c_str();
    
    if (isMultiLine) {
        tokenout << "<STRING," << clean << "> ";
        logout << "Line no " << line_count << ": Token <STRING> Lexeme " << raw << " found --> <STRING, "<< clean <<">\n"<<endl;
    } else {
        tokenout << "<STRING," << clean << "> ";
        logout << "Line no " << line_count << ": Token <STRING> Lexeme " << raw << " found --> <STRING, "<< clean <<">\n"<<endl;
    }

    current_string = "";
    isMultiLine = false;
    BEGIN INITIAL;
}


<STRINGSTATE>[^\n] {
				current_string += yytext;
			}
<STRINGSTATE>[\n]|"\r\n" {
				const char *cstr=current_string.c_str();
				logout << "Error at line no " << string_start_line << ": Unterminated string " << cstr << "\n"<<endl<<endl;
    			total_error++;
				line_count++;
				current_string = "";
				isMultiLine = false;
				BEGIN INITIAL;
			}
<STRINGSTATE><<EOF>> {
    const char* cstr = current_string.c_str();
    logout << "Error at line no " << string_start_line << ": Unterminated string " << cstr << "\n"<<endl<<endl;
    total_error++;
    current_string = "";
    isMultiLine = false;
    BEGIN INITIAL;
}






<CHAR_START>["\'"] {
				log_char += yytext;
				log_error(" Empty character constant error ");
                
				reset_char();
				
				BEGIN INITIAL;
			}

<CHAR_START>{NEWLINE} {
				log_char += yytext;
				log_error("Unterminated character ");
				reset_char();
				line_count++;
				BEGIN INITIAL;
			}

<CHAR_START>["\\"] {
				log_char += yytext;
				BEGIN ESCAPE_START;
			}			
<CHAR_START>[^\n\t\r] {
				log_char += yytext;
				token_char += yytext;
				BEGIN CHAR_END;
			}

<ESCAPE_START>{SPECIAL_CHARACTER_LITERALS} {
    log_char += yytext;
     const char *cstr = log_char.c_str();
    token_char = Escape_seq(cstr+1);
    BEGIN CHAR_END;
}
<ESCAPE_START>["\'"] {
				log_char += yytext;
				log_error("Unterminated character ");
				reset_char();
				
				BEGIN INITIAL;
			}


<CHAR_END>"'" {
    log_char += yytext;
    tokenout << "<CONST_CHAR, " << token_char << "> ";

    logout << "Line no " << line_count << ": Token <CONST_CHAR> Lexeme " << log_char 
       << " found --> <CONST_CHAR, " << token_char << ">\n"<<endl;

    bool check = s.insert( log_char, "CONST_CHAR");
    if (check) {
        s.printAllScopeTable(logout);
    } else {
        logout << s.getErrorMessage( log_char, "CONST_CHAR")<<"\n"<<endl;
    }
    reset_char();
	BEGIN INITIAL;
}


<CHAR_END>{NEWLINE} {
				log_char += yytext;
				log_error("Unterminated character");
				reset_char();
				line_count++;
				BEGIN INITIAL;
			}
<CHAR_END><<EOF>> {
				log_char += yytext;
				log_error("Unterminated character");
				reset_char();
				BEGIN INITIAL;
			}


<CHAR_END>({WHITESPACE}+{NEWLINE}) {

		 log_char+=yytext;
         log_error("Unterminated character");
		 reset_char();
		 line_count++;
		 BEGIN INITIAL;
		 
}	
<CHAR_END>[;] {
				log_error("Unterminated character");
				reset_char();
				BEGIN INITIAL;
			}

<CHAR_END>[^'] {
				log_char += yytext;
				BEGIN MULTICHAR_START;
			}
<MULTICHAR_START>(.)*["\'"] {
				log_char += yytext;
				log_error("Multi character constant error");
				reset_char();
				BEGIN INITIAL;
			}



<<EOF>> {
    s.printAllScopeTable(logout);
    logout << "Total lines: " << line_count << "\n";
    logout << "Total errors: " << total_error << "\n";
    return 0;
}


. {
    logout << "Error at line no " << line_count << ": Unrecognized character " << yytext << "\n"<<endl;
    total_error++;
}


		

  
%%

int main(int argc,char *argv[]){
	
	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
	
	logout.open("log.txt");
	tokenout.open("token.txt");

	yyin= fin;
	yylex();
	fclose(yyin);
	tokenout.close();
	logout.close();
	return 0;
}
