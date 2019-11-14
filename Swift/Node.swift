//------Enumerators------
//------The type should be able to be stored in a byte with the first 4 bits representing the section and the last 4 representing the specific type
enum NodeType{
    //Variable Management, 0x0X
    case CreateVar              //Children - GetVar(Optional), Name                 Purpose - Creates a variable with an empty link in a given object(getVar) or just the current variableScope
    case GetVar                 //Children - GetVar(Optional), Name                 Purpose - Gets the value linked to the variable from the given object(getVar) or just the current variableScope
    case DeleteVar              //Children - GetVar(Optional), Name                 Purpose - Deletes the value assigned with the variable from the given object(getVar) or just the current variableScope
    case GetLink                //Children - GetVar(Optional), Name                 Purpose - Returns the link of a variable as a Real_Int from the given object(getVar) or just the current variableScope
    case Link                   //Children - GetVar(Optional), Name, Real_Int       Purpose - Sets the link of the variable to the link provided from the given object(getVar) or just the current variableScope
    case Unlink                 //Children - GetVar(Optional), Name                 Purpose - Removes the link from a variable, not the value, the var is from the given object(getVar) or just the current variableScope
    case Assign                 //Children - GetVar(Optional), Name, Expression     Purpose - Assigns a value to the variable int the given object(getVar) or just the current variableScope
    //Primitives, 0x1X
    case NullType
    case Text                   //Operand  - Text                                   Proposal - Internally stored as a byte array
    case Real_Int               //Operand  - Int
    case Real_Float             //Operand  - Float
    case Boolean                //Operand  - Boolean
    case Object
    case Array                  //Operand  - Int                                    Purpose - Stores an array of links to the variable container, the operand defines the size of the array
    case Byte                   //Operand  - Int
    case ByteArray              //Operand  - Int                                    Purpose - Stores a collection of bytes, the operand defines the number of bytes
    //Operators, 0x2X
    case Oper_Add               //Children - Int Float, Int Float
    case Oper_Sub               //Children - Int Float, Int Float
    case Oper_Mult              //Children - Int Float, Int Float
    case Oper_Div               //Children - Int Float, Int Float
    case Oper_Bit_Left_Shift    //Children - Int Byte, Int ?
    case Oper_Bit_Right_Shift   //Children - Int Byte, Int ?
    case Oper_Bit_And           //Children - Int Byte, Int Byte
    case Oper_Bit_Or            //Children - Int Byte, Int Byte
    case Oper_Bit_Xor           //Children - Int Byte, Int Byte
    case Oper_Bit_Not           //Children - Int Byte, Int Byte
    //Logic Operators, 0x3X
    case Logic_Is_Equal         //Children - Expression, Expression
    case Logic_Is_Not_Equal     //Children - Expression, Expression
    case Logic_Bigger           //Children - Expression, Expression
    case Logic_Bigger_Equal     //Children - Expression, Expression
    case Logic_Lesser           //Children - Expression, Expression
    case Logic_Lesser_Equal     //Children - Expression, Expression
    case Logic_And              //Children - Expression, Expression                 //Proposal - Move to Operators
    case Logic_Or               //Children - Expression, Expression                 //Proposal - Move to Operators
    case Logic_Not              //Children - Expression, Expression                 //Proposal - Move to Operators
    //Jumps, 0x4X
    case JumpTo                 //Children - RefNamespace, RefLabel                 Purpose - Permenantly jumps to a (parent) execute block with a given label
    case SubRoutine             //Children - RefNamespace, RefLabel                 Purpose - Temporarily jumps to a (parent) execute block with a given label
    case Label                  //Children - Text                                   Purpose - Creates a new label in the process
    case RefLabel               //Children - Text                                   Purpose - Defines a location for a jump                                                                 Entry - Has none as it performs no edits to the registers
    case Recall                 //                                                  Purpose - Ends the current subroutine
    //Namespaces, 0x5X
    case Namespace              //Children - Text, [Execute]                        Purpose - Sets up a namespace for execute blocks                                                        Entry - Has none as it should never be used under an execute
    case RefNamespace           //Children - Text                                   Purpose - References a namespace for SubRoutine or JumpTo                                               Entry - Has none as it performs no edits to the registers
    //Other, 0x6X
    case If                     //Children - Condition, Execute(False), Execute(True)                                                                                                       Entry - Has none as the execution is in node preprocess
    case Execute                //Children - Any                                    Purpose - Execute a list of nodes                                                                       Entry - Has none as it performs no edits to the registers
    case Program                //Children - [Namespace]                            Purpose - Contains all nodes
    case CastText               //Children - Expression                             Purpose - Casts a type to text
    case CastReal_Int           //Children - Expression                             Purpose - Casts a type to Real_Int
    case CastReal_Float         //Children - Expression                             Purpose - Casts a type to Real_Float
}

//------Classes------
//Defines a Node as a class to make it a reference type
//Each node has a type and a child
class Node{
    //------Variables------
    //Defines the node's type
    //it is an Int using a byte format
    var type:UInt8
    //Adds a single piece of extra information, such as a name
    var operand:Any = ""
    //Stores the Node's children, this has to be a specific order
    var children:[Node] = [Node]()

    //------Initialiser------
    //Arguments:    -The type       -Byte
    //              -The operand    -Any
    //              -The children   -[Node ref]
    init(type:UInt8, operand:Any = "", children:[Node] = [Node]()){
        self.type = type
        self.operand = operand
        self.children = children
    }

    //------Procedures/Functions------
    //Preprocesses the node, i.e. pre-executes its children and returns whether pre-processing has finished
    //Arguments:    -The process                        -Ref Process
    //Returns:      -Whether processing has finished    -Bool
    func clockPrerocess(process:Process)->Bool{
        //Makes sure that only the first child of an if node is ran and then it performs the if execution
        if self.type == 0x60 && process.indexStack.last! == 1{                                                                                  //0x60 - If
            //Performs the if execution
            //------Pushes the branch node onto the nodeStack, increments the child index and adds a new index for the branch node
            //Sets the child index to be past all the children
            process.indexStack[process.indexStack.count - 1] = self.children.count + 1

            //Evaluates the condition
            let condition = process.registerStack.last!.value as! Bool; process.registerStack.removeLast() //Extracts the value and removes it from the stack
            //Adds an index of zero to the indexStack for the branch node
            process.indexStack.append(0)
            //Adds the corresponding branch to the nodeStack
            if condition{process.nodeStack.append(self.children[2])}else{process.nodeStack.append(self.children[1])}
            return false
        }
        //Returns true if there are no children or preprocessing has finished
        if self.children.count == 0 || process.indexStack.last! >= self.children.count{return true}
        //Adds the child to the nodeStack of the process
        process.nodeStack.append(self.children[process.indexStack.last!])
        //Adds one to the child index
        process.indexStack[process.indexStack.count - 1] += 1
        //Adds an index of zero to the indexStack for the next node
        process.indexStack.append(0)
        return false
    }
}