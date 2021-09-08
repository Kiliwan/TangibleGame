class HScrollbar {
    float barWidth;  //Bar's width in pixels
    float barHeight; //Bar's height in pixels
    float xPosition;  //Bar's x position in pixels
    float yPosition;  //Bar's y position in pixels

    float sliderPosition, newSliderPosition;    //Position of slider
    float sliderPositionMin, sliderPositionMax; //Max and min values of slider

    boolean mouseOverSlider;
    boolean locked;     //Is the mouse clicking and dragging the slider now?

    /**
     * @brief Creates a new horizontal scrollbar
     *
     * @param x The x position of the top left corner of the bar in pixels
     * @param y The y position of the top left corner of the bar in pixels
     * @param w The width of the bar in pixels
     * @param h The height of the bar in pixels
     */
    HScrollbar (float x, float y, float w, float h) {
        barWidth = w;
        barHeight = h;
        xPosition = x;
        yPosition = y;

        sliderPosition = xPosition + barWidth/2 - barHeight/2;
        newSliderPosition = sliderPosition;

        sliderPositionMin = xPosition;
        sliderPositionMax = xPosition + barWidth - barHeight;
    }

    /**
     * @brief Updates the state of the scrollbar according to the mouse movement
     */
    void update() {
        if (!mousePressed) {
            locked = false;
            updateMouseOverSlider();
        }
        if (mousePressed && mouseOverSlider) {
            locked = true;
        }
        if(locked){
            newSliderPosition = constrain(mouseX /*- width/2*/ - barHeight/2, sliderPositionMin, sliderPositionMax);
        }
        if (abs(newSliderPosition - sliderPosition) > 1) {
            sliderPosition = sliderPosition + (newSliderPosition - sliderPosition);
        }
    }

    /**
     * @brief Gets whether the mouse is hovering the scrollbar
     *
     * @return Whether the mouse is hovering the scrollbar
     */
    void updateMouseOverSlider() {
        if (mouseX /*- width/2*/ > xPosition && mouseX /*- width/2 */< xPosition+barWidth &&
                mouseY /*- height/2*/ > yPosition && mouseY /*- height/2*/ < yPosition+barHeight) {
            mouseOverSlider=true;
        }
        else {
            mouseOverSlider=false;
        }
    }

    /**
     * @brief Draws the scrollbar in its current state
     */
    void display(color scrollbarColor, color scrollbarCursorColor_active, color scrollbarCursorColor_inactive) {
        fill(scrollbarColor);
        rect(xPosition, yPosition, barWidth, barHeight);
        if (mouseOverSlider || locked) {
            fill(scrollbarCursorColor_active);
        }
        else {
            fill(scrollbarCursorColor_inactive);
        }
        rect(sliderPosition, yPosition, barHeight, barHeight);
    }

    /**
     * @brief Gets the slider position
     *
     * @return The slider position in the interval [0,1] corresponding to [leftmost position, rightmost position]
     */
    float getPos() {
        return (sliderPosition - xPosition)/(barWidth - barHeight);
    }
}
