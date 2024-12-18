class Bundle {
  int TTL = 200;
  boolean active;
  long ts;
  ArrayList<Integer> ids;
  ArrayList<PVector> offs;
  float tx, ty, tz, rx, ry, rz;

  Bundle(ArrayList<Integer> bundleIDs, ArrayList<PVector> IDoffsets) {
    this.ids = new ArrayList<Integer>();
    this.offs = new ArrayList<PVector>();
    for (int i = 0; i < bundleIDs.size(); i++) {
      this.ids.add(bundleIDs.get(i));
      this.offs.add(IDoffsets.get(i));
    }
    this.tx = 0;
    this.ty = 0;
    this.tz = 0;
    this.rx = 0;
    this.ry = 0;
    this.rz = 0;
    this.ts = 0;
    this.active = false;
  }

  void setInactive() {
    if (this.active && (millis()-this.ts)>this.TTL) {
      this.active = false;
      bundleAbsent2D(this.ids.get(0), this.tx, this.ty, this.tz, this.rz); 
    }
  }

  void set(float tx, float ty, float tz, float rx, float ry, float rz) {
    this.ts = millis();
    this.tx = tx;
    this.ty = ty;
    this.tz = tz;
    this.rx = rx;
    this.ry = ry;
    this.rz = rz;
    if (!this.active){
      bundlePresent2D(this.ids.get(0), this.tx, this.ty, this.tz, this.rz);
    }else{
      bundleUpdate2D(this.ids.get(0), this.tx, this.ty, this.tz, this.rz);
    }
    this.active = true;
  }
  
  PVector getOffsetFromID (int targetID){
    int index = -1;
    for (int i = 0; i < this.ids.size(); i++) {
      if (this.ids.get(i) == targetID) {
        index = i;
        break;
      }
    }
    if(index>=0) return this.offs.get(index);
    else return new PVector(0,0,0);
  }
}
