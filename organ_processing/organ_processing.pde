
import processing.serial.*;
import ddf.minim.*;

ArmManager manager;
ArrayList<boolean[]> lines = new ArrayList<boolean[]>();
Serial myPort;
int recData = 0;

float OFFSETY = -4;
int LED_POWER = 880;
int LED_POWER_WHITE = 880;

int W = 200;
int H = 200;

float RX = W/2;
float RY = 50;
float ARM1L = 64.5;
float ARM2L = 65;
float cx = W/2;
float cy = 135;
int wait = 0;
float rect = 10;
int[] line = new int[20];
int lineId = 0;
float _y = 100;
int led = 0;
String phase = "find";
boolean roller = false;
boolean led1 = false;
boolean led2 = false;
int playTick = 30;

Player player;

void setup() {
  frameRate(60);
  size(500, 1600);
  player = new Player(new Minim(this));
  myPort = new Serial(this, "COM3", 9600);
  manager = new ArmManager(RX, RY, ARM1L, ARM2L, W/2-60, 100, 120, 70);
  phase = "none";
}
void clearScreen() {
  background(#ffffff);
  strokeWeight(1);
  stroke(#CCCCCC);
  for(int li = 0; li < 20; li++){
    int lx = int(li*6-OFFSETY)*5;
    line(lx, 0, lx, height);
  }
}
void draw() {
  float _x;
  _x = cx;
  if(phase.equals("none")){
    _y = 100;
    roller = false;
  }else if(phase.equals("find")){
    wait++;
    //finding head
    _y = 100;
    if(led < LED_POWER){
      if(wait > 5){
        roller = false;
        phase = "read";
      }
    }else{
      roller = true;
    }
 
  }else if(phase.equals("read")){
    float lh = float(1023-led)/1023f*50f*2;
    float lx = (_y-100)*5;
    float ly = lineId * 60 + 30;
    int id = int((_y-100+OFFSETY)/6);
    stroke(led < LED_POWER?#333333:#999999);
    strokeWeight(5);
    line(lx, ly - lh/2, lx, ly + lh/2);
    led1 = false;
    _y += 1;
    if(_y > 100 + 75) {
      wait = 0;
      phase = "next";
      _y = 100;
    }else{
      //reading
    }
  }else if(phase.equals("next")){
    wait ++;
    _y = 100;
    if(wait > 30){
      if(led > LED_POWER_WHITE){
        boolean[] tmpLine = new boolean[20];
        float ly = lineId * 60 + 30;
        for(int i = 0; i < 20; i ++){
          float lx = (float(i)*6f - OFFSETY + 3f) * 5f;
          
          print((line[i]<10?"0":"")+line[i]+"|");
          tmpLine[i] = line[i]>7;
          if(tmpLine[i] && i > 1){
            noStroke();
            fill(#ffffff);
            ellipse(lx, ly, 10, 10);
            noFill();
          }
          //print((tmpLine[i]?"#":"-"));
          line[i] = 0;
        }
        println();
        player.playLine(tmpLine);
        lines.add(tmpLine);
        phase = "find";
        lineId ++;
        wait = 0;
      }else{
        roller = true;
      }
    }
  }else if(phase.equals("playing")){
    wait++;
    roller = false;
    _x = cx + 60;
    if(wait > playTick) {
      led1 = !led1;
      if(player.next()){
        led1 = true;
      }
      wait = 0;
      //beating led
    }
    
    _y = 100;
  }
  manager.setTarget(_x, _y);
  //rot1 = rot2 = 90;
  servo(
    manager.getRotations().rot1, 
    manager.getRotations().rot2,
    roller?100:90
  );
}

void receiveLED() {
  if(phase.equals("read")){
    int id = int((_y-100+OFFSETY)/6);
    if(id < 0) id = 0;
     if(led < LED_POWER){
       line[id] ++;
       //led1 = true;
     }else{
       //led1 = false;
     }
  }
}
void btn1() {
  clearScreen();
  lineId = 0;
  println("start scanning");
  lines = new ArrayList<boolean[]>();
  phase = "find";
}
void btn2() {
  println("start playing");
  led1 = false;
  phase = "playing";
  wait = 0;
  player.setSound(lines);
}
void servo(float sv1r, float sv2r, float sv3r) {
  
  if(Float.isNaN(sv1r) || Float.isNaN(sv2r)){
    sv1r = 90;
    sv2r = 0;
  }
  
  sv1r += 14;
  sv2r += 1;
  //servo1 min 62
  
  //servo2 max 135
  if(sv2r > 135) sv2r = 135;
  
  //add head
  myPort.write('s');
  //servo1
  myPort.write(Float.toString((sv1r)) + '\n');
  //servo2
  myPort.write(Float.toString((sv2r)) + '\n');
  //servo3
  myPort.write(Float.toString(sv3r) + '\n');
  //requestVolume
  myPort.write((phase.equals("playing")?"1":"0") + '\n');
  //led1
  myPort.write((led1?"1":"0") + '\n');
  //led2
  myPort.write((led2?"1":"0") + '\n');
  
  //println(sv1r + ":" +  sv2r);
}

void serialEvent(Serial p) {
  if(p.available() > 0){
    String data = p.readStringUntil('\n');
    int body;
    char head;
    if(data != null){
      head = data.charAt(0);
      body = int(float(data.substring(1).replaceAll("\n", "")));
      if(head == 'l'){
        led = body;
        receiveLED();
      }
      if(head == '1'){
        if(body == 1) btn1();
      }
      if(head == '2'){
        if(body == 1) btn2();
      }
      if(head == 'v'){
        playTick =  int(float(body)/float(1023) * float(30));
      }
    }
  }
}
class ArmManager {
  private float _rootX, _rootY;
  private float _arm1L, _arm2L;
  private float _areaX, _areaY;
  private float _areaW, _areaH;
  private ArmRotations _rotations;
  public ArmManager(float rootX, float rootY, float arm1L, float arm2L, float areaX, float areaY, float areaW, float areaH) {
    _rootX = rootX;
    _rootY = rootY;
    _arm1L = arm1L;
    _arm2L = arm2L;
    _areaX = areaX;
    _areaY = areaY;
    _areaW = areaW;
    _areaH = areaH;
    _rotations = new ArmRotations();
  }
  public void setTargetInArea(float x, float y) {
    if(x < 0) x = 0;
    if(y < 0) y = 0;
    if(x > _areaW) x = _areaW;
    if(y > _areaH) y = _areaH;
    setTarget(x + _areaX, y + _areaY);
  }
  public void setTarget(float x, float y) {
    float a = getLength(x, y, _rootX, _rootY);
    float b = _arm1L;
    float c = _arm2L;
  
    float A = acos((b * b + c * c - a * a) / (2 * b * c));
    float B = acos((a * a + c * c - b * b) / (2 * a * c));
    float C = acos((a * a + b * b - c * c) / (2 * a * b));
    
    float base = getRadian(_rootX, _rootY, x, y) * 180 / PI;
    
    _rotations.rot1 = base - C * 180 / PI;
    _rotations.rot2 = (PI - A) * 180 / PI;
  }
  public ArmRotations getRotations() {
    return _rotations;
  }
  private float getLength(float tx, float ty, float fx, float fy) {
    float x = tx - fx;
    float y = ty - fy;
    return sqrt(x * x + y * y);
  }
  private float getRadian(float tx, float ty, float fx, float fy) {
    return atan2(fy - ty, fx - tx);
  }
}
class ArmRotations{
  public float rot1 = 0;
  public float rot2 = 0;
}
import ddf.minim.*;
class Player {
  private Minim _minim;
  private ArrayList<boolean[]> _sound;
  private int id = 0;
  HashMap<String, AudioSample> _map;
  public Player(Minim minim) {
    _minim = minim;
    _map = new HashMap<String, AudioSample>();
    init();
  }
  private void init() {
    addSound("1do", _minim.loadSample("piano/1do.wav"), 0.5);
    addSound("2re", _minim.loadSample("piano/2re.wav"), 0.5);
    addSound("3mi", _minim.loadSample("piano/3mi.wav"), 0.5);
    addSound("4fa", _minim.loadSample("piano/4fa.wav"), 0.5);
    addSound("5so", _minim.loadSample("piano/5so.wav"), 0.5);
    addSound("6ra", _minim.loadSample("piano/6ra.wav"), 0.5);
    addSound("7si", _minim.loadSample("piano/7si.wav"), 0.5);
    addSound("8do", _minim.loadSample("piano/8do.wav"), 0.5);
    addSound("d1", _minim.loadSample("drum/1.wav"), 1);
    addSound("d2", _minim.loadSample("drum/2.wav"), 1);
    play("1do");
    play("d1");
  }
  private void addSound(String tag, AudioSample audio, float volume) {
    audio.setVolume(volume);
    _map.put(tag, audio);
  }
  public void setSound(ArrayList<boolean[]> sound) {
    _sound = sound;
    id = 0;
  }
  public boolean next() {
    if(_sound.size() < 1) return false;
    boolean first = false;
    if(id >= _sound.size()) id = 0;
    
    if(id == 0) first = true;
    
    boolean[] line = _sound.get(id);
    
    playLine(line);
    
    id ++;
    return first;
  }
  public void playLine(boolean[] line) {
    for(int i = 0; i < line.length; i ++){
      if(!line[i]) continue;
      switch(i){
        case 11:
        play("1do");
        break;
        
        case 10:
        play("2re");
        break;
        
        case 9:
        play("3mi");
        break;
        
        case 8:
        play("4fa");
        break;
        
        case 7:
        play("5so");
        break;
        
        case 6:
        play("6ra");
        break;
        
        case 5:
        play("7si");
        break;
        
        case 4:
        play("8do");
        break;
        
        case 3:
        play("d1");
        break;
        
        case 2:
        play("d2");
        break;
      }
    }
  }
  private void play(String val) {
    _map.get(val).trigger();
  }
}