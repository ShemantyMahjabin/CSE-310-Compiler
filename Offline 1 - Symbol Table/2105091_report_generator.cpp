#include<iostream>
#include<string>
#include<fstream>
#include <sstream>
#include <unordered_map>  
#include "st.h"

using namespace std;

unsigned int (*HashFunction)(string, unsigned int);

int main(int argc, char *argv[])
{

    unordered_map<string, unsigned int(*)(string, unsigned int)> hashFuncMap = {
        {"SDBM", SDBMHash},
        {"ADD", AdditiveHash},
        {"DJB2", DJB2Hash}  
    };

    if (argc < 3 || argc > 4)
    {
        cout << "Error: Invalid number of arguments" << endl;
        return 1;
    }

    string inputFile = argv[1];
    string outputFile = argv[2];

    if (argc == 4)
    {
        string hashFunctionName = argv[3];
        if (hashFuncMap.find(hashFunctionName) != hashFuncMap.end())
        {
            HashFunction = hashFuncMap[hashFunctionName];
        }
        else
        {
            cout << "Error: Invalid hash function" << endl;
            return 1;
        }
    }
    else
    {
        HashFunction = SDBMHash;
    }

 
    ifstream in(inputFile);
    if (!in)
    {
        cerr << "Error opening input file: " << inputFile << endl;
        return 1;
    }

    string line;
    getline(in, line);
    int bucketSize = stoi(line);
    SymbolTable symbolTable(bucketSize, HashFunction);

    cout << "--------------------------------" << endl;
    symbolTable.enterscope();

    float ratio = 0;
    int totalScope = 1;
    int scopeCount = 0;  
    while (getline(in, line))
    {
        if (line.empty() || line[0] == '#')
            continue;

        istringstream is(line);
        string word, normalizedLine;
        bool flag = true;

        while (is >> word)
        {
            if (!flag)
                normalizedLine += " ";
            normalizedLine += word;
            flag = false;
        }

        istringstream iss(normalizedLine);
        string cmd;
        iss >> cmd;



        if (cmd == "Q")
        {
            while (symbolTable.getCurrentScope() != nullptr)
            {
                float scopeCollisionRatio = (float)(symbolTable.getCurrentScope()->getCollision()) / bucketSize;
                ratio += scopeCollisionRatio;
                scopeCount++;  
                cout << "Scope #" << symbolTable.getCurrentScope()->getID() << " collision " 
                     << symbolTable.getCurrentScope()->getCollision() 
                     << ", Collision Ratio = " << scopeCollisionRatio << endl;
                symbolTable.exitallscope();
            }
            break;
        }

        else if (cmd == "I")
        {
            string name, type;
            iss >> name >> type;
            string fullType = type;
            string part;
            while (iss >> part)
            {
                fullType += " " + part;
            }

            bool insertion = symbolTable.insert(name, fullType);
        }

        else if (cmd == "L")
        {
            string name;
            iss >> name;
            if (name.empty() || iss.peek() != EOF)
            {
                continue;
            }
        }

        else if (cmd == "D")
        {
            string name;
            iss >> name;
            if (name.empty() || iss.peek() != EOF)
            {
                continue;
            }
        }

        else if (cmd == "P")
        {
            
        }

        else if (cmd == "S")
        {
            symbolTable.enterscope();
            totalScope++;
        }
        
        else if (cmd == "E")
        {
            if (symbolTable.getCurrentScope() != nullptr)
            {
                cout << "Exiting ScopeTable #" << symbolTable.getCurrentScope()->getID() << endl;
                ratio += (float)(symbolTable.getCurrentScope()->getCollision()) / bucketSize;
                if (symbolTable.getCurrentScope() != nullptr)
                {
                    symbolTable.exitallscope();
                }
            }
        }
    }



    cout << "Total Scopes Processed: " << scopeCount << endl;
    cout << "Total Collision Ratio: " << ratio << endl;
    cout << "Mean Collision Ratio: " << (scopeCount > 0 ? (ratio / scopeCount) : 0) << endl;

    ofstream appendOut(outputFile, ios::app);
    appendOut << "--------------------------------" << endl;
    if (argc == 3)
    {
        appendOut << "SDBM Hash Function mean collision ratio = " << (float)ratio / totalScope << endl;
        appendOut << "--------------------------------" << endl;
    }
    else
    {
        appendOut << argv[3] << " Hash mean collision ratio = " << (float)ratio / totalScope << endl;
        appendOut << "--------------------------------" << endl;
    }
    appendOut.close();

    return 0;
}
