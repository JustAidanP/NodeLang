//------Variables------
//Stores the canvas
let canvas = document.getElementById("byteCanvas")
//Stores the canvas context
let ctx = canvas.getContext("2d");

//Stores the program node
let programNode = Node(0);
//Stores a reference to the closest node
let closestNode = null;
//Stores a reference to the parent of the closest node
let closestNodeParent = null;
//Stores the mouse x and y
let mousePos = Position(0, 0);

//------Procedures/Functions------
//Creates a position object
//Arguments:    -x          -Int
//              -y          -Int
//Returns:      -A Position -{Int, Int}
function Position(x, y){
    return {x:x, y:y};
}
//Creates a node object
//Arguments:    -The type   -Int
//Returns:      -The node   -Object
function Node(type){
    return {
        type: 0,
        operand: "",
        children: [],
        boundary: 0,                //Stores the size boundary of the node
        position: null,             //Stores the position of the node after it has been drawn, only used for distance checking
        width: 160,
        height: 80
    };
}
//Generates a boundary size for a node by recursively creating boundaries for all the children nodes
//Arguments:    -The node           -Node
//Returns:      -The boundary size  -Int
function generateBoundary(node){
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
//              -The offset     -Ref Position
function drawNode(node, offset){
    //------Draw node routine
    node.position = Position(offset.x + node.boundary / 2, offset.y)
    //Draws the node at the centre of its boundary
    drawRectWithCorner(node.position, node.width, node.height, 10);
    //Stores the node position

    //------Draws other nodes
    //Adds the node height to the y offset for drawing of the children
    offset.y += node.height + 30
    //Draws the children
    for (var i=0; i<node.children.length; i++){
        //Draws a line from the current node to the childNode
        ctx.beginPath();
        ctx.moveTo(node.position.x, node.position.y + node.height / 2);
        ctx.lineTo(offset.x + node.children[i].boundary / 2, offset.y - node.children[i].height / 2);
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
//Arguments:    -The point          -Ref Position
//              -The width          -Int
//              -The height         -Int
//              -The corner radius  -Int
function drawRectWithCorner(pos, width, height, radius){
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
    ctx.stroke();
}

//Finds the node closest to a given position
//Arguments:    -A node             -Node
//              -A position         -Ref Position
function getClosestNode(node, point){
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
                closestNode = node.children[i];
                getClosestNode(node.children[i], point);
                return;
            }
        }
        //Runs the checks for the node if it is last
        if (i == node.children.length - 1){
        //Checks if the position is bigger than the size of the node
            if (larger){
                closestNodeParent = node;
                closestNode = node.children[i];
                getClosestNode(node.children[i], point);
                return;
            }
        }
        //Checks if the poisition is in the node
        if (lesser && larger){
            closestNodeParent = node;
            closestNode = node.children[i];
            getClosestNode(node.children[i], point);
            return;
        }
    }
    //It is assumed that this node is closest
    //Draws a circle at the position
    ctx.beginPath();
    ctx.arc(node.position.x, node.position.y, 10, 0, 2 * Math.PI);
    ctx.stroke();

    distanceFunction(node, point);
}
//Finds the distance between a point and a node
//Arguments:    -A node             -Node
//              -A position         -Ref Position
//Returns:      -A distance         -Float
function distanceFunction(node, point){
    //Works it out for the children first
    var dx = Math.min(Math.max(point.x, node.position.x - node.width / 2), node.position.x + node.width / 2);
    var dy = Math.min(Math.max(point.y, node.position.y - node.height / 2), node.position.y + node.height / 2);

    //Draws a line from the mouse point to the closest position
    ctx.beginPath();
    ctx.moveTo(point.x, point.y);
    ctx.lineTo(dx, dy);
    ctx.stroke();

    //Calculates the distance between the point and the node
    return Math.pow(dx - point.x, 2) + Math.pow(dy - point.y, 2);
}

//Gets the mouse x and y
//Arguments:    -Event  -Event
function getMousePos(event){
    let rect = canvas.getBoundingClientRect();
    //Gets the moust position and scales it to the canvas size
    mousePos.x = event.x * canvas.width / rect.width;
    mousePos.y = event.y * canvas.height / rect.height;

    //Redraws the screen
    drawCanvas();
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
    //Resets the screen
    canvas.width = canvas.width;
    let offset = Position(50, 50);
    drawNode(programNode, offset);
    getClosestNode(programNode, mousePos);
}
//Sets up the canvas
canvasFit();
//------Testing Code------
let node_10 = Node(0);
let node_11 = Node(0);
let node_100 = Node(0);
let node_101 = Node(0);
node_10.children.push(node_100);
node_10.children.push(node_101);
programNode.children.push(node_10);
programNode.children.push(node_11);
//Generates the boundaries for all nodes
generateBoundary(programNode);
//Sets up mouse events
canvas.addEventListener('mousemove', getMousePos);


//------Testing Code------
// let rootNode = Node(0);
// let node_10 = Node(0);
// let node_11 = Node(0);
// let node_100 = Node(0);
// let node_101 = Node(0);
// node_10.children.push(node_100);
// node_10.children.push(node_101);
// rootNode.children.push(node_10);
// rootNode.children.push(node_11);
