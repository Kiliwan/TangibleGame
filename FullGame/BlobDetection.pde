import java.util.ArrayList; 
import java.util.List; 
import java.util.TreeSet;
import java.util.Collections;

class BlobDetection {
  
  //We will return an array with the neighbours that exist and are labelled
  //0: west, 1: north-west, 2:north, 3:north east
  int[] neighbours(int col, int row, PImage input){
    int[] neighbs = {-1, -1, -1, -1};
    int west = row * input.width + col - 1;
    int north_west = (row-1) * input.width + col - 1;
    int north = (row-1) * input.width + col;
    int north_east = (row-1) * input.width + col + 1;
    
    if(col > 0)
      neighbs[0] = west;
      
    if(col > 0 && row > 0)
      neighbs[1] = north_west;
    
    if(row > 0)
      neighbs[2] = north;
    
    if(col < input.width - 1 && row > 0)
      neighbs[3] = north_east;

    return neighbs;
  }
  
  //Returns -1 if no neighbour had a label (could be seen as an error message)
  int getSmallestLabel(int[] labels){
     int smallest = labels[0];
     for(int i = 1; i < labels.length; i++){
       if(labels[i] != 0 && (labels[i] < smallest) || smallest == 0){
          smallest = labels[i];
       }
     }
     return smallest;
  }

  PImage findConnectedComponents(PImage input, boolean onlyBiggest){
  // First pass: label the pixels and store labels' equivalences
  int [] labels = new int [input.width*input.height];
  
  List<TreeSet<Integer>> labelsEquivalences = new ArrayList<TreeSet<Integer>>();
  TreeSet<Integer> initial = new TreeSet<Integer>();
  initial.add(0);
  labelsEquivalences.add(initial);
  
  int currentLabel = 1; 

  //We are now going to start the check
  for(int col = 0; col < input.width ; col++){
    for(int row = 0; row < input.height; row++){
      
      if(input.pixels[row * input.width + col] == color(0,0,0) || col == 0 || col == input.width -1 || row == 0 || row == input.height -1){
        labels[row * input.width + col] = 0;
        continue;
      } else {

      int[] neighbs = neighbours(col, row, input);
      
      //We will now use neighbs to set the neighbs labels (instead of creating a new array)
      int[] neighbs_labels = new int[4];
      for(int i = 0; i < neighbs.length; i++){
        if(neighbs[i] != -1){
          neighbs_labels[i] = labels[neighbs[i]]; 
        } else {
          neighbs_labels[i] = 0;
        }
      }
      
      //We recover the smallest label
      int smallestLabel = getSmallestLabel(neighbs_labels);
        
      //We check if we actaully have neighbours
      
      if(smallestLabel == 0){
        //If we don't, we create a new blob
        TreeSet<Integer> newSet = new TreeSet<Integer>();
        newSet.add(currentLabel);
        labelsEquivalences.add(newSet);
        labels[row * input.width + col] = currentLabel;
        currentLabel++;
        
      }else{
        
        //If we do, we update equivalences
        labels[row * input.width + col] = smallestLabel;
        

        for(int n = 0; n < neighbs.length; n++){
          
            if(neighbs[n] != -1 && labels[neighbs[n]] != 0){
              //Second for loop is no optimal, but it was a faster way of handling the "-1"
              //But anyways, it's a loop of size 4, so it doesn't really make a difference
              for(int m = 0; m < neighbs.length; m++){
                if(neighbs[m] != -1 && labels[neighbs[m]] != 0){
                  labelsEquivalences.get(labels[neighbs[n]]).add(labels[neighbs[m]]);
                }
              }
            }
          }
        } 
      }
    }
  }
  
  //have to merge equivalences if some of the pixels were too elocated from each other 
    for(int i = 0; i < labelsEquivalences.size(); ++i){
      for(int j : labelsEquivalences.get(i)){
        labelsEquivalences.get(j).addAll(labelsEquivalences.get(i));
      }
    }
  
  // Second pass: re-label the pixels by their equivalent class
  for(int col = 1; col < input.width -1; ++col){
    for(int row = 1; row < input.height -1; ++row){
      int curr = row * input.width + col;
      labels[curr] = labelsEquivalences.get(labels[curr]).first();
    }
  }
  
  
  PImage result = createImage(input.width, input.height, ALPHA);

  // if onlyBiggest==true, count the number of pixels for each label and output an image with the biggest blob in white and others in black
  if(onlyBiggest){
    
    //We count the number of pixel for each label
    int[] blobs = new int[labelsEquivalences.size()];
    for(int i  = 0; i < blobs.length; ++i)
      blobs[i] = 0;
      
    for(int col = 1; col < input.width - 1; ++col){
      for(int row = 1; row < input.height - 1; ++row){
        int curr = row * input.width + col;
        int label = labelsEquivalences.get(labels[curr]).first();
        if(label != 0) ++blobs[label];
      }
    }
    
    //We get the biggest label
    int biggest = 0;
    for(int i = 0; i < blobs.length; ++i)
      if(blobs[i] > blobs[biggest]) biggest = i;
      
    //We assign the value : if currentPixel is part of biggest Blob than set to white otherwise set to black
    for(int i = 0; i < input.width * input.height; i++)   
      result.pixels[i] = labels[i] == biggest ?  #00FF00 : #000000;
    
    return result;
    
  } else {
    
    // if onlyBiggest==false, output an image with each blob colored in one uniform color
    
    //Store colors for each label 
    int[] colors = new int[labelsEquivalences.size()+1];
    colors[0] = #000000;

    //Randomize a new color for each label
    for(int i = 1; i < labelsEquivalences.size()+1; i++){
      colors[i] = (int)random(#000000 , #FFFFFF);
    }
    
    for(int i = 0; i < input.width*input.height; i++){
      result.pixels[i] = color(colors[labelsEquivalences.get(labels[i]).first()]); 
    }

    return result;

    }
  }  
}
