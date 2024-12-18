import org.ejml.simple.SimpleMatrix;
import oscP5.*;
import netP5.*;
import processing.net.*;
import java.util.HashSet;
import java.util.Set;
import java.util.HashMap;
import java.util.Map;

PGraphics successOverlay;
boolean gameCompleted = false;

PGraphics failureOverlay;
boolean gameFailed = false;

// 用于记录每个 marker 的供电范围
Map<Integer, Set<String>> markerPoweredAreas = new HashMap<>();
// 定义一个额外的 Map 来记录已支付 marker 的供电范围
HashMap<Integer, PVector> paidMarkerPositions = new HashMap<>();

TagManager tm;
OscP5 oscP5;

int currency = 800;//初始资金
// 新增一个 Set 来跟踪已经处理过的 marker
Set<Integer> paidMarkers = new HashSet<>();

Map<Integer, Long> markerDetectionTimes = new HashMap<>(); // 记录每个 id 的检测时间
Map<Integer, PVector> markerLastPositions = new HashMap<>(); // 记录每个 id 的最后位置

PGraphics bottomLayer, topLayer;
PImage landImg, rockImg, riverImg, greenImg, grassImg, waterImg;
PImage windmillImg, pumpImg, scrubberImg, greenhouseImg, calcifierImg;

int[] cornersID = {};
int[][] bundlesIDs = {};
PVector[][] bundlesOffsets = {};
int camWidth = 1280;
int camHeight = 720;

// 地图参数
int cols = 20; // 地图列数
int rows = 10; // 地图行数
int cellSize = 50; // 每个格子大小
int[][] map = new int[cols][rows]; // 0: 荒地, 1: 石头, 2: 河床, 3: 绿地, 4: 草地
boolean[][] powered = new boolean[cols][rows]; // 是否供电

int totalGrass = 0;  // 草地数量

void setup() {
  size(1000, 600);
  oscP5 = new OscP5(this, 9000);

  // 加载图片
  landImg = loadImage("/picture/earth.png");
  rockImg = loadImage("/picture/stone.png");
  riverImg = loadImage("/picture/riverbed.png");
  greenImg = loadImage("/picture/green.png");
  grassImg = loadImage("/picture/grass.png");
  waterImg = loadImage("/picture/river.png");
  pumpImg= loadImage("/picture/pump.png");  //水泵
  windmillImg= loadImage("/picture/WINDMILL.png"); // 风车
  scrubberImg= loadImage("/picture/toxinScrubber.png"); //毒素清洁
  greenhouseImg= loadImage("/picture/greenhouse.png"); //温室
  calcifierImg= loadImage("/picture/calcifier.png");//沉积

  // 创建两个图层
  bottomLayer = createGraphics(width, height);
  topLayer = createGraphics(width, height);

  initTagManager();
  initializeMap();
}

void draw() {
  tm.update();
  background(200);
  drawMap();
  tm.displayRaw();

  // 在左下角显示货币
  pushStyle();
  fill(0);
  textAlign(LEFT, BOTTOM);
  textSize(24);
  text("Currency: €" + currency, 20, height - 25);
  popStyle();


  drawGreeningRing(greenRate());

  // 检查游戏成功条件
  if (greenRate() > 0.7 && !gameCompleted) {
    createSuccessOverlay();
    gameCompleted = true;
  }

  // 如果游戏已完成，绘制成功叠加层
  if (gameCompleted) {
    image(successOverlay, 0, 0);
  }
  
  // 检查游戏失败条件
  if (currency < 35 && greenRate() < 0.7 && !gameFailed) {
    createFailureOverlay();
    gameFailed = true;
  }
  
  // 如果游戏失败，显示失败窗口
  if (gameFailed) {
    image(failureOverlay, 0, 0);
    drawRetryButton();
  }
}


// 初始化地图
void initializeMap() {
  for (int x = 0; x < cols; x++) {
    for (int y = 0; y < rows; y++) {
      if (random(1) < 0.05 && y!=5) {
        map[x][y] = 1; // 随机生成石头
      } else if (y == 5) {
        map[x][y] = 2; // 随机生成河床
      } else {
        map[x][y] = 0; // 荒地
      }
      powered[x][y] = false; // 默认不供电
    }
  }
}

// 绘制地图
void drawMap() {
  for (int x = 0; x < cols; x++) {
    for (int y = 0; y < rows; y++) {
      PImage imgToDraw = null; // 要绘制的图片

      if (map[x][y] == 0) imgToDraw = landImg; // 荒地
      else if (map[x][y] == 1) imgToDraw = rockImg; // 石头
      else if (map[x][y] == 2) imgToDraw = riverImg; // 河床
      else if (map[x][y] == 3) imgToDraw = greenImg; // 绿地
      else if (map[x][y] == 4) imgToDraw = grassImg; // 草地
      else if (map[x][y] == 5) imgToDraw = waterImg; // 河水
      else if (map[x][y] == 6) imgToDraw = windmillImg;
      else if (map[x][y] == 7) imgToDraw = pumpImg;
      else if (map[x][y] == 8) imgToDraw = scrubberImg;
      else if (map[x][y] == 9) imgToDraw = greenhouseImg;
      else if (map[x][y] == 10) imgToDraw = calcifierImg;

      // 绘制对应的地图图片
      if (imgToDraw != null) {
        image(imgToDraw, x * cellSize, y * cellSize, cellSize, cellSize);
      }

      // 显示供电范围（如需叠加效果，可额外绘制半透明颜色）
      if (powered[x][y]) {
        fill(255, 255, 100, 50);
        rect(x * cellSize, y * cellSize, cellSize, cellSize);
      }
    }
  }
}

void clearPowerForMarker(int markerId) {
  if (paidMarkers.contains(markerId)) {
    // 如果 marker 已支付，跳过清除操作
    return;
  }
  if (markerPoweredAreas.containsKey(markerId)) {
    Set<String> poweredCells = markerPoweredAreas.get(markerId);
    for (String cell : poweredCells) {
      String[] parts = cell.split(",");
      int x = Integer.parseInt(parts[0]);
      int y = Integer.parseInt(parts[1]);
      powered[x][y] = false; // 清除供电
    }
    markerPoweredAreas.remove(markerId); // 从记录中删除
  }

  // 新增：额外检查所有其他 marker 的供电范围
  // 重新计算全局供电状态
  for (int x = 0; x < cols; x++) {
    for (int y = 0; y < rows; y++) {
      powered[x][y] = false; // 先全部重置为未供电
    }
  }

  // 重新应用所有 marker 的供电状态
  for (Integer existingMarkerId : markerPoweredAreas.keySet()) {
    // 假设 12 是风车 marker
    if (existingMarkerId == 1 || existingMarkerId==8 || existingMarkerId==13 || existingMarkerId==8 || existingMarkerId==14 || existingMarkerId==19 || existingMarkerId==3) {
      for (String cell : markerPoweredAreas.get(existingMarkerId)) {
        String[] parts = cell.split(",");
        int x = Integer.parseInt(parts[0]);
        int y = Integer.parseInt(parts[1]);
        powered[x][y] = true;
      }
    }
  }
}

// 清除绿地
void clearGreenForMarker(int markerId) {
  if (paidMarkers.contains(markerId)) {
    // 如果 marker 已支付，跳过清除操作
    return;
  }

  // 获取 marker 的绿地区域
  if (markerPoweredAreas.containsKey(markerId)) {
    Set<String> greenCells = markerPoweredAreas.get(markerId);
    for (String cell : greenCells) {
      String[] parts = cell.split(",");
      int x = Integer.parseInt(parts[0]);
      int y = Integer.parseInt(parts[1]);

      // 将绿地重置为荒地
      if (map[x][y] == 3) { // 确保只重置绿地
        map[x][y] = 0; // 0 代表荒地
      }
    }
    markerPoweredAreas.remove(markerId); // 从记录中删除
  }

  // 只在该格子不再有其他 marker 影响时才重置为荒地
  for (int x = 0; x < cols; x++) {
    for (int y = 0; y < rows; y++) {
      if (map[x][y] == 3) {  // 如果是绿地
        boolean keepGreen = false;

        // 检查是否有其他 marker 还在此区域内供电
        for (Integer existingMarkerId : markerPoweredAreas.keySet()) {
          Set<String> existingGreenCells = markerPoweredAreas.get(existingMarkerId);
          if (existingGreenCells.contains(x + "," + y)) {
            keepGreen = true;
            break;
          }
        }

        // 如果没有其他 marker 保持绿地，则重置为荒地
        if (!keepGreen) {
          map[x][y] = 0;
        }
      }
    }
  }
}


void applyPower(int markerId, int centerX, int centerY, int radius) {
  Set<String> poweredCells = new HashSet<>();
  // 遍历半径内的矩形区域
  for (int x = max(0, centerX - radius); x <= min(cols - 1, centerX + radius); x++) {
    for (int y = max(0, centerY - radius); y <= min(rows - 1, centerY + radius); y++) {
      // 计算当前格子到中心点的距离
      float dist = dist(centerX, centerY, x, y);

      // 如果距离小于或等于半径，则将该格子标记为供电状态
      if (dist <= radius) {
        powered[x][y] = true;  // 设置为供电状态
        poweredCells.add(x + "," + y);  // 保存供电格子的位置
      }
    }
  }

  if (map[centerX][centerY] == 1) {  // 如果中心格子是石头
    map[centerX][centerY] = 6;
  }

  markerPoweredAreas.put(markerId, poweredCells);  // 保存供电范围

  // 更新全局供电状态
  updatePoweredGrid();
}

void updatePoweredGrid() {
  // 重置所有格子的供电状态
  for (int x = 0; x < cols; x++) {
    for (int y = 0; y < rows; y++) {
      powered[x][y] = false;
    }
  }

  // 遍历所有 marker 的供电区域，更新全局供电状态
  for (Set<String> cells : markerPoweredAreas.values()) {
    for (String cell : cells) {
      String[] parts = cell.split(",");
      int x = Integer.parseInt(parts[0]);
      int y = Integer.parseInt(parts[1]);
      powered[x][y] = true;
    }
  }
}


//荒地变为绿地
void applyGreen(int markerId, int centerX, int centerY, int radius) {
  // 遍历半径内的区域
  for (int x = max(0, centerX - radius); x <= min(cols - 1, centerX + radius); x++) {
    for (int y = max(0, centerY - radius); y <= min(rows - 1, centerY + radius); y++) {
      // 计算当前格子到中心点的距离
      float dist = dist(centerX, centerY, x, y);

      // 如果在供电范围内，且格子是荒地
      if (map[x][y] == 0 && dist <= radius) {
        // 将该格子变为绿地
        map[x][y] = 3; // 3 表示绿地
        map[centerX][centerY] = 8;

        markerPoweredAreas.putIfAbsent(markerId, new HashSet<>());
        markerPoweredAreas.get(markerId).add(x + "," + y);
      }
    }
  }
}

//绿地变为草地
void applyGrass(int markerId, int centerX, int centerY, int radius) {
  // 遍历半径内的区域
  for (int x = max(0, centerX - radius); x <= min(cols - 1, centerX + radius); x++) {
    for (int y = max(0, centerY - radius); y <= min(rows - 1, centerY + radius); y++) {
      // 计算当前格子到中心点的距离
      float dist = dist(centerX, centerY, x, y);

      // 如果格子是绿地
      if (map[x][y] == 3 && dist <= radius) {
        // 将该格子变为草地
        map[x][y] = 4;

        // 更新草地数量和资金
        totalGrass++;  // 草地数量+1
        currency += 2; // 资金+2

        map[centerX][centerY] = 9;

        // 记录该格子为 marker 的绿地区域
        markerPoweredAreas.putIfAbsent(markerId, new HashSet<>());
        markerPoweredAreas.get(markerId).add(x + "," + y);
      }
    }
  }
}

//河水
void applyWater(int markerId, int centerX, int centerY) {
  for (int x = 0; x < cols; x++) {
    if (map[x][5] == 2 && map[x][4]!=6 && map[x][4]!=7&& map[x][4]!=8&& map[x][4]!=9&& map[x][4]!=10 && map[x][6]!=6 && map[x][6]!=7&& map[x][6]!=8&& map[x][6]!=9&& map[x][6]!=10) {
      map[x][5] = 5;
      map[x][4] = 4;
      map[x][6] = 4;
    } else if (map[x][4]==6 || map[x][4]==7 || map[x][4]==8 || map[x][4]==9 || map[x][4]==10 || map[x][6]==6 || map[x][6]==7 || map[x][6]==8 || map[x][6]==9 || map[x][6]==10) {
      map[x][5] = 5;
    }
  }
  totalGrass=totalGrass+20;  // 草地数量+1
  currency += 40; // 资金+2
  map[centerX][centerY] = 7;
}

//沉积
void applyStone(int markerId, int centerX, int centerY) {
  for (int x = 1; x < cols - 1; x++) {  // 从1到cols-2，避免越界
    if (map[x][5] == 5 && map[x][4]!=6 && map[x][4]!=7&& map[x][4]!=8&& map[x][4]!=9&& map[x][4]!=10 && map[x][6]!=6 && map[x][6]!=7&& map[x][6]!=8&& map[x][6]!=9&& map[x][6]!=10) {  // 如果该列的第 5 行是水
      // 左侧沉积石头
      if (centerX - 1 >= 0) {
        map[centerX - 1][4] = 1;  // 左边格子变为石头
        map[centerX - 1][6] = 1;  // 左边下方格子变为石头
      }
      // 右侧沉积石头
      if (centerX + 1 < cols) {
        map[centerX + 1][4] = 1;  // 右边格子变为石头
        map[centerX + 1][6] = 1;  // 右边下方格子变为石头
      }
      map[centerX][4] = 1;
      map[centerX][6] = 1;
    }
  }
  map[centerX][centerY] = 10;
}

// 计算绿化率
float greenRate() {
  int totalCells = cols * rows;  // 总格子数
  return Math.round((float) totalGrass / 185 * 100.0) / 100.0f;
}

void createSuccessOverlay() {
  successOverlay = createGraphics(width, height);
  successOverlay.beginDraw();

  // 半透明黑色背景
  successOverlay.background(0, 180);

  // 白色文字
  successOverlay.fill(255);
  successOverlay.textAlign(CENTER, CENTER);

  // 标题
  successOverlay.textSize(48);
  successOverlay.text("Thank you for your effort!", width/2, height/2 - 100);

  // 英文描述
  successOverlay.textSize(20);
  successOverlay.text("Transforming barren land is challenging.", width/2, height/2 + 50);
  successOverlay.text("Let's protect our environment together!", width/2, height/2 + 80);

  successOverlay.endDraw();
}

// 点击关闭成功界面
void mousePressed() {
  if (gameCompleted || gameFailed) {
    int buttonWidth = 200;
    int buttonHeight = 50;
    int buttonX = width / 2 - buttonWidth / 2;
    int buttonY = height / 2 + 100;

    // 检查鼠标是否点击了按钮
    if (mouseX >= buttonX && mouseX <= buttonX + buttonWidth && mouseY >= buttonY && mouseY <= buttonY + buttonHeight) {
      restartGame();
    }
  }
}

// 创建失败叠加层
void createFailureOverlay() {
  failureOverlay = createGraphics(width, height);
  failureOverlay.beginDraw();

  // 半透明黑色背景
  failureOverlay.background(0, 180);

  // 白色文字
  failureOverlay.fill(255);
  failureOverlay.textAlign(CENTER, CENTER);

  // 标题
  failureOverlay.textSize(48);
  failureOverlay.text("Oh! We're running out of money!", width / 2, height / 2 - 100);

  // 英文描述
  failureOverlay.textSize(20);
  failureOverlay.text("The path to a greener future isn't easy, but it's worth it!", width / 2, height / 2 + 50);

  failureOverlay.endDraw();
}

// 绘制重新开始按钮
void drawRetryButton() {
  int buttonWidth = 200;
  int buttonHeight = 50;
  int buttonX = width / 2 - buttonWidth / 2;
  int buttonY = height / 2 + 100;

  fill(100, 200, 100);
  rect(buttonX, buttonY, buttonWidth, buttonHeight, 10);

  fill(255);
  textAlign(CENTER, CENTER);
  textSize(20);
  text("Retry", buttonX + buttonWidth / 2, buttonY + buttonHeight / 2);
}



// 重新开始游戏
void restartGame() {
  gameCompleted = false;
  gameFailed = false;
  currency = 800;
  totalGrass = 0;

  initializeMap();
  markerPoweredAreas.clear();
  paidMarkers.clear();
  markerDetectionTimes.clear();
  markerLastPositions.clear();
}

void drawGreeningRing(float rate) {
  pushStyle();
  
  // 圆心位置与半径
  float centerX = width - 40; // 圆环的X位置
  float centerY = height - 40; // 圆环的Y位置
  float radius = 60; // 圆环的直径（减小）

  // 黑色外边框
  strokeWeight(12); // 边框宽度略宽于圆环
  stroke(0); // 黑色
  noFill();
  ellipse(centerX, centerY, radius, radius);

  // 背景圆环（深灰色）
  strokeWeight(10); // 圆环宽度
  stroke(100); // 深灰色
  ellipse(centerX, centerY, radius, radius);

  // 绿色圆环，根据比例填充
  stroke(100,200,100); // 深绿色
  float endAngle = map(rate, 0, 1, 0, TWO_PI); // 将绿化率映射到弧度范围
  arc(centerX, centerY, radius, radius, -HALF_PI, -HALF_PI + endAngle);

  // 显示文字
  fill(0); 
  textAlign(CENTER, CENTER);
  textSize(24); 
  text("Greening Rate: ", centerX-120, centerY); // 显示标题
  textSize(24); 
  text(int(rate * 100) + "%", centerX, centerY); // 显示百分比

  popStyle();
}
