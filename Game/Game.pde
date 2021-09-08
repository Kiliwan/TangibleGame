// Game settings
int window_height = 800;
int window_width = 1200;
void settings() {
    size(window_width, window_height, P3D);
}

// Ball
Mover ball;
PShape globe;

// Game surfaces
PGraphics gameSurface;
PGraphics bottomSurface;
PGraphics topView;
PGraphics scoreboard;
PGraphics barChart;
PGraphics victorySurface;

// Scrollbar
HScrollbar hs;

// Font
PFont f;
int fontSize = 16;

// Villain
PShape villain;

// Score
static double totalScore;
static double lastScore;
static ArrayList<Double> score_history = new ArrayList<Double>();

//Winning
boolean win;
static ArrayList<Float> ellipses = new ArrayList<Float>();

// Game values

// colors
color cylinderColor = color(255);
color bossColor = color(255,0,0);
color boardColor = color(192,192,192);
color gameBackground = color(255,255,255);
color text = color(0,0,0);
color bottomBackground = color(220,220,200);
color topView_boardColor = color(64,224,208);
color topView_ballColor = color(0,0,255);
color topView_cylinderColor = color(255,255,255);
color topView_bossColor = color(255,0,0);
color scoreboardColor = color(240,248,255);
color barChartColor = color(210,126,255);
color barChart_rectangleColor = color(110,189,49);
color scrollbarColor = color(104);
color scrollbarCursorColor_active = color(0);
color scrollbarCursorColor_inactive = color(104);
color victoryBackground = color(0);
color victoryText = color(255);

// scrollbar
int barHeight = 20;
int barLength = 300;

// score
double cylinderPoint = 1;
double bossPoint = 10;
int pointsPerSquare = 2;

// inteface
int bottomSpace = 300;
int bottomMargin = 5;
int moduleSize = 300;
int bottomPadding = 1;

// top view
int topView_ballRadius = 5;
int topView_cylinderRadius = 10;

// graph
int graphMiddle = bottomSpace - 60;
float squareHeight = 5;
float squareWidth = 5;

// box
int box_size = 600;
int box_width = 10;

// ball

int ballRadius = 15;

// cylinder
ParticleSystem partSys;
int cylinderRadius = 30;
int cylinderHeight = 50;
int cylinderResolution = 10;

// board movement speed
float speed = 1000;

// speed changing rate
int speedRate=5;

void setup() {
  
    f = createFont("Arial",16,true);
    surface.setTitle("Project");

    globe= createShape(SPHERE, ballRadius);
    globe.setStroke(false);
    globe.setTexture(loadImage("earth.jpg"));
    ball = new Mover(box_size,box_width,ballRadius,globe);

    partSys = null; //Initialization as null by default
    villain = loadShape("robotnik.obj");
    villain.setTexture(loadImage("robotnik.png"));
    villain.scale(100);
    villain.rotateX(PI);
    villain.rotateY(PI);

    //Scrollbar
    hs = new HScrollbar(moduleSize*2 + bottomMargin*3, height - barHeight - bottomMargin, barLength, barHeight);

    //Surfaces
    gameSurface = createGraphics(width,height-bottomSpace,P3D);
    bottomSurface = createGraphics(width,bottomSpace,P2D);
    topView = createGraphics(moduleSize,bottomSpace,P2D);
    scoreboard = createGraphics(moduleSize,bottomSpace,P2D);
    barChart = createGraphics(moduleSize, bottomSpace-barHeight, P2D);
    
    victorySurface = createGraphics(width, height, P3D);

    totalScore = 20; // EST_CE QUON VEUT BIEN RESET LE SCORE A CHAQUE FOIS OU CEST UNE ERREUR ?
    lastScore = 0;
    rx = 0;
    rz = 0;
    win = false;
}

//default value for rotation
float rx = 0;
float rz = 0;

//dampening rate
float damp = 0.8;

//temporary rotation
float rh_vector = 0;
float rv_vector = 0;

// User insteraction
void mouseDragged() {
    if(!hs.locked) {
        rx += (mouseY - pmouseY)/speed;
        if(rx > PI/3) {
            rx = PI/3;
        } else if(rx < -PI/3) {
            rx = -PI/3;
        }

        rz += (mouseX - pmouseX)/speed;
        if(rz > PI/3) {
            rz = PI/3;
        } else if(rz < -PI/3) {
            rz = -PI/3;
        }
    }


}

// Variable to check if shift has been / is being pressed
boolean shiftPressed = false;

// Shift detection
void keyPressed() {
    if(key == CODED) {
        if(keyCode == SHIFT) {
            shiftPressed = true;
        }
    }
}
void keyReleased() {
    if(key == CODED) {
        if(keyCode == SHIFT) {
            shiftPressed = false;
        }
    }
}

// Mouse click detection
void mouseClicked() {
    // Restart the game
    if(win == true){
      win = false;
      ellipses.clear();
      setup();
    }else if(shiftPressed == true) {
        float x = mouseX - width/2;
        float z = mouseY - height/2;
        if(isInsideBox(x,z) && isNotOnBall(x,z)) {
            fill(bossColor);
            partSys = new ParticleSystem(new PVector(x, 0, z), cylinderRadius, cylinderHeight, cylinderResolution, villain, cylinderPoint, bossPoint);
        }
    }
    
}

// Check if inside box
boolean isInsideBox(float x, float z) {
    return ( (x>(-box_size/2 + cylinderRadius)) && (x<(box_size/2 - cylinderRadius)) && (z>(-box_size/2 + cylinderRadius)) && (z<(box_size/2 - cylinderRadius)));
}

// Check if not on ball
boolean isNotOnBall(float x, float z) {
    PVector ballToMouse = new PVector((ball.location.x - x), 0, (ball.location.z - z));
    float cylinderDistance = cylinderRadius + ballRadius;
    return (ballToMouse.mag()>cylinderDistance);
}

// Mouse scroll detection
void mouseWheel(MouseEvent event) {
    float count = event.getCount();
    if(count > 0 && speed < 2000) {
        speed += speedRate;
    } else if(count < 0 && speed > 10) {
        speed -= speedRate;
    }
}

////////////////DRAWING SURFACES//////////////////////////

void drawVictory() {
  
      victorySurface.beginDraw();
      
      victorySurface.translate(width, height);
      victorySurface.background(victoryBackground);
      
      if(frameCount%2 == 0) {
        ellipses.add(random(-width, 0));
        ellipses.add(random(-height, 0));
        ellipses.add(random(0, 255));
        ellipses.add(random(0, 255));
        ellipses.add(random(0, 255));
      }
      
      for(int i = 0; i < ellipses.size(); i += 5){
        victorySurface.noStroke();
        victorySurface.ellipse(ellipses.get(i), ellipses.get(i + 1), 10, 10);
        victorySurface.fill(ellipses.get(i + 2), ellipses.get(i + 3), ellipses.get(i + 4));
      }
      
      victorySurface.textFont(f,32);
      victorySurface.fill(victoryText);
      victorySurface.textAlign(CENTER, CENTER);
      victorySurface.text( "WELL DONE \n Click to play again ", -width/2, -height/2);
      
      victorySurface.endDraw();

}

void drawGame() {
    
      // Start drawing on game surface
      gameSurface.beginDraw();
  
      //Set background to background
      gameSurface.background(gameBackground);
  
      //Put object in the center
      gameSurface.translate(width/2, height/2);
      
      // Normal
      if(shiftPressed == false) {
  
          //Box movement
          gameSurface.pushMatrix();
          gameSurface.rotateZ(rz);
          gameSurface.rotateX(-rx);
  
          //Drawing board
          gameSurface.fill(boardColor);
          gameSurface.box(box_size, box_width, box_size);
  
          //Particles
          if(partSys != null && !partSys.particles.isEmpty()) {
              win = partSys.run(gameSurface,ball.velocity.mag(),cylinderColor);
              //Adds a cylinder every 0.5 seconds, as processing is displaying 60 frames/s
              if(frameCount%30 == 0) {
                  partSys.addParticle();
              }
              //Villain
              gameSurface.pushMatrix();
              float angle = atan2(partSys.origin.x-ball.location.x,partSys.origin.z-ball.location.z);
              gameSurface.translate(partSys.origin.x, -cylinderHeight, partSys.origin.z);
              gameSurface.rotateY(angle-PI);
              gameSurface.shape(villain);
              gameSurface.popMatrix();
          }
  
          gameSurface.popMatrix();
          //End box movement
  
          //Information on the window
          gameSurface.textFont(f,16);
          gameSurface.fill(text);
          gameSurface.text( "RotationX: " + rx * 180/PI, -width/2 + 10, -height/2 + 20);
          gameSurface.text( "RotationZ: " + rz * 180/PI, -width/2 + 10, -height/2 + 40);
          gameSurface.text( "Speed: " + 200/speed, -width/2 + 10, -height/2 + 60);
  
          // Ball
          ball.update(rx, rz);
          ball.checkEdges();
          ball.display(gameSurface);
  
          // Shift mode
      } else {
  
          // Drawing board
          gameSurface.fill(boardColor);
          gameSurface.box(box_size, box_size, 0);
  
          //Place in correct view
          gameSurface.pushMatrix();
          gameSurface.rotateX(PI/2);
          gameSurface.rotateY(PI);
          gameSurface.rotateZ(PI);
  
          //Particules
          if(partSys != null && !partSys.particles.isEmpty()) {
              partSys.run(gameSurface, ball.velocity.mag(),cylinderColor);
              gameSurface.translate(partSys.origin.x, -cylinderHeight, partSys.origin.z);
              gameSurface.shape(villain);
          }
          gameSurface.popMatrix();
  
          // Display shift information
          gameSurface.textFont(f,fontSize);
          gameSurface.fill(text);
          gameSurface.text("SHIFT ON", -width/2 + 10, -height/2 + 20);
  
          //Ball
          ball.shiftDisplay(gameSurface);
      }
      // Stop drawing on game surface
      gameSurface.endDraw(); 
}

void drawBottomSpace() {
    bottomSurface.beginDraw();

    bottomSurface.background(bottomBackground);

    bottomSurface.endDraw();
}

void drawTopView() {
    topView.beginDraw();

    topView.fill(topView_boardColor);
    topView.rect(bottomPadding,bottomPadding,bottomSpace-2*bottomPadding,bottomSpace-2*bottomPadding);

    // Ball on topView
    topView.fill(topView_ballColor);
    topView.ellipse(
        map(ball.location.x,-box_size/2+ballRadius,box_size/2 - ballRadius,topView_ballRadius,300-topView_ballRadius),
        map(ball.location.z,-box_size/2+ballRadius,box_size/2 - ballRadius,topView_ballRadius,300-topView_ballRadius),
        topView_ballRadius*2,topView_ballRadius*2);

    if(partSys != null && !partSys.particles.isEmpty()) {
        // Boss cylinder on topView
        topView.fill(topView_bossColor);
        topView.ellipse(
            map(partSys.particles.get(0).location.x,-box_size/2+cylinderRadius,box_size/2 - cylinderRadius,topView_cylinderRadius,300-topView_cylinderRadius-bottomMargin-bottomPadding),
            map(partSys.particles.get(0).location.z,-box_size/2+cylinderRadius,box_size/2 - cylinderRadius,topView_cylinderRadius,300-topView_cylinderRadius-bottomMargin-bottomPadding),
            topView_cylinderRadius*3,topView_cylinderRadius*3);
        // Other cylinders on topView
        topView.fill(topView_cylinderColor);
        for(int i=1; i<partSys.particles.size(); i++) {
            topView.ellipse(
                map(partSys.particles.get(i).location.x,-box_size/2+cylinderRadius,box_size/2 - cylinderRadius,topView_cylinderRadius,300-topView_cylinderRadius-bottomMargin-bottomPadding),
                map(partSys.particles.get(i).location.z,-box_size/2+cylinderRadius,box_size/2 - cylinderRadius,topView_cylinderRadius,300-topView_cylinderRadius-bottomMargin-bottomPadding),
                topView_cylinderRadius*3,topView_cylinderRadius*3);
            // Should not be 3 but 2 instead but is a lot better like this
        }
    }

    topView.endDraw();
}

void drawScoreboard() {
    scoreboard.beginDraw();

    scoreboard.fill(scoreboardColor);
    scoreboard.rect(bottomPadding,bottomPadding,bottomSpace-2*bottomPadding,bottomSpace-2*bottomPadding);

    scoreboard.textFont(f,fontSize);
    scoreboard.fill(text);
    scoreboard.text("Total Score:",30,30);
    scoreboard.text(""+totalScore,30,50);
    scoreboard.text("Velocity:",30,120);
    scoreboard.text(ball.velocity.mag(),30,140);
    scoreboard.text("Last Score:",30,210);
    scoreboard.text(""+lastScore,30,230);

    scoreboard.endDraw();
}

void drawBarChart() {
    if(hs != null) {
        squareWidth = hs.getPos() * 10;
    }

    barChart.beginDraw();

    //Draw Graph Background
    barChart.fill(barChartColor);
    barChart.rect(bottomPadding,bottomPadding,bottomSpace-2*bottomPadding,bottomSpace-2*bottomPadding);

    //Draw score rectangles
    barChart.fill(barChart_rectangleColor);
    for(int i = 0; i < score_history.size(); i++) {
        for(int j = 0; j < Math.abs(score_history.get(i))/pointsPerSquare; j++) {
            float x = i * squareWidth;
            float y = score_history.get(i) < 0 ? graphMiddle - (-j + 20) * squareHeight : graphMiddle - (j + 20) * squareHeight;
            barChart.rect(x+bottomPadding, y, squareWidth, squareHeight);
        }
    }

    barChart.endDraw();
}

/////////////////////////MAIN DRAW////////////////////////////////

void draw() {
    if(win){
      drawVictory();
    }else{
    //Draw different surfaces
    drawGame();
    drawBottomSpace();
    drawTopView();
    drawScoreboard();
    drawBarChart();
    }

    if(win){
      image(victorySurface,0,0);
    }else{
    //Place the surfaces
    image(gameSurface,0,0);
    image(bottomSurface,0,height-bottomSpace);
    image(topView,bottomMargin,height-bottomSpace);
    image(scoreboard,moduleSize*1+bottomMargin*2,height-bottomSpace);
    image(barChart, moduleSize*2 + bottomMargin*3, height-bottomSpace);

    //Scrollbar
    hs.update();
    hs.display(scrollbarColor,scrollbarCursorColor_active,scrollbarCursorColor_inactive);
    }
}
