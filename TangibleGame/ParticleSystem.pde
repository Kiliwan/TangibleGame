// A class to describe a group of Particles
class ParticleSystem {

    ArrayList<Cylinder> particles;

    PVector origin;
    final int cylinderRadius;
    final int cylinderHeight;
    final int cylinderResolution;

    PShape villain;

    final double cylinderPoint;
    final double bossPoint;

    final int NUM_ATTEMPTS = 100;

    ParticleSystem(PVector origin, int cylinderRadius, int cylinderHeight, int cylinderResolution, PShape villain, double cylinderPoint, double bossPoint) {
        this.origin = origin.copy();

        this.cylinderRadius = cylinderRadius;
        this.cylinderHeight = cylinderHeight;
        this.cylinderResolution = cylinderResolution;

        this.villain = villain;

        this.cylinderPoint = cylinderPoint;
        this.bossPoint = bossPoint;

        particles = new ArrayList<Cylinder>();
        particles.add(new Cylinder(origin.x, origin.z, cylinderRadius, cylinderHeight, cylinderResolution));

    }

    void addParticle() {
        PVector center;
        for(int i=0; i<NUM_ATTEMPTS; i++) {
            // Pick a cylinder and its center.
            int index = int(random(particles.size()));
            center = particles.get(index).location.copy();
            // Try to add an adjacent cylinder.
            float angle = random(TWO_PI);
            center.x += sin(angle) * 2*cylinderRadius;
            center.z += cos(angle) * 2*cylinderRadius;
            if(checkPosition(center)) {
                particles.add(new Cylinder(center.x, center.z, cylinderRadius, cylinderHeight, cylinderResolution));
                TangibleGame.totalScore-=cylinderPoint;
                TangibleGame.lastScore=-cylinderPoint;
                TangibleGame.score_history.add(TangibleGame.totalScore);
                break;
            }
        }
    }
    // Iteratively update and display every particle,
    // and remove them from the list if their lifetime is over.
    boolean run(PGraphics TangibleGameSurface,float velocity, color cylinderColor) {
      boolean toRet = false;
      //Check if the ball hit any cylinder and if so remove it
      for (int i = 0; i < particles.size(); i++) {
          fill(cylinderColor);
          TangibleGameSurface.shape(particles.get(i).sides());
          TangibleGameSurface.shape(particles.get(i).top());
          if(ball.checkCylinderCollision(particles.get(i), cylinderRadius)) {
              float velocityFactor = map(velocity,0,50,0,3);
              if(i == 0) {
                  particles.clear();
                  TangibleGame.totalScore+=bossPoint*velocityFactor;
                  TangibleGame.lastScore=bossPoint*velocityFactor;
                  TangibleGame.score_history.add(TangibleGame.totalScore);
                  toRet |= true;
              } else {
                  particles.remove(i);
                  TangibleGame.totalScore+=cylinderPoint*velocityFactor + 5;
                  TangibleGame.lastScore=cylinderPoint*velocityFactor + 5;
                  TangibleGame.score_history.add(TangibleGame.totalScore);
              }
          }
      }
      return toRet;
    }

    // Check if a position is available, i.e.
    // - would not overlap with particles that are already created // (for each particle, call checkOverlap())
    // - is inside the board boundaries
    boolean checkPosition(PVector center) {
        //Would not overlap with any particle
        for(int i=0; i < particles.size(); i++) {
            if(checkOverlap(center, particles.get(i).location)) {
                return false;
            }
        }

        if(checkInside(center)) {
            return false;
        }
        return true;
    }

    // Check if a particle with center c1
    // and another particle with center c2 overlap.
    boolean checkOverlap(PVector c1, PVector c2) {
        return ((c1.x - c2.x)*(c1.x - c2.x) + (c1.z - c2.z)*(c1.z - c2.z) < (2*cylinderRadius)*(2*cylinderRadius));
    }

    // Check if a particule is inside the board
    boolean checkInside(PVector c) {
        int upper_bound = box_size/2 - cylinderRadius;
        int lower_bound = -box_size/2 + cylinderRadius;
        return !(c.x < upper_bound && c.x > lower_bound && c.z > lower_bound && c.z < upper_bound);
    }
}
