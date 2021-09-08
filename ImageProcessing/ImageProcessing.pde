import processing.video.*;

Capture cam;

PImage img;

PImage pipeline;
PImage edge;
PImage blob;

BlobDetection blobDetection;

//hough values
float discretizationStepsPhi = 0.06f; 
float discretizationStepsR = 2.5f; 
int phiDim = (int) (Math.PI / discretizationStepsPhi +1);
float[] tabSin=new float[phiDim];
float[]tabCos=new float[phiDim];
float ang=0;
float inverseR=1.f/discretizationStepsR;
  
// 4 quad corners colors
color[] corners = {color(random(255),random(255),random(255),128), color(random(255),random(255),random(255),128), color(random(255),random(255),random(255),128), color(random(255),random(255),random(255),128)};

void settings() {
  //size(640,480); // for camera
  size(2400,600); // for milestone
}

void setup() {
  
  blobDetection = new BlobDetection();
  
  //pre-compute the sin and cos values for hough
  for(int accPhi=0;accPhi<phiDim;ang+=discretizationStepsPhi,accPhi++){
    // we can also pre-multiply by (1/discretizationStepsR) since we need it in the Hough loop
    tabSin[accPhi]=(float)(Math.sin(ang)*inverseR);
    tabCos[accPhi]=(float)(Math.cos(ang)*inverseR);
  }
  
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
  
  img = loadImage("board1.jpg");
  
}

void draw() {
    
  clear();

  /*
  if(cam.available() == true) {
    cam.read();
  }
  img= cam.get();
  //img = pipelined;
  
  img = thresholdHSB(img,100,150,180,220,90,200);
  img = convolute(img);
  img = blobDetection.findConnectedComponents(img, true);
  img = scharr(img);
  img = threshold(img,200);
  
  image(img,0,0);
    
  List<PVector> lines = hough(pipeline, 100, 4, 1000);
  plot_lines(lines,img);
  QuadGraph quadFinder = new QuadGraph();
  List<PVector> quadLines = quadFinder.findBestQuad(lines, pipeline.width, pipeline.height, 1000000, 10000, true); // true for error messages
  for(int i=0;i<quadLines.size();++i){
    pushStyle();
    fill(corners[i]);
    ellipse(quadLines.get(i).x,quadLines.get(i).y,30,30);
    popStyle();
  }
  */
  
  pipeline = thresholdHSB(img,100,140,80,255,30,160);
  pipeline = convolute(pipeline);
  blob = blobDetection.findConnectedComponents(pipeline, true);
  
  edge = scharr(blob);
  pipeline = threshold(edge,200);
  
  image(img,0,0);
  List<PVector> lines = hough(pipeline, 100, 4, 1000);
  plot_lines(lines,img);
  QuadGraph quadFinder = new QuadGraph();
  List<PVector> quadLines = quadFinder.findBestQuad(lines, pipeline.width, pipeline.height, 1000000, 10000, false); // true for error messages
  for(int i=0;i<quadLines.size();++i){
    pushStyle();
    fill(corners[i]);
    ellipse(quadLines.get(i).x,quadLines.get(i).y,30,30);
    popStyle();
  }
  
  image(edge,800,0);
  image(blob,1600,0);
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
