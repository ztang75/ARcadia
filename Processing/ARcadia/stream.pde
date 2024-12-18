Client client; //for camera streaming
int dataOffset = 163;
PImage prevFrame;

void getGrayscaleImgFromServer() {
  int messageSize = client.available();
  if (messageSize > 0) {
    byte[] sizeBytes = new byte[8];
    client.readBytes(sizeBytes);
    int dataSize = (int) (sizeBytes[0] & 0xFF)
      | (sizeBytes[1] & 0xFF) << 8
      | (sizeBytes[2] & 0xFF) << 16
      | (sizeBytes[3] & 0xFF) << 24;
    if (dataSize == camWidth*camHeight+dataOffset) { //use the file size returned from the following line.
      byte[] imageData = new byte[dataSize];
      client.readBytes(imageData);
      PImage img = getImage(imageData);
      if(img != null) prevFrame = img;
      //prevFrame.resize(width,height);
      
    } else {
      if (dataSize>0) {
        byte[] brokenData = new byte[dataSize];
        client.readBytes(brokenData);
        println("Bad filesize:", dataSize, "@ Frame:", frameCount);
      }
    }
  }
}

PImage getImage(byte[] imageData) {
  PImage img = createImage(camWidth, camHeight, RGB);
  int[] pixels = new int[camWidth * camHeight];
  for (int i = 0; i < pixels.length; i++) {
    pixels[i] = color(imageData[i+149] & 0xFF); //149: the offset found from the following test codes.
  }
  //corruption test:
  int corruptCounter = 0;
  for (int i = pixels.length-10; i < pixels.length; i++) {
    if (pixels[i] == color(0)) ++corruptCounter;
  }
  if (corruptCounter>0) {
    println("corrupted:", corruptCounter, "@ Frame:", frameCount);
    return null;
  } else {
    img.pixels = pixels;
    img.updatePixels();
    return img;
  }
}
