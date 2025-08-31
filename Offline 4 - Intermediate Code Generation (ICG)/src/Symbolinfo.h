
#pragma once
#include<bits/stdc++.h>
#include<fstream>
using namespace std;

class FunctionInfo {
private:
    string returnType;
    vector<string> paramTypes;
    bool isDeclared;
    bool isDefined;
public:
    FunctionInfo() : isDeclared(false),isDefined(false) {}
    void setReturnType(const string& rt) {returnType=rt;}
    string getReturnType() const {return returnType;}
    void setParamTypes(const vector<string>& params) { paramTypes = params; }
    vector<string> getParamTypes() const { return paramTypes; }
    int getNumofParameters() const {return paramTypes.size(); }
    void setIsDeclared(bool val) { isDeclared=val;} 
    bool getIsDeclared() const { return isDeclared; }
    void setIsDefined(bool val) { isDefined = val;}
    bool getIsDefined() const {return isDefined;}   
};

class SymbolInfo{
    private:
        string name,type,datatype;
        SymbolInfo* next;
        bool isArray;
        FunctionInfo* funcInfo;
        bool isFunctionPointer = false;
        int localoffset = 0; 

        
    public:
        SymbolInfo(string name = "", string type = "") : name(name), type(type), next(nullptr) ,isArray(false), funcInfo(nullptr) {}
        ~SymbolInfo() { delete funcInfo; }
        void setIsFunctionPointer(bool v) { isFunctionPointer = v; }
        bool getIsFunctionPointer() { return isFunctionPointer; }
        void setName(string n){ name = n;}
        string getName(){return name;}
        void setType(string t){ type = t;}
        void setDataType(string t){ datatype=t;}
        string getDataType() {return datatype;}
        string getType() {return type;}
        void setNext(SymbolInfo* nxt){next = nxt;}
        SymbolInfo* getNext(){return next;}
        void setIsArray(bool val) { isArray = val; }
        bool getIsArray() const { return isArray; }
        void setFunctionInfo(FunctionInfo* fi) {
            if(funcInfo) delete funcInfo;
            funcInfo = fi;
        }
        FunctionInfo* getFunctionInfo() const { return funcInfo; }
        friend ostream& operator<<(ostream& out,SymbolInfo& symbol)
        {
            out<<"<"<<symbol.name<<","<<symbol.type<<">";
            return out;
        }
        void setLocalOffset(int offset) { localoffset = offset; }
        int getLocalOffset() const { return localoffset; }
};
