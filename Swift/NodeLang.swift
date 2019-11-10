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
    case Text                   //Operand  - Text
    case Real_Int               //Operand  - Int
    case Real_Float             //Operand  - Float
    case Boolean                //Operand  - Boolean
    //Operators, 0x2X
    case Oper_Add               //Children - Expression, Expression
    case Oper_Sub               //Children - Expression, Expression
    case Oper_Mult              //Children - Expression, Expression
    case Oper_Div               //Children - Expression, Expression
    //Logic Operators, 0x3X
    case Logic_Is_Equal         //Children - Expression, Expression
    case Logic_Is_Not_Equal     //Children - Expression, Expression
    case Logic_Bigger           //Children - Expression, Expression
    case Logic_Bigger_Equal     //Children - Expression, Expression
    case Logic_Lesser           //Children - Expression, Expression
    case Logic_Lesser_Equal     //Children - Expression, Expression
    case Logic_And              //Children - Expression, Expression
    case Logic_Or               //Children - Expression, Expression
    case Logic_Not              //Children - Expression, Expression
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
    case If                     //Children - Condition, Execute(False), Execute(True)
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
        //Makes sure that only the first child of an if node is ran
        if self.type == 0x60 && process.indexStack.last! >= 1{return true}                              //0x60 - If
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

//Handles the processing of an execution block
class Process{
    //------Variables------
    //Stores a reference to the process manager
    var processManager:ProcessManager
    //Stores the parent of the process(if it has one)
    var processParent:Process? = nil
    //Defines whether the process should be updating
    var shouldClock:Bool = true
    //Defines whether the process should be killed by the process manager
    var shouldKill:Bool = false
    //Stores the node tree
    var nodeTree:Node = Node(type:0x61)                                         //0x61 - Execute
    //Stores the node stack
    var nodeStack:[Node] = [Node]()
    //Stores the index stack, index's the child of the current node
    var indexStack:[Int] = [0, 0]
    //Stores the register stack
    var registerStack:[VarType] = [VarType]()
    //Stores the labels found of the process
    var labels:[String:NodeState] = [String:NodeState]()

    //------Initialiser------
    //Arguments:    -The process manager it belongs to  -ProcessManager ref
    //              -The process parent                 -Process ref            -Nil
    //              -The node tree                      -Node
    init(_processManager:ProcessManager, _processParent:Process? = nil, _nodeTree:Node){
        self.processManager = _processManager
        self.processParent = _processParent
        self.nodeTree = _nodeTree

        //Adds the nodeTree as the first node in nodeStack
        nodeStack = [nodeTree]
    }

    //------Procedures/Functions------
    //Clocks the process, provides an update outlet
    func clock(){
        //Extracts the currentNode
        let currentNode = nodeStack.last!
        //Clocks the node preprocessing and stops clocking if it hasn't finished
        if !currentNode.clockPrerocess(process: self){return}
        //Removes the indexing for the child of the node
        indexStack.removeLast()

        //Executes the node
        execute(node:currentNode)

        //Finishes the process if the nodes have finished running, this happens when the length of nodeStack is none
        if nodeStack.count == 0{
            shouldKill = true
            //Recalls the process if it has a parent process
            guard let parent = self.processParent else{return}
            //Sets the parent to run again              //------Change for Async
            parent.shouldClock = true
        }
    }

    //Executes a node
    //Arguments:    -The node   -Node
    func execute(node:Node){
        //Removes the node from the node stack
        nodeStack.removeLast()
        //Switches through the Node's type
        switch node.type{
            //Handles variables
            case 0x00: //CreateVar
                var varScope = processManager.scopeStack.stack.last!
                //Extracts the name
                let name = registerStack.last!.value as! String; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Checks if the children count reflects there being a getVar and then overwrites the varScope to be the scope in the register
                if node.children.count >= 2{
                    if let _ = registerStack.last!.value as? VariableScope{
                        varScope = registerStack.last!.value as! VariableScope; registerStack.removeLast() //Extracts the value and removes it from the stack
                    }}
                //Creates a variable with the name of the child
                varScope.declareVar(name: name)
            case 0x01: //GetVar
                var varScope = processManager.scopeStack.stack.last!
                //Extracts the name
                let name = registerStack.last!.value as! String; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Checks if the children count reflects there being a getVar and then overwrites the varScope to be the scope in the register
                if node.children.count >= 2{
                    if let _ = registerStack.last!.value as? VariableScope{
                        varScope = registerStack.last!.value as! VariableScope; registerStack.removeLast() //Extracts the value and removes it from the stack
                    }}
                //Adds the value of the variable to the registerStack
                registerStack.append(varScope.getValue(name: name))
            case 0x02: //DeleteVar
                var varScope = processManager.scopeStack.stack.last!
                //Extracts the name
                let name = registerStack.last!.value as! String; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Checks if the children count reflects there being a getVar and then overwrites the varScope to be the scope in the register
                if node.children.count >= 2{
                    if let _ = registerStack.last!.value as? VariableScope{
                        varScope = registerStack.last!.value as! VariableScope; registerStack.removeLast() //Extracts the value and removes it from the stack
                    }}
                //Deletes the variable with the name
                varScope.deleteVar(name: name)
            case 0x03: //GetLink
                var varScope = processManager.scopeStack.stack.last!
                //Extracts the name
                let name = registerStack.last!.value as! String; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Checks if the children count reflects there being a getVar and then overwrites the varScope to be the scope in the register
                if node.children.count >= 2{
                    if let _ = registerStack.last!.value as? VariableScope{
                        varScope = registerStack.last!.value as! VariableScope; registerStack.removeLast() //Extracts the value and removes it from the stack
                    }}
                //Adds the value of the variable to the registerStack
                registerStack.append(varScope.getLink(name: name))
            case 0x04: //Link
                var varScope = processManager.scopeStack.stack.last!
                //Extracts the value
                let link = registerStack.last! as! Int; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Extracts the name
                let name = registerStack.last!.value as! String; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Checks if the children count reflects there being a getVar and then overwrites the varScope to be the scope in the register
                if node.children.count >= 3{
                    //Checks if the value in the register is a variable scope
                    if let _ = registerStack.last!.value as? VariableScope{
                        varScope = registerStack.last!.value as! VariableScope; registerStack.removeLast() //Extracts the value and removes it from the stack
                    }}
                //Creates a link for the variable
                varScope.setLink(name: name, link: link)
            case 0x05: //Unlink
                var varScope = processManager.scopeStack.stack.last!
                //Extracts the name
                let name = registerStack.last!.value as! String; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Checks if the children count reflects there being a getVar and then overwrites the varScope to be the scope in the register
                if node.children.count >= 2{
                    if let _ = registerStack.last!.value as? VariableScope{
                        varScope = registerStack.last!.value as! VariableScope; registerStack.removeLast() //Extracts the value and removes it from the stack
                    }}
                //Adds the value of the variable to the registerStack
                varScope.removeLink(name: name)
            case 0x06: //Assign
                //Extracts the var scope
                var varScope = processManager.scopeStack.stack.last!
                //Extracts the value
                let value = registerStack.last!; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Extracts the name
                let name = registerStack.last!.value as! String; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Checks if the children count reflects there being a getVar and then overwrites the varScope to be the scope in the register
                if node.children.count >= 3{
                    //Checks if the value in the register is a variable scope
                    if let _ = registerStack.last!.value as? VariableScope{
                        varScope = registerStack.last!.value as! VariableScope; registerStack.removeLast() //Extracts the value and removes it from the stack
                    }}
                //Assigns the second child's value to the first variable
                varScope.assignValue(name: name, value: value)
            //Primitives
            case 0x11: //Text 
                registerStack.append(StringType(value:node.operand))
            case 0x12: //Real_Int
                registerStack.append(IntType(value:node.operand)) //Converts the number to IntType
            case 0x13: //Real_Float
                registerStack.append(FloatType(value:node.operand as! Float)) //Converts the number to FloatType
            case 0x14: //Boolean 
                registerStack.append(BoolType(value:node.operand))
            case 0x15: //Object
                registerStack.append(ObjectType(value:VariableScope()))
            //Operators
            case 0x20: //Oper_Add
                //Extracts the values
                let rhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                let lhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Calls the addition operator and appends the result to the register stack
                if (lhs as? Int != nil) && (rhs as? Int != nil){registerStack.append(IntType.operator_add(lhs:lhs as! Int, rhs:rhs as! Int))}
                else if (lhs as? Float != nil) && (rhs as? Float != nil){registerStack.append(FloatType.operator_add(lhs:lhs as! Float, rhs:rhs as! Float))}
                //Exits
                return
            case 0x21: //Oper_Sub
                //Extracts the values
                let rhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                let lhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Calls the subtraction operator and appends the result to the register stack
                if (lhs as? Int != nil) && (rhs as? Int != nil){registerStack.append(IntType.operator_sub(lhs:lhs as! Int, rhs:rhs as! Int))}
                else if (lhs as? Float != nil) && (rhs as? Float != nil){registerStack.append(FloatType.operator_sub(lhs:lhs as! Float, rhs:rhs as! Float))}
                //Exits
                return
            case 0x22: //Oper_Mult
                //Extracts the values
                let rhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                let lhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Calls the multiplication operator and appends the result to the register stack
                if (lhs as? Int != nil) && (rhs as? Int != nil){registerStack.append(IntType.operator_mult(lhs:lhs as! Int, rhs:rhs as! Int))}
                else if (lhs as? Float != nil) && (rhs as? Float != nil){registerStack.append(FloatType.operator_mult(lhs:lhs as! Float, rhs:rhs as! Float))}
                //Exits
                return
            case 0x23: //Oper_Div
                //Extracts the values
                let rhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                let lhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Calls the division operator and appends the result to the register stack
                if (lhs as? Int != nil) && (rhs as? Int != nil){registerStack.append(IntType.operator_div(lhs:lhs as! Int, rhs:rhs as! Int))}
                else if (lhs as? Float != nil) && (rhs as? Float != nil){registerStack.append(FloatType.operator_div(lhs:lhs as! Float, rhs:rhs as! Float))}
                //Exits
                return
            //Logical Operators
            case 0x30: //Logic_Is_Equal
                //Extracts the values
                let rhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                let lhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Calls the logic is operator and appends the result to the register stack
                if (lhs as? Int != nil) && (rhs as? Int != nil){registerStack.append(IntType.Logic_Is_Equal(lhs:lhs as! Int, rhs:rhs as! Int))}
                else if (lhs as? Float != nil) && (rhs as? Float != nil){registerStack.append(FloatType.Logic_Is_Equal(lhs:lhs as! Float, rhs:rhs as! Float))}
                else if (lhs as? Bool != nil) && (rhs as? Bool != nil){registerStack.append(BoolType.Logic_Is_Equal(lhs:lhs as! Bool, rhs:rhs as! Bool))}
                else if (lhs as? String != nil) && (rhs as? String != nil){registerStack.append(StringType.Logic_Is_Equal(lhs:lhs as! String, rhs:rhs as! String))}
                //Exits
                return
            case 0x31: //Logic_Is_Not_Equal
                //Extracts the values
                let rhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                let lhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Calls the logic is not operator and appends the result to the register stack
                if (lhs as? Int != nil) && (rhs as? Int != nil){registerStack.append(IntType.Logic_Is_Not_Equal(lhs:lhs as! Int, rhs:rhs as! Int))}
                else if (lhs as? Float != nil) && (rhs as? Float != nil){registerStack.append(FloatType.Logic_Is_Not_Equal(lhs:lhs as! Float, rhs:rhs as! Float))}
                else if (lhs as? Bool != nil) && (rhs as? Bool != nil){registerStack.append(BoolType.Logic_Is_Not_Equal(lhs:lhs as! Bool, rhs:rhs as! Bool))}
                else if (lhs as? String != nil) && (rhs as? String != nil){registerStack.append(StringType.Logic_Is_Not_Equal(lhs:lhs as! String, rhs:rhs as! String))}
                //Exits
                return
            case 0x32: //Logic_Bigger
                //Extracts the values
                let rhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                let lhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Calls the logic bigger operator and appends the result to the register stack
                if (lhs as? Int != nil) && (rhs as? Int != nil){registerStack.append(IntType.Logic_Is_Bigger(lhs:lhs as! Int, rhs:rhs as! Int))}
                else if (lhs as? Float != nil) && (rhs as? Float != nil){registerStack.append(FloatType.Logic_Is_Bigger(lhs:lhs as! Float, rhs:rhs as! Float))}
                //Exits
                return
            case 0x33: //Logic_Bigger_Equal
                //Extracts the values
                let rhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                let lhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Calls the logic bigger equal operator and appends the result to the register stack
                if (lhs as? Int != nil) && (rhs as? Int != nil){registerStack.append(IntType.Logic_Is_Bigger_Equal(lhs:lhs as! Int, rhs:rhs as! Int))}
                else if (lhs as? Float != nil) && (rhs as? Float != nil){registerStack.append(FloatType.Logic_Is_Bigger_Equal(lhs:lhs as! Float, rhs:rhs as! Float))}
                //Exits
                return
            case 0x34: //Logic_Lesser
                //Extracts the values
                let rhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                let lhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Calls the logic lesser operator and appends the result to the register stack
                if (lhs as? Int != nil) && (rhs as? Int != nil){registerStack.append(IntType.Logic_Is_Lesser(lhs:lhs as! Int, rhs:rhs as! Int))}
                else if (lhs as? Float != nil) && (rhs as? Float != nil){registerStack.append(FloatType.Logic_Is_Lesser(lhs:lhs as! Float, rhs:rhs as! Float))}
                //Exits
                return
            case 0x35: //Logic_Lesser_Equal
                //Extracts the values
                let rhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                let lhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Calls the logic lesser equal operator and appends the result to the register stack
                if (lhs as? Int != nil) && (rhs as? Int != nil){registerStack.append(IntType.Logic_Is_Lesser_Equal(lhs:lhs as! Int, rhs:rhs as! Int))}
                else if (lhs as? Float != nil) && (rhs as? Float != nil){registerStack.append(FloatType.Logic_Is_Lesser_Equal(lhs:lhs as! Float, rhs:rhs as! Float))}
                //Exits
                return
            case 0x36: //Logic_And
                //Extracts the values
                let rhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                let lhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Calls the logic and operator and appends the result to the register stack
                if (lhs as? Bool != nil) && (rhs as? Bool != nil){registerStack.append(BoolType.Logic_And(lhs:lhs as! Bool, rhs:rhs as! Bool))}
                //Exits
                return
            case 0x37: //Logic_Or
                //Extracts the values
                let rhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                let lhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Calls the logic or operator and appends the result to the register stack
                if (lhs as? Bool != nil) && (rhs as? Bool != nil){registerStack.append(BoolType.Logic_Or(lhs:lhs as! Bool, rhs:rhs as! Bool))}
                //Exits
                return
            case 0x38: //Logic_Not
                //Extracts the values
                let lhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Calls the logic not operator
                if (lhs as? Bool != nil){registerStack.append(BoolType.Logic_Not(lhs:lhs as! Bool))}
                //Exits
                return
            //Jumps
            case 0x40: //JumpTo
                //Jumps the process to the nodestate of the label
                //Extracts the name of the label from the top register
                let labelName = registerStack.last!.value as! String; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Checks if the children count reflects there being a refNamespace
                if node.children.count >= 2{
                    //Extracts the name of the namespace
                    let nsName = registerStack.last!.value as! String; registerStack.removeLast() //Extracts the value and removes it from the stack
                    //Extracts the namespace with the correct name
                    for ns in processManager.namespaces{
                        if ns.name == nsName{
                            //Finds the correct label
                            guard let label = ns.labels[labelName] else{return}
                            //Overwrites the nodeStack and indexStack
                            nodeStack = label.nodeStack
                            indexStack = label.indexStack
                            return  //Exits
                        }}}
                //Finds the correct label
                guard let label = labels[labelName] else{return}
                //Overwrites the nodeStack and indexStack
                nodeStack = label.nodeStack
                indexStack = label.indexStack
                return  //Exits
            case 0x41: //SubRoutine
                //Creates a new process for the nodestate of the label
                //Extracts the name of the label from the top register
                let labelName = registerStack.last!.value as! String; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Checks if the children count reflects there being a refNamespace
                if node.children.count >= 2{
                    //Extracts the name of the namespace
                    let nsName = registerStack.last!.value as! String; registerStack.removeLast() //Extracts the value and removes it from the stack
                    //Extracts the namespace with the correct name
                    for ns in processManager.namespaces{
                        if ns.name == nsName{
                            //Finds the correct label
                            guard let label = ns.labels[labelName] else{return}
                            //Sets this process to not clock
                            self.shouldClock = false
                            //Creates a new process
                            self.processManager.createProcess(label:label, processParent:self)
                            return  //Exits
                        }}}
                //Finds the correct label
                guard let label = labels[labelName] else{return}
                //Sets this process to not clock
                self.shouldClock = false
                //Creates a new process
                self.processManager.createProcess(label:label, processParent:self)
                return  //Exits
            case 0x42: //Label
                //Creates a new label in the current process with the given name
                let labelName = registerStack.last!.value as! String; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Adds a nodeState to the process
                labels[labelName] = NodeState(nodeStack:nodeStack, indexStack:indexStack)
                break
            case 0x44: //Recall
                //Sets the current process to end
                shouldKill = true
                //If the process has a process, it sets it to clock
                if let parent = self.processParent{parent.shouldClock = true}           //------Change for Async
                //Exits
                return
            //Handles other branching
            case 0x60: //If 
                //------Pushes the branch node onto the nodeStack, increments the child index and adds a new index for the branch node
                //Sets the child index to be past all the children
                indexStack[indexStack.count - 1] = node.children.count + 1

                //Evaluates the condition
                let condition = registerStack.last!.value as! Bool; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Adds an index of zero to the indexStack for the branch node
                indexStack.append(0)
                //Adds the corresponding branch to the nodeStack
                if condition{nodeStack.append(node.children[2])}else{nodeStack.append(node.children[1])}
            case 0x63: //CastText
                let value = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                if (value as? Int != nil){registerStack.append(IntType(value:String(value as! Int)))}
                else if (value as? Float != nil){registerStack.append(IntType(value:String(value as! Float)))}
                else if (value as? Bool != nil){registerStack.append(StringType(value: String((value as! Bool) ? 1 : 0)))}
                else{registerStack.append(NullType())}
            case 0x64: //CastReal_Int
                let value = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Checks if the value is string
                if (value as? String != nil){
                    //Checks if the string can convert to an int
                    if let cast = Int(value as! String){registerStack.append(IntType(value:cast))}
                    else{registerStack.append(NullType())}
                }//Checks if the value is a float
                else if (value as? Float != nil){registerStack.append(IntType(value:Int(value as! Float)))}
                //Checks if the value is a boolean
                else if (value as? Bool != nil){registerStack.append(IntType(value: (value as! Bool) ? 1 : 0))}
                //Otherwise null is return
                else{registerStack.append(NullType())}
            case 0x65: //CastReal_Float
                let value = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Checks if the value is string
                if (value as? String != nil){
                    //Checks if the string can convert to an int
                    if let cast = Float(value as! String){registerStack.append(FloatType(value:cast))}
                    else{registerStack.append(NullType())}
                }//Checks if the value is an Int
                else if (value as? Int != nil){registerStack.append(FloatType(value:Float(value as! Int)))}
                //Checks if the value is a boolean
                else if (value as? Bool != nil){registerStack.append(FloatType(value: (value as! Bool) ? Float(1) : Float(0)))}
                //Otherwise null is return
                else{registerStack.append(NullType())}
            default: break
        }
        return
    }
}
//This handles management of processes
class ProcessManager{
    //------Variables------
    //Stores the scope stack
    var scopeStack:ScopeStack
    //Stores a list of namespaces
    var namespaces:[Namespace] = [Namespace]()
    //Stores all processes to be executed
    var processes:[Process] = [Process]()

    //------Initialiser------
    init(){
        //Creates the scope stack
        self.scopeStack = ScopeStack()
        //Pushes a variable scope to the scopeStack
        self.scopeStack.push(scope:VariableScope())
    }
    //------Procedures/Functions------
    //Configurates the program nodeTree to determine all namespaces
    //Arguments:    -The node tree  -Node
    func configurate(nodeTree:Node){
        //Checks if the root node is a program node
        if nodeTree.type == 0x62{                                                               //0x62 - Program
            //Loops through every child to get all the namespaces
            for node in nodeTree.children{
                //Makes sure that the node is a namespace
                if node.type != 0x50{continue}                                                  //0x50 - Namespace
                //Extracts the name of the child, text
                let name = node.children[0].operand as! String
                //Creates a new namespace with a placeholder nodestate
                var ns = Namespace(name:name, labels:[String:NodeState]())
                //Searches through all the other children to identify labels
                for i in 1..<node.children.count{
                    //Extracts the execute node
                    let execute = node.children[i]
                    //Makes sure that the execute has a label
                    if execute.children[0].type != 0x42{continue}                               //0x42 - Label
                    //Creates a NodeState for the node with a starting index past the label
                    let nodeState = NodeState(nodeStack:[execute], indexStack:[0, 1])
                    
                    //Extracts the name of the execute
                    let labelName = execute.children[0].children[0].operand as! String
                    //Detects if the execute is the entry point
                    if name == "main" && labelName == "main"{
                        createProcess(label:nodeState)
                    }else{
                        //Adds the nodestate to the namespace as a label associated with the name
                        ns.labels[labelName] = nodeState
                    }
                }
                //Adds the namespace to namespaces
                self.namespaces.append(ns)
            }
        }
    }
    //Creates a new process from a label
    //Arguments:    -Label              -NodeState
    //              -The process parent -Process    -Nil
    func createProcess(label:NodeState, processParent:Process? = nil){
        //Creates the process
        let process = Process(_processManager:self, _nodeTree:label.nodeStack[label.nodeStack.count - 1])
        //Adds the processParent to the process, if it was passed
        process.processParent = processParent
        //Sets the index stack to the process
        process.indexStack = label.indexStack
        //Adds the process to the manager
        self.processes.append(process)
    }
    //Runs all processes indefinately
    func run(){
        while true{
            //Stores whether a process got clocked
            var processClocked = false
            //Runs every process
            for i in 0..<processes.count{
                let process = processes[i]
                if process.shouldKill{processes.remove(at:i)}
                else if process.shouldClock{process.clock(); processClocked = true; continue}
            }
            if !processClocked{return}
        }
    }
    //Runs for x number of clock cycles, a single clock sends one clock pulse to every process
    //Arguments:    -No. of clocks  -Int
    func runClocks(clocks:Int){
        for _ in 0..<clocks{
            //Runs every process
            for i in 0..<processes.count{
                let process = processes[i]
                if process.shouldKill{processes.remove(at:i)}
                else if process.shouldClock{process.clock(); continue}
                return
            }
        }
    }
    //Stops execution
    func stop(){}
}