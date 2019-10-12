//------Enumerators------
enum NodeType{
    //Vars
    case CreateVar              //Children - GetVar(Optional), Name                 Purpose - Creates a variable in a given scope(getVar), default uses the stack scope
    case GetVar                 //Children - GetVar(Optional), Name                 Purpose - Gets the variable from the given scope(getVar), default uses the stack scope
    case DeleteVar              //Children - GetVar(Optional), Name                 Purpose - Deletes the variable from the given scope(getVar), default uses the stack scope
    case Text                   //Operand  - Text
    case Number                 //Operand  - Number
    case Boolean                //Operand  - Boolean
    //Operators
    case Oper_Add               //Children - Expression, Expression
    case Oper_Sub               //Children - Expression, Expression
    case Oper_Div               //Children - Expression, Expression
    case Oper_Mult              //Children - Expression, Expression
    //Logic Operators
    case Logic_Is_Equal         //Children - Expression, Expression
    case Logic_Is_Not_Equal     //Children - Expression, Expression
    case Logic_Bigger           //Children - Expression, Expression
    case Logic_Bigger_Equal     //Children - Expression, Expression
    case Logic_Lesser           //Children - Expression, Expression
    case Logic_Lesser_Equal     //Children - Expression, Expression
    case Logic_And              //Children - Expression, Expression
    case Logic_Or               //Children - Expression, Expression
    case Logic_Not              //Children - Expression, Expression
    //Conditionals
    case If                     //Children - Condition, Execute(True), Execute(False)
    //Loops
    case JumpTo                 //Children - Label                                  Purpose - Permenantly jumps to a (parent) execute block with a given label
    case SubRoutine             //Children - Label                                  Purpose - Temporarily jumps to a (parent) execute block with a given label
    case Label                  //Children - Text                                   Purpose - Defines a location for a jump
    case Recall                 //                                                  Purpose - Ends the current subroutine
    //Namespaces
    case Namespace              //Children - Label, [Execute]                       Purpose - Sets up a namespace for execute blocks
    case RefNamespace           //Children - Text                                   Purpose - References a namespace for SubRoutine or JumpTo
    //Other
    case Assign                 //Children - GetVar(Optional), Name, Expression     Purpose - Assigns a value to the variable int the given scope(getVar), default uses the stack scope
    case Execute                //Children - Any                                    Purpose - Execute a list of nodes
}

//------Structures------
//Defines a Node
//Each node has a type and a child
struct Node{
    //------Variables------
    //Stores an association of all node types to an index
    static let nodeTypes:[NodeType] = [.CreateVar,.GetVar,.DeleteVar,.Text,.Number,.Boolean,.Oper_Add,.Oper_Sub,.Oper_Div,.Oper_Mult,.Logic_Is_Equal,.Logic_Is_Not_Equal,.Logic_Bigger,.Logic_Bigger_Equal,.Logic_Lesser,.Logic_Lesser_Equal,.Logic_And,.Logic_Or,.Logic_Not,.If,.JumpTo,.SubRoutine,.Assign,.Execute]
    //Defines the node's type
    var type:NodeType
    //Adds a single piece of extra information, such as a name
    var operand:Any = ""
    //Stores the Node's children, this has to be a specific order
    var children:[Node] = [Node]()

    //------Procedures/Functions------
    //Preprocesses the node, i.e. pre-executes its children and returns whether pre-processing has finished
    //Arguments:    -The process                        -Ref Process
    //Returns:      -Whether processing has finished    -Bool
    func clockPrerocess(process:_Process)->Bool{
        //Makes sure that only the first child of an if node is ran
        if self.type == .If && process.indexStack.last! >= 1{return true}
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
    //Runs the Node using the current process
    //Arguments:    -A process      -Process
    //Returns:      -An evaluation  -Any
    func execute(process:Process) -> VarType{
        let varScope = process.scopeStack.stack.last!
        //Switches through the Node's type
        switch self.type{
            //Executes every child node
            case .Execute: for child in self.children{var _ = child.execute(process: process)}
            //Primitives
            case .Text: return StringType(value:self.operand)
            case .Number: return (self.operand as? Int != nil) ? IntType(value:self.operand) : FloatType(value:self.operand as! Float) //Converts the number to FloatType
            case .Boolean: return BoolType(value:self.operand)
            //Handles variables
            case .CreateVar:
                //Checks if a getVar node has been assigned(for object declaration)
                if self.children.count >= 2{
                    if let scope = self.children[1].execute(process:process).value as? VariableScope{
                        scope.declareVar(name: self.children[0].execute(process: process).value as! String); return NullType()  //Declares a variable with the first child name
                }}
                //Creates a variable with the name of the child
                varScope.declareVar(name: self.children[0].execute(process: process).value as! String)
            case .DeleteVar:
                //Checks if a getVar node has been assigned(for object declaration)
                if self.children.count >= 2{
                    if let scope = self.children[1].execute(process:process).value as? VariableScope{
                        scope.deleteVar(name: self.children[0].execute(process: process).value as! String); return NullType()  //Deletes a variable with the first child name
                }}
                //Creates a variable with the name of the child
                varScope.deleteVar(name: self.children[0].execute(process: process).value as! String)
            case .GetVar:
                //Checks if a getVar node has been assigned(for object retrieval)
                if self.children.count >= 2{
                    if let scope = self.children[1].execute(process:process).value as? VariableScope{
                        return scope.getValue(name: self.children[0].execute(process: process).value as! String)    //Gets the variable with the first child name
                }}
                //Returns the value of the variable
                return varScope.getValue(name: self.children[0].execute(process: process).value as! String)
            case .Assign:
                //Checks if there is a third getVar node
                if self.children.count >= 3{
                    //Assigns the value to the object's variable name
                    //Evaluates the third node(getVar node)
                    if let scope = self.children[1].execute(process:process).value as? VariableScope{
                        scope.assignValue(name: self.children[0].execute(process: process).value as! String, value: self.children[2].execute(process: process)) //Sets the third child to the variable with the name of the first child
                        return NullType()   //Exits
                    }}
                //Assigns the second child's value to the first variable
                varScope.assignValue(name: self.children[0].execute(process: process).value as! String, value: self.children[1].execute(process: process))
            //Handles conditional branching
            case .If:
                //Evaluates the condition
                let condition = self.children[0].execute(process:process).value as! Bool
                //Runs the corresponding statment
                if condition{let _ = self.children[1].execute(process:process)}else{let _ = self.children[2].execute(process:process)}
            //Operators
            case .Oper_Add:
                //Extracts the values
                let lhs = self.children[0].execute(process: process).value
                let rhs = self.children[1].execute(process: process).value
                //Calls the addition operator
                if (lhs as? Int != nil) && (rhs as? Int != nil){return IntType.operator_add(lhs:lhs as! Int, rhs:rhs as! Int)}
                else if (lhs as? Float != nil) && (rhs as? Float != nil){return FloatType.operator_add(lhs:lhs as! Float, rhs:rhs as! Float)}
                //Returns NullType
                return NullType()
            case .Oper_Sub:
                //Extracts the values
                let lhs = self.children[0].execute(process: process).value
                let rhs = self.children[1].execute(process: process).value
                //Calls the subtraction operator
                if (lhs as? Int != nil) && (rhs as? Int != nil){return IntType.operator_sub(lhs:lhs as! Int, rhs:rhs as! Int)}
                else if (lhs as? Float != nil) && (rhs as? Float != nil){return FloatType.operator_sub(lhs:lhs as! Float, rhs:rhs as! Float)}
                //Returns NullType
                return NullType()
            case .Oper_Mult:
                //Extracts the values
                let lhs = self.children[0].execute(process: process).value
                let rhs = self.children[1].execute(process: process).value
                //Calls the multiplication operator
                if (lhs as? Int != nil) && (rhs as? Int != nil){return IntType.operator_mult(lhs:lhs as! Int, rhs:rhs as! Int)}
                else if (lhs as? Float != nil) && (rhs as? Float != nil){return FloatType.operator_mult(lhs:lhs as! Float, rhs:rhs as! Float)}
                //Returns NullType
                return NullType()
            case .Oper_Div:
                //Extracts the values
                let lhs = self.children[0].execute(process: process).value
                let rhs = self.children[1].execute(process: process).value
                //Calls the division operator
                if (lhs as? Int != nil) && (rhs as? Int != nil){return IntType.operator_div(lhs:lhs as! Int, rhs:rhs as! Int)}
                else if (lhs as? Float != nil) && (rhs as? Float != nil){return FloatType.operator_div(lhs:lhs as! Float, rhs:rhs as! Float)}
                //Returns NullType
                return NullType()
            //Logical Operators
            case .Logic_Is_Equal:
                //Extracts the values
                let lhs = self.children[0].execute(process: process).value
                let rhs = self.children[1].execute(process: process).value
                //Calls the logic is operator
                if (lhs as? Int != nil) && (rhs as? Int != nil){return IntType.Logic_Is_Equal(lhs:lhs as! Int, rhs:rhs as! Int)}
                else if (lhs as? Float != nil) && (rhs as? Float != nil){return FloatType.Logic_Is_Equal(lhs:lhs as! Float, rhs:rhs as! Float)}
                else if (lhs as? Bool != nil) && (rhs as? Bool != nil){return BoolType.Logic_Is_Equal(lhs:lhs as! Bool, rhs:rhs as! Bool)}
                else if (lhs as? String != nil) && (rhs as? String != nil){return StringType.Logic_Is_Equal(lhs:lhs as! String, rhs:rhs as! String)}
                //Returns NullType
                return NullType()
            case .Logic_Is_Not_Equal:
                //Extracts the values
                let lhs = self.children[0].execute(process: process).value
                let rhs = self.children[1].execute(process: process).value
                //Calls the logic is not operator
                if (lhs as? Int != nil) && (rhs as? Int != nil){return IntType.Logic_Is_Not_Equal(lhs:lhs as! Int, rhs:rhs as! Int)}
                else if (lhs as? Float != nil) && (rhs as? Float != nil){return FloatType.Logic_Is_Not_Equal(lhs:lhs as! Float, rhs:rhs as! Float)}
                else if (lhs as? Bool != nil) && (rhs as? Bool != nil){return BoolType.Logic_Is_Not_Equal(lhs:lhs as! Bool, rhs:rhs as! Bool)}
                else if (lhs as? String != nil) && (rhs as? String != nil){return StringType.Logic_Is_Not_Equal(lhs:lhs as! String, rhs:rhs as! String)}
                //Returns NullType
                return NullType()
            case .Logic_Bigger:
                //Extracts the values
                let lhs = self.children[0].execute(process: process).value
                let rhs = self.children[1].execute(process: process).value
                //Calls the logic bigger operator
                if (lhs as? Int != nil) && (rhs as? Int != nil){return IntType.Logic_Is_Bigger(lhs:lhs as! Int, rhs:rhs as! Int)}
                else if (lhs as? Float != nil) && (rhs as? Float != nil){return FloatType.Logic_Is_Bigger(lhs:lhs as! Float, rhs:rhs as! Float)}
                //Returns NullType
                return NullType()
            case .Logic_Bigger_Equal:
                //Extracts the values
                let lhs = self.children[0].execute(process: process).value
                let rhs = self.children[1].execute(process: process).value
                //Calls the logic bigger equal operator
                if (lhs as? Int != nil) && (rhs as? Int != nil){return IntType.Logic_Is_Bigger_Equal(lhs:lhs as! Int, rhs:rhs as! Int)}
                else if (lhs as? Float != nil) && (rhs as? Float != nil){return FloatType.Logic_Is_Bigger_Equal(lhs:lhs as! Float, rhs:rhs as! Float)}
                //Returns NullType
                return NullType()
            case .Logic_Lesser:
                //Extracts the values
                let lhs = self.children[0].execute(process: process).value
                let rhs = self.children[1].execute(process: process).value
                //Calls the logic lesser operator
                if (lhs as? Int != nil) && (rhs as? Int != nil){return IntType.Logic_Is_Lesser(lhs:lhs as! Int, rhs:rhs as! Int)}
                else if (lhs as? Float != nil) && (rhs as? Float != nil){return FloatType.Logic_Is_Lesser(lhs:lhs as! Float, rhs:rhs as! Float)}
                //Returns NullType
                return NullType()
            case .Logic_Lesser_Equal:
                //Extracts the values
                let lhs = self.children[0].execute(process: process).value
                let rhs = self.children[1].execute(process: process).value
                //Calls the logic lesser equal operator
                if (lhs as? Int != nil) && (rhs as? Int != nil){return IntType.Logic_Is_Lesser_Equal(lhs:lhs as! Int, rhs:rhs as! Int)}
                else if (lhs as? Float != nil) && (rhs as? Float != nil){return FloatType.Logic_Is_Lesser_Equal(lhs:lhs as! Float, rhs:rhs as! Float)}
                //Returns NullType
                return NullType()
            case .Logic_And:
                //Extracts the values
                let lhs = self.children[0].execute(process: process).value
                let rhs = self.children[1].execute(process: process).value
                //Calls the logic and operator
                if (lhs as? Bool != nil) && (rhs as? Bool != nil){return BoolType.Logic_And(lhs:lhs as! Bool, rhs:rhs as! Bool)}
                //Returns NullType
                return NullType()
            case .Logic_Or:
                //Extracts the values
                let lhs = self.children[0].execute(process: process).value
                let rhs = self.children[1].execute(process: process).value
                //Calls the logic or operator
                if (lhs as? Bool != nil) && (rhs as? Bool != nil){return BoolType.Logic_Or(lhs:lhs as! Bool, rhs:rhs as! Bool)}
                //Returns NullType
                return NullType()
            case .Logic_Not:
                //Extracts the values
                let lhs = self.children[0].execute(process: process).value
                //Calls the logic not operator
                if (lhs as? Bool != nil){return BoolType.Logic_Not(lhs:lhs as! Bool)}
                //Returns NullType
                return NullType()
            default: break
        }
        return NullType()
    }
}

//------Classes------
//Defines a Process object
//Handles execution
class Process{
    //Stores a scopeStack for the process
    var scopeStack:ScopeStack
    //------Initialiser------
    init(){
        //Creates a new scopeStack
        self.scopeStack = ScopeStack()
        //Pushes a variable scope to the scopeStack
        self.scopeStack.push(scope:VariableScope())
    }

    //------Procedures/Functions------
    //Runs the nodeTree
    func run(nodeTree:Node){
        nodeTree.execute(process:self)
        self.scopeStack.dump()
        print("Variable Container")
        VariableContainer.dump()
    }
    func testRun(){
        //Creates a variableScope
        self.scopeStack.stack.last!.declareVar(name:"num1")
        self.scopeStack.stack.last!.declareVar(name:"num2")
        self.scopeStack.stack.last!.declareVar(name:"compareTo")
        self.scopeStack.stack.last!.declareVar(name:"output")

        self.scopeStack.stack.last!.assignValue(name:"num1", value:IntType(value:12))
        self.scopeStack.stack.last!.assignValue(name:"num2", value:IntType(value:10))
        self.scopeStack.stack.last!.assignValue(name:"compareTo", value:IntType(value:22))

        let addNode = Node(type:.Oper_Add, children:[Node(type:.GetVar, children:[Node(type:.Text, operand:"num1")]), Node(type:.GetVar, children:[Node(type:.Text, operand:"num2")])])
        let operNode = Node(type:.Logic_Is_Equal, children:[addNode, Node(type:.GetVar, children:[Node(type:.Text, operand:"compareTo")])])

        let ifNode = Node(type:.If, children:[operNode, Node(type:.Assign, children:[Node(type:.Text, operand:"output"), Node(type:.Number, operand:Int(10))]), Node(type:.Assign, children:[Node(type:.Text, operand:"output"), Node(type:.Number, operand:Int(12))])])
        let _ = ifNode.execute(process:self)

        print(self.scopeStack.stack.last!.getValue(name:"output").value)
    }
}

//Handles the processing of an execution block
class _Process{
    //------Variables------
    //Stores a reference to the process manager
    var processManager:ProcessManager
    //Defines whether the process should be updating
    var shouldClock:Bool = true
    //Defines whether the process should be killed by the process manager
    var shouldKill:Bool = false
    //Stores the node tree
    var nodeTree:Node = Node(type:.Execute)
    //Stores the node stack
    var nodeStack:[Node] = [Node]()
    //Stores the index stack, index's the child of the current node
    var indexStack:[Int] = [0, 0]
    //Stores the register stack
    var registerStack:[VarType] = [VarType]()

    //------Initialiser------
    //Arguments:    -The process manager it belongs to  -ProcessManager
    //              -The node tree                      -Node
    init(_processManager:ProcessManager, _nodeTree:Node){
        self.processManager = _processManager
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
        if nodeStack.count == 0{shouldKill = true}
    }

    //Executes a node
    //Arguments:    -The node   -Node
    func execute(node:Node){
        //Removes the node from the node stack
        nodeStack.removeLast()

        //Switches through the Node's type
        switch node.type{
            //Primitives
            case .Text: registerStack.append(StringType(value:node.operand))
            case .Number: registerStack.append((node.operand as? Int != nil) ? IntType(value:node.operand) : FloatType(value:node.operand as! Float)) //Converts the number to FloatType
            case .Boolean: registerStack.append(BoolType(value:node.operand))
            //Handles variables
            case .CreateVar:
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
            case .DeleteVar:
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
            case .GetVar:
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
            case .Assign:
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
            //Handles conditional branching
            case .If:
                //------Pushes the branch node onto the nodeStack, increments the child index and adds a new index for the branch node
                //Sets the child index to be past all the children
                indexStack[indexStack.count - 1] = node.children.count + 1

                //Evaluates the condition
                let condition = registerStack.last!.value as! Bool; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Adds an index of zero to the indexStack for the branch node
                indexStack.append(0)
                //Adds the corresponding branch to the nodeStack
                if condition{nodeStack.append(node.children[2])}else{nodeStack.append(node.children[1])}
            //Operators
            case .Oper_Add:
                //Extracts the values
                let rhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                let lhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Calls the addition operator and appends the result to the register stack
                if (lhs as? Int != nil) && (rhs as? Int != nil){registerStack.append(IntType.operator_add(lhs:lhs as! Int, rhs:rhs as! Int))}
                else if (lhs as? Float != nil) && (rhs as? Float != nil){registerStack.append(FloatType.operator_add(lhs:lhs as! Float, rhs:rhs as! Float))}
                //Exits
                return
            case .Oper_Sub:
                //Extracts the values
                let rhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                let lhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Calls the subtraction operator and appends the result to the register stack
                if (lhs as? Int != nil) && (rhs as? Int != nil){registerStack.append(IntType.operator_sub(lhs:lhs as! Int, rhs:rhs as! Int))}
                else if (lhs as? Float != nil) && (rhs as? Float != nil){registerStack.append(FloatType.operator_sub(lhs:lhs as! Float, rhs:rhs as! Float))}
                //Exits
                return
            case .Oper_Mult:
                //Extracts the values
                let rhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                let lhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Calls the multiplication operator and appends the result to the register stack
                if (lhs as? Int != nil) && (rhs as? Int != nil){registerStack.append(IntType.operator_mult(lhs:lhs as! Int, rhs:rhs as! Int))}
                else if (lhs as? Float != nil) && (rhs as? Float != nil){registerStack.append(FloatType.operator_mult(lhs:lhs as! Float, rhs:rhs as! Float))}
                //Exits
                return
            case .Oper_Div:
                //Extracts the values
                let rhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                let lhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Calls the division operator and appends the result to the register stack
                if (lhs as? Int != nil) && (rhs as? Int != nil){registerStack.append(IntType.operator_div(lhs:lhs as! Int, rhs:rhs as! Int))}
                else if (lhs as? Float != nil) && (rhs as? Float != nil){registerStack.append(FloatType.operator_div(lhs:lhs as! Float, rhs:rhs as! Float))}
                //Exits
                return
            //Logical Operators
            case .Logic_Is_Equal:
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
            case .Logic_Is_Not_Equal:
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
            case .Logic_Bigger:
                //Extracts the values
                let rhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                let lhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Calls the logic bigger operator and appends the result to the register stack
                if (lhs as? Int != nil) && (rhs as? Int != nil){registerStack.append(IntType.Logic_Is_Bigger(lhs:lhs as! Int, rhs:rhs as! Int))}
                else if (lhs as? Float != nil) && (rhs as? Float != nil){registerStack.append(FloatType.Logic_Is_Bigger(lhs:lhs as! Float, rhs:rhs as! Float))}
                //Exits
                return
            case .Logic_Bigger_Equal:
                //Extracts the values
                let rhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                let lhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Calls the logic bigger equal operator and appends the result to the register stack
                if (lhs as? Int != nil) && (rhs as? Int != nil){registerStack.append(IntType.Logic_Is_Bigger_Equal(lhs:lhs as! Int, rhs:rhs as! Int))}
                else if (lhs as? Float != nil) && (rhs as? Float != nil){registerStack.append(FloatType.Logic_Is_Bigger_Equal(lhs:lhs as! Float, rhs:rhs as! Float))}
                //Exits
                return
            case .Logic_Lesser:
                //Extracts the values
                let rhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                let lhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Calls the logic lesser operator and appends the result to the register stack
                if (lhs as? Int != nil) && (rhs as? Int != nil){registerStack.append(IntType.Logic_Is_Lesser(lhs:lhs as! Int, rhs:rhs as! Int))}
                else if (lhs as? Float != nil) && (rhs as? Float != nil){registerStack.append(FloatType.Logic_Is_Lesser(lhs:lhs as! Float, rhs:rhs as! Float))}
                //Exits
                return
            case .Logic_Lesser_Equal:
                //Extracts the values
                let rhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                let lhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Calls the logic lesser equal operator and appends the result to the register stack
                if (lhs as? Int != nil) && (rhs as? Int != nil){registerStack.append(IntType.Logic_Is_Lesser_Equal(lhs:lhs as! Int, rhs:rhs as! Int))}
                else if (lhs as? Float != nil) && (rhs as? Float != nil){registerStack.append(FloatType.Logic_Is_Lesser_Equal(lhs:lhs as! Float, rhs:rhs as! Float))}
                //Exits
                return
            case .Logic_And:
                //Extracts the values
                let rhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                let lhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Calls the logic and operator and appends the result to the register stack
                if (lhs as? Bool != nil) && (rhs as? Bool != nil){registerStack.append(BoolType.Logic_And(lhs:lhs as! Bool, rhs:rhs as! Bool))}
                //Exits
                return
            case .Logic_Or:
                //Extracts the values
                let rhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                let lhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Calls the logic or operator and appends the result to the register stack
                if (lhs as? Bool != nil) && (rhs as? Bool != nil){registerStack.append(BoolType.Logic_Or(lhs:lhs as! Bool, rhs:rhs as! Bool))}
                //Exits
                return
            case .Logic_Not:
                //Extracts the values
                let lhs = registerStack.last!.value; registerStack.removeLast() //Extracts the value and removes it from the stack
                //Calls the logic not operator
                if (lhs as? Bool != nil){registerStack.append(BoolType.Logic_Not(lhs:lhs as! Bool))}
                //Exits
                return
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
    //Stores all processes to be executed
    var processes:[_Process] = [_Process]()
    //------Initialiser------
    init(){
        //Creates the scope stack
        self.scopeStack = ScopeStack()
        //Pushes a variable scope to the scopeStack
        self.scopeStack.push(scope:VariableScope())
    }
    //------Procedures/Functions------
    //Runs all processes indefinately
    func run(){
        while true{
            //Runs every process
            for i in 0..<processes.count{
                let process = processes[i]
                if process.shouldKill{processes.remove(at:i)}
                else if process.shouldClock{process.clock(); continue}
                return
            }
        }
    }
    //Runs for x number of clock cycles, a single clock sends one clock pulse to every process
    //Arguments:    -No. of clocks  -Int
    func runClocks(clocks:Int){}
    //Stops execution
    func stop(){}
}