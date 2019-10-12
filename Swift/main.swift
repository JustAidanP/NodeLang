#!/usr/bin/swift
import Foundation
let str = "{\"main\":{\"type\":23,\"varType\":-1,\"operand\":\"\",\"children\":[{\"type\":0,\"varType\":-1,\"operand\":\"\",\"children\":[{\"type\":3,\"varType\":2,\"operand\":\"num1\",\"children\":[]}]},{\"type\":0,\"varType\":-1,\"operand\":\"\",\"children\":[{\"type\":3,\"varType\":2,\"operand\":\"num2\",\"children\":[]}]},{\"type\":23,\"varType\":-1,\"operand\":\"\",\"children\":[{\"type\":22,\"varType\":-1,\"operand\":\"\",\"children\":[{\"type\":3,\"varType\":2,\"operand\":\"num1\",\"children\":[]},{\"type\":4,\"varType\":1,\"operand\":\"128.5\",\"children\":[]}]},{\"type\":22,\"varType\":-1,\"operand\":\"\",\"children\":[{\"type\":3,\"varType\":2,\"operand\":\"num2\",\"children\":[]},{\"type\":4,\"varType\":1,\"operand\":\"576.5\",\"children\":[]}]}]},{\"type\":23,\"varType\":-1,\"operand\":\"\",\"children\":[{\"type\":0,\"varType\":-1,\"operand\":\"\",\"children\":[{\"type\":3,\"varType\":2,\"operand\":\"output\",\"children\":[]}]},{\"type\":22,\"varType\":-1,\"operand\":\"\",\"children\":[{\"type\":3,\"varType\":2,\"operand\":\"output\",\"children\":[]},{\"type\":8,\"varType\":-1,\"operand\":\"\",\"children\":[{\"type\":1,\"varType\":-1,\"operand\":\"\",\"children\":[{\"type\":3,\"varType\":2,\"operand\":\"num1\",\"children\":[]}]},{\"type\":1,\"varType\":-1,\"operand\":\"\",\"children\":[{\"type\":3,\"varType\":2,\"operand\":\"num2\",\"children\":[]}]}]}]}]}]}}"

// let process = Process()
// process.run(nodeTree:toNode(jsonData:Data(str.utf8)))

let pManager = ProcessManager()
pManager.processes.append(_Process(_processManager:pManager, _nodeTree:toNode(jsonData:Data(str.utf8))))
pManager.run()

pManager.scopeStack.dump()
print("Variable Container")
VariableContainer.dump()