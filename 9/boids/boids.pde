import java.io.FileWriter;
import java.io.IOException;

float agentDrawLengthLong = 10.0;
float agentDrawLengthMed = 5.0;
float agentDrawLengthShort = 3.0;

float visionDistanceSqr = 250.0;
float directionSustain = 0.5;
float directionUpdateRatioCrowding = 0.5;
float directionUpdateRatioAlignment = 0.5;
float directionUpdateRatioCohesion = 0.5;


class Agent {
  private float angle; // -PI ~ PI
  private FloatList position;
  private color c = color(int(random(256)),int(random(256)),int(random(256)));
  private float speed = 1.0;
  
  public Agent(float init_x, float init_y, float init_angle) {
    this.position = new FloatList();
    this.position.append(init_x);
    this.position.append(init_y);
    this.angle = init_angle;
  }
  
  public FloatList getDirection() {
    FloatList direction = new FloatList();
    direction.append(cos(this.angle));
    direction.append(sin(this.angle));
    return direction;
  }
  
  public float getAngle() { return this.angle; }
  
  public FloatList getPosition(){ return this.position; }
  
  public color getColor(){ return this.c; }
  
  public void updateAngle(ArrayList<Agent> neighborAgents){
  
      float angle1 = updateAngleWithCrowding(neighborAgents);
      float angle2 = updateAngleWithAlignment(neighborAgents);
      float angle3 = updateAngleWithCohesion(neighborAgents);
      float total = directionSustain + directionUpdateRatioCrowding 
          + directionUpdateRatioAlignment + directionUpdateRatioCohesion;
       this.angle = (directionSustain*this.angle + directionUpdateRatioCrowding*angle1+
          + directionUpdateRatioAlignment*angle2 + directionUpdateRatioCohesion*angle3)/total;
  }
  
  public float updateAngleWithCrowding(ArrayList<Agent> neighborAgents){
    int num = neighborAgents.size();
    if (num != 0) {
      FloatList alignment = new FloatList();
      alignment.append(0);
      alignment.append(0);
      for (Agent a : neighborAgents){
        float xDist = this.position.get(0) - a.getPosition().get(0);
        float yDist = this.position.get(1) - a.getPosition().get(1);
        float distance = sqrt(sq(xDist) + sq(yDist));
        alignment.add(0, xDist / distance);
        alignment.add(1, yDist / distance);
      }
      alignment.div(0, num);
      alignment.div(1, num);
      FloatList cueentDirection = this.getDirection();
      return atan2(alignment.get(1),alignment.get(0));
    }
    return this.angle;
  }
  
  public float updateAngleWithAlignment(ArrayList<Agent> neighborAgents) {
    int num = neighborAgents.size();
    float newAngle = 0.0;
    if (num != 0) {
      
      for (Agent a : neighborAgents)
        newAngle += a.getAngle();
     
     return newAngle/(float)num;
    }
     return this.angle;
  }
  
  public float updateAngleWithCohesion(ArrayList<Agent> neighborAgents) {
    int num = neighborAgents.size();
    if (num != 0) {
      FloatList center = new FloatList();
      center.append(0);
      center.append(0);
      for (Agent a : neighborAgents) {
        FloatList pos = a.getPosition();
        center.add(0, pos.get(0));
        center.add(1, pos.get(1));
      }
      center.set(0, center.get(0) / num - this.position.get(0));
      center.set(1, center.get(1) / num - this.position.get(1));
      return atan2(center.get(1), center.get(0));
    }
    return this.angle;
  }
  
  public void update() {
    FloatList newpos = new FloatList();
    newpos.append((position.get(0) + speed * cos(this.angle) + width) % width);
    newpos.append((position.get(1) + speed * sin(this.angle) + height) % height);
    position = newpos;
  }
}


// For drawing
public void drawAgent(Agent a){
  stroke(color(100));
  fill(a.getColor());
  FloatList position = a.getPosition();
  FloatList direction = a.getDirection();
  float x = position.get(0);
  float y = position.get(1);
  float dx = direction.get(0);
  float dy = direction.get(1);
  float x1 = x+agentDrawLengthLong*dx;
  float y1 = y+agentDrawLengthLong*dy;
  float pdx = -dy;
  float pdy = dx;
  float x2 = x-agentDrawLengthShort*dx+agentDrawLengthMed*pdx;
  float y2 = y-agentDrawLengthShort*dy+agentDrawLengthMed*pdy;
  float x3 = x-agentDrawLengthShort*dx-agentDrawLengthMed*pdx;
  float y3 = y-agentDrawLengthShort*dy-agentDrawLengthMed*pdy;
  triangle(x1, y1, x2, y2, x3, y3);
}


// For calculation of entropy
public int[] calculateProbability(ArrayList<Agent> agents) {
  int[] probabilityStep = new int[nAgent/binsFactor];
  for (Agent a : agents) {
    float angle = a.getAngle() < 0 ? a.getAngle() + PI : a.getAngle();
    int index = int(nAgent * angle / (2 * PI * binsFactor));
    probabilityStep[index] += 1;
  }
  return probabilityStep;
}

public float calculateEntropy(int[] probability) {
  float val = 0.0;
  for (int i = 0; i < probability.length; i++) {
    if (probability[i] > 0) {
      float pi = probability[i]/(float)nAgent;
      val -= pi*log2(pi);
    }
  }
  val -= log2(nAgent/binsFactor);
  return val;
}


// ******************** MAIN ********************
ArrayList<Agent> sampleAgents = new ArrayList<Agent>();
int nAgent = 100;
int binsFactor = 5;
int count = 0;

FileWriter fw;

void setup() {
  try {
    fw = new FileWriter("./log-3.txt");
  } catch (IOException e) {
    e.printStackTrace();
  }
  size(600, 400);
  background(255);
  for (int i = 0; i< nAgent; i++)
    sampleAgents.add(new Agent(random(width), random(height), random(2*PI) - PI));
}


void draw() {
  count++;
  if (count > 3600) {
    noLoop();
    try {
      fw.close();
    } catch (IOException e) {
      e.printStackTrace();
    }
  }
  
  // Clear
  background(255);
  
  // Entropy
  float entropyStep = calculateEntropy(calculateProbability(sampleAgents));
  if (count % 10 == 0) {
    System.out.println(entropyStep);
    try {
      fw.write(String.valueOf(entropyStep) + "\n");
    } catch (IOException e) {
      e.printStackTrace();
    }
  }
  
  // Update angles
  for (Agent a : sampleAgents) {
    FloatList posa = a.getPosition();
    ArrayList<Agent> neighbors = new ArrayList<Agent>();
    for (Agent b : sampleAgents){
      if (a != b){
        FloatList posb = b.getPosition();
        float dist = sq(posa.get(0)-posb.get(0)) + sq(posa.get(1)-posb.get(1));
        if (dist < visionDistanceSqr){
          neighbors.add(b);
        }
      }
    }
    a.updateAngle(neighbors);
  }
  
  // Draw
  for (Agent a : sampleAgents) {
    a.update();
    drawAgent(a);
  }
}

public float log2(float val){
  return log(val)/log(2);
}
