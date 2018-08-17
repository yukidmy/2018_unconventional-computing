import java.io.FileWriter;
import java.io.IOException;
import java.util.Arrays;
import java.util.Random;


// ******************** AGENT ********************
class Agent {
  private FloatList position = new FloatList();
  private ArrayList<Agent> attached = new ArrayList<Agent>();
  private HashMap<Integer, Float> concentrations = new HashMap<Integer, Float>();
  private boolean isMoved = false;
  
  public Agent(float init_x, float init_y, int[] keys) {
    position.append(init_x);
    position.append(init_y);
    for (int i : keys) concentrations.put(i, new Float(i * 5));
  }
  
  public FloatList getPosition() { return position; }
  public float getConcentration(int n) { return concentrations.getOrDefault(n, 0.0); }
  
  public boolean isAttached() { return !attached.isEmpty(); }
  public boolean isAttached(Agent a) { return attached.contains(a); }
  
  public void attach(Agent a) {
    if (attached.contains(a)) return;
    attached.add(a);
    a.attach(this);
  }
  public void release(Agent a) {
    if (!attached.contains(a)) return;
    attached.remove(a);
    a.release(this);
  }
  
  public float dist(Agent a) {
    return sqrt(pow(position.get(0) - a.getPosition().get(0),2)
              + pow(position.get(1) - a.getPosition().get(1),2));
  }
  
  public void startMoving() { isMoved = false; }
  public void move(float move_x, float move_y) {
    if (this.isMoved) return;
    isMoved = true;
    position.set(0, (position.get(0) + move_x + width) % width);
    position.set(1, (position.get(1) + move_y + height) % height);
    for (Agent a : attached)
      a.move(move_x, move_y);
  }
}


// ******************** MAIN ********************
ArrayList<Agent> beads = new ArrayList<Agent>();
int nAgent = 100;
int[] species = { 0, 1, 2 };
int[] agentSpecies = { 1 };

int envSize = 10;
HashMap<Integer, Float[][]> environment = new HashMap<Integer, Float[][]>();
HashMap<Integer, Float[][]> totalConcentrations = new HashMap<Integer, Float[][]>();

float k1 = 0.7, k2 = 0.7, k3 = 0.5, k4 = 0.5;
float d = 0.0001;
float neighbordist = 10.0;

float max_init_a = 100.0;

Random rand = new Random();
float d1 = 0.1;

ArrayList<Agent> collectNeighbors(Agent a1) {
   ArrayList<Agent> neighbors = new ArrayList<Agent>();
   for (Agent a2 : beads)
     if (a1 != a2 && a1.dist(a2) < neighbordist) neighbors.add(a2);
   return neighbors;
}

void actuation() {
  // a + 2 * ○ -> k1 -> ●●
  // ●● -> k2 -> a + 2 * ○
  for (Agent a : beads) {
    int x = int(a.getPosition().get(0) * envSize / width);
    int y = int(a.getPosition().get(1) * envSize / height);
    for (Agent neighbor : collectNeighbors(a)) {
      if (!a.isAttached(neighbor) && random(1.0) < k1 / 2 &&
          random(1.0) * max_init_a * 1.0E5 < totalConcentrations.get(0)[x][y]) {
        a.attach(neighbor);
        environment.get(0)[x][y] -= 1.0;
      } else if (a.isAttached(neighbor) && random(1.0) < k2 / 2 &&
                 random(1.0) * max_init_a * 1.0E20 > totalConcentrations.get(0)[x][y]) {
        a.release(neighbor);
        environment.get(0)[x][y] += 1.0;
      }
    }
  }
}

void move() {
  for (Agent a : beads)
    a.startMoving();
  for (Agent a : beads) 
    a.move((float)rand.nextGaussian() * sqrt(2 * d1),
           (float)rand.nextGaussian() * sqrt(2 * d1));
}

void updateEnvironment() {
  for (int i : species) {
    Float[][] env = new Float[envSize][];
    for (int j = 0; j < envSize; j++) {
      env[j] = Arrays.copyOf(environment.get(i)[j], environment.get(i)[j].length);
    }
    totalConcentrations.put(i, env);
  }
  
  for (Agent a : beads) {
    for (int i : agentSpecies) {
      int x = int(a.getPosition().get(0) * envSize / width);
      int y = int(a.getPosition().get(1) * envSize / height);
      totalConcentrations.get(i)[x][y] += a.getConcentration(i);
    }
  }
}

void ReactionDefusion () {
  // Reaction Defusion
  // B + C -> k3 -> B + a
  // C -> k4 -> 2C
  HashMap<Integer, Float[][]> nextEnvironment = new HashMap<Integer, Float[][]>();
  HashMap<Integer, Float[][]> nextTotalConcentrations = new HashMap<Integer, Float[][]>();
  for (int s : species) {
    nextEnvironment.put(s, new Float[envSize][envSize]);
    nextTotalConcentrations.put(s, new Float[envSize][envSize]);
  }
  
  for (int i = 0; i < envSize; i++) {
    for (int j = 0; j < envSize; j++) {
      float[] dxdt = {
        k3 * totalConcentrations.get(1)[i][j] * totalConcentrations.get(2)[i][j],
        0.0,
        (k4 - k3 * totalConcentrations.get(1)[i][j]) * totalConcentrations.get(2)[i][j]
      };
      
      for (int s : species) {
        float inflow = 0.0;
        for (int k = i - 1; k < i + 2; k++) {
          for (int l = j - 1; l < j + 2; l++) {
            if (k == i && l == j) continue;
            inflow += totalConcentrations.get(s)[(k + envSize) % envSize][(l + envSize) % envSize];
          }
        }
        dxdt[s] += d * (inflow - 8 * totalConcentrations.get(s)[i][j]);
        nextTotalConcentrations.get(s)[i][j] = totalConcentrations.get(s)[i][j] + dxdt[s];
        nextEnvironment.get(s)[i][j] = environment.get(s)[i][j] + dxdt[s];
        if (nextTotalConcentrations.get(s)[i][j] < 0.0)
          nextTotalConcentrations.get(s)[i][j] = 0.0;
        if (nextEnvironment.get(s)[i][j] < 0.0)
          nextEnvironment.get(s)[i][j] = 0.0;
      }
    }
  }
  
  for (int s : species) {
    environment.put(s, nextEnvironment.get(s));
    totalConcentrations.put(s, nextTotalConcentrations.get(s));
  }
}

void setup() {
  size(500, 500);
  frameRate(128.0);
  background(255);
  
  
  for (int i = 0; i < nAgent; i++)
    beads.add(new Agent(random(width), random(height), agentSpecies));
    
  for (int i : species) {
    Float[][] env = new Float[envSize][];
    for (int j = 0; j < envSize; j++) {
      env[j] = new Float[envSize];
      for (int k = 0; k < envSize; k++) {
        if (j > 0.3 * envSize && j < 0.7 * envSize)
          env[j][k] = max_init_a;
        else
          env[j][k] = 0.0;
      }
    }
    environment.put(i, env);
    totalConcentrations.put(i, env);
  }
    
  
}

void drawAgent(Agent a) {
  stroke(color(100));
  fill(a.isAttached() ? 0 : 255);
  ellipse(a.getPosition().get(0), a.getPosition().get(1), 8, 8);
}

void drawEnvironment() {
  for (int i = 0; i < envSize; i++) {
    for (int j = 0; j < envSize; j++) {
      stroke(color(100));
      fill(255 * (1.0 - totalConcentrations.get(0)[i][j] / max_init_a),  // a
           255 * (1.0 - totalConcentrations.get(1)[i][j] / max_init_a),  // B
           255 * (1.0 - totalConcentrations.get(2)[i][j] / max_init_a)); // C
      rect(i * (width / envSize), j * (height / envSize),
           width / envSize, height / envSize);
      fill(0);
    }
  }
}

void draw() {
  background(255);
  
  // 0) Move beads
  actuation();
  move();
  
  // 1) For each cell: update concentrations
  updateEnvironment();
  
  // 2) For each cell: compute derivative and apply
  ReactionDefusion();
  
  // draw
  drawEnvironment();
  for (Agent a : beads) 
    drawAgent(a);
}
