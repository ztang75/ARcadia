class TagManager {
  Tag[] tags;
  ArrayList<Bundle> tagBundles;
  PMatrix3D projectionMatrix;

  TagManager(int n, ArrayList b_ids, ArrayList b_offs) {
    tags = new Tag[n];
    this.tagBundles = new ArrayList<Bundle>();
    for (int i = 0; i < n; i++) {
      tags[i] = new Tag(i);
    }
    for (int i = 0; i < b_ids.size(); i++) {
      ArrayList<Integer> ids = (ArrayList<Integer>) b_ids.get(i);
      ArrayList<PVector> offs = (ArrayList<PVector>) b_offs.get(i);
      this.tagBundles.add(new Bundle(ids, offs));
    }
  }

  void set(int id, float tx, float ty, float tz, float rx, float ry, float rz, PVector[] corners) {
    tags[id].set(tx, ty, tz, rx, ry, rz, corners);
  }

  void update() {
    for (Tag t : this.tags) {
      t.checkActive();
    }
    for (Bundle b : this.tagBundles) {
      ArrayList<Tag> activeTags = new ArrayList<Tag>();
      for (Integer id : b.ids) {
        if (tags[id].active) {
          activeTags.add(tags[id]);
        }
      }
      if (activeTags.size() > 0) {
        PVector loc = new PVector(0, 0, 0);
        PVector ori = new PVector(0, 0, 0);
        for (Tag t : activeTags) {
          projectionMatrix = new PMatrix3D();
          projectionMatrix.rotateZ(t.rz);
          projectionMatrix.rotateX(t.rx);
          projectionMatrix.rotateY(t.ry);
          PVector off = b.getOffsetFromID(t.id);
          PVector projectedPoint = new PVector();
          projectionMatrix.mult(off, projectedPoint);
          loc.add(new PVector(t.tx + projectedPoint.x, t.ty + projectedPoint.y, t.tz + projectedPoint.z));
          ori.add(new PVector(t.rx, t.ry, t.rz));
        }
        loc.div(activeTags.size());
        ori.div(activeTags.size());
        b.set(loc.x, loc.y, loc.z, ori.x, ori.y, ori.z);
      } else {
        b.setInactive();
      }
    }
  }
  
  void displaySimple() {
    for (Tag t : tags) {
      if (t.active && t.id!=0) {
        pushMatrix();
        pushStyle();
        noStroke();
        //fill(255,0,0);
        //ellipse(t.corners[0].x,t.corners[0].y,5,5);
        //fill(255,255,0);
        //ellipse(t.corners[1].x,t.corners[1].y,5,5);
        //fill(0,255,255);
        //ellipse(t.corners[2].x,t.corners[2].y,5,5);
        //fill(0,0,255);
        //ellipse(t.corners[3].x,t.corners[3].y,5,5);
        //fill(0,0,255);
        
        
        beginShape();
        fill(255);
        stroke(0);
        for (int i = 0; i < 4; i++) {
          vertex(t.corners[i].x,t.corners[i].y);
        }
        endShape(CLOSE);
        
        fill(52);
        noStroke();
        
        PVector c = new PVector((t.corners[0].x+t.corners[2].x)/2,(t.corners[0].y+t.corners[2].y)/2); 
        textAlign(CENTER, CENTER);
        textSize(32);
        text(t.id, c.x, c.y);
        popStyle();
        popMatrix();
      }
    }
  }

  void displayRaw() {
    for (Tag t : tags) {
      if (t.active) {
        pushMatrix();
        pushStyle();
        noStroke();
        fill(255,0,0);
        ellipse(t.corners[0].x,t.corners[0].y,5,5);
        fill(255,255,0);
        ellipse(t.corners[1].x,t.corners[1].y,5,5);
        fill(0,255,255);
        ellipse(t.corners[2].x,t.corners[2].y,5,5);
        fill(0,0,255);
        ellipse(t.corners[3].x,t.corners[3].y,5,5);
        fill(0,0,255);
        
        
        beginShape();
        fill(255);
        stroke(0,255,0);
        for (int i = 0; i < 4; i++) {
          vertex(t.corners[i].x,t.corners[i].y);
        }
        endShape(CLOSE);
        
        fill(52);
        noStroke();
        
        PVector c = new PVector((t.corners[0].x+t.corners[2].x)/2,(t.corners[0].y+t.corners[2].y)/2); 
        //String s = "(x,y)=("+nf(round(t.tx*100))+","+nf(round(t.ty*100))+")\nz="+nf(round(t.tz*100));
        //marker中间显示文字（如果能改成显示图片更好但是算了
        textAlign(CENTER, CENTER);
        textSize(18);
        text("ID="+t.id+"\n", c.x, c.y);
        popStyle();
        popMatrix();
      }
    }
  }

  void display2D(SimpleMatrix homography) {
    for (Tag t : tags) {
      if (!isCorner(t.id) && t.active) {
        float tagD = 30;
        float angle2D = t.rz;
        PVector loc2D = transformPoint(new PVector(t.tx, t.ty, t.tz), homography);
        drawTagSimple(t.id, loc2D, angle2D, tagD, color(0, 127, 255)); //example visualization
      }
    }
    for (Bundle b : tagBundles) {
      if (b.active) {
        float bundleD = 30;
        float angle2D = b.rz;
        PVector loc2D = transformPoint(new PVector(b.tx, b.ty, b.tz), homography);
        drawTagSimple(b.ids.get(0), loc2D, angle2D, bundleD, color(127, 255, 0)); //example visualization
      }
    }
  }
  
  void displayEvents() {
    for (Tag t : tags) {
      if (!isCorner(t.id) && t.active) {
        float tagD = 30;
        float angle2D = t.rz;
        PVector loc2D = transformPoint(new PVector(t.tx, t.ty, t.tz), homography);
        drawTagSimple(t.id, loc2D, angle2D, tagD, color(0, 127, 255)); //example visualization
      }
    }
    for (Bundle b : tagBundles) {
      if (b.active) {
        float bundleD = 30;
        float angle2D = b.rz;
        PVector loc2D = transformPoint(new PVector(b.tx, b.ty, b.tz), homography);
        drawTagSimple(b.ids.get(0), loc2D, angle2D, bundleD, color(127, 255, 0)); //example visualization
      }
    }
  }

  void drawTagSimple(int id, PVector loc2D, float angle2D, float bundleD, color c) {
    float bundleR = bundleD/2;
    pushMatrix();
    pushStyle();
    fill(c);
    stroke(0);
    ellipse(loc2D.x, loc2D.y, bundleD, bundleD);
    line(loc2D.x, loc2D.y, loc2D.x + bundleR * (cos(angle2D)), loc2D.y + bundleR * (sin(angle2D)));
    fill(255);
    noStroke();
    textAlign(CENTER, CENTER);
    text(id, loc2D.x, loc2D.y);
    popStyle();
    popMatrix();
  }
}
