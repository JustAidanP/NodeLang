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
    //Stores the nodeTree
    var nodeTree:Node
    //Stores the indexStack at that point
    var indexStack:[Int]
    //------Procedures/Functions------
    //Gets a clean NodeState
    //Arguments:    -A node tree    -Node
    //Returns:  An empty nodestate  -NodeState
    static func clean(_nodeTree:Node) -> NodeState{
        return NodeState(nodeTree:_nodeTree, indexStack: [0, 0])
    }
}
