<%@page import="com.sogou.qadev.service.cynthia.util.ConfigUtil"%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
	<meta name="Description" content="Cynthia项目缺陷管理系统，拥有表单流程化设计，可视化拖动布局等功能，提供项目管理，缺陷管理，，统计，查询等服务，是您项目上的好帮手！">
	<meta name="Keywords" content="Cynthia,BUG管理,项目管理 ,缺陷管理,任务管理,BUG,缺陷,开源">
	<link href="../lib/bootstrap2/css/bootstrap.min.css" rel="stylesheet" type="text/css">
	<link href="../lib/g_bootstrap/css/google-bootstrap.css" rel="stylesheet" type="text/css">
	<link href="../css/top.css" rel="stylesheet" type="text/css">
	<link href='../lib/select2/select2.css' rel="stylesheet" style="text/css">
	<script type="text/javascript" src="../lib/jquery/jquery-1.9.3.min.js"></script>
	<script type="text/javascript" src='../lib/bootstrap2/js/bootstrap.cynthia.min.js'></script>
	<script type="text/javascript" src="../lib/highchart/highcharts.js"></script>
	<script type="text/javascript" src="../lib/highchart/exporting.js"></script>
	<script type="text/javascript" src="../lib/highchart/export-csv.js"></script>
	<script type="text/javascript" src="../lib/highchart/no-data-to-display.js"></script>
	<script type="text/javascript" src="../lib/highchart/draggable-legend.js"></script>
	<script type="text/javascript" src="../js/util.js"></script>
	<script type="text/javascript" src="../lib/select2/select2.js"></script>
	<script type="text/javascript" src="../js/cynthiaHighChart.js"></script>
	<script language="javascript" defer="defer" src="../lib/My97DatePicker/WdatePicker.js"></script>

	<script type="text/javascript">
		
		var chart = null;
		var origChartWidth = 800;
        var origChartHeight = 400;
        var chartWidth = origChartWidth;
        var chartHeight = origChartHeight;
        var fieldNameIdMap = new Map();
		function initTaskTemplates()
		{
		
			$.ajax({
				url : '../template/getUserTemplate.do',
				dataType : 'json',
				success : onCompleteInitTaskTemplates,
				error:function(){}
			});
		}

		function onCompleteInitTaskTemplates(data)
		{
			$("#taskTemplate").append("<option value=''>--请选择--</option>");
			for(var key in data)
				$("#taskTemplate").append("<option value='"+data[key].first+"'>"+data[key].second+"</option>");
			enableSelectSearch();
		}

		function initTemplateFields(){
			$("#statisticField").empty();
			$("#leftStatisticField").empty();
			$("#rightStatisticField").empty();
			
			var params = "templateId=" + $("#taskTemplate").val();
			$.ajax({
				url : '../bugstatistic/getStatisticField.do',
				data : params,
				type:'POST',
				async: false,
				success : function(data){
					$("#statisticField").append("<option value=''>--请选择--</option>");
					data = eval(data);
					for(var i=0; i<data.length; i++)
					{
						$("#statisticField").append("<option value='"+data[i].fieldId+"'>" + data[i].fieldName +"</option>");
					}
				},
				error : function(data){
				}
			});
		}
		
		function initStatisticField()
		{
			var fieldId = $("#statisticField").val();
			if(fieldId == "")
			{
				alert("请选择字段");
				return;
			}
			
			$("#leftStatisticField").empty();
			$("#rightStatisticField").empty();
			
			var params = "templateId=" + $("#taskTemplate").val() + "&fieldId=" + fieldId;
			$.ajax({
				url : '../bugstatistic/getFieldOption.do',
				data : params,
				type:'POST',
				dataType:'json',
				async: false,
				success : function(data){
					fieldNameIdMap = new Map();
					for(var i=0; i< data.length; i++)
					{
						fieldNameIdMap.put(data[i].fieldName,data[i].fieldId);
						$("#leftStatisticField").append("<option value='"+data[i].fieldId+"'>" + data[i].fieldName +"</option>");
					}
				},
				error : function(data){
				}
			});
		}
		

		function addOption()
		{
			$.each($("#leftStatisticField").find("option:selected"),function(i,node){
				$("#rightStatisticField").append("<option value='" + $(node).val() +"'>"+ $(node).text() +"</option>");
				$(node).remove();
			});
		}
		
		function removeOption()
		{
			$.each($("#rightStatisticField").find("option:selected"),function(i,node){
				$("#leftStatisticField").append("<option value='" + $(node).val() +"'>"+ $(node).text() +"</option>");
				$(node).remove();
			});
		}
		
		function executeBugStatistic()
		{
			$("#show").show();
			$("#tableData").show();
			var templateId = $("#taskTemplate").val();
			var fieldId  = $("#statisticField").val();
			var startTime = $("#startTime").val();
			var endTime = $("#endTime").val();
			
			var statisticOption = new Array();
			
			$.each($("#rightStatisticField").find("option"), function(i,node){
				statisticOption.push($(node).val());
			});
			
			
			var type = $("#type").val();

			if(templateId == "" || templateId == null){
				alert("请选择表单");
				return;						
			}
			
			if(fieldId == ""){
				alert("请选择统计字段");
				return;						
			}
			
			if(statisticOption.length == 0){
				alert("请选择统计选项");
				return;		
			}
			
			initData(templateId,fieldId,startTime,endTime,statisticOption,type);
		}
		
		function initTableData(data)
		{
			var url = "../search/list.html?createTime="+$("#startTime").val()+"&createTime="+$("#endTime").val()+"&templateId=" + $("#taskTemplate").val() + "&" + $("#statisticField").val() + "=";
			$("#tableDataBody").empty();
			var gridHtml = "";
			gridHtml += "<tr>";
			var dataArray = data.datas || [];
			for(var name in dataArray){
				gridHtml += "<tr>";
				gridHtml += "<td>" + name + "</td>";
				gridHtml += "<td><a href=\"" +url + fieldNameIdMap.get(name)+ "\" target=\"_blank\">" + dataArray[name] + "</a></td>";
				gridHtml += "</tr>";
			}
			$("#tableDataBody").html(gridHtml);			
		}
		
		function initData(templateId,fieldId,startTime,endTime,statisticOption,type)
		{
			 chart = initChart('container');  //初始化chart

			 $.ajax({
				 url: '../bugstatistic/getBugData.do',
				 async:false,
				 dataType:'json',
				 data: {'templateId' : templateId,'fieldId' : fieldId , 'startTime' :startTime, 'endTime':endTime, 'statisticOption':statisticOption},				 type:'POST',
				 success: function(data){
					initTableData(data);
					setChartData(chart,data.name,data.datas,type);  //设置chart数据
				 }
			 });
		 }
		 
		function executeLargeChart()
		{
			chart.setSize(chartWidth *= 1.2, chartHeight *= 1.2);
		}
		
		function executeSmallChart()
		{
			chart.setSize(chartWidth *= 0.8, chartHeight *= 0.8);
		}
		
		function executeSame()
		{
			chartWidth = origChartWidth;
			chartHeight = origChartHeight;
			chart.setSize(origChartWidth, origChartHeight);
		}
	 
	</script>
	<title>数据统计插件</title>
</head>
<body onload="initTaskTemplates()">
	<div class="container-fluid">
	<div id ="header-nav">
	</div>
	<div id="main" style="margin-top:50px;">
		<div id="shortmenu">
			<ul>
			</ul>
		</div>
		<div id="content">
				<table class="table table-striped table-bordered table-hover table-condensed" cellpadding="0" cellspacing="0">
    					<tr>
     						<th><label>选择表单</label></th>
        					<td colspan="3">
								<select id="taskTemplate" style="width:220px;" onchange="initTemplateFields()"></select>	
        					</td>
   		 				</tr>
   		 				
						<tr>
     						<th><label>开始时间</label></th>
        					<td>
     							<input size="25" class="Wdate" type="text"  id="startTime"  onfocus="WdatePicker({dateFmt:'yyyy年MM月dd日HH时mm分'})" />
        					</td>
   		 				</tr>
						
						<tr>
     						<th><label>结束时间</label></th>
        					<td>
     							<input size="25" class="Wdate" type="text"  id="endTime"  onfocus="WdatePicker({dateFmt:'yyyy年MM月dd日HH时mm分'})" />
        					</td>
   		 				</tr>
						
   		 				<tr>
     						<th><label>选择统计字段</label></th>
        					<td colspan="3">
								<select id="statisticField" style="width:220px;" onchange="initStatisticField();"></select>	
        					</td>
   		 				</tr>
   		 				<tr>
   		 					<th><label>选择统计选项</label></th>
        					<td>
								<table cellpadding="0" cellspacing="0">
									<tr>
										<td style="border-left:0px;"><select id="leftStatisticField" class="noSearch" multiple="multiple" style="height:100px;"></select>	</td>
										<td style="border-left:0px;">
											<table style="text-align:center">
												<tr>
													<td style="border-left:0px;" align="center" class="tdNoBottom"><input type="button" class="btn btn-primary" value="添加" onclick="addOption()"></td>
												</tr>
												<tr>
													<td style="border-left:0px;" align="center" class="tdNoBottom"><input type="button" class="btn" value="移出" onclick="removeOption()"></td>
												</tr>
											</table>
										</td>
										<td style="border-left:0px;"><select id="rightStatisticField" class="noSearch" multiple="multiple" style="height:100px;"></select>	</td>
									</tr>
								</table>
							</td>
   		 				</tr>
   		 				
   		 				<tr>
   		 					<th><label>图表类型</label></th>
        					<td>
								<select id="type" style="width:150px;">
								<option value="line" selected>线型</option>
								<option value="area">面积</option>
								<option value="bar">柱状图</option>
								<option value="pie">饼图</option>
								</select>	
        					</td>
   		 				</tr>
   		 				
   		 				<tr>
   		 					<td colspan="3" align="center" valign="middle">
   		 						<input type="button" class="btn btn-danger" onclick="executeBugStatistic()" value="查看结果" />
   		 					</td>
   		 				</tr>
				</table>
			</div>
	</div>
	<div>
		<div id="show" style="display:none;width:60%; float:left;">
			<input type="button" class="btn" onclick="executeLargeChart()" value="变大" />
			<input type="button" class="btn" onclick="executeSmallChart()" value="变小" />
			<input type="button" class="btn" onclick="executeSame()" value="原图" />
			<!--highchart显示-->
			<div id="container" style="width:800px; height:400px;">
			</div>
		</div>
		
		<div id="tableData" style="display:none;float:right;width:20%;margin-right:50px;">
			<table class="table table-striped table-bordered table-hover table-condensed" cellpadding="0" cellspacing="0">
				<thead><tr style="background-color: rgb(233, 184, 184);"><th>统计名</th><th>数量</th></tr></thead>
		    	<tbody id="tableDataBody">
		    	</tbody>
			</table>
		</div>
	</div>
	</div>
</body>
</html>