void oscEvent(OscMessage msg) {
  if (msg.checkAddrPattern("/marker")) {
    int id = msg.get(0).intValue();
    float tx = msg.get(1).floatValue();
    float ty = msg.get(2).floatValue();
    float tz = msg.get(3).floatValue();
    float rx = msg.get(4).floatValue();
    float ry = msg.get(5).floatValue();
    float rz = msg.get(6).floatValue();
    float p1x = msg.get(7).intValue();
    float p1y = msg.get(8).intValue();
    float p2x = msg.get(9).intValue();
    float p2y = msg.get(10).intValue();
    float p3x = msg.get(11).intValue();
    float p3y = msg.get(12).intValue();
    float p4x = msg.get(13).intValue();
    float p4y = msg.get(14).intValue();
    
    
    // 计算四个角点的中心点
    float centerX = (p1x + p2x + p3x + p4x)/4;
    float centerY = (p1y + p2y + p3y + p4y)/4;
    
    int gridX = int(centerX/ cellSize);
    int gridY = int(centerY/ cellSize);
    
     // 获取当前时间戳
    long currentTime = millis();
    
    // 获取上次检测到该 id 的时间和位置
    Long lastDetectionTime = markerDetectionTimes.get(id);
    PVector lastPosition = markerLastPositions.get(id);
    
    // 如果没有记录过该 id，或者位置发生变化
    if (lastDetectionTime == null || dist(lastPosition.x, lastPosition.y, centerX, centerY) > cellSize) {
      // 更新检测时间和位置
      markerDetectionTimes.put(id, currentTime);
      markerLastPositions.put(id, new PVector(centerX, centerY));
    }

    // 确保索引在地图范围内
    if (gridX >= 0 && gridX < cols && gridY >= 0 && gridY < rows) {
      // 对未支付的 marker 才清除之前的供电状态
      if (!paidMarkers.contains(id)) {
        clearPowerForMarker(id);
        clearGreenForMarker(id);
      }
      
      if (id == 1 || id==8 || id==13 || id==8 || id==14 || id==19 || id==3) {
        if (!paidMarkers.contains(id)) {
          // 检查是否停留在同一格超过 1 秒
          if (lastDetectionTime != null && (currentTime - lastDetectionTime >= 1000)) {
            if (map[gridX][gridY] == 1) { // 如果当前格是风车位置
              if (currency >= 50) {
                currency -= 50;
                paidMarkers.add(id); // 标记为已支付
                paidMarkerPositions.put(id, new PVector(gridX, gridY)); // 记录供电格子位置
                applyPower(id, gridX, gridY, 3);
              }
            }
          }
        } 
      }
      
    if (id == 17 || id==23 || id==10 || id==7 || id==20 || id==11 || id==16) {
      if (!paidMarkers.contains(id)) {
        // 检查是否停留在同一格超过 1 秒
        if (lastDetectionTime != null && (currentTime - lastDetectionTime >= 1000)) {
          // 确保 marker 中心格子在供电范围内
          if (powered[gridX][gridY]) {
            if (currency >= 75) {
              currency -= 75;
              paidMarkers.add(id);  // 标记为已支付
              applyGreen(id, gridX, gridY, 4); // 应用绿地范围
            }
          }
        }
      }
    }
    
    if (id == 6 || id==15 || id==21 || id==22 || id==9|| id==4) {
        if (!paidMarkers.contains(id)) {
          // 检查是否停留在同一格超过 1 秒
          if (lastDetectionTime != null && (currentTime - lastDetectionTime >= 1000)) {
            // 确保 marker 中心格子在供电范围内
            if (powered[gridX][gridY]) {
              if (currency >= 75) {
                currency -= 75;
                paidMarkers.add(id);  // 标记为已支付
                println("Before applyGrass: map[" + gridX + "][" + gridY + "] = " + map[gridX][gridY]);
                applyGrass(id, gridX, gridY, 4); // 应用草地范围
              }
            }
          }
        }
      }
      
      if (id == 18 && gridY==5) {
        if (!paidMarkers.contains(id)) {
          // 检查是否停留在同一格超过 1 秒
          if (lastDetectionTime != null && (currentTime - lastDetectionTime >= 1000)) {          
            if (currency >= 35) {
              currency -= 35;
              paidMarkers.add(id);  // 标记为已支付
              applyWater(id, gridX, gridY);
            }
          }
        }
      }
      
      if ((id == 20 || id==2 ||id ==12) && gridY==5) {
        if (!paidMarkers.contains(id)) {
          // 检查是否停留在同一格超过 1 秒
          if (lastDetectionTime != null && (currentTime - lastDetectionTime >= 1000)) {          
            if (currency >= 45) {
              currency -= 45;
              paidMarkers.add(id);  // 标记为已支付
              applyStone(id, gridX, gridY);
            }
          }
        }
      }
    }
  
    
    // 更新 marker 信息
    PVector[] corners = {
      new PVector(p1x, p1y),
      new PVector(p2x, p2y),
      new PVector(p3x, p3y),
      new PVector(p4x, p4y)
    };
    tm.set(id, centerX, centerY, 0, 0, 0, 0, corners); // 更新 tagManager
  }
}
