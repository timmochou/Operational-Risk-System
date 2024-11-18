--KRI
function displayDatasetValues() {
  var r = FR.remoteEvaluate("value('CHT_KRI', 2, 1, '" + this.category + "')") || 0;
  var y = FR.remoteEvaluate("value('CHT_KRI', 3, 1, '" + this.category + "')") || 0;
  var s = FR.remoteEvaluate("value('CHT_KRI', 4, 1, '" + this.category + "')") || 0;
  s = Number(s).toLocaleString();
  // 使用模板字符串进行字符串拼接，添加颜色图标
  return `RANGE: ${this.category}<br>
  		  <span style="color: rgb(246, 172, 50); display: inline-block; width: 5px; height: 5px; border-radius: 50%; background-color: #f9c921;"></span> 黃燈: ${y.toString()} 件<br>
        <span style="color: #ff0000; display: inline-block; width: 5px; height: 5px; border-radius: 50%; background-color: red;"></span> 紅燈: ${r.toString()} 件 <br>         
        <span style="color: black; display: inline-block; width: 5px; height: 5px; border-radius: 50%; background-color: black;"></span> SCORE: ${s} 分`;
}


--LDC
function displayDatasetValues() {
  var r = FR.remoteEvaluate("value('CHT_LDC_LINE_SCORE', 2, 1, '" + this.category + "')") || 0;
  var y = FR.remoteEvaluate("value('CHT_LDC_LINE_SCORE', 3, 1, '" + this.category + "')") || 0;
  var g = FR.remoteEvaluate("value('CHT_LDC_SCORE', 3, 1, '" + this.category + "')") || 0;
  var b = FR.remoteEvaluate("value('CHT_LDC_SCORE', 2, 1, '" + this.category + "')") || 0;
  var s = FR.remoteEvaluate("value('CHT_LDC_LINE_SCORE', 4, 1, '" + this.category + "')") || 0;

  // Convert g and b to numbers and format them with commas
  g = Number(g).toLocaleString('zh-TW', { maximumFractionDigits: 0 });
  b = Number(b).toLocaleString('zh-TW', { maximumFractionDigits: 0 });
  s = Number(s).toLocaleString('zh-TW', { maximumFractionDigits: 0 });
  // 使用模板字符串进行字符串拼接，添加颜色图标
  return `RANGE: ${this.category}<br>       
          <span style="color: #ff0000; display: inline-block; width: 5px; height: 5px; border-radius: 50%; background-color: #00b88a;"></span> 損失金額: ${b}<br>       
          <span style="color: #ff0000; display: inline-block; width: 5px; height: 5px; border-radius: 50%; background-color: #358fe3;"></span> 預估損失金額: ${g}<br>       
          <span style="color: #ff0000; display: inline-block; width: 5px; height: 5px; border-radius: 50%; background-color: red;"></span> 重大偶發: ${r.toString()} 件<br> 
          <span style="color: rgb(246, 172, 50); display: inline-block; width: 5px; height: 5px; border-radius: 50%; background-color: #f9c921;"></span> 重要風險事件: ${y.toString()} 件<br>                   
          <span style="color: black; display: inline-block; width: 5px; height: 5px; border-radius: 50%; background-color: black;"></span> SCORE: ${s} 分 <br> `;
}

CHT_LOSS 稽核缺失統計
function displayDatasetValues() {
  var ex = FR.remoteEvaluate("value('CHT_LOSS', 2, 1, '" + this.category + "')") || 0;
  var h = FR.remoteEvaluate("value('CHT_LOSS', 3, 1, '" + this.category + "')") || 0;
  var mh = FR.remoteEvaluate("value('CHT_LOSS', 4, 1, '" + this.category + "')") || 0;
  var m = FR.remoteEvaluate("value('CHT_LOSS', 5, 1, '" + this.category + "')") || 0;
  var l = FR.remoteEvaluate("value('CHT_LOSS', 6, 1, '" + this.category + "')") || 0;
  var s = FR.remoteEvaluate("value('CHT_LOSS', 7, 1, '" + this.category + "')") || 0;
  // convert s to forrmat
  s = Number(s).toLocaleString();


  // 使用模板字符串进行字符串拼接，添加颜色图标
  return `RANGE: ${this.category}<br>       
         <span style="color: green; display: inline-block; width: 5px; height: 5px; border-radius: 50%; background-color: green;"></span> 低風險: ${l.toString()} 件<br>
         <span style="color: yellow; display: inline-block; width: 5px; height: 5px; border-radius: 50%; background-color: yellow;"></span> 中風險: ${m.toString()} 件<br>
         <span style="color: orange; display: inline-block; width: 5px; height: 5px; border-radius: 50%; background-color: orange;"></span> 中高風險: ${mh.toString()} 件<br>
         <span style="color: red; display: inline-block; width: 5px; height: 5px; border-radius: 50%; background-color: red;"></span> 高風險: ${h.toString()} 件<br>
         <span style="color: black; display: inline-block; width: 5px; height: 5px; border-radius: 50%; background-color: black;"></span>  SCORE: ${s} 分`;           
      
}



--CSA
function displayDatasetValues() {
  var r = FR.remoteEvaluate("value('CHT_CSA', 2, 1, '" + this.category + "')") || 0;
  var y = FR.remoteEvaluate("value('CHT_CSA', 3, 1, '" + this.category + "')") || 0;
  var s = FR.remoteEvaluate("value('CHT_CSA', 4, 1, '" + this.category + "')") || 0;
  s = Number(s).toLocaleString();
  // 使用模板字符串进行字符串拼接，添加颜色图标
  return `RANGE: ${this.category}<br>
  		    <span style="color: rgb(246, 172, 50); display: inline-block; width: 5px; height: 5px; border-radius: 50%; background-color: #f9c921;"></span> 黃燈: ${y.toString()} 件<br>
          <span style="color: #ff0000; display: inline-block; width: 5px; height: 5px; border-radius: 50%; background-color: red;"></span> 紅燈: ${r.toString()} 件<br>         
          <span style="color: black; display: inline-block; width: 5px; height: 5px; border-radius: 50 %; background-color: black;"></span> SCORE: ${s} 分`;
}


CHT_CUST 客速事件統計
function displayDatasetValues() {
  var r = FR.remoteEvaluate("value('CHT_CUST', 2, 1, '" + this.category + "')") || 0;
  var y = FR.remoteEvaluate("value('CHT_CUST', 3, 1, '" + this.category + "')") || 0;
  var s = FR.remoteEvaluate("value('CHT_CUST', 5, 1, '" + this.category + "')") || 0;
  s = Number(s).toLocaleString();
  // 使用模板字符串进行字符串拼接，添加颜色图标
  return `RANGE: ${this.category}<br>
  		  <span style="color: rgb(246, 172, 50); display: inline-block; width: 5px; height: 5px; border-radius: 50%; background-color: f9c921;"></span> 本行疏失:${y.toString()} 件<br>
        <span style="color: #ff0000; display: inline-block; width: 5px; height: 5px; border-radius: 50%; background-color: red;"></span> 違反公平待客: ${r.toString()} 件<br>
        <span style="color: black; display: inline-block; width: 5px; height: 5px; border-radius: 50%; background-color: black;"></span>  SCORE: ${s} 分`;
}





#f9c921
#358fe3
#9900cb
#ff0000
#ff9933
#ffcc02
#00b88a

