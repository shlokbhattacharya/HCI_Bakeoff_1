//when in doubt, consult the Processsing reference: https://processing.org/reference/

//Importing some useful packages
import java.awt.AWTException;
import java.awt.Rectangle;
import java.awt.Robot;
import java.util.ArrayList;
import java.util.Collections;
import processing.core.PApplet;

//Setting up a bunch of global variables
int margin = 200; //set the margin around the squares
final int padding = 50; // padding between buttons and also their width/height
final int buttonSize = 40; // padding between buttons and also their width/height
ArrayList<Integer> trials = new ArrayList<Integer>(); //contains the order of buttons that activate in the user study
int trialNum = 0; //the current trial number (indexes into trials array above)
int startTime = 0; // time starts when the first click is captured
int finishTime = 0; //records the time of the final click
int hits = 0; //number of successful clicks
float angle;
int misses = 0; //number of missed clicks
Robot robot; //initialized in setup 

// Snapping variables
float snappedX, snappedY; // The snapped cursor position
final float snapRadius = 150; // Distance within which snapping occurs

int numRepeats = 1; //sets the number of times each button repeats in the user study. 1 = each square will appear as the target once.

void setup()
{
  size(700, 700); // set the size of the window
  //noCursor(); //hides the system cursor if you want
  //noStroke(); //turn off all strokes, we're just using fills here (can change this if you want)
  textFont(createFont("Arial", 16)); //sets the font to Arial size 16
  textAlign(CENTER);
  frameRate(60);
  ellipseMode(CENTER); //ellipses are drawn from the center (BUT RECTANGLES ARE NOT! By default, rectangles are drawn from their upper left corner. )
  //rectMode(CENTER); //enabling will break the scaffold code, but you might find it easier to work with centered rects

 //optional code below. This creates a "Java Robot" class that can move the system cursor.
  try {
    robot = new Robot(); 
  } 
  catch (AWTException e) {
    e.printStackTrace();
  }

  //===DON'T MODIFY MY RANDOM ORDERING CODE==
  //generate list of targets and randomize the order
  for (int i = 0; i < 16; i++) //loop for the number of buttons in 4x4 grid (i.e., 16)
    for (int k = 0; k < numRepeats; k++) //loop for the number of times each button repeats. Scaffold code default is 1, but it will be higher in the actual bakeoff.
      trials.add(i);
  Collections.shuffle(trials); //randomize the order of the targets
  System.out.println("trial order: " + trials); //print out the target list for debugging
  
  surface.setLocation(0,0);// put window in top left corner of screen (doesn't always work)
}


void draw()
{
  background(0); //black out the window each time we draw.
  fill(255); //set fill color to white

  if (trialNum >= trials.size()) //check to see if user study is over
  {
    float timeTaken = (finishTime-startTime) / 1000f;
    float penalty = constrain(((95f-((float)hits*100f/(float)(hits+misses)))*.2f),0,100);
    
    //writes to the screen (not console)
    text("Finished!", width / 2, height / 2); 
    text("Hits: " + hits, width / 2, height / 2 + 20);
    text("Misses: " + misses, width / 2, height / 2 + 40);
    text("Accuracy: " + (float)hits*100f/(float)(hits+misses) +"%", width / 2, height / 2 + 60);
    text("Total time taken: " + timeTaken + " sec", width / 2, height / 2 + 80);
    text("Average time for each button: " + nf((timeTaken)/(float)(hits+misses),0,3) + " sec", width / 2, height / 2 + 100);
    text("Average time for each button + penalty: " + nf(((timeTaken)/(float)(hits+misses) + penalty),0,3) + " sec", width / 2, height / 2 + 140);
    return; //return, nothing else to do now experiment is over
  }

  text((trialNum + 1) + " of " + trials.size(), 40, 20); //display what trial the user is on

  // Calculate snapped cursor position
  updateSnappedCursor();

  for (int i = 0; i < 16; i++)// for all buttons
    drawButton(i); //draw button

  fill(255, 0, 0, 200); // set fill color to translucent red
  ellipse(snappedX, snappedY, 20, 20); //draw user cursor as a circle with a diameter of 20
  stroke(100);
  strokeWeight(2);
  if (trialNum > 0)   {
    //angle = atan(-(((trials.get(trialNum) / 4) - (trials.get(trialNum-1) / 4)) * (padding + buttonSize))/((trials.get(trialNum) % 4) * (padding + buttonSize)-(trials.get(trialNum-1) % 4) * (padding + buttonSize)+.01));
    angle = atan2(-(((trials.get(trialNum) / 4) - (trials.get(trialNum-1) / 4)) * (padding + buttonSize)),(trials.get(trialNum) % 4) * (padding + buttonSize)-(trials.get(trialNum-1) % 4) * (padding + buttonSize));
        //if (((trials.get(trialNum) % 4) * (padding + buttonSize)-(trials.get(trialNum-1) % 4) * (padding + buttonSize)+.01) < 0) angle = PI-angle;

    float cx = (trials.get(trialNum-1) % 4) * (padding + buttonSize) + margin + buttonSize/2;
    float cy = (trials.get(trialNum-1) / 4) * (padding + buttonSize) + margin + buttonSize/2;
    println(angle*180/PI);
    for (int i = 0; i < 5; i++) {
      drawArrow(cx, cy, 10, PI-angle);
      //cx += cos(angle)*30;
      cx +=((trials.get(trialNum) % 4) * (padding + buttonSize)-(trials.get(trialNum-1) % 4) * (padding + buttonSize))/5;
      //cy -= sin(angle)*30;
      cy +=(((trials.get(trialNum) / 4) - (trials.get(trialNum-1) / 4)) * (padding + buttonSize))/5;
    }
    //line((trials.get(trialNum-1) % 4) * (padding + buttonSize) + margin + buttonSize/2, (trials.get(trialNum-1) / 4) * (padding + buttonSize) + margin + buttonSize/2, (trials.get(trialNum) % 4) * (padding + buttonSize) + margin + buttonSize/2,(trials.get(trialNum) / 4) * (padding + buttonSize) + margin + buttonSize/2);
  }
}

// New function to update snapped cursor position
void updateSnappedCursor() {
  float minDist = Float.MAX_VALUE;
  int closestButton = -1;
  
  // Find the closest button to the mouse cursor
  for (int i = 0; i < 16; i++) {
    Rectangle bounds = getButtonLocation(i);
    float buttonCenterX = bounds.x + bounds.width / 2;
    float buttonCenterY = bounds.y + bounds.height / 2;
    
    float dist = dist(mouseX, mouseY, buttonCenterX, buttonCenterY);
    
    if (dist < minDist) {
      minDist = dist;
      closestButton = i;
    }
  }
  
  // If within snap radius, snap to closest button center
  if (minDist < snapRadius && closestButton != -1) {
    Rectangle bounds = getButtonLocation(closestButton);
    snappedX = bounds.x + bounds.width / 2;
    snappedY = bounds.y + bounds.height / 2;
  } else {
    // Otherwise, use actual mouse position
    snappedX = mouseX;
    snappedY = mouseY;
  }
}

void keyPressed() //mouse was pressed! Test to see if hit was in target!
{
  if (trialNum >= trials.size()) //if task is over, just return
    return;

  if (trialNum == 0) //check if first click, if so, start timer
    startTime = millis();

  if (trialNum == trials.size() - 1) //check if final click
  {
    finishTime = millis();
    println("we're done!"); //write to terminal some output. Useful for debugging too.
  }

  Rectangle bounds = getButtonLocation(trials.get(trialNum));

 //check to see if snapped cursor is inside target button 
  if ((snappedX > bounds.x && snappedX < bounds.x + bounds.width) && (snappedY > bounds.y && snappedY < bounds.y + bounds.height)) // test to see if hit was within bounds
  {
    System.out.println("HIT! " + trialNum + " " + (millis() - startTime)); // success
    hits++; 
  } 
  else //must be a miss...
  {
    System.out.println("MISSED! " + trialNum + " " + (millis() - startTime)); // fail
    misses++;
  }

  trialNum++; //doesn't matter if user hit or missed, we move onto next trial

  //in the example code below, we can use Java Robot to move the mouse back to the middle of window
  //robot.mouseMove(width/2, (height)/2); //on click, move cursor to roughly center of window!
}  

//probably shouldn't have to edit this method
Rectangle getButtonLocation(int i) //for a given button index, what is its location and size
{
   int x = (i % 4) * (padding + buttonSize) + margin;
   int y = (i / 4) * (padding + buttonSize) + margin;
   return new Rectangle(x, y, buttonSize, buttonSize);
}

//you can edit this method to change how buttons appear if you wish. 
void drawButton(int i)
{
  Rectangle bounds = getButtonLocation(i);

  if (trials.get(trialNum) == i) // see if current button is the target
    fill(0, 255, 255); // if so, fill cyan
  //else if (trialNum < 15 && trials.get(trialNum+1) == i) fill (0,100,100);
  else {
    fill(200); // if not, fill gray
  }

  rect(bounds.x, bounds.y, bounds.width, bounds.height); //draw button
}
void drawArrow(float x, float y, int length, float angle) {
  strokeWeight(5);
  line(x, y, x+cos(angle+0.785398)*length, y + sin(angle+0.785398)*length);
  line(x, y, x+cos(angle-0.785398)*length, y+sin(angle-0.785398)*length);
}

void mouseMoved()
{
   //can do stuff everytime the mouse is moved (i.e., not clicked)
   //https://processing.org/reference/mouseMoved_.html
}

void mouseDragged()
{
  //can do stuff everytime the mouse is dragged
  //https://processing.org/reference/mouseDragged_.html
}

//void keyPressed() 
{
  //can use the keyboard if you wish
  //https://processing.org/reference/keyTyped_.html
  //https://processing.org/reference/keyCode.html
}
