<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl"/>
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl"/>

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />
			
			<!--
			TEMPLATE
			Match:
			-->
			<x:template match="/">
				<x:apply-templates select="*"/>
				<x:apply-templates select="/output/root[position()=last()]" mode="last"/>
				<br/>
			</x:template>
			<lxslt:component prefix="my-ext" functions="formatJson retrievePrizeTable">
				<lxslt:script lang="javascript">
					<![CDATA[
					
function formatJson(jsonContext, translations, prizeValues, prizeNamesDesc) {
	var scenario = getScenario(jsonContext);
	var tranMap = parseTranslations(translations);
	var prizeMap = parsePrizes(prizeNamesDesc, prizeValues);
	return doFormatJson(scenario, tranMap, prizeMap);

}

function ScenarioConvertor(scenario) {
	this.scenario = scenario;
	this.winType = ['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P'];
	this.winTypeLen = [9,9,9,9,7,7,7,7,5,5,5,5,4,4,4,4];
	this.winTypeIndex = 0;
	this.setUp();
	this.getWinMap();
}

ScenarioConvertor.prototype.setUp = function(){
	this.winMap = {};
	for(var i=0;i<this.winType.length;i++){
		this.winMap[this.winType[i]] = {};
		this.winMap[this.winType[i]]['winPosition'] = [];
		this.winMap[this.winType[i]]['winPosition'].length = this.winTypeLen[i];
		this.winMap[this.winType[i]]['currentLength'] = 0;
	}
}

ScenarioConvertor.prototype.getWinMap = function(){
	var convertScenario = this.scenario.split(',');
	
	for(var i=0,len=convertScenario.length; i<len; i++){
		var item = convertScenario[i];
		var description = item.substring(0,1);
		var index = item.substring(1)-1;

		this.winMap[description]['winPosition'][index] = item;
		this.winMap[description]['currentLength']++;
	}
}

function doFormatJson(scenario, tranMap, prizeMap) {
	
	var result = new ScenarioConvertor(scenario);
	var r = [];
	r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
	r.push('<tr>');
	r.push('<td class="tablehead" width="100%" colspan="11">');
	r.push(tranMap.outcomeLabel);
	r.push('</td>');
	r.push('</tr>');
	
	r.push('<tr>');
	r.push('<td class="tablehead" width="100%">');
	r.push(tranMap.pattern);
	r.push('</td>');
	r.push('<td class="tablehead" width="100%" colspan="9">');
	r.push(tranMap.drawingNumbers);
	r.push('</td>');
	r.push('<td class="tablehead" width="100%">');
	r.push(tranMap.prizes);
	r.push('</td>');
	r.push('</tr>');
	
	for(var key in result.winMap){
		var winPosition = result.winMap[key]['winPosition'];
		r.push('<tr>');
		r.push('<td class="tablebody" width="100%">');
		r.push(result.winType[result.winTypeIndex]);
		r.push('</td>');
		for(var i=0;i<winPosition.length;i++){
			r.push('<td class="tablebody" width="100%">');
			if(winPosition[i]){
				r.push(winPosition[i]);	
			}else{
				r.push("&nbsp;");		
			}
			r.push('</td>');
		}
		if(winPosition.length < 9){
			for(i=winPosition.length;i<9;i++){
				r.push('<td width="100%">');
				r.push("&nbsp;");	
				r.push('</td>');
			}
		}
		
		r.push('<td class="tablebody" width="100%">');
		if(result.winMap[key]['currentLength'] >= winPosition.length){
			r.push(prizeMap[key]);	
		}else{
			r.push("&nbsp;");	
		}
		r.push('</td>');
		r.push('</tr>');
		result.winTypeIndex++;
	}
	
	r.push('</table>');

	r.push('<div width="100%" class="blankStyle">&nbsp;');
	r.push('</div>');
	
	return r.join('');
}
function getScenario(jsonContext) {
	var jsObj = JSON.parse(jsonContext);
	var scenario = jsObj.scenario;
	scenario = scenario.replace(/\0/g, '');
	return scenario;
}
function parsePrizes(prizeNamesDesc, prizeValues) {
	var prizeNames = (prizeNamesDesc.substring(1)).split(',');
	var convertedPrizeValues = (prizeValues.substring(1)).split('|');
	var map = [];
	for (var idx = 0; idx < prizeNames.length; idx++) {
		map[prizeNames[idx]] = convertedPrizeValues[idx];
	}
	return map;
}
function parseTranslations(translationNodeSet) {
	var map = [];
	var list = translationNodeSet.item(0).getChildNodes();
	for (var idx = 1; idx < list.getLength(); idx++) {
		var childNode = list.item(idx);
		if (childNode.name == "phrase") {
			map[childNode.getAttribute("key")] = childNode.getAttribute("value");
		}
	}
	return map;
}
					]]>
				</lxslt:script>
			</lxslt:component>
		
			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit"/>
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount"/>
								<x:with-param name="code" select="/output/denom/currencycode"/>
								<x:with-param name="locale" select="//translation/@language"/>
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit"/>
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode"/>
								<x:with-param name="locale" select="//translation/@language"/>
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>
		
			<!--
			TEMPLATE
			Match:		digested/game
			-->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="History.Detail" />
				</x:if>
				<x:if test="OutcomeDetail/Stage = 'Wager' and OutcomeDetail/NextStage = 'Wager'">
					<x:call-template name="History.Detail" />
				</x:if>
			</x:template>
		
			<!--
			TEMPLATE
			Name:		Wager.Detail (base game)
			-->
			<x:template name="History.Detail">
				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value"/>
							<x:value-of select="': '"/>
							<x:value-of select="OutcomeDetail/RngTxnId"/>
						</td>
					</tr>
				</table>
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />
				<x:variable name="convertedPrizeValues">
					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>
				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>
				
			<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			
			</x:template>
			
			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>
			
			<x:template match="text()"/>
			
		</x:stylesheet>
	</xsl:template>
	
	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
		    <clickcount>
		        <x:value-of select="."/>
		    </clickcount>
		</x:template>
		<x:template match="*|@*|text()">
		    <x:apply-templates/>
		</x:template>
	</xsl:template>
	
</xsl:stylesheet>
