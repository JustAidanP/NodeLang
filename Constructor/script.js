//------Variables------
//Stores the canvas
let canvas = document.getElementById("nodeCanvas")
//Stores the canvas context
let ctx = canvas.getContext("2d");
//Stores all node types
let nodeTypes = ["CreateVar","GetVar","DeleteVar","Text","Number","Boolean","Oper_Add","Oper_Sub","Oper_Div","Oper_Mult","Logic_Is_Equal","Logic_Is_Not_Equal","Logic_Bigger","Logic_Bigger_Equal","Logic_Lesser","Logic_Lesser_Equal","Logic_And","Logic_Or","Logic_Not","If","While","For","Assign","Execute"]
let nodeTypeInfo = [["#0062ff", "+V"], ["#0043ad", "V"], ["#002e78", "-V"],             //Blue
["#00ff0d", "Text"], ["#009608", "Num"], ["#006e06", "Bool"],                                //Green
["#ff0000", "+"], ["#bd0000", "-"], ["#bd0000", "/"], ["#8c4d4d", "*"],                     //Red
["#ff00fb", "=="], ["#821980", "!="], ["#660264", ">"], ["#b000ac", ">="], ["#e07bde", "<"], ["#a15d9f", "<="], ["#5c335a", "&&"], ["#ebb2e8", "||"], ["#a1749e", "!"],  //Pink
["#eaff00", "If"], ["#b5c404", "While"], ["#687001", "For"],                                //Yellow
["#00fbff", "="], ["#03a3a6", "E"]                                             //Cyan
]
//Stores an x divider, this defines the position of the last bottom node
var xDivider = 0;
//Stores all nodes as children
var nodeTree = generateNode("Execute", "")
//Stores a newNode
var newNode = null
//Stores a node that has been selected
var selectedNode = null
//Stores the mouse x and y
var mouseX = 0
var mouseY = 0

//------Procedures/Functions------
//Generates a new node
//Arguments:    -The nodeType   -String
//              -An operand     -String
function generateNode(_nodeType, _operand){
    return{
        xPos:0,
        yPos:0,
        type:nodeTypes.indexOf(_nodeType),
        varType:-1,
        operand:_operand,
        children:[]
    };
}

//Generates an xPosition for each node
//Arguments:    -A node -Node
//              -A yPos -Int
function generateX(node, yPos){
    node.yPos = yPos
    //Checks to see if the node is a last node
    if (node.children.length == 0){
        //Sets the xPos to the next space beyond the boundary
        node.xPos = xDivider + 75;
        xDivider = node.xPos;
    }
    else{
        //Calculates the mean between all children points
        var xMean = 0;
        for (var i=0; i<node.children.length; i++){
            generateX(node.children[i], yPos + 75)
            xMean += node.children[i].xPos;
        }
        //Calculates the xPos as the mean
        node.xPos = xMean / node.children.length;
    }
    //Draws the node
    drawNode(node);
    //Draws a line to all of it's children
    for (var i=0; i<node.children.length; i++){
        drawLine(node.xPos, node.yPos + 25, node.children[i].xPos, node.children[i].yPos - 25);
    }
}

//Adds a child node to a node
//Arguments:    -A node -Node
function addChild(node){
    node.children.push(generateNode());
}

//Calculates a magnitude
//Arguments:    -x          -Int
//              -y          -Int
//Returns:      -Magnitude  -Float
function mag(x, y){return Math.sqrt(x * x + y * y)}

//Performs a search for an x and y to find the closest node
//Arguments:    -An x   -Int
//              -A y    -Int
function searchTree(x, y){
    //Stores the current closest node
    var closestNode = nodeTree
    //Keeps looking for a closer node
    while (true){
        //Stores the new closest node
        var newClosest = closestNode
        for (var i=0; i<closestNode.children.length; i++){
            //Checks if this node is closer than the current closest
            if (mag(closestNode.children[i].xPos - x, closestNode.children[i].yPos - y) < mag(newClosest.xPos - x, newClosest.yPos - y)){
                newClosest = closestNode.children[i]
            }
        }
        //If closestNode didn't change, it is returned
        if (closestNode == newClosest){return closestNode}
        //Otherwise it sets closestNode to newClosest
        closestNode = newClosest
    }
}

//Redraws the canvas
function reDraw(){
    //Clears the screen
    canvas.width = canvas.width;
    //Draws the nodeTree
    xDivider = 0;
    generateX(nodeTree, 50);

    //Draws the newNode at the mouse position
    if (newNode != null){
        drawNode(newNode);
        //Finds the node closest to newNode
        let closest = searchTree(newNode.xPos, newNode.yPos);
        //Draws a line to the closestNode
        drawLine(closest.xPos, closest.yPos + 25, newNode.xPos, newNode.yPos - 25)
    }
}

//Draws a node
//Arguments:    -A node -Node
function drawNode(node){
    //Checks if the node is the selectedNode
    if (node === selectedNode){ctx.fillStyle = "#CDCDCD";}
    else{ctx.fillStyle = "White";}
    //Sets the stroke style to the node colour
    ctx.strokeStyle = nodeTypeInfo[node.type][0];
    //Draws a circle at the xPos, yPos
    ctx.beginPath();
    ctx.arc(node.xPos, node.yPos, 25, 0, 2 * Math.PI);
    //Fills the node
    ctx.fill();
    ctx.stroke();

    //Adds text
    ctx.textAlign = "center";
    ctx.textBaseline = 'middle';
    ctx.font = "30px Arial";
    ctx.fillStyle = "Black"
    ctx.fillText(nodeTypeInfo[node.type][1], node.xPos, node.yPos); 

    //Resets the styling
    ctx.strokeStyle = "Black";
    ctx.fillStyle = "White"
}

//Draws a line
//Arguments:    -x1 -Int
//              -y1 -Int
//              -y2 -Int
//              -y2 -Int
function drawLine(x1, y1, x2, y2){
    ctx.beginPath();
    ctx.moveTo(x1, y1);
    ctx.lineTo(x2, y2);
    ctx.stroke();
}

//Gets the mouse x and y
//Arguments:    -Event  -Event
function getMousePos(event){
    let rect = canvas.getBoundingClientRect();
    mouseX = event.x - rect.left;
    mouseY = event.y - rect.top;
    //Sets the newNode position to the mouse position
    if (newNode != null){
        newNode.xPos = mouseX
        newNode.yPos = mouseY
    }
    //Redraws the screen
    reDraw();
}

//Detects a mouse click
//Arguments:    -Event  -Event
function getMouseDown(event){
    //Finds the closest node
    let closestNode = searchTree(mouseX, mouseY)
    //If there is a newNode, it assigns it to the nearest node
    if (newNode){closestNode.children.push(newNode); newNode = null; return}
    //Otherwise it will check if a node was clicked, checks if the click is within the circle radius of a node
    if (mag(closestNode.xPos - mouseX, closestNode.yPos - mouseY) < 25 && newNode == null){
        //Sets selectedNode to the clicked node
        selectedNode = closestNode;
        //Sets node type to the selectedNode type
        document.getElementById("NodeType").value = nodeTypes[closestNode.type];
        //Sets the operand to the selectedNode type
        document.getElementById("Operand").value = closestNode.operand;
        //Updates the button text
        document.getElementById("GenerateNode").innerHTML = "Edit Node";
    }else{
        //Updates the button text
        document.getElementById("GenerateNode").innerHTML = "Generate Node";
        //Resets selectedNode
        selectedNode = null;
    }

    //Redraws ths screen
    reDraw();
}
//Detects a mouse release
//Arguments:    -Event  -Event
function getMouseUp(event){
}

//Handles an outlet for the generateNode button click
function genNodeOutlet(){
    //Manages action based on whether a node has been selected
    if (selectedNode){
        //Updates the type
        selectedNode.type = nodeTypes.indexOf(document.getElementById('NodeType').value);
        //Updates the operand
        selectedNode.operand = document.getElementById('Operand').value;
        //Updates the button text
        document.getElementById("GenerateNode").innerHTML = "Generate Node";
        //Resets selectedNode
        selectedNode = null
    }else{
        //Generates a new node
        newNode = generateNode(document.getElementById('NodeType').value, document.getElementById('Operand').value);
    }

    //Redraws the screen
    reDraw();
}

//Adds nodeType elements to the creationTab
function addNodeTypes(){
    for(var i = 0; i < ips["ips"].length; i++){
        //Adds the ip as an option to the stat selector
        element = document.createElement("option");
        element.text = ips["ips"][i];
        document.getElementById('ipSelector').add(element);
    }
}
//Removes all position data from the nodes
//Arguments:    -A Node     -Node
function removePositionData(node){
    delete node.xPos
    delete node.yPos
    //Fills in varType
    if (node.type == 4){if (Number.isInteger(parseFloat(node.operand))){node.varType = 0}}        //Int
    if (node.type == 4){if (!Number.isInteger(parseFloat(node.operand))){node.varType = 1}}        //Float
    if (node.type == 3){node.varType = 2}        //String
    if (node.type == 5){node.varType = 3}        //Bool
    //Gets its children to remove positionData
    for (var i=0; i < node.children.length; i++){
        removePositionData(node.children[i])
    }
}
//Exports the nodeTree as json
function exportNode(){
    //Removes position data
    removePositionData(nodeTree)
    //Removes the position data from the nodes
    return JSON.stringify({"main":nodeTree});
}

//------Logic------
//Populates the node selector
for(var i = 0; i < nodeTypes.length; i++){
    //Adds the ip as an option to the stat selector
    element = document.createElement("option");
    element.text = nodeTypes[i];
    document.getElementById('NodeType').add(element);
}
//Sets up mouse events
canvas.addEventListener('mousemove', getMousePos);
canvas.addEventListener('mousedown', getMouseDown);
canvas.addEventListener('mouseup', getMouseUp);

reDraw();