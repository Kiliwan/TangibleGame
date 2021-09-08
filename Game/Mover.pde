class Mover {

    PShape globe;

    PVector location;
    PVector velocity;
    PVector gravity;

    final float GRAVITY_CONSTANT = 1.3; //m/s^2

    final int ballRadius;
    final int box_size;
    final int box_width;

    final float bounce_coefficient = 0.3;

    Mover(int box_size, int box_width, int ballRadius, PShape globe) {
        this.ballRadius = ballRadius;
        this.box_size = box_size;
        this.box_width = box_width;
        location = new PVector(0, -ballRadius-(box_width/2), 0);
        velocity = new PVector(0, 0, 0);
        gravity = new PVector(0, 0, 0);
        this.globe = globe;
    }

    void update(float rx, float rz) {

        //Calculating gravity influence
        gravity.x = sin(rz) * GRAVITY_CONSTANT;
        gravity.z = sin(rx) * GRAVITY_CONSTANT;
        velocity.add(gravity);

        //Calculating friction influence
        float normalForce= 1;
        float mu = 0.01;
        float frictionMagnitude= normalForce* mu;
        PVector friction= velocity.copy();
        friction.normalize();
        friction.mult(-1);
        friction.mult(frictionMagnitude);
        velocity.add(friction);

        //Applying forces
        location.add(velocity);
    }

    void display(PGraphics gameSurface) {
        gameSurface.pushMatrix();

        gameSurface.rotateZ(rz);
        gameSurface.rotateX(-rx);

        gameSurface.translate(location.x, location.y, location.z);

        gameSurface.shape(globe);

        gameSurface.popMatrix();
    }

    void shiftDisplay(PGraphics gameSurface) {
        gameSurface.translate(location.x, location.z, 0);
        gameSurface.shape(globe);
    }

    void checkEdges() {
        //Checks that ball stays in box
        if(location.x > ((box_size/2 - ballRadius))) {
            location.x = (int)((box_size/2 - ballRadius));
            velocity.x=-velocity.x*bounce_coefficient;
        } else if(location.x < ((-box_size/2 + ballRadius))) {
            location.x = (int)((-box_size/2 + ballRadius));
            velocity.x=-velocity.x*bounce_coefficient;
        }
        if(location.z > ((box_size/2 - ballRadius))) {
            location.z = (int)((box_size/2 - ballRadius));
            velocity.z=-velocity.z*bounce_coefficient;
        } else if(location.z < ((-box_size/2 + ballRadius))) {
            location.z = (int)((-box_size/2 + ballRadius));
            velocity.z=-velocity.z*bounce_coefficient;
        }
    }


    boolean checkCylinderCollision(Cylinder cyl, float cylRadius) {
        // Check that ball bounces to cylinders and doesn't go inside them
        PVector ballToCylinder = new PVector((location.x - cyl.location.x), 0, (location.z - cyl.location.z));
        //float cylinderDistance = cylRadius + ballRadius;
        // We used cylRadius directly instead because otherwise the ball would bounce before even touching the cylinder

        float insideDistance = cylRadius - ballToCylinder.mag();

        if(insideDistance >= 0) {

            PVector normal = ballToCylinder.copy();

            ballToCylinder.normalize();

            location.add(ballToCylinder.mult(insideDistance));

            normal.normalize();
            PVector result = normal.mult(velocity.dot(normal));
            velocity = velocity.sub(result.mult(2));
            //Return true, so that the ball hit the cylinder
            return true;
        }
        //Return false, the bal didn't hit the cylinder
        return false;
    }
}
