class KalmanFilter2D {
  KalmanFilter1D x = new KalmanFilter1D();
  KalmanFilter1D y = new KalmanFilter1D();
  
  KalmanFilter2D() {}; 
  KalmanFilter2D(float q, float r) {
    q(q);
    r(r); 
  }
  
  void q(float q) { 
    x.q = q;
    y.q = q;
  }
  
  void r(float r) { 
    x.r = r;
    y.r = r;
  }
  
  float xhat() { 
    return x.xhat;
  }
  
  float yhat() { 
    return y.xhat;
  }
  
  void predictX() { 
    x.predict();
  }
  
  void predictY() { 
    y.predict();
  }
  
  float correctX(float x1) {
    x.correct(x1);
    return x.xhat;
  }
  
  float correctY(float y1) {
    y.correct(y1);
    return y.xhat;
  }
  
  float predict_and_correctX(float x1) { 
    predictX();
    return correctX(x1); 
  }
  
  float predict_and_correctY(float y1) { 
    predictY();
    return correctY(y1); 
  }
  
}
