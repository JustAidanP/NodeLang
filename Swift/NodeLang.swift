//------Enumerators------
enum NodeType{
    //Vars
    case CreateVar              //Children - Name, GetVar(Optional)                 Purpose - Creates a variable in a given scope(getVar), default uses the stack scope
    case GetVar                 //Children - Name, GetVar(Optional)                 Purpose - Gets the variable from the given scope(getVar), default uses the stack scope
    case DeleteVar                 //Children - Name, GetVar(Optional)                 Purpose - Deletes the variable from the given scope(getVar), default uses the stack scope
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
    case For
    case While
    case RepeatExecute          //Children - Condition, Execute             //PROPOSED LOOP CODE
    case StopExecute            //Children - Condition, Execute
    case JumpTo
    case SubRoutine
    case Label
    case Recall
    //Other
    case Assign                 //Children - Name, GetVar(Optional), Expression     Purpose - Assigns a value to the variable int the given scope(getVar), default uses the stack scope
    case Execute                //Children - Any                                    Purpose - Execute a list of nodes
    case Namespace              //Children - Label, Execute                         Purpose - Stores subprocesses
}

//------Structures------
//Defines a Node
//Each node has a type and a child
struct Node{
    //------Variables------
    //Stores an association of all node types to an index
    static let nodeTypes:[NodeType] = [.CreateVar,.GetVar,.DeleteVar,.Text,.Number,.Boolean,.Oper_Add,.Oper_Sub,.Oper_Div,.Oper_Mult,.Logic_Is_Equal,.Logic_Is_Not_Equal,.Logic_Bigger,.Logic_Bigger_Equal,.Logic_Lesser,.Logic_Lesser_Equal,.Logic_And,.Logic_Or,.Logic_Not,.If,.While,.For,.Assign,.Execute]
    //Defines the node's type
    var type:NodeType
    //Adds a single piece of extra information, such as a name
    var operand:Any = ""
    //Stores the Node's children, this has to be a specific order
    var children:[Node] = [Node]()

    //------Procedures/Functions------
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
            // case .Logic_Bigger:
            //     //Gets the values of both children
            //     let lhs = self.children[0].execute(process: process) as! Float
            //     let rhs = self.children[1].execute(process: process) as! Float
            //     return lhs > rhs
            // case .Logic_Bigger_Equal:
            //     //Gets the values of both children
            //     let lhs = self.children[0].execute(process: process) as! Float
            //     let rhs = self.children[1].execute(process: process) as! Float
            //     return lhs >= rhs
            // case .Logic_Lesser:
            //     //Gets the values of both children
            //     let lhs = self.children[0].execute(process: process) as! Float
            //     let rhs = self.children[1].execute(process: process) as! Float
            //     return lhs < rhs
            // case .Logic_Lesser_Equal:
            //     //Gets the values of both children
            //     let lhs = self.children[0].execute(process: process) as! Float
            //     let rhs = self.children[1].execute(process: process) as! Float
            //     return lhs <= rhs
            // case .Logic_And:
            //     //Gets the values of both children
            //     let lhs = self.children[0].execute(process: process) as! Bool
            //     let rhs = self.children[1].execute(process: process) as! Bool
            //     return lhs && rhs
            // case .Logic_Or:
            //     //Gets the values of both children
            //     let lhs = self.children[0].execute(process: process) as! Bool
            //     let rhs = self.children[1].execute(process: process) as! Bool
            //     return lhs || rhs
            // case .Logic_Not:
                // return !(self.children[0].execute(process: process) as! Bool)
            default: break
        }
        return StringType(value:"")
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