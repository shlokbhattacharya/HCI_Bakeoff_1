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
int misses = 0; //number of missed clicks
Robot robot; //initialized in setup 

int numRepeats = 1; //sets the number of times each button repeats in the user study. 1 = each square will appear as the target once.

// Snapping feature
final float SNAP_DISTANCE = 100;
int snappedX = -1;
int snappedY = -1;

// Arrows-to-next feature
float angle;

void setup()
{
  size(700, 700); // set the size of the window
  //noCursor(); //hides the system cursor if you want
  textFont(createFont("Arial", 16)); //sets the font to Arial size 16
  textAlign(CENTER);
  frameRate(60);
  ellipseMode(CENTER); //ellipses are drawn from the center (BUT RECTANGLES ARE NOT! By default, rectangles are drawn from their upper left corner. )

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

  for (int i = 0; i < 16; i++)// for all buttons
    drawButton(i); //draw button

  // Snapping feature
  updateSnappedPosition();

  // Larger cursor feature
  int cx = (snappedX != -1 && snappedY != -1) ? snappedX : mouseX;
  int cy = (snappedY != -1 && snappedX != -1) ? snappedY : mouseY;
  fill(255, 0, 0, 200);
  noStroke();
  ellipse(cx, cy, 35, 35);
  stroke(255);
  strokeWeight(3);
  noFill();
  ellipse(cx, cy, 39, 39);
  noStroke();

  // Arrows-to-next feature
  stroke(100);
  strokeWeight(2);
  if (trialNum > 0) {
    angle = atan2(
      -(((trials.get(trialNum) / 4) - (trials.get(trialNum-1) / 4)) * (padding + buttonSize)),
      (trials.get(trialNum) % 4) * (padding + buttonSize) - (trials.get(trialNum-1) % 4) * (padding + buttonSize)
    );

    float ax = (trials.get(trialNum-1) % 4) * (padding + buttonSize) + margin + buttonSize/2;
    float ay = (trials.get(trialNum-1) / 4) * (padding + buttonSize) + margin + buttonSize/2;

    for (int i = 0; i < 5; i++) {
      drawArrow(ax, ay, 10, PI - angle);
      ax += ((trials.get(trialNum) % 4) * (padding + buttonSize) - (trials.get(trialNum-1) % 4) * (padding + buttonSize)) / 5.0;
      ay += (((trials.get(trialNum) / 4) - (trials.get(trialNum-1) / 4)) * (padding + buttonSize)) / 5.0;
    }
  }
  noStroke();
}

// Snapping feature
void updateSnappedPosition() {
  float minDistance = SNAP_DISTANCE;
  int closestButtonX = -1;
  int closestButtonY = -1;
  
  for (int i = 0; i < 16; i++) {
    Rectangle bounds = getButtonLocation(i);
    int buttonCenterX = bounds.x + bounds.width / 2;
    int buttonCenterY = bounds.y + bounds.height / 2;
    float distance = dist(mouseX, mouseY, buttonCenterX, buttonCenterY);
    if (distance < minDistance) {
      minDistance = distance;
      closestButtonX = buttonCenterX;
      closestButtonY = buttonCenterY;
    }
  }
  snappedX = closestButtonX;
  snappedY = closestButtonY;
}

// Arrows-to-next feature
void drawArrow(float x, float y, int length, float angle) {
  strokeWeight(5);
  line(x, y, x + cos(angle + 0.785398) * length, y + sin(angle + 0.785398) * length);
  line(x, y, x + cos(angle - 0.785398) * length, y + sin(angle - 0.785398) * length);
}

// Keyboard press (in arrowsToNext branch)
void keyPressed()
{
  if (trialNum >= trials.size())
    return;

  if (trialNum == 0)
    startTime = millis();

  if (trialNum == trials.size() - 1) {
    finishTime = millis();
    println("we're done!");
  }

  Rectangle bounds = getButtonLocation(trials.get(trialNum));

  int clickX = (snappedX != -1) ? snappedX : mouseX;
  int clickY = (snappedY != -1) ? snappedY : mouseY;

  if ((clickX > bounds.x && clickX < bounds.x + bounds.width) &&
      (clickY > bounds.y && clickY < bounds.y + bounds.height)) {
    System.out.println("HIT! " + trialNum + " " + (millis() - startTime));
    hits++; 
  } else {
    System.out.println("MISSED! " + trialNum + " " + (millis() - startTime));
    misses++;
  }

  trialNum++;
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
  else
    fill(200); // if not, fill gray

  rect(bounds.x, bounds.y, bounds.width, bounds.height); //draw button
}

void mouseMoved()
{
   //https://processing.org/reference/mouseMoved_.html
}

void mouseDragged()
{
  //https://processing.org/reference/mouseDragged_.html
}
