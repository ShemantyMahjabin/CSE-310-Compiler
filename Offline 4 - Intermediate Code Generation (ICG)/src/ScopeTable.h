#pragma once
#include<bits/stdc++.h>
#include<fstream>
#include "Symbolinfo.h"
using namespace std;

unsigned int sdbmHash(const char *p);
class ScopeTable{
        SymbolInfo** table;
        ScopeTable* parent_scope;
        int unique_id;
        int pos;
        int total_buckets;
        static int scopecount;
        int index;
        int collision;
        int childCount;
        unsigned int (*HashFunction)(const char*);
        string id;

    public:
        ScopeTable(){}

        ScopeTable(int n, ScopeTable* parent_scope=nullptr, unsigned int (*hashFunc)(const char*) = sdbmHash): 
            total_buckets(n), parent_scope(parent_scope), HashFunction(hashFunc),childCount(0) {
            collision = 0;
            scopecount++;
            unique_id = scopecount;

            table = new SymbolInfo*[n];
            for(int i=0; i<n; i++){
                table[i] = nullptr;
            }
            if (parent_scope == nullptr) {
                id = "1";
            } else {
                parent_scope->childCount++;
                id = parent_scope->id + "." + to_string(parent_scope->childCount);
            }
        }

        ~ScopeTable(){
            for(int i=0; i<total_buckets; i++){
                SymbolInfo* entry = table[i];
                while(entry){
                    SymbolInfo* temp = entry;
                    entry = entry->getNext();
                    delete temp;
                }
            }
            delete[] table;
        }
        
        int hash_result(string name) {
            unsigned int hashValue = HashFunction(name.c_str());
            return hashValue % total_buckets;
        }

        int getIndex() {
            return index + 1;
        }
        
        int getPosition() {
            return pos;
        }
        
        int getCollision() {
            return collision;
        }
        
        int getID(){ 
            return unique_id; 
        }
        const string& getScopeID() const {
        return id;
    }
        
        ScopeTable* getParentScope() const{ 
            return parent_scope;
        }
        
        bool insert(string name, string type)
        {
            if(lookup(name, 0) != nullptr){
                return false;
            }
            
            int indx = hash_result(name);
            index = indx; 
            SymbolInfo* head = table[indx];
            pos = 1;
            SymbolInfo* current = head;
            
            if(current == nullptr){
                SymbolInfo* newSymbol = new SymbolInfo(name, type);
                newSymbol->setNext(nullptr);
                table[indx] = newSymbol;
                return true;
            }
            
            
            while(current->getNext() != nullptr){
                pos++;
                current = current->getNext();   
            }
            
            SymbolInfo* newSymbol = new SymbolInfo(name, type);
            current->setNext(newSymbol);
            newSymbol->setNext(nullptr);
            pos++;
            return true;
        }

        SymbolInfo* lookup(string name, int c=1){
            int indx = hash_result(name);
            index = indx; // Store the bucket index for reporting
            SymbolInfo* current = table[indx];
            pos = 1;
            
            while(current){
                if(current->getName() == name){
                    return current;
                }
                current = current->getNext();
                pos++;
            }
            
            return nullptr;
        }

        bool Delete(string name){
            int indx = hash_result(name);
            SymbolInfo* current = table[indx];
            pos = 1;

            if(lookup(name, 0) == nullptr){
                return false;
            }

            if(current->getName() == name){
                SymbolInfo* temp = current;
                table[indx] = current->getNext();
                delete temp;
                return true;
            }

            while(current->getNext()){
                if(current->getNext()->getName() == name){
                    SymbolInfo* temp = current->getNext();
                    current->setNext(current->getNext()->getNext());
                    delete temp;
                    return true;
                }
                current = current->getNext();
                pos++;
            }
            return false;
        }

        void print(ofstream &out, int indent = 1){
            // Format: ScopeTable # 1.1
            // string scopeID;
            // if (parent_scope != nullptr) {
            //     scopeID = parent_scope->getScopeID() + "." + to_string(unique_id - parent_scope->getID());
            //     out << "ScopeTable # " << scopeID << "\n";
            // } else {
            //     scopeID = to_string(unique_id);
            //     out << "ScopeTable # " << scopeID << "\n";
            // }
            out << "ScopeTable # " << id << endl;
            for(int i=0; i<total_buckets; i++){
                SymbolInfo* current = table[i];
                if (current != nullptr) { // Only print non-empty buckets
                    out << i << " --> ";
                    while(current){
                        out << "< " << current->getName() << " : " << current->getType() << " >";
                       
                        current = current->getNext();
                    }
                    out << "\n";
                }
            }
        }
        int getChildCount() const {
        return childCount;
    }

        // string getScopeID() {
        //     if (parent_scope != nullptr) {
        //         return to_string(parent_scope->getID()) + "." + to_string(unique_id - parent_scope->getID());
        //     } else {
        //         return to_string(unique_id);
        //     }
        // }
};


