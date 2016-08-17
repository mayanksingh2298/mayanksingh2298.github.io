class Player {
  int[][] map;
  boolean isAlive = true;
  int x, y;
  int direction;
  int speed=1;
  float cooloff=0.03;
  long dirtaken; 

  public Player(int X, int Y, int d) {
    x = X;
    y = Y;
    map = new int[width][height];
    direction = d;
    dirtaken = (new Date).getTime();

    for (int i=0; i<width; i++)
      for (int j=0; j<height; j++)
        if (i<=3 || j<=3 || i== (width-1) || j == (height-1))
          map[i][j]=1;
  }

  int rand2(int a, int b) {
    float rand = random(0, 100);
    if (rand<50)
      return a;
    else
      return b;
  }


  void randomizeDirection(Player opponent) {
    if (((new Date).getTime()-dirtaken) >=cooloff*1000) {
      dirtaken=(new Date).getTime();
      switch(direction) {
      case 0:
        for (int j=y; j>0&&y-j<=40; j--) {
          if (opponent.map[x][j]==1) {
            direction = rand2(1, 3);
            break;
          }
        }
        break;
      case 3:
        for (int i=x; i>0&&x-i<=40; i--) 
          if (opponent.map[i][y]==1) {
            direction = rand2(0, 2);
            break;
          }

        break;
      case 2:
        for (int j=y; j<height&&j-y<=40; j++)
          if (opponent.map[x][j]==1) {
            direction = rand2(1, 3);
            break;
          }
        break;
      case 1:
        for (int i=x; i<width&&i-x<=40; i++)
          if (opponent.map[i][y]==1) {
            direction = rand2(0, 2);
            break;
          }
        break;
      }
    }
  }

  void left() {
    if (x-speed>=0)
      x-=speed;
  }

  void right() {
    if (x+speed<width)
      x+=speed;
  }

  void up() {
    if (y-speed>=0)
      y-=speed;
  }

  void down() {
    if (y+speed<height)
      y+=speed;
  }

  void draw() {
    switch(direction) {
    case 0: 
      up(); 
      break;
    case 1: 
      right();
      break;
    case 2: 
      down();
      break;
    case 3: 
      left();
      break;
    }
    text("*", x, y);
    map[x][y] = 1;
  }
}



Player p1;
Player p2;
boolean started=false;
void setup() {
  size(500, 400);
  background(123, 31, 162);
  rectMode(CENTER);
  textAlign(CENTER);
  noStroke();
  
  smooth();

  p1 = new Player((width/2)-100, (height/2), 1);
  p2 = new Player((width/2)+100, (height/2), 3);

  frameRate(180);
  if (!started) {
    fill(33, 33, 33);
    rect(width/2, height/2 -10, 170, 50);
    fill(233, 30, 99);
    textSize(32);
    text("Start", width/2, height/2);
  }


  textSize(14);


}

void draw() {
  if (p1.isAlive && p2.isAlive && started) {
    fill(233, 30, 99);
    p1.draw();
    fill(33, 33, 33);
    p2.draw();
    p2.randomizeDirection(p1);
  }

  if (p2.map[p1.x][p1.y]==1) {
    p1.isAlive=false;
    fill(33, 33, 33);
    rect(width/2, height/2 -10, 170, 50);
    fill(233, 30, 99);
    textSize(32);
    text("You lose", width/2, height/2);
  }
  if (p1.map[p2.x][p2.y]==1) {
    p2.isAlive=false;
    fill(33, 33, 33);
    rect(width/2, height/2 -10, 170, 50);
    fill(233, 30, 99);
    textSize(32);
    text("You Win", width/2, height/2);
  }
}

void keyReleased()
{ 
  if (started)
    switch(key) {
    case 'w':
      if (p1.direction!=2)
        p1.direction=0;
      break;
    case 'a':
      if (p1.direction!=1)
        p1.direction=3;
      break;
    case 's':
      if (p1.direction!=0)
        p1.direction=2;
      break;
    case 'd':
      if (p1.direction!=3)
        p1.direction=1;
      break;
    }
}

void mousePressed() {
  if (!started) {
    if (mouseX<(width/2 +85) && mouseX>(width/2 -85) && mouseY<(height/2 -10 +25) && mouseY>(height/2 -10 -25)) {
      background(123, 31, 162);
      started=true;
    }
  }
  if (!p1.isAlive || !p2.isAlive) {
    if (mouseX<(width/2 +85) && mouseX>(width/2 -85) && mouseY<(height/2 -10 +25) && mouseY>(height/2 -10 -25)) {
      setup();
    }
  }
}