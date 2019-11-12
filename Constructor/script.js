//------Variables------
//Stores the canvas
let canvas = document.getElementById("byteCanvas")
//Stores the canvas context
let ctx = canvas.getContext("2d");
//Stores the canvas translation
let translation = Vector(0, 0);
//Stores the canvas scale
let scale = Vector(1, 1);

//Stores the program node
let programNode = Node(0x62);
//Stores the selected node  -Default    -Null
let selectedNode = null;
//Stores the highlighted node, used for the info panel
let highlightedNode = null;
//Stores the highlighted node parent, used for the info panel
let highlightedNodeParent = null;
//Stores a reference to the closest node
let closestNode = null;
//Stores a reference to the parent of the closest node
let closestNodeParent = null;
//Stores the mouse x and y
let mousePos = Vector(0, 0);
//Stores if the canvas is being dragged
let dragCanvas = false;

//------Procedures/Functions------
//Creates a position object
//Arguments:    -x          -Int
//              -y          -Int
//Returns:      -A Vector -{Int, Int}
function Vector(x, y){
    return {x:x, y:y};
}
//Creates a node object
//Arguments:    -The type   -Int
//Returns:      -The node   -Object
function Node(type){
    return {
        type: type,
        operand: "",
        children: [],
        boundary: 0,                //Stores the size boundary of the node
        position: null,             //Stores the position of the node after it has been drawn, only used for distance checking
        width: 160,
        height: 80,
        strokeColour: "#111111"
    };
}
//Generates a boundary size for a node by recursively creating boundaries for all the children nodes
//Arguments:    -The node           -Node
//Returns:      -The boundary size  -Int
function generateBoundary(node){
    //Sets the node's boundary to default to 0
    node.boundary = 0;
    //Checks if the boundary should be returned as the size of the node with padding
    if (node.children.length == 0){node.boundary = node.width + 20; return node.boundary;}
    //Recursively calculates the boundaries
    for (var i=0; i<node.children.length; i++){
        //Generates the boundary for the node and adds it to the sum of the boundary for this node
        node.boundary += generateBoundary(node.children[i]);
    }
    //Returns the boundary size
    return node.boundary;
}
//Draws the nodes based on their boundaries
//Arguments:    -The node       -Node
//              -The offset     -Ref Vector
function drawNode(node, offset){
    //------Draw node routine
    node.position = Vector(offset.x + node.boundary / 2, offset.y)
    //Draws the type text
    drawTypeForNode(node);
    //Draws the node at the centre of its boundary
    drawRectWithCorner(node.position, node.width, node.height, 10, node.strokeColour);

    //------Draws other nodes
    //Adds the node height to the y offset for drawing of the children
    offset.y += node.height + 30
    //Draws the children
    for (var i=0; i<node.children.length; i++){
        //Draws a line from the current node to the childNode
        ctx.beginPath();
        ctx.moveTo(node.position.x, node.position.y + node.height / 2);
        ctx.lineTo(offset.x + node.children[i].boundary / 2, offset.y - node.children[i].height / 2);
        ctx.strokeStyle = "#111111";
        ctx.stroke();
        //Generates the boundary for the node and adds it to the sum of the boundary for this node
        drawNode(node.children[i], offset);
    }

    //Only adds the boundary size if the node has no children
    if (node.children.length == 0){offset.x += node.boundary;}
    //Removes the node height from the y offset
    offset.y -= node.height + 30
}

//Draws a rectangle at a point with a particular corner radius
//Arguments:    -The point          -Ref Vector
//              -The width          -Int
//              -The height         -Int
//              -The corner radius  -Int
//              -The stroke colour  -String
function drawRectWithCorner(pos, width, height, radius, strokeColour){
    //Defines constants
    const halfWidth = width / 2;
    const halfHeight = height / 2;
    //Use MoveTo, LineTo and Arc
    ctx.beginPath();
    //Moves to the top left position and draws to the right
    ctx.moveTo(pos.x - halfWidth + radius, pos.y - halfHeight);
    //Top segment
    ctx.lineTo(pos.x + halfWidth - radius, pos.y - halfHeight);
    ctx.arc(pos.x + halfWidth - radius, pos.y - halfHeight + radius, radius, - Math.PI / 2, 0);
    //Right segment
    ctx.lineTo(pos.x + halfWidth, pos.y + halfHeight - radius);
    ctx.arc(pos.x + halfWidth - radius, pos.y + halfHeight - radius, radius, 0, Math.PI / 2);
    //Bottom Segment
    ctx.lineTo(pos.x - halfWidth + radius, pos.y + halfHeight);
    ctx.arc(pos.x - halfWidth + radius, pos.y + halfHeight - radius, radius, Math.PI / 2, Math.PI);
    //Top Segment
    ctx.lineTo(pos.x - halfWidth, pos.y - halfHeight + radius);
    ctx.arc(pos.x - halfWidth + radius, pos.y - halfHeight + radius, radius, Math.PI, -Math.PI / 2);
    ctx.strokeStyle = strokeColour;
    ctx.lineWidth = 2;
    ctx.stroke();

    ctx.lineWidth = 1;
}
//Draws the type for a particular node
//Arguments:    -A node -Node
function drawTypeForNode(node){
    //Switches through all types and draws the specific type
    switch (node.type){
        case 0x00: //CreateVar
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("CreateVar", node.position.x, node.position.y);
            break;
        case 0x01: //GetVar
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("GetVar", node.position.x, node.position.y);
            break;
        case 0x02: //DeleteVar
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("DeleteVar", node.position.x, node.position.y);
            break;
        case 0x03: //GetLink
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("GetLink", node.position.x, node.position.y);
            break;
        case 0x04: //Link
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("Link", node.position.x, node.position.y);
            break;
        case 0x05: //Unlink
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("Unlink", node.position.x, node.position.y);
            break;
        case 0x06: //Assign
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("Assign", node.position.x, node.position.y);
            break;
        //Primitives
        case 0x10: //Null 
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("Null", node.position.x, node.position.y);
            break;
        case 0x11: //Text 
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("Text", node.position.x, node.position.y);
            break;
        case 0x12: //Real_Int
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("Real_Int", node.position.x, node.position.y);
            break;
        case 0x13: //Real_Float
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("Real_Float", node.position.x, node.position.y);
            break;
        case 0x14: //Boolean 
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("Boolean", node.position.x, node.position.y);
            break;
        case 0x15: //Object
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("Object", node.position.x, node.position.y);
            break;
        //Operators
        case 0x20: //Oper_Add
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("+", node.position.x, node.position.y);
            break;
        case 0x21: //Oper_Sub
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("-", node.position.x, node.position.y);
            break;
        case 0x22: //Oper_Mult
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("*", node.position.x, node.position.y);
            break;
        case 0x23: //Oper_Div
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("/", node.position.x, node.position.y);
            break;
        //Logical Operators
        case 0x30: //Logic_Is_Equal
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("==", node.position.x, node.position.y);
            break;
        case 0x31: //Logic_Is_Not_Equal
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("!=", node.position.x, node.position.y);
            break;
        case 0x32: //Logic_Bigger
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText(">", node.position.x, node.position.y);
            break;
        case 0x33: //Logic_Bigger_Equal
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText(">=", node.position.x, node.position.y);
            break;
        case 0x34: //Logic_Lesser
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("<", node.position.x, node.position.y);
            break;
        case 0x35: //Logic_Lesser_Equal
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("<=", node.position.x, node.position.y);
            break;
        case 0x36: //Logic_And
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("Logic_And", node.position.x, node.position.y);
            break;
        case 0x37: //Logic_Or
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("Logic_Or", node.position.x, node.position.y);
            break;
        case 0x38: //Logic_Not
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("Logic_Not", node.position.x, node.position.y);
            break;
        //Jumps
        case 0x40: //JumpTo
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("JumpTo", node.position.x, node.position.y);
            break;
        case 0x41: //SubRoutine
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("SubRoutine", node.position.x, node.position.y);
            break;
        case 0x42: //Label
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("Label", node.position.x, node.position.y);
            break;
        case 0x43: //RefLabel
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("RefLabel", node.position.x, node.position.y);
            break;
        case 0x44: //Recall
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("Recall", node.position.x, node.position.y);
            break;
        //Namespaces
        case 0x50: //Namespace
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("Namespace", node.position.x, node.position.y);
            break;
        case 0x51: //RefNamespace
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("RefNamespace", node.position.x, node.position.y);
            break;
        //Handles conditional branching
        case 0x60: //If
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("If", node.position.x, node.position.y);
            break;
        case 0x61: //Execute
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("Execute", node.position.x, node.position.y);
            break;
        case 0x62: //Program
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("Program", node.position.x, node.position.y);
            break;
        case 0x63: //CastText
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("CastText", node.position.x, node.position.y);
            break;
        case 0x64: //CastReal_Int
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("CastReal_Int", node.position.x, node.position.y);
            break;
        case 0x65: //CastReal_Float
            //Draws the text
            ctx.font = "30px Arial";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText("CastReal_Float", node.position.x, node.position.y);
            break;
        default:
            break;
    }
}

//Finds the node closest to a given position
//Arguments:    -A node             -Node
//              -A position         -Ref Vector
function getClosestNode(node, point){
    closestNode = node;
    //Stores the y distance between the point and the node
    let dy = Math.abs(point.y - node.position.y);
    //Checks if any child is closer
    for (var i=0;i<node.children.length;i++){
        //Stores the y distance between the point and the child node
        let dyc = Math.abs(point.y - node.children[i].position.y);
        //Checks if the node's y position is closer than the current node, it then skips the checks for the node
        if (dyc > dy){continue;}

        //Stores whether the point is less that the size of the node
        let lesser = point.x <= node.children[i].position.x + node.children[i].boundary / 2;
        //Stores whether the point is bigger that the size of the node
        let larger = point.x >= node.children[i].position.x - node.children[i].boundary / 2;

        //Runs the checks for the node if it is first
        if (i == 0){
            //Checks if the position is less than the size of the node
            if (lesser){
                closestNodeParent = node;
                getClosestNode(node.children[i], point);
                return;
            }
        }
        //Runs the checks for the node if it is last
        if (i == node.children.length - 1){
        //Checks if the position is bigger than the size of the node
            if (larger){
                closestNodeParent = node;
                getClosestNode(node.children[i], point);
                return;
            }
        }
        //Checks if the poisition is in the node
        if (lesser && larger){
            closestNodeParent = node;
            getClosestNode(node.children[i], point);
            return;
        }
    }
    //It is assumed that this node is closest
    //Sets the colour of the node to red if it isn't the highlighted node
    if (node !== highlightedNode) node.strokeColour = "red";

    distanceFunction(node, point);
}
//Finds the distance between a point and a node
//Arguments:    -A node             -Node
//              -A position         -Ref Vector
//Returns:      -A distance         -Float
function distanceFunction(node, point){
    //Works it out for the children first
    var dx = Math.min(Math.max(point.x, node.position.x - node.width / 2), node.position.x + node.width / 2);
    var dy = Math.min(Math.max(point.y, node.position.y - node.height / 2), node.position.y + node.height / 2);

    //Draws a line from the mouse point to the closest position
    ctx.beginPath();
    ctx.moveTo(point.x, point.y);
    ctx.lineTo(dx, dy);
    ctx.strokeStyle = "#222222";
    ctx.stroke();

    //Calculates the distance between the point and the node
    return Math.pow(dx - point.x, 2) + Math.pow(dy - point.y, 2);
}

//Adds a new button when selected in the selector
//Arguments:    -The type   -Int
function addButtonSelector(type){
    //Doesn't select a new node if one is currently selected
    if (selectedNode != null) return;
    selectedNode = Node(type);
}
//Deletes the highlighted node
function deleteHighlighted(){
    //Searches through the hightlightedParent until the node is found
    let i = 0;
    while (i < highlightedNodeParent.children.length){
        if (highlightedNodeParent.children[i] === highlightedNode){
            //Deletes the node
            highlightedNodeParent.children.splice(i, 1);
            highlightedNode = null;
            showHighlighted();
            break;
        }
        i++;
    }
    //Generates new boundaries
    generateBoundary(programNode);
    //Finds the new closestNode
    getClosestNode(programNode, mousePos);
}
//Adds the highlightedNode to the infoPanel
function showHighlighted(){
    if (highlightedNode == null){
        document.getElementById("TypeName").innerHTML = "";
        document.getElementById("TypeOpcode").innerHTML = "";
        document.getElementById("OperandText").value = "";
        document.getElementById("OperandReal_Int").value = "";
        document.getElementById("OperandReal_Float").value = "";
        return;
    }
    //Converts the type to hex
    let hex = highlightedNode.type.toString(16);
    hex = (hex.length == 1) ? "0x0" + hex : "0x" + hex;
    //Changes the name of the infopanel
    document.getElementById("TypeName").innerHTML = document.getElementById(hex).innerHTML;
    //Changes the opcode of the infopanel
    document.getElementById("TypeOpcode").innerHTML = hex;

    //Shows the textarea operand for text
    if (highlightedNode.type == 0x11){
        document.getElementById("OperandText").hidden = false;
        document.getElementById("OperandText").value = highlightedNode.operand;
    }else document.getElementById("OperandText").hidden = true;
    //Shows the input operand for Real_Int
    if (highlightedNode.type == 0x12){
        document.getElementById("OperandReal_Int").hidden = false;
        document.getElementById("OperandReal_Int").value = highlightedNode.operand;
    }else document.getElementById("OperandReal_Int").hidden = true;
    //Shows the input operand for Real_Float
    if (highlightedNode.type == 0x13){
        document.getElementById("OperandReal_Float").hidden = false;
        document.getElementById("OperandReal_Float").value = highlightedNode.operand;
    }else document.getElementById("OperandReal_Float").hidden = true;
}

//Converts a mouse event to an x and y
//Arguments:    -An event   -Event
//Returns:      -An x and y -Vector
function eventToVec(event){
    let rect = canvas.getBoundingClientRect();
    //Gets the moust position and scales it to the canvas size
    mouseX = (event.x - rect.x) * canvas.width / rect.width;
    mouseY = (event.y - rect.y) * canvas.height / rect.height;
    //Finds the inverse of the transform matrix
    let inverse = ctx.getTransform().invertSelf();

    mouseX = mouseX * inverse.a + mouseY * inverse.c + inverse.e;
    mouseY = mouseX * inverse.b + mouseY * inverse.d + inverse.f;

    return Vector(mouseX, mouseY);
}
//Gets the mouse x and y
//Arguments:    -Event  -Event
function getMousePos(event){
    eventVec = eventToVec(event);
    //If the mouse is down or if the shift key is being pressed, the canvas is moved with the mouse
    if (dragCanvas || event.shiftKey){
        translateCanvas(event.movementX, event.movementY);
    }

    mousePos.x = eventVec.x;
    mousePos.y = eventVec.y;

    //Redraws the screen
    drawCanvas();
}
//Detects mouse down
function onMouseDown(event){
    //Checks if the mouse is intersecting a node
    if (distanceFunction(closestNode, mousePos) == 0 && closestNode !== programNode && selectedNode == null){
        closestNode.strokeColour = "#111111";
        //Sets the closestNode to the selectedNode
        selectedNode = closestNode;
        //Removes the node from the parent
        let i = 0;
        while (i<closestNodeParent.children.length){
            //Removes the element that is directly equal to the closestNode
            if (closestNodeParent.children[i] === closestNode){
                closestNodeParent.children.splice(i, 1);
            }
            i++;
        }
        //Generates new boundaries
        generateBoundary(programNode);
        //Finds the new closestNode
        getClosestNode(programNode, mousePos);
    }else{
        //Sets the closestNode to the highlighted node
        if (closestNode !== programNode){
            //Resets the previous highlighted node colour
            if (highlightedNode != null) highlightedNode.strokeColour = "#111111";
            highlightedNode = closestNode;
            highlightedNodeParent = closestNodeParent;
            highlightedNode.strokeColour = "blue";
            //Shows the highlighted node on the info panel
            showHighlighted();
        }
        dragCanvas = true;
    }
}
//Detects mouse release
function onMouseRelease(event){
    dragCanvas = false;
    //Gets the x position of the mouse
    mouseX = eventToVec(event).x;

    //Gives the selectedNode to the closestNode as long as the closestNode isn't itself
    if (selectedNode != null && selectedNode !== closestNode){
        //Finds the position among the children that the node should be placed
        let i = 0;
        //Finds the first child that is to the right of the mouse x
        while (i < closestNode.children.length){
            if (mouseX < closestNode.children[i].position.x){break}
            i++;
        }
        closestNode.children.splice(i, 0, selectedNode);
        selectedNode = null;
        //Generates new boundaries
        generateBoundary(programNode);
        //Redraws the canvas
        drawCanvas();
    }
}
//Detects scrool wheel
function onScrollWheel(event){
    console.log(event.deltaMode);
    if (event.deltaY < 0){
        scaleCanvas(0.1, 0.1);
    }else if (event.deltaY > 0){
        scaleCanvas(-0.1, -0.1);
    }
    //Redraws the canvas
    drawCanvas();
}

//Translates the canvas
//Arguments:    -Change in x    -Int
//              -Change in y    -Int
function translateCanvas(dx, dy){
    translation.x += dx
    translation.y += dy
}
//Scales the canvas
//Arguments:    -Change in x    -Int
//              -Change in y    -Int
function scaleCanvas(dx, dy){
    scale.x += (scale.x <= 0.15 && dx < 0) ? 0 : dx;
    scale.y += (scale.y <= 0.15 && dy < 0) ? 0 : dy;
}
//Transforms the canvas
function transformCanvas(){
    ctx.setTransform(scale.x, 0, 0, scale.y, translation.x, translation.y);
}
//Makes the canvas fit the container
function canvasFit(){
    //Makes the canvas visually fill the positioned parent
    canvas.style.width ='100%';
    canvas.style.height='100%';
    //Sets the dimensions of the canvas to match the actual size    
    canvas.width  = canvas.offsetWidth * 2;
    canvas.height = canvas.offsetHeight * 2;
}
//Handles drawing
function drawCanvas(){
    //Store the current transformation matrix
    ctx.save();
    //Use the identity matrix while clearing the canvas
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    //Restore the transform
    ctx.restore();

    //Transforms the canvas
    transformCanvas();

    let offset = Vector(50, 50);
    drawNode(programNode, offset);
    if (closestNode != null && closestNode !== highlightedNode) closestNode.strokeColour = "#111111";
    getClosestNode(programNode, mousePos);

    //Draws the slectedNode at the mousePos
    if (selectedNode != null){drawNode(selectedNode, mousePos);}
}

//Exports the node tree as a byte code
function exportByteCode(){return "";
}
//Exports the node tree for any particular node as a js object
//Arguments:    -The node to run an export on
//Returns:      -A js object of the node
function exportObject(node){
    //Stores the node tree for the node
    let nodeTree = {type:node.type, operand:node.operand, children:[]}
    //Adds the export of every child to the node tree
    for (var i=0; i<node.children.length; i++) nodeTree.children.push(exportObject(node.children[i]));
    //Returns the object
    return nodeTree;
}
//Imports a node tree for a js object
//Arguments:    -The js object to run an import on
//Returns:      -A node
function importObject(node){
    //Stores the node tree for the node
    let nodeTree = Node(node.type);
    nodeTree.operand = node.operand;
    // let nodeTree = {type:node.type, operand:node.operand, children:[]}
    //Adds the export of every child to the node tree
    for (var i=0; i<node.children.length; i++) nodeTree.children.push(importObject(node.children[i]));
    //Returns the object
    return nodeTree;
}

//Sets up the canvas
canvasFit();
//Generates the boundaries for all nodes
generateBoundary(programNode);
//Draws the canvas
drawCanvas();
//Sets up mouse events
canvas.addEventListener('mousemove', getMousePos);
canvas.addEventListener('mousedown', onMouseDown);
canvas.addEventListener('mouseup', onMouseRelease);
canvas.addEventListener('wheel', onScrollWheel);