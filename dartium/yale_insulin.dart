import 'dart:html';
import 'dart:async';
import 'dart:json';
import 'dart:svg';
import 'dart:math';
import 'lib/yale_insulin_algorithm.dart' as yia;

final DivElement output = query("#yio");
final Element header = query("#yihm");
final ButtonElement reset = query("#yirc");
final Element clock = query("#yiht");

final InputElement bgInput = query("#yicbg");
final ButtonElement enter = query("#yice");
final DateInputElement dateInput = query("#yicd");
final NumberInputElement hourInput = query("#yicth");
final NumberInputElement minInput = query("#yictm");
final DivElement editTime = query("#yichmd");
final Element confirmDiv = query("#yicc");
final DivElement tablediv = query("#yit");
final DivElement chartdiv = query("#yig");

final TableRowElement lastReadGlucose = new TableRowElement();
final TableRowElement bolusInstructions = new TableRowElement();
final TableRowElement infusionInstructions = new TableRowElement();
final TableRowElement d50Instructions = new TableRowElement();
final TableRowElement specialInstructions = new TableRowElement();

final yia.YaleInsulinAlgorithm alg = new yia.YaleInsulinAlgorithm();
int blood_glucose = -1;
int timeStamp = -1;

const int START = 0;
const int INITIAL = 1;
const int FOLLOW = 2;

void main() {
  initiate();
}

void initiate() {
  editTime.classes.toggle("hide");
  reset.on.click.add(handleReset);
  refreshClock(new Date.now());
  new Timer.repeating(1000,handleTimer);
  header.innerHtml = "The following insulin infusion protocol is intended for use in hyperglycemic adult patients in an ICU setting."
                      "<br/>Blood Glucose goal: <span style='color:red;'>${alg.GOAL_MIN.toString()}</span> - <span style='color:blue;'>${alg.GOAL_MAX.toString()}</span> mg/dL.";
  bgInput.placeholder = "Blood Glucose (mg/dL)";
  enter.disabled = true;
  
  bgInput.on.input.add(validateBGInput);
  bgInput.on.keyDown.add((KeyEvent e) {
    if (e.keyCode == 13) {
      enter.click();
    }
  });
  enter.on.click.add(confirmEntry);
  
  refresh();
  
  window.on.resize.add((e){
    refresh();
  });
}

void refreshClock(Date date) {
  
  String year = "${date.year}";
  
  String month = "${date.month}";
  
  String day = "${date.day}";
  
  String hour = "${date.hour}";
  if (date.hour == 0) {
    hour = "0$hour";
  }
  
  String min = "${date.minute}";
  if (min.length < 2) {
    min = "0$min";
  }
  
  String sec = "${date.second}";
  if (sec.length < 2) {
    sec = "0$sec";
  }
  clock.text = "$month/$day/$year $hour:$min:$sec";
}

void handleTimer(Timer t) {
  var date = new Date.now();
  refreshClock(date);
}


String toDate(Date date) {
  String year = "${date.year}";
  String month = "${date.month}";
  String day = "${date.day}";
  if (month.length < 2) {
    month = "0$month";
  }
  if (day.length < 2) {
    day = "0$day";
  }
  
  return "$year-$month-$day";
}

void validateBGInput(Event e) {
  String value = bgInput.value;
  if (value != "") {
    try {
      int.parse(value);
      enter.disabled = false;
      bgInput.placeholder = "Blood Glucose (mg/dL)";
      if (bgInput.classes.contains("alert")) {
        bgInput.classes.remove("alert");
      }
    } catch(e) {
      bgInput.value = "";
      bgInput.placeholder = "Only whole numbers.";
      if (!bgInput.classes.contains("alert")) {
        bgInput.classes.add("alert");
      }
      enter.disabled = true;
    }
    
  } else {
    if (bgInput.classes.contains("alert")) {
      bgInput.classes.remove("alert");
    }
    bgInput.placeholder = "Blood Glucose (mg/dL)";
  }
}

void confirmEntry(Event e) {
  int blood_glucose = int.parse(bgInput.value);
  Date timeStamp = new Date.fromMillisecondsSinceEpoch(e.timeStamp);
  enter.disabled = true;
  String year = timeStamp.year.toString();
  String month = timeStamp.month.toString();
  String day = timeStamp.day.toString();
  
  if (month.length < 2) {
    month = "0$month";
  }
  
  if (day.length < 2) {
    day = "0$day";
  }
  
  dateInput.value = "$year-$month-$day";
  hourInput.value = timeStamp.hour.toString();
  minInput.value = timeStamp.minute.toString();
  
  editTime.classes.toggle("hide");
  
  confirmDiv.innerHtml =  "<span class='confirm'>Are you sure? </span>"
                          "<input type='radio' id='yicccy' name='yiccc' value='Yes'></input>"
                          "<label for='yicccy'>Yes</label>"
                          "<input type='radio' id='yicccn' name='yiccc' value='Clear'></input>"
                          "<label for='yicccn'>Clear</label>";
  Element yes = query("#yicccy");
  Element no = query("#yicccn");
  yes.on.click.add((e){
    editTime.classes.toggle("hide");
    bgInput.value = ""; 
    confirmDiv.innerHtml = "";
    
    String hour = hourInput.value;
    String min = minInput.value;
    
    if (hour.length < 2) {
      hour = "0$hour";
    }
    
    if (min.length < 2) {
      min = "0$min";
    }
    
    String dateString = "${dateInput.value} $hour:$min:00";
    timeStamp = new Date.fromString(dateString);
    
    
    if (window.localStorage.length > 0) {
      followReading(timeStamp, blood_glucose);
    } else {
      initialReading(timeStamp, blood_glucose);
    }
    refresh();

  });
  
  no.on.click.add((e){
    editTime.classes.toggle("hide");
    
    bgInput.value = ""; 
    confirmDiv.innerHtml = "";
    
  });
}

void initialReading(Date timeStamp, int blood_glucose) {
  num bolus = alg.initial_bolus(blood_glucose);
  num infusion = alg.initial_infusion(blood_glucose);
  
  yia.Entry entry = new yia.Entry();
  entry.date = timeStamp;
  entry.blood_glucose = blood_glucose;
  entry.insulin_dose = bolus;
  entry.uom = "Units";
  entry.comments = "Initial Bolus";
  window.localStorage[timeStamp.millisecondsSinceEpoch.toString()] = entry.toString();
  
  timeStamp = timeStamp.add(new Duration(minutes:5));
  
  entry = new yia.Entry();
  entry.date = timeStamp;
  entry.blood_glucose = blood_glucose;
  entry.insulin_dose = infusion;
  entry.uom = "Units/hr";
  entry.comments = "Initial Infusion";
  window.localStorage[timeStamp.millisecondsSinceEpoch.toString()] = entry.toString();
  
}

void followReading(Date timeStamp, int blood_glucose) {
  String lastKey = window.localStorage.keys.last;
  yia.Entry lastEntry = new yia.Entry.fromMap(parse(window.localStorage[lastKey]));
  num infusion = alg.followup_infusion(blood_glucose, lastEntry);
  
  yia.Entry entry = new yia.Entry();
  entry.date = timeStamp;
  entry.blood_glucose = blood_glucose;
  entry.insulin_dose = infusion;
  entry.uom = "Units/hr";
  
  window.localStorage[timeStamp.millisecondsSinceEpoch.toString()] = entry.toString();
}

void refresh() {
  refreshInstructions();
  refreshTable();
  refreshChart();
}

int state() {
  int length = window.localStorage.length;
  
  switch (length) {
    case 0:
      return START;
    case 1:
      return -1;
    case 2:
      return INITIAL;
    default:
      return FOLLOW;
        
  } 
}

void refreshInstructions() {
  output.innerHtml = "";
  if (window.localStorage.length > 0) {
    String lastKey = window.localStorage.keys.last;
    String firstKey = window.localStorage.keys.first;
    yia.Entry infusionEntry = new yia.Entry.fromMap(parse(window.localStorage[lastKey]));
    TableElement table = new TableElement();
    table.classes.add("instructions");
    output.children.add(table);
    switch(state()) {
      case 0:
        break;
      case -1:
        break;
      case INITIAL:
        yia.Entry bolusEntry = new yia.Entry.fromMap(parse(window.localStorage[firstKey]));
        bolusInstructions.innerHtml = "<td style='text-align:right;'>Initial Bolus:</td><td><span style='color:blue;'>${bolusEntry.insulin_dose}</span> ${bolusEntry.uom}</td>";
        table.children.add(bolusInstructions);
        continue follow;
     follow:
      case FOLLOW:
        infusionInstructions.innerHtml = "<td style='text-align:right;'>Infusion:</td><td><span style='color:blue;'>${infusionEntry.insulin_dose}</span> ${infusionEntry.uom}</td>";
        table.children.add(infusionInstructions);
        break;
    }
    TableRowElement empty = new TableRowElement();
    empty.innerHtml = "<td>&nbsp;</td><td></td>";
    table.children.add(empty);
    lastReadGlucose.innerHtml = "<td style='text-align:right;'>Last Read Glucose:</td><td><span>${infusionEntry.blood_glucose}</span> mg/dL</td>";
    table.children.add(lastReadGlucose);
  }
}

void refreshTable() {
  tablediv.innerHtml = "";
  if (window.localStorage.length > 0) {
    TableElement table = new TableElement();
    tablediv.children.add(table);
    table.innerHtml = "<thead style='background:#8C8989;color:white;'><tr>"
                      "<th>Date/Time</th>"
                      "<th>Blood Glucose</th>"
                      "<th>Dose</th>"
                      "<th>Comments</th>"                
                      "</tr></thead>";
    Element tbody = new Element.html("<tbody></tbody>");
    
    table.children.add(tbody);
    window.localStorage.forEach((key, value){
      yia.Entry entry = new yia.Entry.fromMap(parse(value));
      TableRowElement row = new TableRowElement();
      row.classes.add("alt");
      tbody.children.add(row);
      TableCellElement dateCell = new TableCellElement();
      dateCell.style.paddingRight = "2em";
      TableCellElement bgCell = new TableCellElement();
      bgCell.style.paddingRight = "2em";
      TableCellElement doseCell = new TableCellElement();
      doseCell.style.paddingRight = "2em";
      TableCellElement commentCell = new TableCellElement();
      commentCell.style.paddingRight = "2em";
      row.children.add(dateCell);
      row.children.add(bgCell);
      row.children.add(doseCell);
      row.children.add(commentCell);
      
      Date timeStamp = entry.date;
      String hour = "${timeStamp.hour}";
      String min = "${timeStamp.minute}";
      String month = "${timeStamp.month}";
      String day = "${timeStamp.day}";
      
      if (min.length < 2) {
        min = "0$min";
      }
      
      dateCell.innerHtml = "$hour:$min $month/$day";
      bgCell.innerHtml = "${entry.blood_glucose} mg/dL";
      doseCell.innerHtml = "${entry.insulin_dose} ${entry.uom}";
      commentCell.innerHtml = "${entry.comments}";
      commentCell.id = "t:$key";
      commentCell.on.doubleClick.add(handleCommentClk);
    });
  }
}

void handleCommentClk(Event e) {
  Element target = e.currentTarget;
  String comment = target.text;
  String id = target.id;
  target.innerHtml = "";
  TextAreaElement tae = new TextAreaElement();
  ButtonElement button = new ButtonElement();
  tae.value = comment;
  button.text = "Ok";
  target.children.add(tae);
  target.children.add(button);
  
  button.on.click.add((e){
    comment = tae.value;
    String key = id.substring(2);
    yia.Entry entry = new yia.Entry.fromMap(parse(window.localStorage[key]));
    entry.comments = comment;
    window.localStorage[key] = entry.toString();
    refresh();
  });
}

void refreshChart() {
  chartdiv.innerHtml = "";
  
  LineElement bg_line = new LineElement();
  LineElement ins_line = new LineElement();
  
  if (window.localStorage.length > 1) {
    
    int window_width = document.body.offsetWidth;
    int min_bg = alg.GOAL_MIN;
    int max_bg = alg.GOAL_MAX;
    num min_insulin = 0;
    num max_insulin = 40;
    
    for(int i=1; i<window.localStorage.length; i++) {
      String key = window.localStorage.keys.elementAt(i);
      yia.Entry entry = new yia.Entry.fromMap(parse(window.localStorage[key]));
      min_bg = min(entry.blood_glucose, min_bg);
      max_bg = max(entry.blood_glucose, max_bg);
    }
    
    max_bg = (1.1*max_bg).toInt();
    min_bg = (0.9*min_bg).toInt();
    
    //In units of em
    num chart_hgt = 20;
    num bg_chart_hgt = (3/4)*chart_hgt;
    num ins_chart_hgt = (1/4)*chart_hgt;
    num x_width = 5;
    num y_bg_chart = bg_chart_hgt / max_bg;
    num y_ins_chart = ins_chart_hgt / max_insulin;
    num y0_bg_chart = bg_chart_hgt;
    num y0_ins_chart = chart_hgt;
    
    /*  Couldn't get this to work:
    DivElement divAxis = new DivElement();
    divAxis.style
    ..float = "left"
    ..borderRight = "1px solid black"
    ..position = "fixed"
    ..height = "25em"
    ..top = "37em"
    ..width = "1em";
    
    
    SpanElement bg_label = new SpanElement();
    bg_label
    ..text = "Blood Glucose (mg/dL)";
    bg_label.style
    ..position = "fixed"
    ..left = "3em"
    ..fontWeight = "bold"
    ..textDecoration = "underline";
    
    divAxis.children.add(bg_label);
    
    SpanElement ins_label = new SpanElement();
    ins_label
    ..text = "Insulin Infusion (Units/Hr)";
    ins_label.style
    ..position = "fixed"
    ..left = "3em"
    ..top = "54em"
    //..width = "10em"
    ..fontWeight = "bold"
    ..textDecoration = "underline";
    divAxis.children.add(ins_label);
    
    chartdiv.children.add(divAxis);
    */
    SvgSvgElement svgRoot = new SvgSvgElement();
    DivElement div = new DivElement();
    div.children.add(svgRoot);
    div.style.float = "right";
    chartdiv.children.add(div);
    
    chartdiv.style.height = "${chart_hgt}em";
    
    
    chartdiv.style.overflow = "scroll";
    div.style.width = "${window_width}px";
    
    LineElement sep = new LineElement();
    sep.attributes["stroke"] = "black";
    sep.y1.baseVal.valueAsString = "${y0_bg_chart}em";
    sep.y2.baseVal.valueAsString = sep.y1.baseVal.valueAsString;
    sep.x1.baseVal.valueAsString = "1em";
    sep.x2.baseVal.valueAsString = div.style.width;
    svgRoot.children.add(sep);
    
    LineElement min_bg_line = new LineElement();
    min_bg_line.attributes["stroke"] = "red";
    min_bg_line.attributes["stroke-dasharray"] = "5, 5";
    min_bg_line.y1.baseVal.valueAsString = "${y0_bg_chart-(alg.GOAL_MIN*y_bg_chart)}em";
    min_bg_line.y2.baseVal.valueAsString = min_bg_line.y1.baseVal.valueAsString;
    min_bg_line.x1.baseVal.valueAsString = "1em";
    min_bg_line.x2.baseVal.valueAsString = div.style.width;
    svgRoot.children.add(min_bg_line);

    LineElement max_bg_line = new LineElement();
    max_bg_line.attributes["stroke"] = "blue";
    max_bg_line.attributes["stroke-dasharray"] = "5, 5";
    max_bg_line.y1.baseVal.valueAsString = "${y0_bg_chart-(alg.GOAL_MAX*y_bg_chart)}em";
    max_bg_line.y2.baseVal.valueAsString = max_bg_line.y1.baseVal.valueAsString;
    max_bg_line.x1.baseVal.valueAsString = "1em";
    max_bg_line.x2.baseVal.valueAsString = div.style.width;
    svgRoot.children.add(max_bg_line);
    
    TextElement goal_text = new TextElement();
    goal_text.attributes
    ..["style"] = "fill:green;"
    ..["x"] = "${min_bg_line.x1.baseVal.value+5}"
    ..["y"] = "${((max_bg_line.y1.baseVal.value + min_bg_line.y1.baseVal.value)/2)+5}";
    goal_text.text = "Goal: ${alg.GOAL_MIN} - ${alg.GOAL_MAX} mg/dL";
    svgRoot.children.add(goal_text);
    
    for(int i=1; i<window.localStorage.length; i++) {
      String key = window.localStorage.keys.elementAt(i);
      yia.Entry entry = new yia.Entry.fromMap(parse(window.localStorage[key]));
      
      CircleElement bg_point = new CircleElement();
      bg_point.attributes["fill"] = "black";
      
      bg_point.cx.baseVal.valueAsString = "${x_width*i}em";
      bg_point.cy.baseVal.valueAsString = "${y0_bg_chart - (y_bg_chart*entry.blood_glucose)}em";
      
      if(i > 1) {
        bg_line.x2.baseVal.valueAsString = bg_point.cx.baseVal.valueAsString;
        bg_line.y2.baseVal.valueAsString = bg_point.cy.baseVal.valueAsString;
        svgRoot.children.add(bg_line);
      }
      
      bg_line = new LineElement();
      bg_line.attributes["stroke"] = "black";
      bg_line.x1.baseVal.valueAsString = bg_point.cx.baseVal.valueAsString;
      bg_line.y1.baseVal.valueAsString = bg_point.cy.baseVal.valueAsString;
      
      bg_point.r.baseVal.valueAsString = "0.3em";
      bg_point.title = "${entry.blood_glucose} mg/dL";
      if (entry.comments != "") {
        bg_point.title = "${bg_point.title}, ${entry.comments}";
      }
      bg_point.id = "b$i";
      bg_point.on.mouseOver.add((e){
        CircleElement c = e.target;
        TextElement t = new TextElement();
        t.attributes["x"] = "${c.cx.baseVal.value + 3}";
        t.attributes["y"] = "${c.cy.baseVal.value - 3}";
        t.text = c.title;
        t.id = "${c.id}t";
        SvgSvgElement s = c.parent;
        s.children.add(t);
        
      });
      
      bg_point.on.mouseOut.add((e){
        CircleElement c = e.target;
        String id = "#${c.id}t";
        query(id)
        ..remove();
      });
      
      svgRoot.children.add(bg_point);
      
      CircleElement ins_point = new CircleElement();
      ins_point.attributes["fill"] = "black";
      ins_point.cx.baseVal.valueAsString = "${x_width*i}em";
      ins_point.cy.baseVal.valueAsString = "${y0_ins_chart - (y_ins_chart*entry.insulin_dose)}em";
      
      if(i > 1) {
        ins_line.x2.baseVal.valueAsString = ins_point.cx.baseVal.valueAsString;
        ins_line.y2.baseVal.valueAsString = ins_point.cy.baseVal.valueAsString;
        svgRoot.children.add(ins_line);
      }
      
      ins_line = new LineElement();
      ins_line.attributes["stroke"] = "black";
      ins_line.x1.baseVal.valueAsString = ins_point.cx.baseVal.valueAsString;
      ins_line.y1.baseVal.valueAsString = ins_point.cy.baseVal.valueAsString;
      
      ins_point.r.baseVal.valueAsString = "0.3em";
      ins_point.title = "${entry.insulin_dose} Units";
      ins_point.id = "in$i";
      svgRoot.children.add(ins_point);
      
      ins_point.on.mouseOver.add((e){
        CircleElement c = e.target;
        TextElement t = new TextElement();
        t.attributes["x"] = "${c.cx.baseVal.value + 3}";
        t.attributes["y"] = "${c.cy.baseVal.value - 3}";
        t.text = c.title;
        t.id = "${c.id}t";
        SvgSvgElement s = c.parent;
        s.children.add(t);
      });
      
      ins_point.on.mouseOut.add((e){
        CircleElement c = e.target;
        String id = "#${c.id}t";
        query(id)
        ..remove();
        
      });
    }
    
    
    
    chartdiv.scrollLeft = window.localStorage.length;
    
  }
  
  
}

void handleReset(Event e) {
  DivElement confirm = query("#yircc");
  confirm.innerHtml = "<span class='confirm'>Are you sure? </span>"
                      "<input type='radio' id='yirccy' name='yircc' value='Yes'></input>"
                      "<label for='yicccy'>Yes</label>"
                      "<input type='radio' id='yirccn' name='yircc' value='No'></input>"
                      "<label for='yicccn'>No</label>";
  Element yes = query("#yirccy");
  Element no = query("#yirccn");
  yes.on.click.add((e){
    confirm.innerHtml = "";
    window.localStorage.clear();
    refresh();
  });
  
  no.on.click.add((e){
    confirm.innerHtml = "";
  });
}


