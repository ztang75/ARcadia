class Tag {
  int TTL = 200;
  boolean active;
  long ts;
  int id;
  float tx, ty, tz, rx, ry, rz;
  PVector[] corners;

  Tag(int id) {
    this.id = id;
    this.tx = 0;
    this.ty = 0;
    this.tz = 0;
    this.rx = 0;
    this.ry = 0;
    this.rz = 0;
    this.corners = new PVector[4];
    this.ts = 0;
    this.active = false;
  }

  void checkActive() {
    if (this.active && (millis()-this.ts)>this.TTL) {
      this.active = false;
      tagAbsent2D(this.id, this.tx, this.ty, this.tz, this.rz);
      tagAbsent3D(this.id, this.tx, this.ty, this.tz, this.rx, this.ry, this.rz);
    }
  }

  void set(float tx, float ty, float tz, float rx, float ry, float rz, PVector[] corners) {
    this.ts = millis();
    this.tx = tx;
    this.ty = ty;
    this.tz = tz;
    this.rx = rx;
    this.ry = ry;
    this.rz = rz;
    this.corners = corners;
    if (!this.active){
      tagPresent2D(this.id, this.tx, this.ty, this.tz, this.rz);
      tagPresent3D(this.id, this.tx, this.ty, this.tz, this.rx, this.ry, this.rz);
    }else{
      tagUpdate2D(this.id, this.tx, this.ty, this.tz, this.rz);
      tagUpdate3D(this.id, this.tx, this.ty, this.tz, this.rx, this.ry, this.rz);
    }
    this.active = true;
  }
}
