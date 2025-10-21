//when in doubt, consult the Processsing reference: https://processing.org/reference/

//Importing some useful packages
import java.awt.AWTException;
import java.awt.Rectangle;
import java.awt.Robot;
import java.util.ArrayList;
import java.util.Collections;
import processing.core.PApplet;

// import for CSV writing
import java.io.PrintWriter;

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
float snappedX, snappedY; 
final float snapRadius = 150; 

int numRepeats = 1; //sets the number of times each button repeats in the user study. 1 = each square will appear as the target once.

// constant to track start time and cursor location
int participantID = 1;        
float trialStartCursorX = 0;  
float trialStartCursorY = 0;   
int trialStartMillis = 0;     
PrintWriter csv;               
boolean csvOpen = false;       

void setup()
{
  size(700, 700); // set the size of the window
  textFont(createFont("Arial", 16)); //sets the font
  textAlign(CENTER);
  frameRate(60);
  ellipseMode(CENTER);

  try {
    robot = new Robot(); 
  } 
  catch (AWTException e) {
    e.printStackTrace();
  }

  //===DON'T MODIFY MY RANDOM ORDERING CODE==
  for (int i = 0; i < 16; i++)
    for (int k = 0; k < numRepeats; k++)
      trials.add(i);
  Collections.shuffle(trials);
  System.out.println("trial order: " + trials);
  
  surface.setLocation(0,0);

  // Print a header
  // System.out.println("Trial,ParticipantID,CursorStartX,CursorStartY,TargetCenterX,TargetCenterY,TargetWidth,TimeSecs,Success"); // CHANGED: no console header now that we save CSV

  // initialize CSV
  csv = createWriter("bakeoff_data_PID_" + participantID + ".csv");
  csv.println("ParticipantID,Trial,CursorStartX,CursorStartY,TargetCenterX,TargetCenterY,TargetWidth,TimeSecs,Success");
  csv.flush(); 
  csvOpen = true;

  // Update initial position and time
  trialStartCursorX = mouseX;   
  trialStartCursorY = mouseY;  
  trialStartMillis  = millis();
}

void draw()
{
  background(0);
  fill(255);

  if (trialNum >= trials.size())
  {
    float timeTaken = (finishTime-startTime) / 1000f;
    float penalty = constrain(((95f-((float)hits*100f/(float)(hits+misses)))*.2f),0,100);
    
    text("Finished!", width / 2, height / 2); 
    text("Hits: " + hits, width / 2, height / 2 + 20);
    text("Misses: " + misses, width / 2, height / 2 + 40);
    text("Accuracy: " + (float)hits*100f/(float)(hits+misses) +"%", width / 2, height / 2 + 60);
    text("Total time taken: " + timeTaken + " sec", width / 2, height / 2 + 80);
    text("Average time for each button: " + nf((timeTaken)/(float)(hits+misses),0,3) + " sec", width / 2, height / 2 + 100);
    text("Average time for each button + penalty: " + nf(((timeTaken)/(float)(hits+misses) + penalty),0,3) + " sec", width / 2, height / 2 + 140);

    // close CSV when experiment over
    if (csvOpen && csv != null) {
      csv.flush();                
      csv.close();                
      csvOpen = false;            
    }                             
    return;
  }

  text((trialNum + 1) + " of " + trials.size(), 40, 20);

  updateSnappedCursor();

  for (int i = 0; i < 16; i++)
    drawButton(i);

  if (trialNum > 0) {
    stroke(100);
    strokeWeight(2);
    angle = atan2(-(((trials.get(trialNum) / 4) - (trials.get(trialNum-1) / 4)) * (padding + buttonSize)), 
                 (trials.get(trialNum) % 4) * (padding + buttonSize)-(trials.get(trialNum-1) % 4) * (padding + buttonSize));

    float cx = (trials.get(trialNum-1) % 4) * (padding + buttonSize) + margin + buttonSize/2;
    float cy = (trials.get(trialNum-1) / 4) * (padding + buttonSize) + margin + buttonSize/2;
    //println(angle*180/PI);
    for (int i = 0; i < 5; i++) {
      drawArrow(cx, cy, 10, PI-angle);
      cx += ((trials.get(trialNum) % 4) * (padding + buttonSize)-(trials.get(trialNum-1) % 4) * (padding + buttonSize))/5;
      cy += (((trials.get(trialNum) / 4) - (trials.get(trialNum-1) / 4)) * (padding + buttonSize))/5;
    }
  }

  noStroke();
  fill(255, 0, 0, 200);
  ellipse(snappedX, snappedY, 20, 20);
}

void updateSnappedCursor() {
  float minDist = Float.MAX_VALUE;
  int closestButton = -1;
  
  for (int i = 0; i < 16; i++) {
    Rectangle bounds = getButtonLocation(i);
    float buttonCenterX = bounds.x + bounds.width / 2;
    float buttonCenterY = bounds.y + bounds.height / 2;
    
    float d = dist(mouseX, mouseY, buttonCenterX, buttonCenterY);
    if (d < minDist) {
      minDist = d;
      closestButton = i;
    }
  }
  
  if (minDist < snapRadius && closestButton != -1) {
    Rectangle bounds = getButtonLocation(closestButton);
    snappedX = bounds.x + bounds.width / 2;
    snappedY = bounds.y + bounds.height / 2;
  } else {
    snappedX = mouseX;
    snappedY = mouseY;
  }
}

void keyPressed()
{
  if (trialNum >= trials.size())
    return;

  if (trialNum == 0) // start global timer on first click
    startTime = millis();

  Rectangle bounds = getButtonLocation(trials.get(trialNum));

  boolean hit = (snappedX > bounds.x && snappedX < bounds.x + bounds.width) &&
                (snappedY > bounds.y && snappedY < bounds.y + bounds.height);

  int success = 0;

  if (hit) {
    hits++;
    success = 1;
  } else {
    misses++;
  }
  
  // Compute Center Coordinate of Target
  float targetCenterX = bounds.x + bounds.width / 2.0f;
  float targetCenterY = bounds.y + bounds.height / 2.0f;
  float timeSecs = (millis() - trialStartMillis) / 1000.0f;

  // build csv row
  String row = 
    participantID + "," +
    (trialNum + 1) + "," +                 
    nf(trialStartCursorX, 0, 0) + "," +    
    nf(trialStartCursorY, 0, 0) + "," +   
    nf(targetCenterX, 0, 0) + "," +        
    nf(targetCenterY, 0, 0) + "," +        
    buttonSize + "," +                  
    nf(timeSecs, 0, 3) + "," +             
    success;                                    

  // === ADDED: write to CSV (only for correct trials) ===
  if (csvOpen && csv != null) { 
    csv.println(row);           
    csv.flush();                
  }                            
  
  // don't increment if done
  if (trialNum == trials.size() - 1) { 
    finishTime = millis();             
    println("Tracking Done");            

    // close CSV at the end as a safety (also closed in draw() end-state)
    if (csvOpen && csv != null) { 
      csv.flush();                
      csv.close();               
      csvOpen = false;            
    }                             

    trialNum++;                        
    return;                            
  }

  // Update the cursor location for the NEXT trial
  trialNum++;                                  
  trialStartCursorX = mouseX;                  
  trialStartCursorY = mouseY;                  
  trialStartMillis  = millis();                
}

Rectangle getButtonLocation(int i)
{
   int x = (i % 4) * (padding + buttonSize) + margin;
   int y = (i / 4) * (padding + buttonSize) + margin;
   return new Rectangle(x, y, buttonSize, buttonSize);
}

void drawButton(int i)
{
  Rectangle bounds = getButtonLocation(i);
  
  boolean isHovered = (snappedX > bounds.x && snappedX < bounds.x + bounds.width) && 
                      (snappedY > bounds.y && snappedY < bounds.y + bounds.height);

  if (trials.get(trialNum) == i && isHovered)
    fill(255, 165, 0);
  else if (trials.get(trialNum) == i)
    fill(0, 255, 255);
  else
    fill(200);

  rect(bounds.x, bounds.y, bounds.width, bounds.height);
}

void drawArrow(float x, float y, int length, float angle) {
  stroke(255, 165, 0);
  strokeWeight(5);
  line(x, y, x+cos(angle+0.785398)*length, y + sin(angle+0.785398)*length);
  line(x, y, x+cos(angle-0.785398)*length, y+sin(angle-0.785398)*length);
}

void mouseMoved(){}
void mouseDragged(){}
//void keyPressed(){ /* unused variant */ }
