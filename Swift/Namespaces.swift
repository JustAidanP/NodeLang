//------Structures------
//Defines a namespace, this can be used for jumps
struct Namespace{
    //Stores the name of the namespace
    var name:String
    //Stores the labels of the namespace
    var labels:[String:NodeState] = [String:NodeState]()
}

//Defines a NodeState, this stores information about the process at the point of storage
struct NodeState{
    //------Variables------
    //Stores the nodeStack
    var nodeStack:[Node]
    //Stores the indexStack at that point
    var indexStack:[Int]
    //------Procedures/Functions------
    //Gets a clean NodeState
    //Arguments:    -A node stack    -[Node]
    //Returns:  An empty nodestate  -NodeState
    static func clean(_nodeStack:Node) -> NodeState{
        return NodeState(nodeStack:_nodeStack, indexStack: [0, 0])
    }
}
