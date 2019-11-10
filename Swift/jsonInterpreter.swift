import Foundation
func toNode(jsonData:Data) -> Node{
    do{
        if let node = try JSONSerialization.jsonObject(with: jsonData, options:[]) as? Dictionary<String, Any>{
            print("Serialised")
            return createNode(nodeData:node)
        }
        return Node(type:0x61)                          //0x61 - Execute
    }
    catch let e{print(e); return Node(type:0x61)}       //0x61 - Execute
}


func createNode(nodeData:[String:Any]) -> Node{
    //Creates a node with the defined type
    let node = Node(type:nodeData["type"]! as! UInt8)
    //Will store the operand based on the type of the node
    if let _ = nodeData["operand"]{
        if node.type == 0x12{node.operand = (nodeData["operand"]! as! Int) as Any}           //0x10 - Int
        else if node.type == 0x13{node.operand = (nodeData["operand"]! as! Float) as Any}    //0x12 - Float
        else if node.type == 0x11{node.operand = String(nodeData["operand"]! as! String) as Any}    //0x10 - String
        else if node.type == 0x14{                                                                  //0x13 - Boolean
            if nodeData["operand"]! as! String == "1"{node.operand = true}
            else if nodeData["operand"]! as! String == "0"{node.operand = false}
        }
    }
    //Checks if there are children
    if let children = nodeData["children"] as? Array<Dictionary<String, Any>>{
        for child in children{node.children.append(createNode(nodeData:child))}
    }
    return node
}