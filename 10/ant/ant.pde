import java.util.Arrays;


int environmentSize = 4;
float maximumCost = 10.0;
float maximumPheromon = 10.0;

// ******************** AGENT: ANT ********************
class Agent {
  private int position;
  ArrayList<Integer> visited = new ArrayList<Integer>();
  
  public Agent(int init_pos) {
    this.position = init_pos;
    visited.add(this.position);
  }
  
  public int getPosition() { return this.position; }
  
  public ArrayList<Integer> getVisited() { return this.visited; }
  
  public void move(int pos) {
    this.position = pos;
    visited.add(this.position);
  }
}


// ******************** MAIN STEP ********************
ArrayList<Agent> agents = new ArrayList<Agent>();
int nAgent = 50;

FloatList[][] environment;
int start = 0;
int success = 3; // floor(random(environmentSize));

// parameters
float alpha = 1.0, beta = 1.0, q = 10.0, decay = 0.0;


void printEnvironment() {
  System.out.println("Environment:");
  for (int i = 0; i < environmentSize; i++) {
    for (int j = 0; j < environmentSize; j++)
      System.out.printf("    %.2f, ", environment[i][j].get(0));
    System.out.printf("%n");
  }
}


float[][] calculateProbability() {
  float[][] probability = new float[environmentSize][];
  for (int i = 0; i < environmentSize; i++) {
    probability[i] = new float[environmentSize];
    float total = 0.0;
    for (int j = 0; j < environmentSize; j++) {
      FloatList path = environment[i][j];
      probability[i][j] = (path.get(0) == 0.0 ? 0.0 
                          : pow(path.get(1), alpha) * pow(1.0 / path.get(0), beta));
      total += probability[i][j];
    }
    if (total > 0.0) {
      for (int j = 0; j < environmentSize; j++)
        probability[i][j] = probability[i][j] / total;
    }
  }
  return probability;
}

boolean isMovable(float[] probability) {
  boolean result = false;
  for (float f : probability) {
    if (f != 0.0) {
      result = true;
      break;
    }
  }
  return result;
}

void move(Agent a, float[] probability) {
  float f = random(1.0);
  for (int i = 0; i < environmentSize; i++) {
    f -= probability[i];
    if (f < 0) {
      a.move(i);
      break;
    }
  }
}

float evaluate(Agent a) {
  ArrayList<Integer> visited = a.getVisited();
  float e = 0.0;
  for(int i = 0; i < visited.size() - 1; i++)
    e += environment[visited.get(i)][visited.get(i + 1)].get(0);
  return (e != 0.0 && a.getPosition() == success) ?  q / e : 0.0;
}

void update_environment(float[] pheromon) {
  for (int i = 0; i < environmentSize; i++) {
    for (int j = 0; j < environmentSize; j++)
      environment[i][j].set(1, (1.0 - decay) * environment[i][j].get(1));
  }
  for (int i = 0; i < agents.size(); i++) {
    ArrayList<Integer> visited = agents.get(i).getVisited();
    for (int j = 0; j < visited.size() - 1; j++) {
      environment[visited.get(j)][visited.get(j + 1)].add(1, pheromon[i]);
    }
  }
}

void step() {
  agents.clear();
  for (int i = 0; i< nAgent; i++)
    agents.add(new Agent(start));
    
  // move
  int initTime = millis();
  int interval = 5000; // 1s = 1000
  float[][] probability = calculateProbability();
  boolean flag = true;
  while (flag && millis() - initTime < interval) {
    flag = false;
    for (Agent a : agents) {
      if (isMovable(probability[a.getPosition()])) {
        move(a, probability[a.getPosition()]);
        flag = true;
      }
    }
  }
  
  // evaluate & update
  float[] pheromon = new float[nAgent];
  for (int i = 0; i < nAgent; i++)
    pheromon[i] = evaluate(agents.get(i));
  update_environment(pheromon);
}


// ******************** PATH FINDING ********************
float amount(IntList path) {
  float result = 0.0;
  for (int i = 0; i < path.size() - 1; i++)
    result += environment[path.get(i)][path.get(i + 1)].get(1);
  return result;
}

IntList make_best_path(IntList current_path) {
  ArrayList<IntList> pathresults = new ArrayList<IntList>();
  for (int i = 0; i < environmentSize; i++) {
    if (current_path.hasValue(i) ||
        environment[current_path.get(current_path.size() - 1)][i].get(0) == 0.0)
      continue;
    IntList next = new IntList();
    for (int pos : current_path)
      next.append(pos);
    next.append(i);
    pathresults.add(make_best_path(next));
  }
  
  IntList result = current_path;
  float minamount = maximumCost * environmentSize;
  for (IntList l : pathresults) {
    float amnt = amount(l);
    if (amnt < minamount) {
      minamount = amnt;
      result = l;
    }
  }
  return result;
}

void calc() {
  IntList init_list = new IntList();
  init_list.append(start);
  IntList result = make_best_path(init_list);
  System.out.print("BEST PATH: ");
  for (int i : result) {
    System.out.print(i);
  }
  System.out.printf("%n");
}


// ******************** DRAW ********************
float prev_max = 0.0;

void setup() {
  size(500, 500);
  frameRate(2.0);
  background(255);
  System.out.println("start = " + start + ", success = " + success);
  environment = new FloatList[environmentSize][];
  for (int i = 0; i < environmentSize; i++) {
    environment[i] = new FloatList[environmentSize];
    for (int j = 0; j < environmentSize; j++) {
      FloatList path = new FloatList();
      //if (i != j && i != success && int(random(environmentSize)) != 0)
      //  path.append(random(0.5, maximumCost));
      //else 
      path.append(0);
      path.append(0.1);
      environment[i][j] = path;
    }
  }
  //int n = success;
  //while (n == success)
  //  n = floor(random(environmentSize));
  //environment[n][success].set(0, random(0.5, maximumCost));
  environment[0][1].set(0, random(0.5, maximumCost));
  environment[0][2].set(0, random(0.5, maximumCost));
  environment[1][2].set(0, random(0.5, maximumCost));
  environment[1][3].set(0, random(0.5, maximumCost));
  environment[2][3].set(0, random(0.5, maximumCost));
  
  printEnvironment();
  calc();
  step();
  for (FloatList[] l : environment) {
    for (FloatList path : l) {
      if (path.get(1) > maximumPheromon)
        maximumPheromon = path.get(1);
    }
  }
  maximumPheromon = maximumPheromon * 5; // てきとう
}

void draw() {
  background(255);
  
  // draw
  float max = 0.0;
  for (int i = 0; i < environmentSize; i++) {
    for (int j = 0; j < environmentSize; j++) {
      if (environment[i][j].get(1) > max)
        max = environment[i][j].get(1);
      stroke(color(100));
      //fill(255 * (environment[i][j].get(1) / maximumPheromon),
      //     255,
      //     255 * (environment[i][j].get(0) / maximumCost));
      fill(255 * (1.0- environment[i][j].get(1) / maximumPheromon),
           255,
           255 * (1.0 - environment[i][j].get(1) / maximumPheromon));
      rect(j * (width / environmentSize), i * (height / environmentSize),
           width / environmentSize, height / environmentSize);
      fill(0);
      textAlign(CENTER);
      text(str(i)+" → " + str(j), 
           (j + 0.5) * (width / environmentSize),
           (i + 0.5) * (height / environmentSize));
    }
  }
  if (max == prev_max)
    System.out.println("prev_max = max = " + max);
  prev_max = max;
  
  step();
}
