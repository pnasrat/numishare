<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:numishare="https://github.com/ewg118/numishare" exclude-result-prefixes="#all"
	version="2.0">
	<!-- includes -->
	<xsl:include href="header.xsl"/>
	<xsl:include href="footer.xsl"/>
	<xsl:include href="functions.xsl"/>

	<xsl:param name="pipeline"/>
	<xsl:param name="department"/>
	<xsl:variable name="display_path">../</xsl:variable>
	<xsl:variable name="collection_type" select="/content//collection_type"/>

	<xsl:param name="q"/>
	<xsl:param name="lang"/>
	<xsl:variable name="tokenized_q" select="tokenize($q, ' AND ')"/>

	<xsl:template match="/">
		<html lang="en">
			<head>
				<title>
					<xsl:value-of select="//config/title"/>
					<xsl:text>: </xsl:text>
					<xsl:value-of select="numishare:normalizeLabel('header_maps', $lang)"/>
				</title>
				<link rel="shortcut icon" type="image/x-icon" href="{$display_path}images/favicon.png"/>
				<meta name="viewport" content="width=device-width, initial-scale=1"/>

				<!-- jquery -->
				<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js"/>				

				<!-- bootstrap -->
				<link rel="stylesheet" href="http://netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css"/>
				<script type="text/javascript" src="http://netdna.bootstrapcdn.com/bootstrap/3.1.1/js/bootstrap.min.js"/>
				<script type="text/javascript" src="{$display_path}javascript/bootstrap-multiselect.js"/>
				<link rel="stylesheet" href="{$display_path}bootstrap-multiselect.css" type="text/css"/>

				<!-- local theme and styling -->
				<link type="text/css" href="{$display_path}themes/{//config/theme/jquery_ui_theme}.css" rel="stylesheet"/>
				<link type="text/css" href="{$display_path}fullscreen.css" rel="stylesheet"/>

				<!-- display timemap for hoards, regular openlayers map for coin and coin type collections -->
				<xsl:choose>
					<xsl:when test="$collection_type='hoard'">
						<!-- timemap dependencies -->
						<script type="text/javascript" src="http://www.openlayers.org/api/OpenLayers.js"/>
						<script type="text/javascript" src="http://maps.google.com/maps/api/js?v=3.2&amp;sensor=false"/>
						<script type="text/javascript" src="{$display_path}javascript/mxn.js"/>
						<script type="text/javascript" src="{$display_path}javascript/timeline-2.3.0.js"/>
						<link type="text/css" href="{$display_path}timeline-2.3.0.css" rel="stylesheet"/>
						<script type="text/javascript" src="{$display_path}javascript/timemap_full.pack.js"/>
						<script type="text/javascript" src="{$display_path}javascript/param.js"/>
						<script type="text/javascript" src="{$display_path}javascript/loaders/kml.js"/>
						<script type="text/javascript" src="{$display_path}javascript/map_fullscreen_functions.js"/>
						<script type="text/javascript" src="{$display_path}javascript/map_functions.js"/>
						<script type="text/javascript" src="{$display_path}javascript/facet_functions.js"/>
					</xsl:when>
					<xsl:otherwise>
						<!-- Add fancyBox -->
						<link rel="stylesheet" href="{$display_path}jquery.fancybox.css?v=2.1.5" type="text/css" media="screen"/>
						<script type="text/javascript" src="{$display_path}javascript/jquery.fancybox.pack.js?v=2.1.5"/>
						<!-- maps-->
						<script type="text/javascript" src="http://www.openlayers.org/api/OpenLayers.js"/>
						<script type="text/javascript" src="http://maps.google.com/maps/api/js?v=3.2&amp;sensor=false"/>
						<script type="text/javascript" src="{$display_path}javascript/map_fullscreen_functions.js"/>
						<script type="text/javascript" src="{$display_path}javascript/map_functions.js"/>
						<script type="text/javascript" src="{$display_path}javascript/facet_functions.js"/>
					</xsl:otherwise>
				</xsl:choose>

				<!-- Google Analytics -->
				<xsl:if test="string(/config/google_analytics)">
					<script type="text/javascript">
						<xsl:value-of select="//config/google_analytics"/>
					</script>
				</xsl:if>
			</head>
			<body>
				<xsl:call-template name="maps"/>
			</body>
		</html>
	</xsl:template>

	<xsl:template name="maps">
		<div id="backgroundPopup"/>
		<div class="container-fluid">

			<xsl:choose>
				<xsl:when test="//result[@name='response']/@numFound &gt; 0">
					<div id="legend">
						<h2>
							<xsl:value-of select="numishare:regularize_node('legend', $lang)"/>
							<small>
								<a href="#map_filters" id="show_filters">
									<xsl:value-of select="numishare:normalizeLabel('results_refine-results', $lang)"/>
								</a>
							</small>
						</h2>

						<div class="legend">
							<table>
								<tbody>
									<tr>
										<td style="background-color:#0000ff;border:2px solid #000072;width:50px;"/>
										<td style="width:100px">
											<xsl:value-of select="numishare:regularize_node('mint', $lang)"/>
										</td>
										<td style="background-color:#00a000;border:2px solid #006100;width:50px;"/>
										<td style="width:100px">
											<xsl:value-of select="numishare:regularize_node('findspot', $lang)"/>
										</td>
									</tr>
								</tbody>
							</table>
						</div>
						<small>
							<a href="{$display_path}maps"><span class="glyphicon glyphicon-arrow-left"/>Return</a>
						</small>
					</div>
					<div style="display:none">
						<div id="map_filters">
							<h2>
								<xsl:value-of select="numishare:normalizeLabel('results_refine-results', $lang)"/>
							</h2>
							<xsl:apply-templates select="//lst[@name='facet_fields']"/>
							<input type="button" class="btn btn-default" id="close" value="Close"/>
						</div>
					</div>
					<!-- display timemap divs for hoard records or regular map + ajax results div for non-hoard collections -->
					<xsl:choose>
						<xsl:when test="$collection_type='hoard'">
							<div class="row">
								<div class="col-md-12">
									<div id="timemap">
										<div id="mapcontainer">
											<div id="map"/>
										</div>
										<div id="timelinecontainer">
											<div id="timeline"/>
										</div>
									</div>
								</div>
							</div>
						</xsl:when>
						<xsl:otherwise>
							<div class="row">
								<div class="col-md-12">
									<div id="mapcontainer"/>
								</div>
							</div>
							<div class="row">
								<div class="col-md-12">
									<a name="results"/>
									<div id="results"/>
								</div>
							</div>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<div class="row">
						<div class="col-md-12">
							<h1> No results found.</h1>
						</div>
					</div>
				</xsl:otherwise>
			</xsl:choose>
			<div style="display:none">
				<input id="facet_form_query" name="q" value="*:*" type="hidden"/>
				<xsl:if test="string($lang)">
					<input type="hidden" name="lang" value="{$lang}"/>
				</xsl:if>
				<span id="collection_type">
					<xsl:value-of select="$collection_type"/>
				</span>
				<span id="path">
					<xsl:value-of select="$display_path"/>
				</span>
				<span id="pipeline">
					<xsl:value-of select="$pipeline"/>
				</span>
				<span id="section">maps</span>
				<span id="baselayers">
					<xsl:value-of select="string-join(//config/baselayers/layer[@enabled=true()], ',')"/>
				</span>
			</div>
		</div>
	</xsl:template>

	<xsl:template match="lst[@name='facet_fields']">
		<xsl:for-each select="lst[not(@name='mint_geo') and number(int[@name='numFacetTerms']) &gt; 0 and not(@name='mint_facet')]|lst[@name='mint_facet' and $collection_type='hoard']">

			<xsl:variable name="val" select="@name"/>
			<xsl:variable name="new_query">
				<xsl:for-each select="$tokenized_q[not(contains(., $val))]">
					<xsl:value-of select="."/>
					<xsl:if test="position() != last()">
						<xsl:text> AND </xsl:text>
					</xsl:if>
				</xsl:for-each>
			</xsl:variable>

			<xsl:variable name="title">
				<xsl:value-of select="numishare:normalize_fields(@name, $lang)"/>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="contains(@name, '_hier')">
					<!--<xsl:variable name="title" select="numishare:regularize_node(substring-before(@name, '_'), $lang)"/>

						<button class="ui-multiselect ui-widget ui-state-default ui-corner-all hierarchical-facet" type="button" title="{$title}" aria-haspopup="true" style="width: 180px;"
							id="{@name}_link" label="{$q}">
							<span class="ui-icon ui-icon-triangle-2-n-s"/>
							<span>
								<xsl:value-of select="$title"/>
							</span>
						</button>

						<div class="ui-multiselect-menu ui-widget ui-widget-content ui-corner-all hierarchical-div" id="{substring-before(@name, '_hier')}-container" style="width: 180px;">
							<div class="ui-widget-header ui-corner-all ui-multiselect-header ui-helper-clearfix ui-multiselect-hasfilter">
								<ul class="ui-helper-reset">
									<li class="ui-multiselect-close">
										<a class="ui-multiselect-close hier-close" href="#"> close<span class="ui-icon ui-icon-circle-close"/>
										</a>
									</li>
								</ul>
							</div>
							<ul class="{substring-before(@name, '_hier')}-multiselect-checkboxes ui-helper-reset hierarchical-list" id="{@name}-list" style="height: 175px;" title="{$title}"/>
						</div>-->
				</xsl:when>
				<xsl:when test="@name='century_num'">
					<!--<button class="ui-multiselect ui-widget ui-state-default ui-corner-all" type="button" title="{numishare:regularize_node('date', $lang)}" aria-haspopup="true"
							style="width: 180px;" id="{@name}_link" label="{$q}">
							<span class="ui-icon ui-icon-triangle-2-n-s"/>
							<span>
								<xsl:value-of select="numishare:regularize_node('date', $lang)"/>
							</span>
						</button>
						<div class="ui-multiselect-menu ui-widget ui-widget-content ui-corner-all date-div" style="width: 180px;">
							<div class="ui-widget-header ui-corner-all ui-multiselect-header ui-helper-clearfix ui-multiselect-hasfilter">
								<ul class="ui-helper-reset">
									<li class="ui-multiselect-close">
										<a class="ui-multiselect-close century-close" href="#"> close<span class="ui-icon ui-icon-circle-close"/>
										</a>
									</li>
								</ul>
							</div>
							<ul class="century-multiselect-checkboxes ui-helper-reset" id="{@name}-list" style="height: 175px;"/>
						</div>-->
				</xsl:when>
				<xsl:otherwise>
					<xsl:variable name="count" select="number(int[@name='numFacetTerms'])"/>
					<xsl:variable name="mincount" as="xs:integer">
						<xsl:choose>
							<xsl:when test="$count &gt; 500">
								<xsl:value-of select="ceiling($count div 500)"/>
							</xsl:when>
							<xsl:otherwise>1</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:variable name="select_new_query">
						<xsl:choose>
							<xsl:when test="string($new_query)">
								<xsl:value-of select="$new_query"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:text>*:*</xsl:text>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<div class="col-md-4">
						<select id="{@name}-select" multiple="multiple" class="multiselect" title="{$title}" q="{$q}" mincount="{$mincount}"
							new_query="{if (contains($q, @name)) then $select_new_query else ''}">
							<xsl:if test="$pipeline='maps'">
								<xsl:attribute name="style">width:180px</xsl:attribute>
							</xsl:if>
						</select>
					</div>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>
</xsl:stylesheet>
