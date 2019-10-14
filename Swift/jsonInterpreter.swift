import Foundation
func toNode(jsonData:Data) -> Node{
    do{
        if let json = try JSONSerialization.jsonObject(with: jsonData, options:[]) as? [String: Any]{
            if let node = json["main"] as? [String:Any]{
                return createNode(nodeData:node)
            }
        }
        return Node(type:.Execute)
    }
    catch let e{print(e); return Node(type:.Execute)}
}


func createNode(nodeData:[String:Any]) -> Node{
    //Creates a node with the defined type
    let node = Node(type:Node.nodeTypes[nodeData["type"]! as! Int])
    //Gets the VarType
    let varType = nodeData["varType"]! as! Int
    //Will store the operand based on the VarType)
    if varType == 0{node.operand = Int(nodeData["operand"]! as! String)! as Any}
    else if varType == 1{node.operand = Float(nodeData["operand"]! as! String)! as Any}
    else if varType == 2{node.operand = String(nodeData["operand"]! as! String) as Any}
    else if varType == 3{
        if nodeData["operand"]! as! String == "1"{node.operand = true}
        else if nodeData["operand"]! as! String == "0"{node.operand = false}
    }
    //Checks if there are children
    if let children = nodeData["children"] as? Array<Dictionary<String, Any>>{
        for child in children{node.children.append(createNode(nodeData:child))}
    }
    return node
}