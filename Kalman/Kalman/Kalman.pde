KalmanFilter2D pred = new KalmanFilter2D(1, 6);

void setup() {
       size(400, 400);
       //stroke(255);
       //background(192, 64, 0);
       
 } 

 void draw() {
   clear();
   fill(255,0,0);
   circle(mouseX, mouseY, 30);
   fill(0,255,0);
   circle(pred.predict_and_correctX(mouseX), pred.predict_and_correctY(mouseY), 30);
 }
