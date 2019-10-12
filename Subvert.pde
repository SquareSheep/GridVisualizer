static String songName = "ghostvoices";

import ddf.minim.analysis.*;
import ddf.minim.*;

Minim mim;
AudioPlayer song;
FFT fft;

static int binCount = 256;
static int bin = 10;
float[] av = new float[binCount];
float max;
float avg;
boolean kick = false;
float kickThreshold = 60;
float kickPercent = 0.95;

ArrayList<Cube> ar = new ArrayList<Cube>();
ArrayList<Sparkle> sr = new ArrayList<Sparkle>();
static float depth;

void setup() {
  frameRate(120);
  //fullScreen(P3D);
  size(1200,1200,P3D);
  depth = height*3/8;
  rectMode(CENTER);
  noStroke();
  noStroke();
  mim = new Minim(this);
  song = mim.loadFile("../../../Music/" + songName + ".mp3", 1024);
  song.loop();
  fft = new FFT(song.bufferSize(), song.sampleRate());

  float w = width/bin;
  for (int i = 0 ; i < bin ; i ++) {
    for (int k = 0 ; k < bin ; k ++) {
      ar.add(new Cube((k + 0.5) * w, (i + 0.5) * w, 0, w, i * bin + k));
    }
  }
}

void draw() {
  update();
  beginCamera();
  camera();
  rotateX(-PI/15 + sin((float)frameCount/540)*0.02);
  translate(0,-height*0.05 + cos((float)frameCount/540) * 50,-width);
  endCamera();
  background(0);
  for (int i = 0 ; i < ar.size() ; i ++) {
    ar.get(i).render();
  }

  for (int i = 0 ; i < sr.size() ; i ++) {
    sr.get(i).render();
  }

}

void update() {
  if (frameCount % 6 == 0 && sr.size() < 60) {
    int index = (int)random(0,binCount);
    sr.add(new Sparkle((float)index/binCount*width,width, width*1.2, index));
    index = (int)random(0,binCount);
    sr.add(new Sparkle((float)index/binCount*width,0, width*1.2, index));
    index = (int)random(0,binCount);
    sr.add(new Sparkle(width,(float)index/binCount*width, width*1.2, index));
    index = (int)random(0,binCount);
    sr.add(new Sparkle(0,(float)index/binCount*width, width*1.2, index));
  }
  calcFFT();
  for (int i = 0 ; i < ar.size() ; i ++) {
    ar.get(i).update();
  }
  for (int i = 0 ; i < sr.size() ; i ++) {
    Sparkle sp = sr.get(i);
    sp.update();
    if (sp.z < 0) sr.remove(i);
  }
}

void calcFFT() {
  fft.forward(song.mix);

  avg = 0;
  max = 0;
  for (int i = 0 ; i < av.length ; i ++) {
    float temp = 0;
    for (int k = i ; k < fft.specSize() ; k += i + 1) {
      temp += fft.getBand(k);
    }
    temp /= av.length / (i + 1);
    temp = pow(temp,2);
    avg += temp;
    av[i] = temp;
  }
  avg /= av.length;

  float kickProp = 0;
  for (int i = 0 ; i < av.length ; i ++) {
    if (av[i] > kickThreshold) kickProp ++;
    if (av[i] < avg*1.7) {
      av[i] /= 2;
    } else {
      av[i] += (av[i] - avg * 1.7) /2;
    }
    if (av[i] > max) max = av[i];
  }
  kick = (kickProp/av.length > kickPercent);

}

void renderQuad(Point p1, Point p2, Point p3, Point p4) {
  beginShape();
  vertex(p1.x, p1.y, p1.z);
  vertex(p2.x, p2.y, p2.z);
  vertex(p3.x, p3.y, p3.z);
  vertex(p4.x, p4.y, p4.z);
  vertex(p1.x, p1.y, p1.z);
  endShape();
}

class Sparkle {
  float x;
  float y;
  float z;
  float vx = 0;
  float vy = 0;
  float vz = 0;
  float mult;
  int i;
  float w;
  float r=255;
  float g = 255;
  float b=255;
  float a=255;

  Sparkle(float x, float y, float z, int i) {
   this.x = x;
   this.y = y;
   this.z = z;
   this.w = w;
   this.i = i;
   vz = -0.1;
  }

  void render() {
    push();
    fill(r,g,b,a);
    translate(x, y, z);
    box(w);
    pop();
  }

  void update() {
    float scale = av[i]/(max/5 + 1)/400;
    r = 125 - (av[i]*4-b)/4 - i/3;
    g = av[i] + i + scale*30;
    b = scale*30000 + av[i]/5;
    mult = av[i] + 10;
    x += vx * mult;
    y += vy * mult;
    z += vz * mult;
    w += (av[i]/8 + 5 - w)*width*0.0001;
  }
}

class Cube {
  Point[] ar = new Point[8];
  float w;
  float x;
  float y;
  float z;
  int i;
  float r = 0;
  float g = 0;
  float b = 0;
  float a = 155;

  Cube(float x, float y, float z, float w, int index) {
    this.x = x;
    this.y = y;
    this.z = z;
    this.w = w;
    i = index;
    float d = w/2;
    ar[0] = new Point(-d,-d,-d);
    ar[1] = new Point(d,-d,-d);
    ar[2] = new Point(d, d, -d);
    ar[3] = new Point(-d, d, -d);
    ar[4] = new Point(-d,-d, d);
    ar[5] = new Point(d,-d, d);
    ar[6] = new Point(d, d, d);
    ar[7] = new Point(-d, d, d);
  }

  void render() {
    push();
    fill(r, g, b, a);
    translate(x, y, z);
    renderQuad(ar[0],ar[1],ar[2],ar[3]);
    renderQuad(ar[4],ar[5],ar[6],ar[7]);
    renderQuad(ar[1],ar[2],ar[6],ar[5]);
    renderQuad(ar[0],ar[3],ar[7],ar[4]);
    renderQuad(ar[0],ar[1],ar[5],ar[4]);
    renderQuad(ar[3],ar[2],ar[6],ar[7]);
    pop();
  }

  void update() {
    float scale = av[i]/(max/5 + 1)/400;
    r = 125 - (av[i]*4-b)/4 - i/3;
    g = av[i] + i + scale*30;
    b = scale*30000 + av[i]/5;
    //shake(av[i]/500);
    pushZ(scale*3000);
    for (int i = 0 ; i < 8 ; i ++) {
      ar[i].update();
    }
  }

  void shake(float amount) {
    for (int i = 0 ; i < 8 ; i ++) {
      float angle = random(0, PI * 2);
      ar[i].vx += cos(angle) * amount;
      ar[i].vy += sin(angle) * amount;
      ar[i].vz += sin(angle) * amount;
    }
  }

  void pushZ(float amount) {
    for (int i = 4 ; i < 8 ; i ++) {
      ar[i].vz += amount;
    }
  }

  void move(float x, float y, float z) {
    this.x = x;
    this.y = y;
    this.z = z;
    float dx = x - this.x;
    float dy = y - this.y;
    float dz = z - this.z;
    for (int i = 0 ; i < 8 ; i ++) {
      ar[i].X += dx;
      ar[i].Y += dy;
      ar[i].Z += dz;
    }
  }

  void displaceZ(float z) {
    this.z += z;
    for (int i = 0 ; i < 8 ; i ++) {
      ar[i].Z += z;
      ar[i].z += z;
    }
  }

  void displace(float x, float y, float z) {
    this.x += x;
    this.y += y;
    this.z += z;
    for (int i = 0 ; i < 8 ; i ++) {
      ar[i].X += x;
      ar[i].Y += y;
      ar[i].Z += z;
      ar[i].x += x;
      ar[i].y += y;
      ar[i].z += z;
    }
  }
}

class Bar {
  float mass = 5;
  float x;
  float y;
  float w;
  float h = 0;
  float H = 0;
  Bar(float x, float y, float w) {
    this.x = x;
    this.y = y;
    this.w = w;
  }

  void render() {
    rect(x, y, w, h);
  }

  void update() {
    h += (H - h) / mass;
  }
}

class Point {
  float x;
  float y;
  float z;
  float X;
  float Y;
  float Z;
  float vx = 0;
  float vy = 0;
  float vz = 0;
  float vMult = 0.7;
  float mass = 15;

  Point(float x, float y, float z) {
    this.x = x;
    this.y = y;
    this.z = z;
    this.X = x;
    this.Y = y;
    this.Z = z;
  }
  
  void update() {
    x += vx;
    y += vy;
    z += vz;
    vx *= vMult;
    vy *= vMult;
    vz *= vMult;
    vx += (X - x)/mass;
    vy += (Y - y)/mass;
    vz += (Z - z)/mass;
  }

}