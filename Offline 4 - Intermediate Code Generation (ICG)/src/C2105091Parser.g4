parser grammar C8086Parser;

options {
    tokenVocab = C8086Lexer;
}

@parser::header {
    #include <iostream>
    #include <fstream>
    #include <string>
    #include <cstdlib>
    #include "C8086Lexer.h"
	#include "SymbolTable.h"
	using namespace std;
    extern std::ofstream parserLogFile;
    extern std::ofstream errorFile;
	
	
    extern int syntaxErrorCount;
	extern SymbolTable symbolTable;

}

@parser::members {
	ofstream asmFile;
	

	int labelcount =0;
	int stackOffset = 0;
	bool insideFunc=false;
	bool codestart=false;
	string currFunc="";
	
	

	string returnLabel = "";
    bool returned = false;

	map<string,int>localVarOffset;
	vector<string>globalVars;
	stack<string>endlblstack;
	stack<string>falselblstack;
	stack<string>startlblstack;  
	vector<string> currentFuncParams;

	vector<string>asmlines;
	ofstream optfile;

	void initializeCode(){
		asmFile.open("code1.asm");
		
		if(!asmFile.is_open()){
			cerr<<"Error opening assembly files!"<<endl;
			exit(1);
		}
		writeToAsm(".MODEL SMALL");
		writeToAsm(".STACK 1000H");
		writeToAsm(".DATA");
		writeToAsm("\tnumber DB \"00000$\"");
        
	}

	string newLabel(){
		return "L" + to_string(++labelcount);
	}

	void writeToAsm(const string& code){
		asmlines.push_back(code);
		asmFile << code << endl;
		asmFile.flush();
	}

	void writeComment(const string& comment,int line){
		asmlines.push_back("\t" + comment + "		;Line " + to_string(line));
		asmFile<<"\t"<<comment<<"		;Line "<<line<<endl;
		asmFile.flush();
	}
	void writeLabel(const string& label){
		asmlines.push_back(label + ":");
		asmFile<<label<<":"<<endl;
		asmFile.flush();
	}


	void printlastLines(){

      writeToAsm("");
      writeToAsm("new_line proc");
      writeToAsm("    push ax");
      writeToAsm("    push dx");
      writeToAsm("    mov ah,2");
      writeToAsm("    mov dl,0Dh");
      writeToAsm("    int 21h");
      writeToAsm("    mov ah,2");
      writeToAsm("    mov dl,0Ah");
      writeToAsm("    int 21h");
      writeToAsm("    pop dx");
      writeToAsm("    pop ax");
      writeToAsm("    ret");
      writeToAsm("new_line endp");
      writeToAsm("");
      writeToAsm("print_output proc  ;print what is in ax");
      writeToAsm("    push ax");
      writeToAsm("    push bx");
      writeToAsm("    push cx");
      writeToAsm("    push dx");
      writeToAsm("    push si");
      writeToAsm("    lea si,number");
      writeToAsm("    mov bx,10");
      writeToAsm("    add si,4");
      writeToAsm("    cmp ax,0");
      writeToAsm("    jnge negate");
      writeToAsm("    print:");
      writeToAsm("    xor dx,dx");
      writeToAsm("    div bx");
      writeToAsm("    mov [si],dl");
      writeToAsm("    add [si],'0'");
      writeToAsm("    dec si");
      writeToAsm("    cmp ax,0");
      writeToAsm("    jne print");
      writeToAsm("    inc si");
      writeToAsm("    lea dx,si");
      writeToAsm("    mov ah,9");
      writeToAsm("    int 21h");
      writeToAsm("    pop si");
      writeToAsm("    pop dx");
      writeToAsm("    pop cx");
      writeToAsm("    pop bx");
      writeToAsm("    pop ax");
      writeToAsm("    ret");
      writeToAsm("    negate:");
      writeToAsm("    push ax");
      writeToAsm("    mov ah,2");
      writeToAsm("    mov dl,'-'");
      writeToAsm("    int 21h");
      writeToAsm("    pop ax");
      writeToAsm("    neg ax");
      writeToAsm("    jmp print");
      writeToAsm("print_output endp");
      writeToAsm("END main");
	  asmFile.close();
	  
	  
	}

	void optimizeAsm() {
		vector<string> optimizedLines;
		for(int i=0;i<asmlines.size();i++){
			string l1=asmlines[i];
			string l2 = (i + 1 < (int)asmlines.size()) ? asmlines[i + 1] : "";
			bool skip=false;

			if(l1.find("MOV AX,") != string::npos && l2.find("MOV") != string::npos) {
				string varname = l1.substr(l1.find("MOV AX,") + 7);
				if(l2.find("MOV " + varname + ", AX") != string::npos) {
					optimizedLines.push_back(l1);
					i++;
					skip = true;
				}
			} 
			if(l1.find("PUSH AX") != string::npos && l2.find("POP AX") != string::npos) {
				i++;
				skip = true;
			}

			if (l1.find("ADD AX, 0") != string::npos || 
				l1.find("SUB AX, 0") != string::npos || 
				l1.find("MUL AX, 1") != string::npos) {
				skip = true;
			}

			
			if(!skip) {
				optimizedLines.push_back(l1);
			}
		}
		asmlines = optimizedLines;
	}
	void writeOptimizedAsm() {
		optfile.open("optimized.asm");
		if(!optfile.is_open()) {
			cerr << "Error opening optimized.asm file!" << endl;
			exit(1);
		}

		optimizeAsm();
		for(const string& line : asmlines) {
			optfile << line << endl;
		}
		optfile.close();
	}

    void writeIntoparserLogFile(const std::string message) {
        if (!parserLogFile) {
            std::cout << "Error opening parserLogFile.txt" << std::endl;
            return;
        }

        parserLogFile << message << std::endl;
        parserLogFile.flush();
    }

    void writeIntoErrorFile(const std::string message) {
        if (!errorFile) {
            std::cout << "Error opening errorFile.txt" << std::endl;
            return;
        }
        errorFile << message << std::endl;
        errorFile.flush();
    }
	
	
}


start : {initializeCode(); } program
	{
		printlastLines();
		writeOptimizedAsm();
        writeIntoparserLogFile("Parsing completed successfully with " + std::to_string(syntaxErrorCount) + " syntax errors.");
	}
	;

program : program unit 
	| unit
	;
	
unit : var_declaration
     | func_declaration
     | func_definition
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
		| type_specifier ID LPAREN RPAREN SEMICOLON
		;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN
		{
			if(!codestart){
				codestart=true;
				writeToAsm(".CODE");
		
			}
			currFunc=$ID->getText();
			returned = false;
			returnLabel.clear();

			insideFunc=true;
			stackOffset=0;
			localVarOffset.clear();
			FunctionInfo* f = new FunctionInfo();
			f->setReturnType($type_specifier.name_line);
			symbolTable.insert(currFunc,"FUNCTION");
			SymbolInfo* sym = symbolTable.lookup(currFunc);
            sym->setFunctionInfo(f);

			
			if(currFunc=="main"){
				writeToAsm("main PROC");
				writeToAsm("\tMOV AX, @DATA");
				writeToAsm("\tMOV DS, AX");
				writeToAsm("\tPUSH BP");
				writeToAsm("\tMOV BP, SP");
			}else {
				writeToAsm(currFunc + " PROC");
				writeToAsm("\tPUSH BP");
        		writeToAsm("\tMOV BP, SP");
			}
				
                symbolTable.enterscope();
			
		}
		
		
		compound_statement
		{
			
		if (returned && returnLabel!="") {
    writeLabel(returnLabel);
    if (currFunc == "main") {
        if (stackOffset > 0)
            writeToAsm("\tADD SP, " + std::to_string(stackOffset));
        
    } else {
        int dest = currentFuncParams.size() * 2;
        if (stackOffset > 0)
            writeToAsm("\tADD SP, " + std::to_string(dest));
        
    }
        writeToAsm("\tMOV SP, BP");
    
    writeToAsm("\tPOP BP");
    if (currFunc != "main") {
        int dest = currentFuncParams.size() * 2;
        if (dest > 0) {
            writeToAsm("\tRET " + std::to_string(dest));
        } else {
            writeToAsm("\tRET");
        }
    } else {
        writeToAsm("\tMOV AX, 4CH");
        writeToAsm("\tINT 21H");
    }
}else{
	 writeToAsm("\tMOV SP, BP");
    
    writeToAsm("\tPOP BP");
	writeToAsm("\tRET");
}

			writeToAsm(currFunc + " ENDP");
				symbolTable.exitscope();
				insideFunc=false;
				currentFuncParams.clear();	
		}
 		
		| type_specifier ID LPAREN RPAREN 
		{
			currFunc=$ID->getText();
			returned = false;              
    		returnLabel.clear();           
			insideFunc=true;
			stackOffset=0;
			if(!codestart){
				codestart=true;
				writeToAsm(".CODE");
			}
			localVarOffset.clear();
			FunctionInfo* f = new FunctionInfo();
			f->setReturnType($type_specifier.name_line);
			symbolTable.insert(currFunc,"ID");
			SymbolInfo* sym = symbolTable.lookup(currFunc);
            sym->setFunctionInfo(f);

			;
			if(currFunc=="main"){
				
				writeToAsm("main PROC");
				writeToAsm("\tMOV AX, @DATA");
				writeToAsm("\tMOV DS, AX");
				writeToAsm("\tPUSH BP");
				writeToAsm("\tMOV BP, SP");
                symbolTable.enterscope();
			}else{
				writeToAsm(currFunc + " PROC");
				writeToAsm("\tPUSH BP");
				writeToAsm("\tMOV BP, SP");
				symbolTable.enterscope();
			}
		}
		compound_statement
		{
			
			if (returned && returnLabel!="") {
			writeLabel(returnLabel);
			if (currFunc == "main") {
				if (stackOffset > 0)
					writeToAsm("\tADD SP, " + std::to_string(stackOffset));
				
			} else {
				int dest = currentFuncParams.size() * 2;
				if (stackOffset > 0)
					writeToAsm("\tADD SP, " + std::to_string(dest));
				
			}
				writeToAsm("\tMOV SP, BP");
			
			writeToAsm("\tPOP BP");
			if (currFunc != "main") {
				int dest = currentFuncParams.size() * 2;
				if (dest > 0) {
					writeToAsm("\tRET " + std::to_string(dest));
				} else {
					writeToAsm("\tRET");
				}
			} else {
				writeToAsm("\tMOV AX, 4CH");
				writeToAsm("\tINT 21H");
			}
		}else{
			writeToAsm("\tMOV SP, BP");
			
			writeToAsm("\tPOP BP");
			writeToAsm("\tRET");
		}

			writeToAsm(currFunc + " ENDP");
				symbolTable.exitscope();
				insideFunc=false;
				currentFuncParams.clear();	
		}
 		

 		;				


parameter_list  : parameter_list COMMA type_specifier ID
		{
			string paramType = $type_specifier.name_line;
			string paramName = $ID->getText();
			currentFuncParams.push_back(paramName);
			symbolTable.insert(paramName, "ID");
			SymbolInfo* paramSym = symbolTable.lookup(paramName);
			if(paramSym) {
				paramSym->setDataType(paramType);
			}

		}
		| parameter_list COMMA type_specifier
 		| type_specifier ID
		{
			string paramType = $type_specifier.name_line;
			string paramName = $ID->getText();
			currentFuncParams.push_back(paramName);
			symbolTable.insert(paramName, "ID");
			
		}
		| type_specifier
 		;

 		
compound_statement : LCURL statements RCURL
 		    | LCURL RCURL
 		    ;
 		    
var_declaration 
    : t=type_specifier dl=declaration_list sm=SEMICOLON 
    | t=type_specifier de=declaration_list_err sm=SEMICOLON 
    ;

declaration_list_err returns [std::string error_name]: {
        $error_name = "Error in declaration list";
    };

 		 
type_specifier returns [std::string name_line]	
        : INT {
            $name_line = "type: INT at line" + std::to_string($INT->getLine());
        }
 		| FLOAT {
            $name_line = "type: FLOAT at line" + std::to_string($FLOAT->getLine());
        }
 		| VOID {
            $name_line = "type: VOID at line" + std::to_string($VOID->getLine());
        }
 		;
 		
declaration_list : declaration_list COMMA ID
			{
				string var = $ID->getText();
				
				if(insideFunc){
					stackOffset+=2;
					localVarOffset[var]=stackOffset;
                    symbolTable.addLocalVariable(var, stackOffset, "INT");
					writeToAsm("\tSUB SP,2");
				}else{
                    symbolTable.addGlobalVariable(var, "INT");
                    writeToAsm("\t"+var+" DW 1 DUP (0000H)");
					globalVars.push_back(var);
				}
			}
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
		  {
			string var=$ID->getText();
			int arraylen=stoi($CONST_INT->getText());
			//symbolTable.insert(var,"ID");
			if(insideFunc){
				stackOffset+=2*arraylen;
				localVarOffset[var]=stackOffset;
				writeToAsm("\tSUB SP, "+to_string(2*arraylen));
				symbolTable.addLocalVariable(var, stackOffset, "INT");
			}else{
				writeToAsm("\t"+var+" DW "+to_string(arraylen)+" DUP (0000H)");
				symbolTable.addGlobalVariable(var, "INT");
				globalVars.push_back(var);
				
			}
		  }
 		  | ID
		  {
			string var = $ID->getText();
				
				if(insideFunc){
					stackOffset+=2;
					localVarOffset[var]=stackOffset;
                    symbolTable.addLocalVariable(var, stackOffset, "INT");
					writeToAsm("\tSUB SP,2");
				}else{
                    symbolTable.addGlobalVariable(var, "INT");
                    writeToAsm("\t"+var+" DW 1 DUP (0000H)");
					globalVars.push_back(var);
				}
		  }
 		  | ID LTHIRD CONST_INT RTHIRD
		  {
			string var=$ID->getText();
			int arraylen=stoi($CONST_INT->getText());
			//symbolTable.insert(var,"ID");
			if(insideFunc){
				stackOffset+=2*arraylen;
				localVarOffset[var]=stackOffset;
				writeToAsm("\tSUB SP, "+to_string(2*arraylen));
				symbolTable.addLocalVariable(var, stackOffset, "INT");
			}else{
				writeToAsm("\t"+var+" DW "+to_string(arraylen)+" DUP (0000H)");
				symbolTable.addGlobalVariable(var, "INT");
				globalVars.push_back(var);
				
			}
		  }
 		  ;
 		  
statements : statement
	   | statements statement
	   ;
	   
statement : var_declaration
	  | expression_statement
	  | compound_statement


	 
	  
| FOR LPAREN 
	expression_statement  // i =0
	{
		
		string loopcondition = newLabel();//i<n
		string loopinc = newLabel();//i++
		string loopbody = newLabel();//body
		string loopcontinue = newLabel();//continue
		string loopEnd = newLabel();//break
		writeLabel(loopcondition);
	
	}
	expression_statement  // condition
	{
		
		writeComment("POP AX", $FOR->getLine());
		writeToAsm("\tCMP AX, 0");
		writeToAsm("\tJNE " + loopbody);
		writeToAsm("\tJMP " + loopEnd);
		writeLabel(loopinc);
	}
	expression RPAREN    
	{
		writeToAsm("\tPOP AX");
		writeToAsm("\tJMP " + loopcondition);
		writeLabel(loopbody);

	}
	statement            // body
	{
		writeLabel(loopcontinue);
		writeToAsm("\tJMP " + loopinc);
		writeLabel(loopEnd);
	}
	  | IF LPAREN expression RPAREN 
	  {
		string truelabel=newLabel();
		string endlabel=newLabel();
		writeToAsm("\tCMP AX, 0");
		writeToAsm("\tJNE "+ truelabel);
		writeToAsm("\tJMP "+endlabel);
		writeLabel(truelabel);
		endlblstack.push(endlabel);

	  }
	  statement
	  {
		writeLabel(endlblstack.top());
		endlblstack.pop();
	  }


	  | IF LPAREN expression RPAREN
	  {
        writeComment("POP AX", $IF->getLine());
		string truelabel=newLabel();
		string falselabel=newLabel();
		string endlabel=newLabel();
		writeToAsm("\tCMP AX, 0");
		writeToAsm("\tJNE "+ truelabel);
		writeToAsm("\tJMP "+ falselabel);
		writeLabel(truelabel);
		falselblstack.push(falselabel);
		endlblstack.push(endlabel);

	  } statement ELSE
	  {
		writeToAsm("\tJMP " + endlblstack.top());
		writeLabel(falselblstack.top());
		falselblstack.pop();
		
	  } statement
	  {
		writeLabel(endlblstack.top());
		endlblstack.pop();
	  }



	  
	  | WHILE LPAREN 
	  {
		string startLabel = newLabel();
		string endLabel = newLabel();
		writeLabel(startLabel);
		startlblstack.push(startLabel);
		endlblstack.push(endLabel);
		
	  }
	  expression RPAREN 
	  {
		writeComment("POP AX", $WHILE->getLine());
		writeToAsm("\tCMP AX, 0");
		writeToAsm("\tJE " + endlblstack.top());
	  }
	  statement
	  {
		writeToAsm("\tJMP " + startlblstack.top());
		writeLabel(endlblstack.top());
		startlblstack.pop();
		endlblstack.pop();
		
	  }


	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  {
		string var=$ID->getText();

		writeLabel(newLabel());
		if(find(currentFuncParams.begin(), currentFuncParams.end(), var) != currentFuncParams.end()) {
			
			int paramindex = distance(currentFuncParams.begin(), find(currentFuncParams.begin(), currentFuncParams.end(), var));
			int offset = (currentFuncParams.size() - paramindex) * 2 + 2;
			writeComment("MOV AX, [BP+" + to_string(offset) + "]", $ID->getLine());
		} else if(localVarOffset.find(var) != localVarOffset.end()){
			
			writeComment("MOV AX, [BP-"+to_string(localVarOffset[var])+"]",$ID->getLine());
		}else{
			
			writeComment("MOV AX, "+var,$ID->getLine());
		}
		writeToAsm("\tCALL print_output");
		writeToAsm("\tCALL new_line");
	  }
	  | RETURN expression SEMICOLON
	  {
		//writeLabel(newLabel());//35
        writeComment("POP AX", $RETURN->getLine());
		if (!returned) {
        returnLabel = newLabel();
        returned = true;
		//returnLabelStack.push(returnLabel);
    }
	writeToAsm("\tJMP " + returnLabel);


	  }
	  ;
	  
expression_statement 	: SEMICOLON			

			| {
				writeLabel(newLabel());
			}expression SEMICOLON 

			;
	  
variable returns [string val,bool global,bool isarray]:
	 ID
	 {
		string var=$ID->getText();
        SymbolInfo* sym = symbolTable.lookup(var);
        
		if(find(currentFuncParams.begin(), currentFuncParams.end(), var) != currentFuncParams.end()) {
			
			int paramindex = distance(currentFuncParams.begin(), find(currentFuncParams.begin(), currentFuncParams.end(), var));
			int offset = (currentFuncParams.size() - paramindex) * 2 + 2;
			writeComment("MOV AX, [BP+" + to_string(offset) + "]", $ID->getLine());
		} else if(localVarOffset.find(var) != localVarOffset.end()){
			
			writeComment("MOV AX, [BP-"+to_string(localVarOffset[var])+"]",$ID->getLine());
		}else{
			
			writeComment("MOV AX, "+var,$ID->getLine());

		}
        $val = var;
		$global = find(globalVars.begin(), globalVars.end(), var) != globalVars.end();
		$isarray = false;

	 } 		
	 | ID LTHIRD expression RTHIRD 
	 {
		string var=$ID->getText();
		$val = var;
		$global = find(globalVars.begin(), globalVars.end(), var) != globalVars.end();
		$isarray = true;
		//writeComment("POP BX", $ID->getLine());
		writeToAsm("\tPUSH AX");
		writeToAsm("\tPOP BX");
		writeToAsm("\tMOV AX, 2");
		writeToAsm("\tMUL BX");
		writeToAsm("\tMOV BX, AX");
		//writeToAsm("\tPOP AX");
		if($global){
			writeToAsm("\tMOV AX, "+var+"[BX]");
            //writeToAsm("\tPUSH AX");
			//writeToAsm("\tPOP AX");
			

		}else {
			int offset = localVarOffset[var];
			
			
			writeToAsm("\tMOV AX, " + to_string(offset));
			writeToAsm("\tSUB AX,BX");
			writeToAsm("\tMOV BX, AX");
			writeToAsm("\tMOV SI, BX");
			writeToAsm("\tNEG SI");
			
		}
		
	 }
	 ;

 expression returns [bool is_array,bool is_global]: logic_expression{
	$is_array = $logic_expression.is_array;
	$is_global = $logic_expression.is_global;
 }
	   | variable ASSIGNOP logic_expression
	   {
		$is_array = false;
		$is_global = false;
		string varname=$variable.val;
		bool global=$variable.global;
		bool arr=$variable.isarray;
        SymbolInfo* sym = symbolTable.lookup(varname);
        if(arr || $logic_expression.is_array) {
			if(global){
				if(arr){
					writeToAsm("\tMOV "+$variable.val+"[BX], AX");
				}else{
					writeToAsm("\tMOV "+$variable.val+", AX");
				}
			}else{
				if($logic_expression.is_array && !$logic_expression.is_global) 
				{
					writeToAsm("\tMOV AX, [BP+SI]");
						
				}
				if(arr){
					writeToAsm("\tMOV [BP+SI], AX");
				}else if($logic_expression.is_array){
					//writeToAsm("\tPOP AX");
					int offset = localVarOffset[varname];
					writeToAsm("\tMOV [BP-" + to_string(offset) + " ], AX");
				}else{
					writeToAsm("\tPOP AX");
					int offset = localVarOffset[varname];
					writeToAsm("\tMOV [BP-" + to_string(offset) + " ], AX");
				}
				
			}
				
		}
			else{
			writeComment("POP AX", $ASSIGNOP->getLine());
			if(find(currentFuncParams.begin(), currentFuncParams.end(), varname) != currentFuncParams.end()) {
				
				int paramindex = distance(currentFuncParams.begin(), find(currentFuncParams.begin(), currentFuncParams.end(), varname));
				int offset = (currentFuncParams.size() - paramindex) * 2 + 2;
				writeToAsm("\tMOV [BP+" + to_string(offset) + "], AX");
			} else if(localVarOffset.find(varname) != localVarOffset.end()){
				
				writeToAsm("\tMOV [BP-" + to_string(localVarOffset[varname]) + "], AX");
			}else{
				
				writeToAsm("\tMOV " + varname + ", AX");
			}
        
		writeToAsm("\tPUSH AX");
	   }	
	}
	   ;
			
logic_expression returns [bool is_array,bool is_global]: rel_expression 
{
	$is_array = $rel_expression.is_array;
	$is_global = $rel_expression.is_global;
}
		 | lhs=rel_expression LOGICOP rhs=rel_expression 
		 {
			$is_array=false;
			$is_global=false;
			string op=$LOGICOP->getText();
            string truelabel=newLabel();//20
			string falseLabel=newLabel();//21
			string endLabel=newLabel();	//22
            string nextlabel=newLabel();//23

			if(op == "||"){
				writeComment("POP AX", $LOGICOP->getLine());
                
				writeToAsm("\tCMP AX,0");
				writeToAsm("\tJNE "+truelabel);//21
                writeToAsm("\tJMP "+falseLabel);//20

                writeLabel(falseLabel);//20
                writeComment("POP AX", $LOGICOP->getLine());
                writeToAsm("\tCMP AX,0");
                writeToAsm("\tJNE "+truelabel);//21
				writeToAsm("\tJMP "+endLabel);//23

				writeLabel(truelabel);	//21
				writeToAsm("\tMOV AX, 1");
				writeToAsm("\tJMP "+nextlabel);//22


				writeLabel(endLabel);	//23
				writeToAsm("\tMOV AX, 0");
				writeLabel(nextlabel);	//22
                writeToAsm("\tPUSH AX");
			}else if (op=="&&")
			{
                writeComment("POP AX", $LOGICOP->getLine());
				
                
				writeToAsm("\tCMP AX, 0");
				writeToAsm("\tJNE " + truelabel);//26
				writeToAsm("\tJMP " + falseLabel);//29

				writeLabel(truelabel);//26
                writeComment("POP AX", $LOGICOP->getLine());
				writeToAsm("\tCMP AX, 0");
				writeToAsm("\tJNE " + endLabel);//27
				writeToAsm("\tJMP " + falseLabel);//29

				writeLabel(endLabel);//27
				writeToAsm("\tMOV AX, 1");
				writeToAsm("\tJMP " + nextlabel);//28

				writeLabel(falseLabel);//29
				writeToAsm("\tMOV AX, 0");
				writeLabel(nextlabel);//28
                writeToAsm("\tPUSH AX");
			}

		 }	
		 ;
			
rel_expression	returns [bool is_array,bool is_global] : se1=simple_expression
{
	$is_array = $se1.is_array;
	$is_global = $se1.is_global;
}
		| se2=simple_expression RELOP se3=simple_expression	
		{
			$is_array = false;
			$is_global = false;
			string op=$RELOP->getText();
			string trueLabel = newLabel();
            string falseLabel = newLabel();
            string endLabel=newLabel();
			
			writeComment("POP DX", $RELOP->getLine());
            writeComment("POP AX", $RELOP->getLine());
			writeToAsm("\tCMP AX, DX");

			if(op == "<="){
				writeToAsm("\tJLE " + trueLabel);
			}else if(op == ">="){
				writeToAsm("\tJGE "+ trueLabel);
			}else if(op == "<"){
				writeToAsm("\tJL "+trueLabel);
			}else if(op == ">"){
				writeToAsm("\tJG "+trueLabel);
			}else if(op == "=="){
				writeToAsm("\tJE "+trueLabel);
			}else if(op == "!="){
				writeToAsm("\tJNE "+trueLabel);
			}

			writeToAsm("\tJMP "+falseLabel);

			writeLabel(trueLabel);
			writeToAsm("\tMOV AX, 1");
			writeToAsm("\tJMP "+endLabel);

			writeLabel(falseLabel);
			writeToAsm("\tMOV AX, 0");
			writeLabel(endLabel);
			writeToAsm("\tPUSH AX");
		}
		;
				
simple_expression returns [bool is_array,bool is_global]: t=term {
	$is_array = $t.is_array;
	$is_global = $t.is_global;
}
		  | se=simple_expression ADDOP t2=term
		  {
			$is_array = false;
			$is_global = false;
			string op = $ADDOP->getText();
			
			if(op == "+"){
                writeComment("POP DX", $ADDOP->getLine());
                writeComment("POP AX", $ADDOP->getLine());
				writeToAsm("\tADD AX, DX");
                writeToAsm("\tPUSH AX");
			}else if(op == "-"){
                writeComment("POP DX", $ADDOP->getLine());
                writeComment("POP AX", $ADDOP->getLine());
				writeToAsm("\tSUB AX,DX");
                writeToAsm("\tPUSH AX");
			}
			
		  } 
		  ;

term returns [bool is_array,bool is_global]: u=unary_expression{
	$is_array = $u.is_array;
	$is_global = $u.is_global;
}
     |  t2=term MULOP u2=unary_expression
	 {
	$is_array = false;
	$is_global = false;
		string op = $MULOP->getText();
		if(op == "*"){
            writeComment("POP CX", $MULOP->getLine());
            writeComment("POP AX", $MULOP->getLine());
			writeToAsm("\tCWD");
			writeToAsm("\tMUL CX");
			writeToAsm("\tPUSH AX");
		}else if(op=="/"){
            writeComment("POP CX", $MULOP->getLine());
            writeComment("POP AX", $MULOP->getLine());
			writeToAsm("\tCWD");
			writeToAsm("\tDIV CX");
			writeToAsm("\tPUSH AX");
		}else if(op=="%"){
            writeComment("POP CX", $MULOP->getLine());
            writeComment("POP AX", $MULOP->getLine());
			writeToAsm("\tCWD");
			writeToAsm("\tDIV CX");
			writeToAsm("\tPUSH DX");
			
		}
	 }
     ;

unary_expression returns [bool is_array,bool is_global] : ADDOP unary_expression
		 {
			$is_array = $unary_expression.is_array;
			$is_global = $unary_expression.is_global;
			string op =  $ADDOP->getText();
			if(op == "-"){
                writeComment("POP AX", $ADDOP->getLine());
                writeToAsm("\tNEG AX");
                writeToAsm("\tPUSH AX");
			}
			
		 }
		 | NOT unary_expression {
			$is_array = $unary_expression.is_array;
			$is_global = $unary_expression.is_global;
		 }
		 | factor {
			$is_array = $factor.is_array;
			$is_global = $factor.is_global;
		 }
		 ;

factor returns [bool is_array,bool is_global] : variable
	{
		$is_array = $variable.isarray;
		$is_global = $variable.global;
		writeToAsm("\tPUSH AX");
	}
	| ID LPAREN argument_list RPAREN
	{
		$is_array = false;
		$is_global = false;
		string funcName = $ID->getText();
		writeToAsm("\tCALL " + funcName);
		
		writeToAsm("\tPUSH AX"); 
	}
	| LPAREN expression RPAREN
	{
		$is_array = $expression.is_array;
		$is_global = $expression.is_global;
	}
	| CONST_INT 
	{
		$is_array = false;
		$is_global = false;
		string val = $CONST_INT->getText();
		writeComment("MOV AX, " + val, $CONST_INT->getLine());
		writeToAsm("\tPUSH AX");
	}
	| CONST_FLOAT
    {
		$is_array = false;
		$is_global = false;
        string val = $CONST_FLOAT->getText();
        writeComment("MOV AX, " + val, $CONST_FLOAT->getLine());
        writeToAsm("\tPUSH AX");
    }
	| variable INCOP 
	{
		$is_array = $variable.isarray;
		$is_global = $variable.global;
		string varname=$variable.val;
		SymbolInfo* sym = symbolTable.lookup(varname);
        if(sym){
            writeToAsm("\tPUSH AX");  
		    writeToAsm("\tINC AX");   
            
			if(find(currentFuncParams.begin(), currentFuncParams.end(), varname) != currentFuncParams.end()) {
				
				int paramindex = distance(currentFuncParams.begin(), find(currentFuncParams.begin(), currentFuncParams.end(), varname));
				int offset = (currentFuncParams.size() - paramindex) * 2 + 2;
				writeToAsm("\tMOV [BP+" + to_string(offset) + "], AX");
			} else if(localVarOffset.find(varname) != localVarOffset.end()) {
				
                writeToAsm("\tMOV [BP-" + to_string(localVarOffset[varname]) + "], AX");
            } else {
				
                writeToAsm("\tMOV " + varname + ", AX");
            }
            writeToAsm("\tPOP AX");   
		    writeToAsm("\tPUSH AX");  
	    }
    }
	| variable DECOP
	{
	$is_array = $variable.isarray;
	$is_global = $variable.global;
		string varname=$variable.val;
        SymbolInfo* sym = symbolTable.lookup(varname);
        if(sym){
            writeToAsm("\tPUSH AX");  
            writeToAsm("\tDEC AX");  
            
			if(find(currentFuncParams.begin(), currentFuncParams.end(), varname) != currentFuncParams.end()) {
				
				int paramindex = distance(currentFuncParams.begin(), find(currentFuncParams.begin(), currentFuncParams.end(), varname));
				int offset = (currentFuncParams.size() - paramindex) * 2 + 2;
				writeToAsm("\tMOV [BP+" + to_string(offset) + "], AX");
			} else if(localVarOffset.find(varname) != localVarOffset.end()) {
				
                writeToAsm("\tMOV [BP-" + to_string(localVarOffset[varname]) + "], AX");
            } else {
				
                writeToAsm("\tMOV " + varname + ", AX");
            }
            writeToAsm("\tPOP AX");  
            writeToAsm("\tPUSH AX");  
        }
	}
	;
	
argument_list : arguments
			  |
			  ;
	
arguments : arguments COMMA logic_expression
		{
			writeComment("POP AX", $COMMA->getLine());
			writeToAsm("\tPUSH AX");
		}
	      | logic_expression
		  {
			writeToAsm("\tPOP AX");
			writeToAsm("\tPUSH AX");
		  }
	      ;