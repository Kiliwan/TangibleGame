class Cylinder {

    PShape openCylinder = new PShape();
    PShape top = new PShape();
    PShape bottom = new PShape();

    PVector location;

    Cylinder(float x_board, float z_board, int cylinderRadius, int cylinderHeight, int cylinderResolution) {
        location = new PVector(x_board, 0, z_board);
        float angle;
        float[] x = new float[cylinderResolution + 1];
        float[] z = new float[cylinderResolution + 1];

        //get the x and y position on a circle for all the sides
        for(int i = 0; i < x.length; i++) {
            angle = (TWO_PI / cylinderResolution) * i;
            x[i] = x_board + cos(angle) * cylinderRadius;
            z[i] = z_board + sin(angle) * cylinderRadius;
        }

        //Sides of cylinder
        openCylinder = createShape();
        openCylinder.beginShape(TRIANGLE_STRIP);

        for(int i = 0; i < x.length; i++) {
            openCylinder.vertex(x[i], 0, z[i]);
            openCylinder.vertex(x[i], -cylinderHeight, z[i]);
        }
        openCylinder.endShape(CLOSE);

        //Top of cylinder
        top = createShape();
        top.beginShape(TRIANGLE_STRIP);

        top.vertex(x[0], -cylinderHeight, z[0]);
        for(int i = 1; i < x.length; i++) {
            top.vertex(x_board, -cylinderHeight, z_board);
            top.vertex(x[i], -cylinderHeight, z[i]);
        }
        top.endShape(CLOSE);

        //Bottom of cylinder
        bottom = createShape();
        bottom.beginShape(TRIANGLE_STRIP);

        bottom.vertex(x[0], 0, z[0]);
        for(int i = 1; i < x.length; i++) {
            bottom.vertex(x_board, 0, z_board);
            bottom.vertex(x[i], 0, z[i]);
        }
        bottom.endShape(CLOSE);

    }

    //Return drawing parts

    PShape sides() {
        return openCylinder;
    }

    PShape top() {
        return top;
    }

    PShape bottom() {
        return bottom;
    }
}
