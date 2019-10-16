//------Protocol------
//Defines a varType, this is a parent for all variable types
protocol VarType{
    var type:Int {get}
    var value:Any {get set}
    //------Procedures/Functions------
    //Produces a string representation
    //Returns:  -A dump -String
    func getDump() -> String
}
//------Structures------
//Stores all of the different variable types
struct NullType:VarType{
    var type:Int = -1
    var value:Any = 0
    //------Procedures/Functions------
    //Produces a string representation
    //Returns:  -A dump -String
    func getDump() -> String{return "\(type), \(value)"}
}
//Stores all of the different variable types
struct IntType:VarType{
    var type:Int = 0
    var value:Any
    //------Operator Overloading------
    static func operator_add(lhs:Int, rhs:Int) -> IntType{return IntType(value:lhs + rhs)}
    static func operator_sub(lhs:Int, rhs:Int) -> IntType{return IntType(value:lhs - rhs)}
    static func operator_mult(lhs:Int, rhs:Int) -> IntType{return IntType(value:lhs * rhs)}
    static func operator_div(lhs:Int, rhs:Int) -> IntType{return IntType(value:lhs / rhs)}
    //------Logical Operator Overloading------
    static func Logic_Is_Equal(lhs:Int, rhs:Int) -> BoolType{return BoolType(value: lhs == rhs)}
    static func Logic_Is_Not_Equal(lhs:Int, rhs:Int) -> BoolType{return BoolType(value: lhs != rhs)}
    static func Logic_Is_Bigger(lhs:Int, rhs:Int) -> BoolType{return BoolType(value: lhs > rhs)}
    static func Logic_Is_Bigger_Equal(lhs:Int, rhs:Int) -> BoolType{return BoolType(value: lhs >= rhs)}
    static func Logic_Is_Lesser(lhs:Int, rhs:Int) -> BoolType{return BoolType(value: lhs < rhs)}
    static func Logic_Is_Lesser_Equal(lhs:Int, rhs:Int) -> BoolType{return BoolType(value: lhs <= rhs)}
    //------Procedures/Functions------
    //Produces a string representation
    //Returns:  -A dump -String
    func getDump() -> String{return "\(type), \(value)"}
}
struct FloatType:VarType{
    var type:Int = 1
    var value:Any
    //------Operator Overloading------
    static func operator_add(lhs:Float, rhs:Float) -> FloatType{return FloatType(value:lhs + rhs)}
    static func operator_sub(lhs:Float, rhs:Float) -> FloatType{return FloatType(value:lhs - rhs)}
    static func operator_mult(lhs:Float, rhs:Float) -> FloatType{return FloatType(value:lhs * rhs)}
    static func operator_div(lhs:Float, rhs:Float) -> FloatType{return FloatType(value:lhs / rhs)}
    //------Logical Operator Overloading------
    static func Logic_Is_Equal(lhs:Float, rhs:Float) -> BoolType{return BoolType(value: lhs == rhs)}
    static func Logic_Is_Not_Equal(lhs:Float, rhs:Float) -> BoolType{return BoolType(value: lhs != rhs)}
    static func Logic_Is_Bigger(lhs:Float, rhs:Float) -> BoolType{return BoolType(value: lhs > rhs)}
    static func Logic_Is_Bigger_Equal(lhs:Float, rhs:Float) -> BoolType{return BoolType(value: lhs >= rhs)}
    static func Logic_Is_Lesser(lhs:Float, rhs:Float) -> BoolType{return BoolType(value: lhs < rhs)}
    static func Logic_Is_Lesser_Equal(lhs:Float, rhs:Float) -> BoolType{return BoolType(value: lhs <= rhs)}
    //------Procedures/Functions------
    //Produces a string representation
    //Returns:  -A dump -String
    func getDump() -> String{return "\(type), \(value)"}
}
struct BoolType:VarType{
    var type:Int = 2
    var value:Any
    //------Logical Operator Overloading------
    static func Logic_Is_Equal(lhs:Bool, rhs:Bool) -> BoolType{return BoolType(value: lhs == rhs)}
    static func Logic_Is_Not_Equal(lhs:Bool, rhs:Bool) -> BoolType{return BoolType(value: lhs != rhs)}
    static func Logic_And(lhs:Bool, rhs:Bool) -> BoolType{return BoolType(value: lhs && rhs)}
    static func Logic_Or(lhs:Bool, rhs:Bool) -> BoolType{return BoolType(value: lhs || rhs)}
    static func Logic_Not(lhs:Bool) -> BoolType{return BoolType(value: !lhs)}
    //------Procedures/Functions------
    //Produces a string representation
    //Returns:  -A dump -String
    func getDump() -> String{return "\(type), \(value)"}
}
struct StringType:VarType{
    var type:Int = 3
    var value:Any
    //------Logical Operator Overloading------
    static func Logic_Is_Equal(lhs:String, rhs:String) -> BoolType{return BoolType(value: lhs == rhs)}
    static func Logic_Is_Not_Equal(lhs:String, rhs:String) -> BoolType{return BoolType(value: lhs != rhs)}
    //------Procedures/Functions------
    //Produces a string representation
    //Returns:  -A dump -String
    func getDump() -> String{return "\(type), \(value)"}
}
struct ObjectType:VarType{
    var type:Int = 4
    var value:Any
    //------Procedures/Functions------
    //Produces a string representation
    //Returns:  -A dump -String
    func getDump() -> String{return "\(type), \(value)"}
}

//------Classes------
//Defines a variable container
//Stores every varible created
class VariableContainer{
    //------Variables------
    //Stores all variables in a list
    static var variableContainer:[VarType] = []
    //Stores a set of all available index, i.e. where vars have been removed
    static var availableIndex:[Int] = []
    //------Procedures/Functions-------
    //Adds a variable to the first available slot
    //Arguments:    -A variable -VarType
    //Returns:      -An index   -Int
    static func addVar(_ variable:VarType) -> Int{
        //Appends the variable if there are no available index
        if VariableContainer.availableIndex.count == 0{
            VariableContainer.variableContainer.append(variable)
            //Returns the index into the list
            return VariableContainer.variableContainer.count - 1
        }
        //Adds the variable to the first available index
        let index = VariableContainer.availableIndex[0]
        VariableContainer.variableContainer[index] = variable
        //Removes the index from the available list
        VariableContainer.availableIndex.remove(at:0)
        //Returns the index
        return index
    }
    //Removes a variable index from the list
    //Arguments:    -An index   -Int
    static func releaseIndex(_ index:Int){
        //Sets the variable at the index to null
        VariableContainer.variableContainer[index] = IntType(value:0)
        //Releases the index to availableIndex
        VariableContainer.availableIndex.append(index)
    }
    //Assigns a value to the variable at an index
    //Arguments:    -An index   -Int
    //              -A value    -VarType
    static func assignValue(index:Int, value:VarType){VariableContainer.variableContainer[index] = value}
    //Gets the variable at a specific index
    //Arguments:    -An index   -Int
    //Returns       -A variable -Any
    static func getValue(_ index:Int) -> VarType{return VariableContainer.variableContainer[index]}
    //Dumps the variables
    static func dump(){for i in 0..<VariableContainer.variableContainer.count{print(i, " - ", VariableContainer.variableContainer[i].getDump())}}
}
//Defines a variable scope
//Used when a new set of local vars are needed
class VariableScope{
    //------Variables------
    //Stores all the variables, with a name and an index into the VariableContainer
    var scopeVariables:[String: Int] = [String:Int]()

    //------Procedures/Functions------
    //Adds a new variable to variables with an index into variableContainer
    //Arguments:    -A variable name    -String
    func declareVar(name:String){
        //Gets an index for a new variable
        let index = VariableContainer.addVar(IntType(value:0))
        //Adds the variable name and index into variables
        self.scopeVariables[name] = index
    }
    //Deletes a variable
    //Arguments:    -A variable name    -String
    func deleteVar(name:String){
        guard let index = self.scopeVariables[name] else{return}
        //Releases the variable index
        VariableContainer.releaseIndex(index)
        //Removes the variable from the scope
        self.scopeVariables[name] = nil
    }
    //Gets the index for a particular variable
    //Arguments:    -A variable name    -String
    //Returns:      -An index           -Int
    func getLink(name:String) -> VarType{
        guard let index = self.scopeVariables[name] else{return -1}
        //Returns the index
        return IntType(value:index)
    }
    //Assigns a link to a variable
    //Arguments:    -A variable name    -String
    //              -The link           -Int
    func setLink(name:String, link:Int){
        //Assigns the variable to the link
        self.scopeVariables[name] = link
    }
    //Deletes the link between a variable and a value
    //Arguments:    -A variable name    -String
    func removeLink(name:String){
        //Deletes the variable link
        self.scopeVariables[name] = nil
    }

    //Assigns a value to a variable
    //Arguments:    -A variable name    -String
    //              -The value          -VarType
    func assignValue(name:String, value:VarType){
        //Gets the index
        guard let index = self.scopeVariables[name] else{return}
        //Assigns the value to variableContainer
        VariableContainer.assignValue(index: index, value:value)
    }
    //Gets the value from a variable
    //Arguments:    -A variable name    -String
    //Returns:      -The value          -Any
    func getValue(name:String) -> VarType{
        //Gets the index
        guard let index = self.scopeVariables[name] else{return IntType(value:-1)}
        //Assigns the value to variableContainer
        return VariableContainer.getValue(index)
    }
    //Dumps the variables
    func dump(){for key in self.scopeVariables.keys{print(key, " - ", self.scopeVariables[key]!)}}
}
//Defines a stack of variable scopes
class ScopeStack{
    //------Variables------
    //Stores the stack
    var stack:[VariableScope] = [VariableScope]()
    //------Procedures/Functions------
    //Pushes a new VariableScope to the stack
    //Arguments:    -A scope    -VariableScope
    func push(scope:VariableScope){self.stack.append(scope)}
    //Pops the last VariableScope from the stack
    func pop(){self.stack.removeLast()}
    //Dumps the stack
    func dump(){for scope in self.stack{print("Scope");scope.dump()}}
}