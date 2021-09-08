class KalmanFilter1D {
  float q = 1; // process variance
  float r = 2.0; // estimate of measurement variance, change to see effect 
  float xhat = 0.0; // a posteriori estimate of x
  float xhatminus = 0.0;  // a priori estimate of x
  float p = 1.0; // a posteriori error estimate
  float pminus;  // a priori error estimate
  float kG = 0.0; // kalman gain

  KalmanFilter1D() {}; 
  
  KalmanFilter1D(float q, float r) {
    q(q);
    r(r); 
  }
  
  void q(float q) { 
    this.q = q;
  }
  
  void r(float r) { 
    this.r = r;
  }
  
  float xhat() { 
    return this.xhat;
  }
  
  void predict() { 
    xhatminus = xhat; 
    pminus = p + q;
  }
  
  float correct(float x) {
    kG = pminus / (pminus + r);
    xhat = xhatminus + kG * (x - xhatminus); 
    p = (1 - kG) * pminus;
    return xhat;
  }
  
  float predict_and_correct(float x) { 
    predict();
    return correct(x); 
  }
}
