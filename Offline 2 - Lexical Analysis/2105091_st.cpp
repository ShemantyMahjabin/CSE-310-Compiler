#include<bits/stdc++.h>
#include<fstream>
using namespace std;

class SymbolInfo{
    private:
        string name,type;
        SymbolInfo* next;
    public:
        SymbolInfo(string name = "", string type = "") : name(name), type(type), next(nullptr) {}
        void setName(string n){ name = n;}
        string getName(){return name;}
        void setType(string t){ type = t;}
        string getType() {return type;}
        void setNext(SymbolInfo* nxt){next = nxt;}
        SymbolInfo* getNext(){return next;}
        friend ostream& operator<<(ostream& out,SymbolInfo& symbol)
        {
            out<<"<"<<symbol.name<<","<<symbol.type<<">";
            return out;
        }
};

unsigned int sdbmHash(const char *p) 
{ 
    unsigned int hash = 0; 
    auto *str = (unsigned char *) p; 
    int c{};
    while ((c = *str++)) 
    { 
        hash = c + (hash << 6) + (hash << 16) - hash;
    } 
    
    return hash;
} 

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

int ScopeTable::scopecount = 0;

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
};