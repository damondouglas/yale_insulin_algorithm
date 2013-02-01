library yale_insulin_algorithm;

import 'dart:json';

class YaleInsulinAlgorithm {
  final int GOAL_MIN = 100;
  final int GOAL_MAX = 139;
  final Map<int,Entry> data = new Map<int,Entry>();
  String specialInstructions = "";
  
  num initial_bolus(int blood_glucose) {
    num factor = blood_glucose / 100;
    num base = factor.floor();
    return base + 0.5;
  }
  
  num initial_infusion(int blood_glucose) {
    return initial_bolus(blood_glucose);
  }
  
  num followup_infusion(int blood_glucose, Entry lastEntry) {
    
    if (blood_glucose <= 74) {
      return 0;
    }
    if (blood_glucose >= 75) {
        int dbg = blood_glucose - lastEntry.blood_glucose;
        int factor = null;
        if (blood_glucose <=99) {
          factor = _delta_75_99(dbg);
        }
        if (blood_glucose > 99 && blood_glucose <=139) {
          factor = _delta_100_139(dbg);
        }
        if (blood_glucose > 139 && blood_glucose <=199) {
          factor = _delta_140_199(dbg);
        }
        if (blood_glucose >= 200) {
          factor = _delta_200(dbg);
        }
        num ird = infusion_rate_delta(lastEntry.insulin_dose);
        num dose_change = ird*factor;
        return lastEntry.insulin_dose + dose_change;
    }
  }
  
  num infusion_rate_delta(num currentInfusion) {
    if (currentInfusion < 3.0) {
      return 0.5;
    }
    if (currentInfusion >= 3.0 && currentInfusion <= 6.0) {
      return 1.0;
    }
    if (currentInfusion >= 6.5 && currentInfusion <= 9.5) {
      return 1.5;
    }
    if (currentInfusion >= 10 && currentInfusion <= 14.5) {
      return 2;
    }
    if (currentInfusion >= 15 && currentInfusion <= 19.5) {
      return 3;
    }
    if (currentInfusion >= 20 && currentInfusion <= 24.5) {
      return 4;
    }
    if (currentInfusion >= 25 ) {
      return 5;
    }
  }
  
  int _delta_75_99(int delta_bg) {
    if (delta_bg > 0) {
      return 0;
    } else {
      int abs_dbg = delta_bg.abs();
      
      if (abs_dbg == 0) {
        return 0;
      }
      
      if (abs_dbg >=1 && abs_dbg <= 25) {
        return -1;
      }
      
      if (abs_dbg > 25) {
        return -2;
      }
    }
    
  }
  
  int _delta_100_139(int delta_bg) {
    int abs_dbg = delta_bg.abs();
    
    if (delta_bg > 25) {
      return 1;
    }
    
    if (abs_dbg <=25) {
      return 0;
    } 
    
    if (delta_bg < -25) {
      if (abs_dbg >=26 && abs_dbg <=50) {
        return -1;
      }
      
      if (abs_dbg > 50) {
        return -2;
      }
    }
    
  }
  
  int _delta_140_199(int delta_bg) {
    int abs_dbg = delta_bg.abs();
    
    if (delta_bg >=0) {
      if (abs_dbg <= 50) {
        return 1;
      }
      if (abs_dbg >50) {
        return 2;
      }
    }
    
    if (delta_bg <0) {
      if (abs_dbg <=50) {
        return 0;
      }
      
      if (abs_dbg >50 && abs_dbg <= 75) {
        return -1;
      }
      
      if (abs_dbg > 75) {
        return -2;
      }
    }
  }
  
  int _delta_200(int delta_bg){
    int abs_dbg = delta_bg.abs();
    
    if(delta_bg > 0) {
      return 2;
    }
    
    if(delta_bg <=0) {
      if(abs_dbg <=25) {
        return 1;
      }
      
      if(abs_dbg > 25 && abs_dbg <=75) {
        return 0;
      }
      
      if(abs_dbg > 75 && abs_dbg <=100) {
        return -1;
      }
      
      if(abs_dbg > 100) {
        return -2;
      }
    }
  }
  
  void set(Entry entry, Function callback) {
    Date date = entry.date;
    int key = date.millisecond;
    data[key] = entry;
    data.forEach(callback);
  }
  
  Entry get(int key) => data[key];
  
  List<Entry> entries() => data.values;
  
  bool isAtGoal(int blood_glucose) {
    return blood_glucose >= GOAL_MIN && blood_glucose <= GOAL_MAX;
  }
  
  Date nextBloodGlucose(int blood_glucose,[Date fromDate]) {
    Duration duration = new Duration(hours: 1);
    
    if (isAtGoal(blood_glucose)) {
      duration = new Duration(hours: 2);
    }
    
    if(?fromDate) {
      fromDate = new Date.now();
    }
    
    return fromDate.add(duration);
    
  }
}

class Entry {
  Date date;
  int blood_glucose;
  num insulin_dose;
  String uom = "";
  String comments = "";
  
  
  Entry();
  
  Entry.fromMap(Map map) {
    Entry entry = new Entry();
    int timeStamp = map["date"];
    date = new Date.fromMillisecondsSinceEpoch(timeStamp);
    blood_glucose = map["bg"];
    insulin_dose = map["insulin"];
    uom = map["uom"];
    comments = map["comments"];
  }
  
  String toString() {
    return stringify(toMap());
  }
  
  Map toMap() {
    Map map = {
               "date":date.millisecondsSinceEpoch,
               "bg":blood_glucose,
               "insulin":insulin_dose,
               "uom":uom,
               "comments":comments
    };
    return map;
  }
  
  
}
