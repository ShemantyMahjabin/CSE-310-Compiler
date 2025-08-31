#include<bits/stdc++.h>
#include<fstream>
using namespace std;


ofstream out;
class SymbolInfo{
    private:
        string name,type;
        SymbolInfo* next;
    public:

        SymbolInfo(string name = "", string type = "") : name(name), type(type), next(nullptr) {}
        void setName(string n){ name =n;}
        string getName(){return name;}
        void setType(string t){ type=t;}
        string getType() {return type;}
        void setNext(SymbolInfo* nxt){next=nxt;}
        SymbolInfo* getNext(){return next;}
        friend ostream& operator<<(ostream& out,SymbolInfo& symbol)
        {
            out<<"<"<<symbol.name<<","<<symbol.type<<">";
            return out;
        }
};

unsigned int SDBMHash(string str, unsigned int num_buckets)
{
	unsigned int hash = 0;
	unsigned int len = str.length();
	for (unsigned int i = 0; i < len; i++)
	{
		hash = ((str[i]) + (hash << 6) + (hash << 16) - hash) %
			   num_buckets;
	}
	return hash;
}

unsigned int AdditiveHash(std::string str, unsigned int num_buckets)
{
	unsigned int hash = 0;
	for (char ch : str)
		hash += ch;
	return hash % num_buckets;
}


unsigned int DJB2Hash(string s, unsigned int bucketSize) {
    unsigned int hash = 5381; // Start with a large prime number
    for (char c : s) {
        hash = (hash * 33) + c; // Multiply by 33 and add the current character
    }
    return hash % bucketSize; // Return the index within the table size
}


class ScopeTable{
        SymbolInfo** table;
        //int num_bucket;
        ScopeTable* parent_scope;
        int unique_id;
        int pos;
        int total_buckets;
        static int scopecount;
        int index;
        int collision;
        unsigned int (*HashFunction)(string, unsigned int);



    public:
        ScopeTable(){}

        ScopeTable(int n,ScopeTable* parent=nullptr,unsigned int (*hashFunc)(string, unsigned int) = SDBMHash): total_buckets(n),parent_scope(parent){
            collision=0;
            scopecount++;
            unique_id=scopecount;
            HashFunction = hashFunc;

            table=new SymbolInfo*[n];
            for( int i=0; i<n; i++){
                table[i]=nullptr;
            }
        }

        ~ScopeTable(){
            for(int i=0;i<total_buckets;i++){
                SymbolInfo* entry=table[i];
                while(entry){
                    SymbolInfo* temp=entry;
                    entry=entry->getNext();
                    delete temp;
                }
            }
            delete[] table;
        }


        
        int hash_result(string name) {
            unsigned int hashValue = HashFunction(name, total_buckets);
            // cout << "hashValue" << hashValue << endl;
            //return hashValue % total_buckets;
            return hashValue;
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
        int getID(){ return unique_id; }
        ScopeTable* getParentScope() { return parent_scope;}
        bool insert(string name,string type)
        {
            if(lookup(name,0)!=nullptr){
                out<<"\t"<<"'"<<name<<"' already exists in the current Scopetable"<<endl;
                return false;
            }
            int indx=hash_result(name);
            SymbolInfo* head=table[indx];
            pos=1;
            SymbolInfo* current=head;
            if(current==nullptr){
                SymbolInfo* newSymbol=new SymbolInfo(name,type);
                newSymbol->setNext(nullptr);
                table[indx]=newSymbol;
                out<<"\t"<<"Inserted in ScopeTable# "<<unique_id<<" at position "<<indx+1<<","<<pos<<"\n";
                return true;
            }
            collision++;
            while(current->getNext()!=nullptr){
                
                pos++;
                current=current->getNext();   
            }
            SymbolInfo* newSymbol=new SymbolInfo(name,type);
            current->setNext(newSymbol);
            newSymbol->setNext(nullptr);
            pos++;
            out<<"\t"<<"Inserted in ScopeTable# "<<unique_id<<" at position "<<indx+1<<","<<pos<<"\n";
            return true;
            
        }

        SymbolInfo* lookup(string name,int c=1){
            int index=hash_result(name);
            SymbolInfo* current=table[index];
            pos=1;
            
            while(current){
                if(current->getName()==name){
                    if(c==1){
                        out<<"\t"<<"'"<<name<<"' found in ScopeTable# "<<unique_id<<" at position "<<index+1<<", "<<pos<<"\n";
                        
                    }
                    return current;
                }
                current=current->getNext();
                pos++;
            }
            //out<<"Not found\n";
            return nullptr;
        }

        bool Delete(string name){
            int indx=hash_result(name);
            SymbolInfo* current=table[indx];
            pos=1;

            if(lookup(name,0)==nullptr){
                out<<"\t"<<"Not found in the current ScopeTable"<<endl;
                return false;
            }

            if(current->getName()==name){
                current=current->getNext();
                table[indx]=current;
                out <<"\t"<< "Deleted '" << name<<"' from Scopetable# " <<unique_id<< " at position " << indx+1 << " ,"<<pos<<endl;
                return true;
            }

            while(current->getNext()){
                if(current->getNext()->getName()==name){
                        current->setNext(current->getNext()->getNext());
                        out <<"\t"<< "Deleted '" << name<<"' from Scopetable# " <<unique_id<< " at position " << indx+1 << " ,"<<pos<<endl;
                        return true;
                }
                current=current->getNext();
                pos++;
            }
            return false;

        }

        void print(int indent = 1){
            string spaces(indent, '\t');
            out<< spaces <<"Scopetable # "<<unique_id<<"\n";
            for(int i=0;i<total_buckets;i++){
                out<< spaces<<i+1<<" -->";
                SymbolInfo* current=table[i];
                while(current){
                    out<<" <"<<current->getName() <<","<<current->getType()<<">";
                    current=current->getNext();
                }
                out<<"\n";
            }
        }

};
int ScopeTable::scopecount = 0;



class SymbolTable{
    ScopeTable* current;
    int total_buckets;
    unsigned int (*hashFunc)(string,unsigned int);

public:
    SymbolTable(int n,unsigned int (*hashFunc)(string, unsigned int) = SDBMHash):current(nullptr){
        total_buckets=n;
        this->hashFunc=hashFunc;
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
        current=new ScopeTable(total_buckets,current,hashFunc);
        out<<"\t"<<"ScopeTable# "<<current->getID()<<" created\n";
    }

    void exitscope(int istable1=0){
        if(current->getID()==1 && istable1==0){
            out<<"\t"<<"ScopeTable# 1 cannot be removed"<<endl;
            return;
        }
        out<<"ScopeTable# "<<current->getID()<<" removed\n";
        current=current->getParentScope();
        return;
    }
    bool insert(string name, string type) {
        if(current==nullptr) return false;
        return current->insert(name, type);
    }
    bool remove(string name) {
        if(current==nullptr) {
            out << "\t" << "no ScopeTable in the SymbolTable" << endl;
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
    void printCurrentScopeTable() {
        if(current==nullptr){
            out<< "\t" << "no ScopeTable in the SymbolTable" << endl;
            return;
        }
        current->print();
        return;
    }

    void printAllScopeTable() {
        int indent = 0;
        ScopeTable* temp = current;
        while (temp) {
            indent++;
            temp->print(indent);
            temp = temp->getParentScope();
        }
    } 

    void exitallscope(){
        if (current != nullptr) {
            ScopeTable* temp = current;
            current = current->getParentScope();
            delete temp;
        }
    }
};