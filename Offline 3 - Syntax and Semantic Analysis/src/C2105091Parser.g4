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

    extern std::ofstream parserLogFile;
    extern std::ofstream errorFile;

    extern int syntaxErrorCount;
    extern SymbolTable symbolTable;
}

@parser::members {
    std::string currentFunctionName="";
    bool typemismatcherror=false;
    bool voidFuncerror=false;
    bool nonint=false;
    bool unexpectedassignop=false;
    bool skipAssignText = false;
    bool skipnextgram=false;
    bool skiphash=false;
    std::vector<std::string> pendingParamTypes;
    std::vector<std::string> pendingParamNames;
    
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

start :{pendingParamTypes.clear();pendingParamNames.clear();} program
    {
        writeIntoparserLogFile("Line " + std::to_string($program.stop->getLine()) + ": start : program\n");
        symbolTable.printAllScopeTable(parserLogFile);
        writeIntoparserLogFile("");
        writeIntoparserLogFile("Total number of lines: " + std::to_string($program.stop->getLine()));
        writeIntoparserLogFile("Total number of errors: " + std::to_string(syntaxErrorCount));
    }
    ;

program returns [std::string text] : 
    p=program u=unit {
        $text = $p.text + "\n" + $u.text;
        writeIntoparserLogFile("Line " + std::to_string($u.stop->getLine()) + ": program : program unit\n");
        writeIntoparserLogFile($p.text + "\n" + $u.text + "\n");
    }
    | u=unit {
        $text = $u.text;
        writeIntoparserLogFile("Line " + std::to_string($u.stop->getLine()) + ": program : unit\n");
        writeIntoparserLogFile($u.text + "\n");
    }
    ;
    
unit returns [std::string text] : 
    vd=var_declaration {
        $text = $vd.text;
        writeIntoparserLogFile("Line " + std::to_string($vd.start->getLine()) + ": unit : var_declaration\n");
        writeIntoparserLogFile($vd.text + "\n");
    }
    | fd=func_declaration {
        $text = $fd.text;
        writeIntoparserLogFile("Line " + std::to_string($fd.start->getLine()) + ": unit : func_declaration\n");
        writeIntoparserLogFile($fd.text + "\n");
    }
    | fdn=func_definition {
        $text = $fdn.text;
        writeIntoparserLogFile("Line " + std::to_string($fdn.stop->getLine()) + ": unit : func_definition\n");
        writeIntoparserLogFile($fdn.text + "\n");
    }
    ;
     
func_declaration returns [std::string text] :
    t=type_specifier id=ID LPAREN pl=parameter_list RPAREN SEMICOLON {
        $text = $t.text + " " + $id->getText() + "(" + $pl.paramText + ");";

        vector<string> paramTypes = $pl.types;
        FunctionInfo* f = new FunctionInfo();
        f->setReturnType($t.typeName);
        f->setParamTypes(paramTypes);
        f->setIsDeclared(true);

        if (!symbolTable.insert($id->getText(), "ID")) {
            // Already exists
            SymbolInfo* sym = symbolTable.lookup($id->getText());
            if (sym->getFunctionInfo() && sym->getFunctionInfo()->getIsDefined()) {
                writeIntoparserLogFile("Error at line " + std::to_string($id->getLine()) +
                    ": Function '" + $id->getText() + "' already defined");
                writeIntoErrorFile("Error at line " + std::to_string($id->getLine()) +
                    ": Function '" + $id->getText() + "' already defined");
                syntaxErrorCount++;
            } else {
                sym->setFunctionInfo(f);
                writeIntoparserLogFile("Function declaration updated: " + $id->getText());
            }
        } else {
            // Newly inserted
            SymbolInfo* sym = symbolTable.lookup($id->getText());
            sym->setFunctionInfo(f);
        }

        writeIntoparserLogFile("Line " + std::to_string($id->getLine()) + 
            ": func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n");
        writeIntoparserLogFile($text + "\n");
    }

    | t=type_specifier id=ID LPAREN RPAREN SEMICOLON {
        $text = $t.text + " " + $id->getText() + "();";

        FunctionInfo* f = new FunctionInfo();
        f->setReturnType($t.typeName);
        f->setParamTypes({});
        f->setIsDeclared(true);

        if (!symbolTable.insert($id->getText(), "ID")) {
            SymbolInfo* sym = symbolTable.lookup($id->getText());
            if (sym->getFunctionInfo() && sym->getFunctionInfo()->getIsDefined()) {
                writeIntoparserLogFile("Error at line " + std::to_string($id->getLine()) +
                    ": Function '" + $id->getText() + "' already defined");
                writeIntoErrorFile("Error at line " + std::to_string($id->getLine()) +
                    ": Function '" + $id->getText() + "' already defined");
                syntaxErrorCount++;
            } else {
                sym->setFunctionInfo(f);
                writeIntoparserLogFile("Function declaration updated: " + $id->getText());
            }
        } else {
            SymbolInfo* sym = symbolTable.lookup($id->getText());
            sym->setFunctionInfo(f);
        }

        writeIntoparserLogFile("Line " + std::to_string($id->getLine()) + 
            ": func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n");
        writeIntoparserLogFile($text + "\n");
    }
    ;
func_definition returns [std::string text] : 
    t=type_specifier id=ID LPAREN pl=parameter_list RPAREN {
        vector<string> paramTypes = $pl.types;

        FunctionInfo* f = new FunctionInfo();
        f->setReturnType($t.typeName);
        f->setParamTypes(paramTypes);
        f->setIsDefined(true);
        f->setIsDeclared(true);

        if (!symbolTable.insert($id->getText(), "ID")) {
            // Already exists
            SymbolInfo* sym = symbolTable.lookup($id->getText());

            if (sym->getFunctionInfo() && sym->getFunctionInfo()->getIsDefined()) {
                writeIntoparserLogFile("Error at line " + std::to_string($id->getLine()) + ": Multiple definition of function '" + $id->getText() + "'");
                writeIntoErrorFile("Error at line " + std::to_string($id->getLine()) + ": Multiple definition of function '" + $id->getText() + "'");
                syntaxErrorCount++;
            } else if(sym && sym->getFunctionInfo()) {
                //sym->setFunctionInfo(f);
                if(sym && sym->getFunctionInfo()){
                
                if(sym->getFunctionInfo()->getReturnType()!=$t.typeName) {
                    writeIntoparserLogFile("Error at line " + std::to_string($id->getLine()) + ": Return type mismatch with function declaration in function " + $id->getText());
                    writeIntoErrorFile("Error at line " + std::to_string($id->getLine()) + ": Return type mismatch with function declaration in function " + $id->getText());
					syntaxErrorCount++;
                }
                if(sym->getFunctionInfo()->getParamTypes().size() != paramTypes.size()){
                    writeIntoparserLogFile("Error at line " + std::to_string($id->getLine()) + ": Total number of arguments mismatch with declaration in function " + $id->getText());
                    writeIntoErrorFile("Error at line " + std::to_string($id->getLine()) + ": Total number of arguments mismatch with declaration in function " + $id->getText());
					syntaxErrorCount++;
                }else{
                vector<string>ftypes=sym->getFunctionInfo()->getParamTypes();
                for(int i=0;i<paramTypes.size();i++){
                    if(ftypes[i]!=paramTypes[i]){
                        writeIntoparserLogFile("Error at line " + std::to_string($id->getLine()) + ": All parameters must be of the same type in function '" + $id->getText() + "'");
                        writeIntoErrorFile("Error at line " + std::to_string($id->getLine()) + ": All parameters must be of the same type in function '" + $id->getText() + "'");
                        syntaxErrorCount++;
                        break;
                    }
                }
            }
            sym->getFunctionInfo()->setIsDefined(true);
        }
    }else {
        // Not a function, error
        writeIntoparserLogFile("Error at line " + std::to_string($id->getLine()) +
            ": Multiple declaration of " + $id->getText());
        writeIntoErrorFile("Error at line " + std::to_string($id->getLine()) +
            ": Multiple declaration of " + $id->getText());
        syntaxErrorCount++;
        }
        } else {
            // Newly inserted
            SymbolInfo* sym = symbolTable.lookup($id->getText());
            sym->setFunctionInfo(f);
            
        }
        currentFunctionName = $id->getText();
        pendingParamTypes = $pl.types;
        pendingParamNames = $pl.names;
        
    } compound_statement {
        $text = $t.text + " " + $id->getText() + "(" + $pl.paramText + ")" + $compound_statement.text;


        currentFunctionName = "";
        

        writeIntoparserLogFile("Line " + std::to_string($compound_statement.stop->getLine()) + ": func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n");
        writeIntoparserLogFile($text + "\n");
    }

    | t=type_specifier id=ID LPAREN RPAREN {
        FunctionInfo* f = new FunctionInfo();
        f->setReturnType($t.typeName);
        f->setParamTypes({});
        f->setIsDefined(true);
        f->setIsDeclared(true);

        if (!symbolTable.insert($id->getText(), "ID")) {
            SymbolInfo* sym = symbolTable.lookup($id->getText());
            if (sym && sym->getFunctionInfo() && sym->getFunctionInfo()->getIsDefined()) {
                writeIntoparserLogFile("Error at line " + std::to_string($id->getLine()) + ": Multiple definition of function '" + $id->getText() + "'");
                writeIntoErrorFile("Error at line " + std::to_string($id->getLine()) + ": Multiple definition of function '" + $id->getText() + "'");
                syntaxErrorCount++;
            } else if (sym && sym->getFunctionInfo()){
                
				if(sym->getFunctionInfo()->getReturnType() != $t.typeName) {
                    writeIntoparserLogFile("Error at line " + std::to_string($id->getLine()) + ": Return type mismatch with function declaration in function " + $id->getText());
					writeIntoErrorFile("Error at line " + std::to_string($id->getLine()) + ": Return type mismatch with function declaration in function " + $id->getText());
					syntaxErrorCount++;
				}
				//  parameter count mismatch
				if(sym->getFunctionInfo()->getParamTypes().size() != 0) {
                    writeIntoparserLogFile("Error at line " + std::to_string($id->getLine()) + ": Total number of arguments mismatch with declaration in function " + $id->getText());
					writeIntoErrorFile("Error at line " + std::to_string($id->getLine()) + ": Total number of arguments mismatch with declaration in function " + $id->getText());
					syntaxErrorCount++;
				}
                sym->getFunctionInfo()->setIsDefined(true);
            
            }
        } else {
            SymbolInfo* sym = symbolTable.lookup($id->getText());
            sym->setFunctionInfo(f);
            
        }
        currentFunctionName = $id->getText();
        
        pendingParamTypes.clear();
        pendingParamNames.clear();
    } compound_statement {
        $text = $t.text + " " + $id->getText() + "()" + $compound_statement.text;

        
        currentFunctionName = "";
       
        writeIntoparserLogFile("Line " + std::to_string($compound_statement.stop->getLine()) + ": func_definition : type_specifier ID LPAREN RPAREN compound_statement\n");
        writeIntoparserLogFile($text + "\n");
    }
    ;

        
parameter_list returns[std::vector<std::string>types, std::vector<std::string>names, std::string paramText] :
    pl=parameter_list COMMA t=type_specifier id=ID {
        // Check for multiple declaration of parameter
			for(const auto& name : $pl.names) {
				if(name == $id->getText()) {
                    writeIntoparserLogFile("Error at line " + std::to_string($id->getLine()) + ": Multiple declaration of " + $id->getText() + " in parameter");
					writeIntoErrorFile("Error at line " + std::to_string($id->getLine()) + ": Multiple declaration of " + $id->getText() + " in parameter");
					syntaxErrorCount++;
					break;
				}
			}
        $types = $pl.types;
        $types.push_back($t.typeName);
        $names = $pl.names;
        $names.push_back($id->getText());
        $paramText = $pl.paramText + "," + $t.text + " " + $id->getText();
        
        writeIntoparserLogFile("Line " + std::to_string($id->getLine()) + ": parameter_list : parameter_list COMMA type_specifier ID\n");
        writeIntoparserLogFile($paramText + "\n");
    }
    | pl=parameter_list COMMA t=type_specifier {
        $types = $pl.types;
        $types.push_back($t.typeName);
        $names = $pl.names;
        $names.push_back("");
        $paramText = $pl.paramText + "," + $t.text;
        writeIntoparserLogFile("Line " + std::to_string($t.start->getLine()) + ": parameter_list : parameter_list COMMA type_specifier\n");
        writeIntoparserLogFile($paramText + "\n");
    }
    |pl=parameter_list parameter_error{
        $types = $pl.types;
        $types.push_back("ERROR");
        $names = $pl.names;
        $names.push_back("ERROR_PARAM");
        $paramText = $pl.paramText;
        writeIntoparserLogFile("Line "+std::to_string($parameter_error.start->getLine())+ "parameter_list : type_specifier\n" + $paramText+"\n");
        writeIntoErrorFile("Error at line " + std::to_string($parameter_error.start->getLine()) + 
            ": syntax error, unexpected ADDOP, expecting RPAREN or COMMA");
        writeIntoparserLogFile("Error at line " + std::to_string($parameter_error.start->getLine()) + 
            ": syntax error, unexpected ADDOP, expecting RPAREN or COMMA");
        syntaxErrorCount++;
    }
    | pe=parameter_error{
        
        $paramText = $pe.text;
        writeIntoparserLogFile("Line "+std::to_string($parameter_error.start->getLine())+ ": parameter_list : type_specifier\n" + $paramText+"\n");
        writeIntoErrorFile("Error at line " + std::to_string($parameter_error.start->getLine()) + 
            ": syntax error, unexpected ADDOP, expecting RPAREN or COMMA");
        writeIntoparserLogFile("Error at line " + std::to_string($parameter_error.start->getLine()) + 
            ": syntax error, unexpected ADDOP, expecting RPAREN or COMMA");
        syntaxErrorCount++;
    }
    | t=type_specifier id=ID {
        $types = { $t.typeName };
        $names = { $id->getText() };
        $paramText = $t.text + " " + $id->getText();
        
        writeIntoparserLogFile("Line " + std::to_string($id->getLine()) + ": parameter_list : type_specifier ID\n");
        writeIntoparserLogFile($paramText + "\n"); 
    }
    | t=type_specifier {
        $types = { $t.typeName };
        $names = { "" };
        $paramText = $t.text;
        writeIntoparserLogFile("Line " + std::to_string($t.start->getLine()) + ": parameter_list : type_specifier\n");
        writeIntoparserLogFile($paramText + "\n");
    }
    
    ;
parameter_error returns [std::string text]:
    t=type_specifier ADDOP{
        $text=$t.text;
    }
    |t=type_specifier 
    ;
         
compound_statement returns [std::string text] : 
    LCURL {
        symbolTable.enterscope();
        for (size_t i = 0; i < pendingParamNames.size(); i++) {
            if (!pendingParamNames[i].empty()) {
                symbolTable.insert(pendingParamNames[i], "ID");
                
                SymbolInfo* paramSym = symbolTable.lookup(pendingParamNames[i]);
                if (paramSym) {
                    paramSym->setDataType(pendingParamTypes[i]);  // actual data type
                }
            
            }
        }
        pendingParamTypes.clear();
        pendingParamNames.clear();
    } statements RCURL {
        $text = "{\n" + $statements.text + "\n}";
        
        
        writeIntoparserLogFile("Line " + std::to_string($RCURL->getLine()) + ": compound_statement : LCURL statements RCURL\n");
        writeIntoparserLogFile($text);
        symbolTable.printAllScopeTable(parserLogFile);
        symbolTable.exitscope();
    }
    | LCURL {
        symbolTable.enterscope();
    } RCURL {
        for (size_t i = 0; i < pendingParamNames.size(); i++) {
            if (!pendingParamNames[i].empty()) {
                symbolTable.insert(pendingParamNames[i], "ID");
            }
        }
        pendingParamTypes.clear();
        pendingParamNames.clear();
        $text = "{}";
        
        
        writeIntoparserLogFile("Line " + std::to_string($RCURL->getLine()) + ": compound_statement : LCURL RCURL\n");
        writeIntoparserLogFile($text + "\n");
        symbolTable.printAllScopeTable(parserLogFile);
        symbolTable.exitscope();
    }
    ;
            
var_declaration returns [std::string text] : 
    t=type_specifier dl=declaration_list sm=SEMICOLON {
        if($t.typeName == "VOID"){
            writeIntoparserLogFile("Error at line " + std::to_string($sm->getLine()) + ": Variable type cannot be void");
            writeIntoErrorFile("Error at line " + std::to_string($sm->getLine()) + ": Variable type cannot be void");
			syntaxErrorCount++;
        }
        $text = $t.text + " ";
        for (int i = 0; i < $dl.displayNames.size(); i++) {
            $text += $dl.displayNames[i];
            if (i != $dl.displayNames.size() - 1) $text += ",";
        }
        $text += ";";

        // Insert each variable
        for (int i = 0; i < $dl.name.size(); i++) {
            string varName = $dl.name[i];
            bool isArray = $dl.isArrays[i];

            if (!symbolTable.insert(varName, "ID")) {
                writeIntoparserLogFile("Error at line " + std::to_string($sm->getLine()) + ": Multiple declaration of " + varName);
                writeIntoErrorFile("Error at line " + std::to_string($sm->getLine()) + ": Multiple declaration of " + varName);
                syntaxErrorCount++;
            } else {
                SymbolInfo* symbol = symbolTable.lookup(varName);
                if (symbol) {
                    symbol->setIsArray(isArray);
                    symbol->setDataType($t.typeName);
                    }
            }
        }

        writeIntoparserLogFile("Line " + std::to_string($sm->getLine()) + ": var_declaration : type_specifier declaration_list SEMICOLON\n");
        writeIntoparserLogFile($text + "\n");
    }
    | t=type_specifier de=declaration_list_err sm=SEMICOLON {
        $text = $t.text + " " + $de.error_name + ";";
        writeIntoparserLogFile(
            std::string("Error at line ") + std::to_string($sm->getLine()) +
            " with error name: " + $de.error_name +
            " - Syntax error at declaration list of variable declaration"
        );
        writeIntoErrorFile(
            std::string("Error at line ") + std::to_string($sm->getLine()) +
            " with error name: " + $de.error_name +
            " - Syntax error at declaration list of variable declaration"
        );
        syntaxErrorCount++;
    }
;

declaration_list_err returns [std::string error_name]: {
        $error_name = "Error in declaration list";
    };
         
type_specifier returns [std::string typeName, std::string text] :
    INT {
        $typeName = "INT";
        $text = $INT->getText();
        writeIntoparserLogFile("Line " + std::to_string($INT->getLine()) + ": type_specifier : INT\n");
        writeIntoparserLogFile($text + "\n");
    }
    | FLOAT {
        $typeName = "FLOAT";
        $text = $FLOAT->getText();
        writeIntoparserLogFile("Line " + std::to_string($FLOAT->getLine()) + ": type_specifier : FLOAT\n");
        writeIntoparserLogFile($text + "\n");
    }
    | VOID {
        $typeName = "VOID";
        $text = $VOID->getText();
        writeIntoparserLogFile("Line " + std::to_string($VOID->getLine()) + ": type_specifier : VOID\n");
        writeIntoparserLogFile($text + "\n");
    }
    ;
declaration_list returns [std::vector<std::string> name, std::vector<bool> isArrays,std::vector<std::string>displayNames] :
    dl=declaration_list COMMA id=ID {
        $name = $dl.name;
        $isArrays = $dl.isArrays;
        $displayNames=$dl.displayNames;
        $name.push_back($id->getText());
        $displayNames.push_back($id->getText());
        $isArrays.push_back(false);
        
        std::string combined;
        for (const auto& n : $displayNames) {
            if (!combined.empty()) combined += ",";
            combined += n;
        }
        writeIntoparserLogFile("Line " + std::to_string($id->getLine()) + ": declaration_list : declaration_list COMMA ID\n");
        writeIntoparserLogFile(combined + "\n");
    }
    | dl=declaration_list COMMA id=ID LTHIRD CONST_INT RTHIRD {
        $name = $dl.name;
        $isArrays = $dl.isArrays;
        $displayNames = $dl.displayNames;
        $displayNames.push_back($id->getText() + "[" + $CONST_INT->getText() + "]");

        $name.push_back($id->getText());
        $isArrays.push_back(true);
        
        std::string combined;
        for (const auto& n : $displayNames) {
            if (!combined.empty()) combined += ",";
            combined += n;
        }
        writeIntoparserLogFile("Line " + std::to_string($id->getLine()) + ": declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n");
        writeIntoparserLogFile(combined + "\n");
    }
    | dl=declaration_list COMMA declaration_error {
        $name = $dl.name;
        $isArrays = $dl.isArrays;
        $displayNames = $dl.displayNames;
        std::string combined;
        for (const auto& n : $displayNames) {
            if (!combined.empty()) combined += ",";
            combined += n;
        }
        writeIntoparserLogFile("Line "+std::to_string($declaration_error.start->getLine()) + ": declaration_list : ID");
        writeIntoparserLogFile(combined+"\n");
        writeIntoErrorFile("Error at line " + std::to_string($declaration_error.start->getLine()) + 
            ": syntax error, unexpected ADDOP, expecting COMMA or SEMICOLON");
        writeIntoparserLogFile("Error at line " + std::to_string($declaration_error.start->getLine()) + 
            ": syntax error, unexpected ADDOP, expecting COMMA or SEMICOLON");
        syntaxErrorCount++;
    }
    | de=declaration_error {
        $name.push_back($de.text);
        $displayNames.push_back($de.text);
        $isArrays.push_back(false);
        writeIntoparserLogFile("Line "+std::to_string($declaration_error.start->getLine()) + ": declaration_list : ID");
        writeIntoparserLogFile($de.text+"\n");
        writeIntoErrorFile("Error at line " + std::to_string($declaration_error.start->getLine()) + 
            ": syntax error, unexpected ADDOP, expecting COMMA or SEMICOLON");
        writeIntoparserLogFile("Error at line " + std::to_string($declaration_error.start->getLine()) + 
            ": syntax error, unexpected ADDOP, expecting COMMA or SEMICOLON");
        syntaxErrorCount++;
    }
    | id=ID {
        $name.push_back($id->getText());
        $displayNames.push_back($id->getText());
        $isArrays.push_back(false);
        writeIntoparserLogFile("Line " + std::to_string($id->getLine()) + ": declaration_list : ID\n");
        writeIntoparserLogFile($id->getText() + "\n");
    }
    | id=ID LTHIRD ci=CONST_INT RTHIRD {
        $name.push_back($id->getText());
        $displayNames.push_back($id->getText() + "[" + $ci->getText() + "]");
        $isArrays.push_back(true);
        writeIntoparserLogFile("Line " + std::to_string($id->getLine()) + ": declaration_list : ID LTHIRD CONST_INT RTHIRD\n");
        writeIntoparserLogFile($id->getText() + "[" + $ci->getText() + "]\n");
    }
    ;

declaration_error returns [std::string text]:
    ID ADDOP {
        $text = $ID->getText();
        writeIntoErrorFile("Error at line " + std::to_string($ID->getLine()) + 
            ": syntax error, unexpected ADDOP, expecting COMMA or SEMICOLON");
        writeIntoparserLogFile("Error at line " + std::to_string($ID->getLine()) + 
            ": syntax error, unexpected ADDOP, expecting COMMA or SEMICOLON");
        syntaxErrorCount++;
    }
    | id1=ID ADDOP ID {
        $text = $id1->getText();
    }
    ;         
statements returns [std::string text] : 
    { skipnextgram = false;skiphash=false; }s=statement {
        $text = $s.text+"\n";
        writeIntoparserLogFile("Line " + std::to_string($s.start->getLine()) + ": statements : statement\n");
        writeIntoparserLogFile($s.text + "\n");
    }
    | ss=statements { skipnextgram = false;skiphash=false; } s=statement {
        $text = $ss.text +"\n" + $s.text+"\n";
        if(!skipnextgram && !skiphash){
        writeIntoparserLogFile("Line " + std::to_string($s.stop->getLine()) + ": statements : statements statement\n");
        writeIntoparserLogFile($ss.text + $s.text + "\n");
        }
    }
    ;
       
statement returns [std::string text] :
    vd=var_declaration {
        $text = $vd.text;
        writeIntoparserLogFile("Line " + std::to_string($vd.start->getLine()) + ": statement : var_declaration\n");
        writeIntoparserLogFile($vd.text + "\n");
    }
    | es=expression_statement {
        $text = $es.text;
        if(!skipnextgram){
        writeIntoparserLogFile("Line " + std::to_string($es.start->getLine()) + ": statement : expression_statement\n");
        writeIntoparserLogFile($es.text + "\n");
        }
    }
    | cs=compound_statement {
        $text = $cs.text;
        writeIntoparserLogFile("Line " + std::to_string($cs.stop->getLine()) + ": statement : compound_statement\n");
        writeIntoparserLogFile($cs.text + "\n");
    }
    | FOR LPAREN es1=expression_statement es2=expression_statement e=expression RPAREN s=statement {
        $text = "for(" + $es1.text + $es2.text + $e.text + ")" + $s.text;
        writeIntoparserLogFile("Line " + std::to_string($FOR->getLine()) + ": statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n");
        writeIntoparserLogFile($text + "\n");
    }
    | IF LPAREN e=expression RPAREN s1=statement ELSE s2=statement {
        $text = "if(" + $e.text + ")" + $s1.text + "else " + $s2.text;
        writeIntoparserLogFile("Line " + std::to_string($IF->getLine()) + ": statement : IF LPAREN expression RPAREN statement ELSE statement\n");
        writeIntoparserLogFile($text + "\n");
    }
    | IF LPAREN e=expression RPAREN s=statement {
        $text = "if(" + $e.text + ")" + $s.text;
        writeIntoparserLogFile("Line " + std::to_string($IF->getLine()) + ": statement : IF LPAREN expression RPAREN statement\n");
        writeIntoparserLogFile($text + "\n");
    }
    | WHILE LPAREN e=expression RPAREN s=statement {
        $text = "while(" + $e.text + ")" + $s.text;
        writeIntoparserLogFile("Line " + std::to_string($WHILE->getLine()) + ": statement : WHILE LPAREN expression RPAREN statement\n");
        writeIntoparserLogFile($text + "\n");
    }
    | PRINTLN LPAREN id=ID RPAREN sm=SEMICOLON {
        SymbolInfo* sym = symbolTable.lookup($id->getText());
        if(!sym) {
            writeIntoparserLogFile("Error at line " + std::to_string($id->getLine()) + ": Undeclared variable " + $id->getText());
            writeIntoErrorFile("Error at line " + std::to_string($id->getLine()) + ": Undeclared variable " + $id->getText());
            syntaxErrorCount++;
        }
        $text = "println(" + $id->getText() + ");";
        writeIntoparserLogFile("Line " + std::to_string($PRINTLN->getLine()) + ": statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n");
        writeIntoparserLogFile($text + "\n");
    }
    | PRINTF LPAREN id=ID RPAREN sm=SEMICOLON {
        SymbolInfo* sym = symbolTable.lookup($id->getText());
        if(!sym) {
            writeIntoparserLogFile("Error at line " + std::to_string($id->getLine()) + ": Undeclared variable " + $id->getText());
            writeIntoErrorFile("Error at line " + std::to_string($id->getLine()) + ": Undeclared variable " + $id->getText());
            syntaxErrorCount++;
        }
        $text = "printf(" + $id->getText() + ");";
        writeIntoparserLogFile("Line " + std::to_string($PRINTF->getLine()) + ": statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n");
        writeIntoparserLogFile($text + "\n");
    }
    | RETURN e=expression sm=SEMICOLON {
        if(currentFunctionName.empty()){
            writeIntoparserLogFile("Error at line " + std::to_string($RETURN->getLine()) + ": Return statement outside function");
            writeIntoErrorFile("Error at line " + std::to_string($RETURN->getLine()) + ": Return statement outside function");
            syntaxErrorCount++;
        }else{
            SymbolInfo* funcSym = symbolTable.lookup(currentFunctionName);
            if(funcSym && funcSym->getFunctionInfo()){
                std::string expectedType = funcSym->getFunctionInfo()->getReturnType();
                std::string actualType= $e.exprType;
                if(expectedType=="VOID"){
                    writeIntoparserLogFile("Error at line " + std::to_string($RETURN->getLine()+1) + ": Cannot return value from function "+currentFunctionName+" with void return type");
                    writeIntoErrorFile("Error at line " + std::to_string($RETURN->getLine()+1) + ": Cannot return value from function "+currentFunctionName+" with void return type");
                    syntaxErrorCount++;
                }else if(expectedType!=actualType){
                    writeIntoparserLogFile("Error at line " + std::to_string($RETURN->getLine()) + 
                            ": Return type mismatch. Expected '" + expectedType + "', got '" + actualType + "'");
                    writeIntoErrorFile("Error at line " + std::to_string($RETURN->getLine()) + 
                            ": Return type mismatch. Expected '" + expectedType + "', got '" + actualType + "'");
                        syntaxErrorCount++;
                }
            }
        }
        $text = "return " + $e.text + ";";
        writeIntoparserLogFile("Line " + std::to_string($RETURN->getLine()) + ": statement : RETURN expression SEMICOLON\n");
        writeIntoparserLogFile($text + "\n");
    }
    | RETURN sm=SEMICOLON {
        if(currentFunctionName.empty()){
            writeIntoparserLogFile("Error at line " + std::to_string($RETURN->getLine()) + ": Return statement outside function");
            writeIntoErrorFile("Error at line " + std::to_string($RETURN->getLine()) + ": Return statement outside function");
            syntaxErrorCount++;
        }else{
             SymbolInfo* funcSym = symbolTable.lookup(currentFunctionName);
            if (funcSym && funcSym->getFunctionInfo()) {
                std::string expectedType = funcSym->getFunctionInfo()->getReturnType();
                
                if (expectedType != "VOID") {
                    writeIntoparserLogFile("Error at line " + std::to_string($RETURN->getLine()) + 
                        ": Non-void function must return a value");
                    writeIntoErrorFile("Error at line " + std::to_string($RETURN->getLine()) + 
                        ": Non-void function must return a value");
                    syntaxErrorCount++;
                }
            }
        }
        $text = "return;\n";
        writeIntoparserLogFile("Line " + std::to_string($RETURN->getLine()) + ": statement : RETURN SEMICOLON\n");
        writeIntoparserLogFile($text + "\n");
    }
    | HASHTAG {
        $text="";
        skiphash=true;
        writeIntoErrorFile("Error at line " + std::to_string($HASHTAG->getLine()) + 
            ": Unrecognized character #");
        writeIntoparserLogFile("Error at line " + std::to_string($HASHTAG->getLine()) + 
            ": Unrecognized character #");
        syntaxErrorCount++;
    }
    ;
  
expression_statement returns [std::string text] :
    sm=SEMICOLON {
        $text = ";";
        writeIntoparserLogFile("Line " + std::to_string($sm->getLine()) + ": expression_statement : SEMICOLON\n");
        writeIntoparserLogFile($text + "\n");
    }
    |   e=expression sm=SEMICOLON {
        $text = $e.text + ";";
        if(!skipnextgram){
        writeIntoparserLogFile("Line " + std::to_string($sm->getLine()) + ": expression_statement : expression SEMICOLON\n");
        writeIntoparserLogFile($text + "\n");
        }
    }
    ;
      
variable returns [std::string text,std::string varType,bool isArrayAccess] : 
    id=ID {
        SymbolInfo* sym = symbolTable.lookup($id->getText());
        if(!sym) {
            writeIntoparserLogFile("Error at line " + std::to_string($id->getLine()) + ": Undeclared variable " + $id->getText());
            writeIntoErrorFile("Error at line " + std::to_string($id->getLine()) + ": Undeclared variable " + $id->getText());
			syntaxErrorCount++;
			$varType = "ERROR";
        } else {
            $varType = sym->getDataType();
        }
        $isArrayAccess=false;
        $text = $id->getText();
        writeIntoparserLogFile("Line " + std::to_string($id->getLine()) + ": variable : ID\n");
        writeIntoparserLogFile($text + "\n");
    }
    | id=ID LTHIRD e=expression RTHIRD {
        SymbolInfo* sym = symbolTable.lookup($id->getText());
		if(!sym) {
            writeIntoparserLogFile("Error at line " + std::to_string($id->getLine()) + ": Undeclared variable " + $id->getText());
			writeIntoErrorFile("Error at line " + std::to_string($id->getLine()) + ": Undeclared variable " + $id->getText());
			syntaxErrorCount++;
			$varType = "ERROR";
		}else{
            if(!sym->getIsArray()){
                writeIntoparserLogFile("Error at line " + std::to_string($id->getLine()) + ": " + $id->getText() + " not an array");
                writeIntoErrorFile("Error at line " + std::to_string($id->getLine()) + ": " + $id->getText() + " not an array");
				syntaxErrorCount++;
            }
            $varType = sym->getDataType();
        }
        if($e.exprType != "INT") {
            writeIntoparserLogFile("Error at line " + std::to_string($id->getLine()) + ": Expression inside third brackets not an integer");
            writeIntoErrorFile("Error at line " + std::to_string($id->getLine()) + ": Expression inside third brackets not an integer");
			syntaxErrorCount++;
        }
        $isArrayAccess = true;
        $text = $id->getText() + "[" + $e.text + "]";
        writeIntoparserLogFile("Line " + std::to_string($id->getLine()) + ": variable : ID LTHIRD expression RTHIRD\n");
        writeIntoparserLogFile($text + "\n");
    }
    ;
     
expression returns [std::string text,std::string exprType] : 
    le=logic_expression {
        $exprType=$le.exprType;
        $text = $le.text;
        writeIntoparserLogFile("Line " + std::to_string($le.start->getLine()) + ": expression : logic_expression\n");
        writeIntoparserLogFile($text + "\n");
    }
    | {voidFuncerror=false;nonint=false;unexpectedassignop=false;}v=variable ASSIGNOP le=logic_expression {
          
          if($le.exprType == "VOID"){
            voidFuncerror=true;
            writeIntoparserLogFile("Error at line " + std::to_string($v.start->getLine()) + " Void function used in expression");
             writeIntoErrorFile("Error at line " + std::to_string($v.start->getLine()) + " Void function used in expression");
            syntaxErrorCount++;
          }
          if ($v.varType != "ERROR" && $le.exprType != "ERROR" && !voidFuncerror && !nonint && !unexpectedassignop) {
            if ( $v.varType == "FLOAT" && $le.exprType == "INT") {
                
            } else if ($v.varType != $le.exprType) {
                writeIntoparserLogFile("Error at line " + std::to_string($v.start->getLine()) + ": Type Mismatch");
                writeIntoErrorFile("Error at line " + std::to_string($v.start->getLine()) + ": Type Mismatch");
                syntaxErrorCount++;
            }
        }

        if(!$v.isArrayAccess){
            SymbolInfo* sym = symbolTable.lookup($v.text);
            if(sym && sym->getIsArray()) {
                writeIntoparserLogFile("Error at line " + std::to_string($v.start->getLine()) + ": Type mismatch, " + $v.text + " is an array");
                writeIntoErrorFile("Error at line " + std::to_string($v.start->getLine()) + ": Type mismatch, " + $v.text + " is an array");
                syntaxErrorCount++;
                typemismatcherror=true;
            }
        }
        $exprType=$v.varType;
        if(skipAssignText){
            $text=$le.text;
            skipAssignText=false;
        }else{
            $text = $v.text + "=" + $le.text;
        }
        
        writeIntoparserLogFile("Line " + std::to_string($v.start->getLine()) + ": expression : variable ASSIGNOP logic_expression\n");
        writeIntoparserLogFile($text + "\n");
    }
    ;
            
logic_expression returns [std::string text,std::string exprType] : 
    re=rel_expression {
        $exprType=$re.exprType;
        $text = $re.text;
        writeIntoparserLogFile("Line " + std::to_string($re.start->getLine()) + ": logic_expression : rel_expression\n");
        writeIntoparserLogFile($text + "\n");
    }
    | re1=rel_expression LOGICOP re2=rel_expression {
        $exprType = "INT";
        $text = $re1.text + $LOGICOP.text + $re2.text;
        writeIntoparserLogFile("Line " + std::to_string($re1.start->getLine()) + ": logic_expression : rel_expression LOGICOP rel_expression\n");
        writeIntoparserLogFile($text + "\n");
    }
    ;
            
rel_expression returns [std::string text,std::string exprType] : 
    se=simple_expression {
        $exprType = $se.exprType;
        $text = $se.text;
        writeIntoparserLogFile("Line " + std::to_string($se.start->getLine()) + ": rel_expression : simple_expression\n");
        writeIntoparserLogFile($text + "\n");
    }
    | se1=simple_expression RELOP se2=simple_expression {
        $exprType = "INT";
        $text = $se1.text + $RELOP.text + $se2.text;
        writeIntoparserLogFile("Line " + std::to_string($se1.start->getLine()) + ": rel_expression : simple_expression RELOP simple_expression\n");
        writeIntoparserLogFile($text + "\n");
    }
    ;
                
simple_expression returns [std::string exprType,std::string text] : 
    t=term {
        $exprType = $t.exprType;
        $text = $t.text;
        writeIntoparserLogFile("Line " + std::to_string($t.start->getLine()) + ": simple_expression : term\n");
        writeIntoparserLogFile($text + "\n");
    }
    | se=simple_expression ADDOP t=term {
        if($se.exprType=="ERROR" || $t.exprType=="ERROR"){
            $exprType="ERROR";
        } else if($se.exprType=="FLOAT" || $t.exprType=="FLOAT"){
            $exprType="FLOAT";
        } else {
            $exprType="INT";
        }
        $text = $se.text + $ADDOP.text + $t.text;
        writeIntoparserLogFile("Line " + std::to_string($se.start->getLine()) + ": simple_expression : simple_expression ADDOP term\n");
        writeIntoparserLogFile($text + "\n");
    }
    | se=simple_expression ADDOP ASSIGNOP le=logic_expression {
        $exprType = "Error";
        $text = $le.text;
        unexpectedassignop=true;
        skipAssignText = true;
        skipnextgram=true;
        writeIntoErrorFile("Error at line " + std::to_string($se.start->getLine()) + 
            ": syntax error, unexpected ASSIGNOP");
        writeIntoparserLogFile("Error at line " + std::to_string($se.start->getLine()) + 
            ": syntax error, unexpected ASSIGNOP");
        syntaxErrorCount++;
    }
    ;



term returns [std::string exprType,std::string text] : 
    ue=unary_expression {
        $exprType = $ue.exprType;
        $text = $ue.text;
        writeIntoparserLogFile("Line " + std::to_string($ue.start->getLine()) + ": term : unary_expression\n");
        writeIntoparserLogFile($text + "\n");
    }
    | t=term MULOP ue=unary_expression {
        if ($MULOP->getText() == "%") {
            if ($t.exprType != "INT" || $ue.exprType != "INT") {
                nonint=true;
                writeIntoparserLogFile("Error at line " + std::to_string($MULOP->getLine()) + ": Non-Integer operand on modulus operator");
                writeIntoErrorFile("Error at line " + std::to_string($MULOP->getLine()) + ": Non-Integer operand on modulus operator");
                syntaxErrorCount++;
            }
            
            if ($ue.text == "0") {
                writeIntoparserLogFile("Error at line " + std::to_string($MULOP->getLine()) + ": Modulus by Zero");
                writeIntoErrorFile("Error at line " + std::to_string($MULOP->getLine()) + ": Modulus by Zero");
                syntaxErrorCount++;
            }
        }
        if($ue.exprType=="VOID"){
            voidFuncerror=true;
            writeIntoparserLogFile("Error at line " + std::to_string($MULOP->getLine()) + " Void function used in expression");
            writeIntoErrorFile("Error at line " + std::to_string($MULOP->getLine()) + " Void function used in expression");
            syntaxErrorCount++;
        }
        if($t.exprType=="ERROR" || $ue.exprType=="ERROR"){
            $exprType="ERROR";
        } else if ($t.exprType == "FLOAT" || $ue.exprType == "FLOAT")
            $exprType = "FLOAT";
        else
            $exprType = "INT";
        $text = $t.text + $MULOP.text + $ue.text;
        writeIntoparserLogFile("Line " + std::to_string($t.start->getLine()) + ": term : term MULOP unary_expression\n");
        writeIntoparserLogFile($text + "\n");
    }
    ;

unary_expression returns [std::string exprType,std::string text] : 
    ADDOP ue=unary_expression {
        $exprType = $ue.exprType;
        $text = $ADDOP.text + $ue.text;
        writeIntoparserLogFile("Line " + std::to_string($ADDOP->getLine()) + ": unary_expression : ADDOP unary_expression\n");
        writeIntoparserLogFile($text + "\n");
    }
    | NOT ue=unary_expression {
        $exprType = "INT";
        $text = $NOT.text + $ue.text;
        writeIntoparserLogFile("Line " + std::to_string($NOT->getLine()) + ": unary_expression : NOT unary_expression\n");
        writeIntoparserLogFile($text + "\n");
    }
    | f=factor {
        $exprType = $f.exprType;
        $text = $f.text;
        writeIntoparserLogFile("Line " + std::to_string($f.start->getLine()) + ": unary_expression : factor\n");
        writeIntoparserLogFile($text + "\n");
    }
    ;
    
factor returns [std::string exprType,std::string text] : 
    v=variable {
        if (!$v.isArrayAccess) {
            SymbolInfo* sym = symbolTable.lookup($v.text);
            if (sym && sym->getIsArray()) {
                writeIntoparserLogFile("Error at line " + std::to_string($v.start->getLine()) + ": Type mismatch, " + $v.text + " is an array");
                writeIntoErrorFile("Error at line " + std::to_string($v.start->getLine()) + ": Type mismatch, " + $v.text + " is an array");
                syntaxErrorCount++;
                typemismatcherror=true;
            }
        }
        $exprType = $v.varType;
        $text = $v.text;
        writeIntoparserLogFile("Line " + std::to_string($v.start->getLine()) + ": factor : variable\n");
        writeIntoparserLogFile($text + "\n");
    }
    | id=ID LPAREN al=argument_list RPAREN {
        bool hasError = false; // flag to track so 1 error shows

        SymbolInfo* sym = symbolTable.lookup($id->getText());

        // Check if function is declared
        if (!sym || !sym->getFunctionInfo()) {
            writeIntoparserLogFile("Error at line " + std::to_string($id->getLine()) + ": Undefined function " + $id->getText());
            writeIntoErrorFile("Error at line " + std::to_string($id->getLine()) + ": Undefined function " + $id->getText());
            syntaxErrorCount++;
            $exprType = "ERROR";
            hasError = true;
        }

        
        if (!hasError) {
            FunctionInfo* funcInfo = sym->getFunctionInfo();
            $exprType = funcInfo->getReturnType();

            

            // Check argument list only if return type is OK
            if (!hasError) {
                vector<string> expectedTypes = funcInfo->getParamTypes();
                vector<string> actualTypes = $al.argTypes;

                if (expectedTypes.size() != actualTypes.size()) {
                    writeIntoparserLogFile("Error at line " + std::to_string($id->getLine()) + ": Total number of arguments mismatch in function " + $id->getText());
                    writeIntoErrorFile("Error at line " + std::to_string($id->getLine()) + ": Total number of arguments mismatch in function " + $id->getText());
                    syntaxErrorCount++;
                    $exprType = "ERROR";
                    hasError = true;
                } else {
                    if(!typemismatcherror){
                    for (int i = 0; i < expectedTypes.size(); i++) {
                        if (expectedTypes[i] != actualTypes[i]) {
                            writeIntoparserLogFile("Error at line " + std::to_string($id->getLine()) + ": " + std::to_string(i + 1) + "th argument mismatch in function " + $id->getText());
                            writeIntoErrorFile("Error at line " + std::to_string($id->getLine()) + ": " + std::to_string(i + 1) + "th argument mismatch in function " + $id->getText());
                            syntaxErrorCount++;
                            $exprType = "ERROR";
                            hasError = true;
                            break;
                        }
                    }
                    }
                }
            }
        }

        
        if ($exprType != "ERROR")
            $exprType = sym->getFunctionInfo()->getReturnType();

        $text = $id->getText() + "(" + $al.text + ")";
        writeIntoparserLogFile("Line " + std::to_string($id->getLine()) + ": factor : ID LPAREN argument_list RPAREN\n");
        writeIntoparserLogFile($text + "\n");
    }

    | LPAREN e=expression RPAREN {
        $exprType = $e.exprType;
        $text = "(" + $e.text + ")";
        writeIntoparserLogFile("Line " + std::to_string($LPAREN->getLine()) + ": factor : LPAREN expression RPAREN\n");
        writeIntoparserLogFile($text + "\n");
    }
    | CONST_INT {
        $exprType = "INT";
        $text = $CONST_INT.text;
        writeIntoparserLogFile("Line " + std::to_string($CONST_INT->getLine()) + ": factor : CONST_INT\n");
        writeIntoparserLogFile($text + "\n");
    }
    | CONST_FLOAT {
        $exprType = "FLOAT";
        $text = $CONST_FLOAT.text;
        writeIntoparserLogFile("Line " + std::to_string($CONST_FLOAT->getLine()) + ": factor : CONST_FLOAT\n");
        writeIntoparserLogFile($text + "\n");
    }
    | variable INCOP {
        if (!$variable.isArrayAccess && symbolTable.lookup($variable.start->getText())->getIsArray()) {
            writeIntoparserLogFile("Error at line " + std::to_string($variable.start->getLine()) + ": Invalid increment on array name");
            writeIntoErrorFile("Error at line " + std::to_string($variable.start->getLine()) + ": Invalid increment on array name");
            syntaxErrorCount++;
        }
        $exprType = $variable.varType;
        $text = $variable.text + "++";
        writeIntoparserLogFile("Line " + std::to_string($variable.start->getLine()) + ": factor : variable INCOP\n");
        writeIntoparserLogFile($text + "\n");
    }
    | variable DECOP {
        if (!$variable.isArrayAccess && symbolTable.lookup($variable.start->getText())->getIsArray()) {
            writeIntoparserLogFile("Error at line " + std::to_string($variable.start->getLine()) + ": Invalid decrement on array name");
            writeIntoErrorFile("Error at line " + std::to_string($variable.start->getLine()) + ": Invalid decrement on array name");
            syntaxErrorCount++;
        }

        $exprType = $variable.varType;
        $text = $variable.text + "--";
        writeIntoparserLogFile("Line " + std::to_string($variable.start->getLine()) + ": factor : variable DECOP\n");
        writeIntoparserLogFile($text + "\n");
    }
    ;
    
argument_list returns [std::vector<std::string> argTypes, std::string text] :
    a=arguments {
        $argTypes = $a.argTypes;
        $text = $a.text;
        writeIntoparserLogFile("Line " + std::to_string($a.start->getLine()) + ": argument_list : arguments\n");
        writeIntoparserLogFile($text + "\n");
    }
    | {
        $argTypes = {};
        $text = "";
        writeIntoparserLogFile("Line ?: argument_list : (empty)\n");
        writeIntoparserLogFile("\n");
    }
    ;
    
arguments returns [std::vector<std::string> argTypes, std::string text] :
    a=arguments COMMA l=logic_expression {
        $argTypes = $a.argTypes;
        $argTypes.push_back($l.exprType);
        $text = $a.text + "," + $l.text;
        writeIntoparserLogFile("Line " + std::to_string($a.start->getLine()) + ": arguments : arguments COMMA logic_expression\n");
        writeIntoparserLogFile($text + "\n");
    }
    | l=logic_expression {
        $argTypes = { $l.exprType };
        $text = $l.text;
        writeIntoparserLogFile("Line " + std::to_string($l.start->getLine()) + ": arguments : logic_expression\n");
        writeIntoparserLogFile($text + "\n");
    }
    ;