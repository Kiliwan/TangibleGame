import gab.opencv.*;

import processing.video.*;


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

// image processing
ImageProcessing imgproc;

PImage img;

class ImageProcessing extends PApplet {

  Movie vid;

  Capture cam;

  OpenCV opencv;
  
  PImage pipeline;
  
  PApplet parent;
  
  BlobDetection blobDetection;
  
  TwoDThreeD pose;
  PVector orientation;
  
  KalmanFilter2D corner1;
  KalmanFilter2D corner2;
  KalmanFilter2D corner3;
  KalmanFilter2D corner4;
  
  //hough values
  float discretizationStepsPhi = 0.06f; 
  float discretizationStepsR = 2.5f; 
    
  int phiDim = (int) (Math.PI / discretizationStepsPhi +1);
  
  float[] tabSin=new float[phiDim];
  float[]tabCos=new float[phiDim];
  float ang=0;
  float inverseR=1.f/discretizationStepsR;
    
  // quad corners colors
  color[] cornersColors = {color(random(255),random(255),random(255),128), color(random(255),random(255),random(255),128), color(random(255),random(255),random(255),128), color(random(255),random(255),random(255),128)};
  
  
  ImageProcessing(PApplet parent){
    this.parent = parent;
  }
  
  void settings() {
    //size(640,480); // for camera
    size(800,600); // for image/video
  }
  
  void setup() {
    
    blobDetection = new BlobDetection();
    
    opencv = new OpenCV(this,100,100);
    
    pose = new TwoDThreeD(width,height,frameRate); // for camera/video
    //pose = new TwoDThreeD(width,height,0); // for image
    
    //pre-compute the sin and cos values for hough
    for(int accPhi=0;accPhi<phiDim;ang+=discretizationStepsPhi,accPhi++){
      // we can also pre-multiply by (1/discretizationStepsR) since we need it in the Hough loop
      tabSin[accPhi]=(float)(Math.sin(ang)*inverseR);
      tabCos[accPhi]=(float)(Math.cos(ang)*inverseR);
    }
    
    
    //needed if tried on camera
    /*
    String[] cameras= Capture.list();
  
    if(cameras.length== 0) {
      println("There are no cameras available for capture.");
      exit();
    }else{
      println("Available cameras: "+cameras.length);
      for(int i = 0; i < cameras.length; i++) {
        println(cameras[i]);
      }
      
      cam = new Capture(this, 640, 480, cameras[0]);
      
      cam.start();
    }
    */
    
    vid = new Movie(parent, "testvideo.avi");
    vid.loop();
    vid.volume(0); // for convenience
    
    corner1 = new KalmanFilter2D(1,5);
    corner2 = new KalmanFilter2D(1,5);
    corner3 = new KalmanFilter2D(1,5);
    corner4 = new KalmanFilter2D(1,5);
  }
  
  void draw() {
    
    clear();
      
    //needed if tried on camera
    /*
    if(cam.available() == true) {
      cam.read();
    }
    img = cam.get();
    */
    
    if(vid.available()==true){
      vid.read();
    }
    img = vid.get();
    
    image(img,0,0);
    
    List<PVector> homogeneousCorners = new ArrayList<PVector>();
    
    if(frameCount%1==0){
      img = thresholdHSB(img,100,140,30,255,30,220);
      img = convolute(img);
      img = blobDetection.findConnectedComponents(img, true);
      img = scharr(img);
      img = threshold(img,200);
      
      List<PVector> lines = hough(img, 100, 6, 1000);
      plot_lines(lines,img);
      QuadGraph quadFinder = new QuadGraph();
      List<PVector> corners = quadFinder.findBestQuad(lines, img.width, img.height, 1000000, 1000, false); // true for error messages
      
      for(int i=0;i<corners.size();++i){
        homogeneousCorners.add(new PVector(corners.get(i).x,corners.get(i).y,1f));
      }
    }
    
    if(homogeneousCorners.size()!=0){
      homogeneousCorners.get(0).x = corner1.predict_and_correctX(homogeneousCorners.get(0).x);
      homogeneousCorners.get(0).y = corner1.predict_and_correctY(homogeneousCorners.get(0).y);
      
      homogeneousCorners.get(1).x = corner2.predict_and_correctX(homogeneousCorners.get(1).x);
      homogeneousCorners.get(1).y = corner2.predict_and_correctY(homogeneousCorners.get(1).y);
      
      homogeneousCorners.get(2).x = corner3.predict_and_correctX(homogeneousCorners.get(2).x);
      homogeneousCorners.get(2).y = corner3.predict_and_correctY(homogeneousCorners.get(2).y);
      
      homogeneousCorners.get(3).x = corner4.predict_and_correctX(homogeneousCorners.get(3).x);
      homogeneousCorners.get(3).y = corner4.predict_and_correctY(homogeneousCorners.get(3).y);
    
    }else{
      corner1.predictX();
      corner1.predictY();
      
      homogeneousCorners.add(new PVector(corner1.xhat(),corner1.yhat(),1f));
      
      corner2.predictX();
      corner2.predictY();
      
      homogeneousCorners.add(new PVector(corner2.xhat(),corner2.yhat(),1f));

      corner3.predictX();
      corner3.predictY();
      
      homogeneousCorners.add(new PVector(corner3.xhat(),corner3.yhat(),1f));

      corner4.predictX();
      corner4.predictY();
      
      homogeneousCorners.add(new PVector(corner4.xhat(),corner4.yhat(),1f));

    }
    
    for(int i=0;i<homogeneousCorners.size();i++){
      pushStyle();
      fill(cornersColors[i]);
      ellipse(homogeneousCorners.get(i).x,homogeneousCorners.get(i).y,30,30);
      popStyle();
    }
    
    orientation = pose.get3DRotations(homogeneousCorners);
  }
  
  //for testing
  boolean imagesEqual(PImage img1, PImage img2){
    if(img1.width!= img2.width|| img1.height!= img2.height)
      return false;
    for(int i = 0; i < img1.width*img1.height; i++)
      //assuming that all the three channels have the same value
      if(red(img1.pixels[i]) != red(img2.pixels[i]))
        return false;
    return true;
  }
  
  //global threshold
  PImage threshold(PImage img,int threshold){
    PImage result = createImage(img.width, img.height, RGB);
    for(int i = 0; i < img.width* img.height; i++){
      if(brightness(img.pixels[i]) < threshold){
        result.pixels[i] = color(0);
      }else{
        result.pixels[i] = color(255);
      }
    }
    return result;
  }
  
  //3-channel thresholding
  PImage thresholdHSB(PImage img, float minH, float maxH, float minS, float maxS, float minB, float maxB){
    PImage result = createImage(img.width, img.height, RGB);
    for(int i = 0; i < img.width * img.height; ++i){
      color p = img.pixels[i];
      float sat = saturation(p);
      float hue = hue(p);
      float br = brightness(p);
      if(sat < minS || sat > maxS || hue < minH || hue > maxH || br < minB || br > maxB){
        result.pixels[i] = color(0);
      } else {
        result.pixels[i] = color(255);
      }
    }
    return result;
  }
  
  //blurring
  PImage convolute(PImage img) {
    float[][]kernel= {{ 9, 12, 9 },
                      { 12, 15, 12 },
                      { 9, 12, 9 }};
    float normFactor= 99.f;
    
    // create a greyscale image (type: ALPHA) for output
    PImage result = createImage(img.width, img.height, ALPHA);
  
    // kernel size N = 3
    //// for each (x,y) pixel in the image:
    //    - multiply intensities for pixels in the range
    //      (x - N/2, y - N/2) to (x + N/2, y + N/2) by the
    //      corresponding weights in the kernel matrix
    //    - sum all these intensities and divide it by normFactor
    //    - set result.pixels[y * img.width + x] to this value
    int N = kernel.length;
    for(int i = 1; i < img.height -1; ++i){
      for(int j = 1; j < img.width -1; ++j){
        float brightness = 0;
        for(int k = -N/2; k < N/2 + 1; ++k){
          for(int l = -N/2; l < N/2 + 1; ++l){
            brightness+=brightness(img.pixels[(i+k)*img.width + (j+l)]) * kernel[k+N/2][l+N/2];
          }
        }
        brightness /= normFactor;
        result.pixels[i*img.width + j] = color(brightness); 
      }
    }
    return result;
  }
  
  //edge detection
  PImage scharr(PImage img) {
      
    float[][] vKernel= {
                 {  3, 0, -3  },
                 { 10, 0, -10 },
                 {  3, 0, -3  } };
    float[][] hKernel= {
                 {  3, 10, 3 },
                 {  0, 0, 0 },
                 { -3, -10, -3 } };
                 
    PImage result= createImage(img.width, img.height, ALPHA);
    
    // clear the image
    for(int i = 0; i < img.width* img.height; i++){
      result.pixels[i] = color(0);
    }
    
    float max = 0;
    float[] buffer = new float[img.width* img.height];
    
    float normFactor = 1.0;
    
    int N = 0;
    if(vKernel.length == hKernel.length){
      N = vKernel.length;
    }
    
    for(int i = 1; i < img.height - 1; ++i){
      for(int j = 1; j < img.width - 1; ++j){
        float sum_h = 0;
        float sum_v = 0;
        for(int k = -N/2; k <= N/2; ++k){
          for(int l = -N/2; l <= N/2; ++l){
            sum_h+=brightness(img.pixels[(i+k)*img.width + (j+l)]) * vKernel[k+N/2][l+N/2];
            sum_v+=brightness(img.pixels[(i+k)*img.width + (j+l)]) * hKernel[k+N/2][l+N/2];
          }
        }
        sum_h /= normFactor;
        sum_v /= normFactor;
        float sum = sqrt(pow(sum_h, 2) + pow(sum_v, 2));
        buffer[i*img.width + j] = sum;
        if(sum>max){ max = sum; }
      }
    }
    
    for(int y = 1; y < img.height - 1; y++){// Skip top and bottom edges
      for(int x = 1; x < img.width - 1; x++) {// Skip left and right
        int val=(int) ((buffer[y * img.width+ x] / max)*255);
        result.pixels[y * img.width+ x]=color(val);
      }
    }
    return result;
  }
  
  //line detection
  List<PVector> hough(PImage edgeImg, int minVotes, int nLines, int localMaximaRange) {
    
    // max radius is the image diagonal, but it can be also negative 
    int rDim = (int) ((sqrt(edgeImg.width*edgeImg.width + edgeImg.height*edgeImg.height) * 2) / discretizationStepsR + 1);
    
    // our accumulator
    int[] accumulator = new int[phiDim * rDim];
    
    // Fill the accumulator: on edge points (ie, white pixels of the edge 
    // image), store all possible (r, phi) pairs describing lines going 
    // through the point.
    int r_index = 0;
    float r_calc = 0;
    for (int y = 0; y < edgeImg.height; y++) {
      for (int x = 0; x < edgeImg.width; x++) {
      // Are we on an edge?
        if (brightness(edgeImg.pixels[y * edgeImg.width + x]) != 0) {
              // ...determine here all the lines (r, phi) passing through
              // pixel (x,y), convert (r,phi) to coordinates in the
              // accumulator, and increment accordingly the accumulator.
              // Be careful: r may be negative, so you may want to center onto
              // the accumulator: r += rDim / 2
              for(int phi = 0; phi < phiDim; phi++){
                 r_calc = ((x * tabCos[phi] + y * tabSin[phi]));
                 r_calc += rDim/2;
                 r_index = (int) r_calc;
                 accumulator[phi * rDim + r_index] += 1; 
              }
        } 
      }
    }
    ArrayList<PVector> lines = new ArrayList<PVector>();
    ArrayList<Integer> bestCandidates = new ArrayList<Integer>();
    
    int range = localMaximaRange/2;
    
    for (int idx = 0; idx < accumulator.length; idx++) { 
      int accPhi = (int) (idx / (rDim));
      int accR = idx - (accPhi) * (rDim);
      float r = (accR - (rDim) * 0.5f) * discretizationStepsR; 
      float phi = accPhi * discretizationStepsPhi; 
      lines.add(new PVector(r,phi));
      if(accumulator[idx] > minVotes){
        boolean check = true;
        for(int j=-range;j<=range;++j){
          if(idx+j>0 && idx+j<accumulator.length &&
             accumulator[idx+j]>accumulator[idx]){
               check = false;
          }
          if(idx+j*rDim>0 && idx+j*rDim<accumulator.length &&
             accumulator[idx+j*rDim]>accumulator[idx]){
               check = false;
          }
        }
        if(check)
          bestCandidates.add(idx);
        }
    }
    
    Collections.sort(bestCandidates,new HoughComparator(accumulator));
    
    ArrayList<PVector> selectedCandidates = new ArrayList<PVector>();
    
    int finalNLines = nLines < bestCandidates.size() ? nLines : bestCandidates.size();
    
    for(int i = 0; i < finalNLines; ++i){
      selectedCandidates.add(lines.get(bestCandidates.get(i)));
    }
    
    return selectedCandidates;
  }
  
  class HoughComparator implements java.util.Comparator<Integer>{
    int[]accumulator;
    public HoughComparator(int[]accumulator){
      this.accumulator=accumulator;
    }
    @Override
    public int compare(Integer l1,Integer l2){
    if(accumulator[l1]>accumulator[l2]||(accumulator[l1]==accumulator[l2]&&l1<l2))
      return -1;
    return 1;
    }
  }
  
  void plot_lines(List<PVector> lines, PImage edgeImg){
    for (int idx = 0; idx < lines.size(); idx++) { 
      PVector line=lines.get(idx);
      float r = line.x; float phi = line.y;
           // Cartesian equation of a line: y = ax + b
           // in polar, y = (-cos(phi)/sin(phi))x + (r/sin(phi))
           // => y = 0 : x = r / cos(phi)
           // => x = 0 : y = r / sin(phi)
        // compute the intersection of this line with the 4 borders of // the image
        int x0 = 0;
        int y0 = (int) (r / sin(phi));
        int x1 = (int) (r / cos(phi));
        int y1 = 0;
        int x2 = edgeImg.width;
        int y2 = (int) (-cos(phi) / sin(phi) * x2 + r / sin(phi));
        int y3 = edgeImg.width;
        int x3 = (int) (-(y3 - r / sin(phi)) * (sin(phi) / cos(phi)));
           // Finally, plot the lines
        stroke(204,102,0); 
        if (y0 > 0) {
          if (x1 > 0)
            line(x0, y0, x1, y1);
          else if (y2 > 0)
            line(x0, y0, x2, y2);
          else
             line(x0, y0, x3, y3);
         }else {
          if (x1 > 0) {
            if (y2 > 0)
              line(x1, y1, x2, y2); 
            else
              line(x1, y1, x3, y3);
             }else
               line(x2, y2, x3, y3);
           }
      }
  }
}

PVector rotation;

void setup() {
  
    f = createFont("Arial",16,true);
    surface.setTitle("TangibleGame");

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

    totalScore = 20;
    lastScore = 0;
    win = false;
    
    rotation = new PVector(rx,rz);
    
    
    if(imgproc==null){
      imgproc = new ImageProcessing(this);
      String[] args = {"Image processing window"};
      PApplet.runSketch(args,imgproc);
    }
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
  
          if(imgproc.orientation!=null && !Float.isNaN(imgproc.orientation.x) && !Float.isNaN(imgproc.orientation.y) && !Float.isNaN(imgproc.orientation.z)){
           rotation = imgproc.orientation;
          }
                    
          //Box movement
          gameSurface.pushMatrix();
          gameSurface.rotateZ(rotation.y);
          gameSurface.rotateX(-rotation.x+PI);
  
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
  
          // Ball
          ball.update(-rotation.x, rotation.y);
          ball.checkEdges();
          ball.display(gameSurface);
          
          //End box movement
          gameSurface.popMatrix();
          
           //Information on the window
          gameSurface.textFont(f,16);
          gameSurface.fill(text);
          gameSurface.text( "RotationX: " + rx * 180/PI, -width/2 + 10, -height/2 + 20);
          gameSurface.text( "RotationZ: " + rz * 180/PI, -width/2 + 10, -height/2 + 40);
          gameSurface.text( "Speed: " + 200/speed, -width/2 + 10, -height/2 + 60);
  
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
