#pragma once
#include<bits/stdc++.h>
#include<fstream>
#include "ScopeTable.h"


class SymbolTable{
    ScopeTable* current;
    int total_buckets;
    unsigned int (*hashFunc)(const char*);

public:
    SymbolTable(int n, unsigned int (*hashFunc)(const char*) = sdbmHash):
        total_buckets(n), hashFunc(hashFunc), current(nullptr) {
        enterscope();
    }
    
    ~SymbolTable() {
        while (current) {
            ScopeTable* temp = current;
            current = current->getParentScope();
            delete temp;
        }
    }

    ScopeTable* getCurrentScope(){
        return current;
    }
    
    void enterscope(){
        current = new ScopeTable(total_buckets, current, hashFunc);
    }

    void exitscope(int istable1=0){
        if(current == nullptr) {
            return;
        }
        
        if(current->getScopeID() == "1" && istable1 == 0) return;
        
        ScopeTable* temp = current;
        current = current->getParentScope();
        delete temp;
    }
    
    bool insert(string name, string type) {
        if(current == nullptr) return false;
        
        
        SymbolInfo* existing = current->lookup(name, 0);
        if(existing != nullptr) {
            
            return false;
        }
        
        return current->insert(name, type);
    }
    
    
    string getErrorMessage(string name, string type) {
        if(current == nullptr) return "";
        
        
        current->lookup(name, 0);
        return "< " + name + " : " + type + " > already exists in ScopeTable# " + 
               current->getScopeID() + " at position " + 
               to_string(current->getIndex()-1) + ", " + 
               to_string(current->getPosition()-1);
    }
    
    bool remove(string name) {
        if(current == nullptr) {
            return false;
        }
        return current->Delete(name);
    }
    
    SymbolInfo* lookup(string name) {
        ScopeTable* t = current;
        while (t) {
            SymbolInfo* rslt = t->lookup(name);
            if (rslt) return rslt;
            t = t->getParentScope();
        }
        return nullptr;
    }
    
    void printCurrentScopeTable(ofstream &out) {
        if(current == nullptr){
            out << "no ScopeTable in the SymbolTable" << endl;
            return;
        }
        current->print(out);
    }

    void printAllScopeTable(ofstream &out) {
        ScopeTable* temp = current;
        while (temp) {
            temp->print(out);
            temp = temp->getParentScope();
        }
        out<<endl;
    } 

    void exitallscope(){
        while (current != nullptr) {
            ScopeTable* temp = current;
            current = current->getParentScope();
            delete temp;
        }
    }
    bool addGlobalVariable(string name, string type) {
        if(current == nullptr || current->getParentScope() != nullptr) {
            return false;
        }
        SymbolInfo* sym=new SymbolInfo(name, type);        
        return current->insert(name, "ID");
    }
    bool addLocalVariable(string name, int offset,string type) {
        if(current == nullptr ) {
            return false;
        }
        SymbolInfo* sym=new SymbolInfo(name, type);
        sym->setLocalOffset(offset);
        return current->insert(name, "ID");
    }

    bool isLocal(const string &name) const {
        if (current == nullptr) return false;
        SymbolInfo* sym = current->lookup(name);
        return (sym != nullptr);
    }

    bool isGlobal(const std::string &name) const {
    // Find the root scope
        ScopeTable* rootScope = current;
        while (rootScope != nullptr && rootScope->getParentScope() != nullptr) {
            rootScope = rootScope->getParentScope();
        }
        if (rootScope == nullptr) return false;
    
        SymbolInfo* sym = rootScope->lookup(name);
        return (sym != nullptr);
    }
    int getLocalOffset(const string &name) const {
        if (current == nullptr) return -1;
        SymbolInfo* sym = current->lookup(name);
        if (sym != nullptr) {
            return sym->getLocalOffset();
        }
        return -1; // Not found
    }
};