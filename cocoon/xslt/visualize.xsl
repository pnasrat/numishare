<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:cinclude="http://apache.org/cocoon/include/1.0"
	xmlns:numishare="https://github.com/ewg118/numishare" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0">
	<xsl:output method="xml" encoding="UTF-8"/>
	<xsl:include href="header.xsl"/>
	<xsl:include href="footer.xsl"/>
	<xsl:include href="templates.xsl"/>
	<xsl:include href="functions.xsl"/>

	<xsl:param name="pipeline"/>
	<xsl:param name="display_path"/>
	<xsl:param name="lang"/>

	<xsl:param name="q"/>

	<!-- quantitative analysis parameters -->
	<!-- typological comparison -->
	<xsl:param name="category"/>
	<xsl:param name="compare"/>
	<xsl:param name="custom"/>
	<xsl:param name="options"/>
	<xsl:param name="type"/>

	<!-- measurement comparison -->
	<xsl:param name="measurement"/>
	<xsl:param name="numericType"/>
	<xsl:param name="interval"/>
	<xsl:param name="fromDate"/>
	<xsl:param name="toDate"/>
	<xsl:param name="sparqlQuery"/>
	<xsl:variable name="tokenized_sparqlQuery" as="item()*">
		<xsl:sequence select="tokenize($sparqlQuery, '\|')"/>
	</xsl:variable>
	<xsl:variable name="duration" select="number($toDate) - number($fromDate)"/>

	<!-- both -->
	<xsl:param name="chartType"/>

	<!-- variables -->
	<xsl:variable name="category_normalized">
		<xsl:value-of select="numishare:normalize_fields($category, $lang)"/>
	</xsl:variable>
	<xsl:variable name="tokenized_q" select="tokenize($q, ' AND ')"/>
	<xsl:variable name="numFound" select="//result[@name='response']/@numFound" as="xs:integer"/>
	<xsl:variable name="qString" select="if (string($q)) then $q else '*:*'"/>

	<!-- config variables -->
	<xsl:variable name="url">
		<xsl:value-of select="//config/url"/>
	</xsl:variable>
	<xsl:variable name="collection_type" select="//config/collection_type"/>

	<!-- load facets into variable -->
	<xsl:variable name="facets" select="//lst[@name='facet_fields']"/>

	<xsl:template match="/">
		<html>
			<head>
				<title>
					<xsl:value-of select="//config/title"/>
					<xsl:text>: </xsl:text>
					<xsl:value-of select="numishare:normalizeLabel('header_visualize', $lang)"/>
				</title>
				<link rel="shortcut icon" type="image/x-icon" href="{$display_path}images/favicon.png"/>	
				<link type="text/css" href="{$display_path}themes/{//config/theme/jquery_ui_theme}.css" rel="stylesheet"/>				
				<meta name="viewport" content="width=device-width, initial-scale=1"/>				
				<link type="text/css" href="{$display_path}style.css" rel="stylesheet"/>
				<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.4/jquery.min.js"/>
				<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jqueryui/1.10.4/jquery-ui.min.js"/>
				<!-- bootstrap -->
				<link rel="stylesheet" href="http://netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css"/>
				<script src="http://netdna.bootstrapcdn.com/bootstrap/3.1.1/js/bootstrap.min.js"/>
				<!-- Add fancyBox -->
				<link rel="stylesheet" href="{$display_path}jquery.fancybox.css?v=2.1.5" type="text/css" media="screen" />
				<script type="text/javascript" src="{$display_path}javascript/jquery.fancybox.pack.js?v=2.1.5"></script>
				<script type="text/javascript">
					$(document).ready (function(){
						$("#tabs").tabs();
					});
				</script>
				<!-- required libraries -->				
				<!--<script type="text/javascript" src="{$display_path}javascript/jquery.livequery.js"/>-->
				<!-- visualize functions -->
				<script type="text/javascript" src="{$display_path}javascript/highcharts.js"/>
				<script type="text/javascript" src="{$display_path}javascript/modules/exporting.js"/>
				<script type="text/javascript" src="{$display_path}javascript/visualize_functions.js"/>
				<!-- compare/customQuery functions -->
				<script type="text/javascript" src="{$display_path}javascript/search_functions.js"/>

				<xsl:if test="string(/config/google_analytics/script)">
					<script type="text/javascript">
						<xsl:value-of select="//config/google_analytics/script"/>
					</script>
				</xsl:if>
			</head>
			<body>
				<xsl:call-template name="header"/>
				<xsl:call-template name="visualize"/>
				<xsl:call-template name="footer"/>
			</body>
		</html>
	</xsl:template>

	<xsl:template name="visualize">
		<div class="container-fluid">
			<div class="row">
				<div class="col-md-12">
					<h1>
						<xsl:value-of select="numishare:normalizeLabel('header_visualize', $lang)"/>
					</h1>
					<p><xsl:value-of select="numishare:normalizeLabel('visualize_desc', $lang)"/>: <a href="http://wiki.numismatics.org/numishare:visualize"
							target="_blank">http://wiki.numismatics.org/numishare:visualize</a>.</p>

					<!-- display tabs for measurement analysis only if there is a sparql endpoint-->
					<xsl:choose>
						<xsl:when test="string(//config/sparql_endpoint)">
							<div id="tabs">
								<ul>
									<li>
										<a href="#typological">
											<xsl:value-of select="numishare:normalizeLabel('visualize_typological', $lang)"/>
										</a>
									</li>
									<li>
										<a href="#measurements">
											<xsl:value-of select="numishare:normalizeLabel('visualize_measurement', $lang)"/>
										</a>
									</li>
								</ul>
								<div id="typological">
									<xsl:apply-templates select="/content/response"/>
								</div>
								<div id="measurements">
									<xsl:call-template name="measurementForm"/>
								</div>
							</div>
						</xsl:when>
						<xsl:otherwise>
							<xsl:apply-templates select="/content/response"/>
						</xsl:otherwise>
					</xsl:choose>
				</div>
			</div>
		</div>
	</xsl:template>

	<xsl:template match="response">
		<!-- display the facet list only if there is a $q -->
		<xsl:if test="string($q)">
			<xsl:call-template name="display_facets">
				<xsl:with-param name="tokens" select="$tokenized_q"/>
			</xsl:call-template>
			<a href="results?q={$q}">Return to search results.</a>
		</xsl:if>

		<xsl:call-template name="visualize_options"/>

		<div style="display:none">
			<div id="searchBox">
				<h3>
					<xsl:value-of select="numishare:normalizeLabel('visualize_add_query', $lang)"/>
				</h3>
				<xsl:call-template name="search_forms"/>
			</div>
		</div>
	</xsl:template>

	<xsl:template name="visualize_options">
		<xsl:variable name="chartTypes">column,bar</xsl:variable>

		<form action="#typological" id="visualize-form" style="margin-bottom:40px;">
			<h3>1. <xsl:value-of select="numishare:normalizeLabel('visualize_response_type', $lang)"/></h3>
			<input type="radio" name="type" value="percentage">
				<xsl:if test="$type != 'count'">
					<xsl:attribute name="checked">checked</xsl:attribute>
				</xsl:if>
			</input>
			<label for="type-radio">
				<xsl:value-of select="numishare:normalizeLabel('numeric_percentage', $lang)"/>
			</label>
			<br/>
			<input type="radio" name="type" value="count">
				<xsl:if test="$type = 'count'">
					<xsl:attribute name="checked">checked</xsl:attribute>
				</xsl:if>
			</input>
			<label for="type-radio">
				<xsl:value-of select="numishare:normalizeLabel('numeric_count', $lang)"/>
			</label>
			<br/>
			<div style="display:table;width:100%">
				<h3>2. <xsl:value-of select="numishare:normalizeLabel('visualize_chart_type', $lang)"/></h3>
				<xsl:for-each select="tokenize($chartTypes, ',')">
					<span class="anOption">
						<input type="radio" name="chartType" value="{.}">
							<xsl:choose>
								<xsl:when test="$chartType = .">
									<xsl:attribute name="checked">checked</xsl:attribute>
								</xsl:when>
								<xsl:when test=". = 'column' and not(string($chartType))">
									<xsl:attribute name="checked">checked</xsl:attribute>
								</xsl:when>
							</xsl:choose>
						</input>
						<label for="chartType-radio">
							<xsl:value-of select="numishare:normalizeLabel(concat('chart_', .), $lang)"/>
						</label>
					</span>
				</xsl:for-each>
			</div>

			<!-- include checkbox categories -->
			<div style="display:table;width:100%">
				<h3>3. <xsl:value-of select="numishare:normalizeLabel('visualize_categories', $lang)"/></h3>
				<cinclude:include src="cocoon:/get_vis_categories?category={$category}&amp;q={$qString}"/>

				<div id="customQueryDiv">
					<h4>
						<xsl:text><xsl:value-of select="numishare:normalizeLabel('visiualize_add_custom', $lang)"/></xsl:text>
						<span style="font-size:80%;margin-left:10px;">
							<a href="#searchBox" class="addQuery" id="customQuery">
								<xsl:value-of select="numishare:normalizeLabel('visualize_add_query', $lang)"/>
							</a>
						</span>
					</h4>
					<xsl:for-each select="tokenize($custom, '\|')">
						<div class="customQuery">
							<b><xsl:value-of select="numishare:normalizeLabel('visualize_custom_query', $lang)"/>: </b>
							<span>
								<xsl:value-of select="."/>
							</span>
							<a href="#" class="removeQuery">
								<xsl:value-of select="numishare:normalizeLabel('visualize_remove_query', $lang)"/>
							</a>
						</div>
					</xsl:for-each>
				</div>
			</div>

			<h3>
				<xsl:choose>
					<xsl:when test="string($q)">
						<xsl:text>4.<xsl:value-of select="numishare:normalizeLabel('visualize_compare_optional', $lang)"/></xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>4. <xsl:value-of select="numishare:normalizeLabel('visualize_compare', $lang)"/></xsl:text>
					</xsl:otherwise>
				</xsl:choose>

				<span style="font-size:80%;margin-left:10px;">
					<a href="#searchBox" class="addQuery" id="compareQuery">
						<xsl:value-of select="numishare:normalizeLabel('visualize_add_query', $lang)"/>
					</a>
				</span>
			</h3>
			<div id="compareQueryDiv">
				<xsl:for-each select="tokenize($compare, '\|')">
					<div class="compareQuery">
						<b><xsl:value-of select="numishare:normalizeLabel('visualize_comparison_query', $lang)"/>: </b>
						<span>
							<xsl:value-of select="."/>
						</span>
						<a href="#" class="removeQuery">
							<xsl:value-of select="numishare:normalizeLabel('visualize_remove_query', $lang)"/>
						</a>
					</div>
				</xsl:for-each>
			</div>

			<div>
				<h4>
					<xsl:value-of select="numishare:normalizeLabel('visualize_optional_settings', $lang)"/>
					<span style="font-size:60%;margin-left:10px;">
						<a href="#" class="optional-button" id="visualize-options">
							<xsl:value-of select="numishare:normalizeLabel('visualize_hide-show', $lang)"/>
						</a>
					</span>
				</h4>
				<div class="optional-div" style="display:none;">
					<div>
						<label for="stacking">
							<xsl:value-of select="numishare:normalizeLabel('visualize_stacking_options', $lang)"/>
						</label>
						<select id="stacking">
							<option value="">
								<xsl:value-of select="numishare:normalizeLabel('results_select', $lang)"/>
							</option>
							<option value="stacking:normal">
								<xsl:if test="contains($options, 'stacking:normal')">
									<xsl:attribute name="selected">selected</xsl:attribute>
								</xsl:if>
								<xsl:value-of select="numishare:normalizeLabel('numeric_cumulative', $lang)"/>
							</option>
							<option value="stacking:percent">
								<xsl:if test="contains($options, 'stacking:percent')">
									<xsl:attribute name="selected">selected</xsl:attribute>
								</xsl:if>
								<xsl:value-of select="numishare:normalizeLabel('numeric_percentage', $lang)"/>
							</option>
						</select>
					</div>

				</div>
			</div>

			<input type="hidden" name="category" id="calculate-input" value=""/>
			<input type="hidden" name="compare" id="compare-input" value=""/>
			<input type="hidden" name="options" id="options-input" value="{$options}"/>
			<input type="hidden" name="custom" id="custom-input" value=""/>
			<xsl:if test="string($q)">
				<input type="hidden" name="q" value="{$q}"/>
			</xsl:if>
			<xsl:if test="string($lang)">
				<input type="hidden" name="lang" value="{$lang}"/>
			</xsl:if>
			<br/>
			<input type="submit" value="{numishare:normalizeLabel('visualize_generate', $lang)}" id="submit-calculate"/>
		</form>

		<!-- output charts and tables for facets -->
		<xsl:if test="string($category) and (string($q) or string($compare))">
			<xsl:for-each select="tokenize($category, '\|')">
				<xsl:call-template name="quant">
					<xsl:with-param name="facet" select="."/>
				</xsl:call-template>
			</xsl:for-each>
		</xsl:if>
		<xsl:if test="string($custom)">
			<xsl:for-each select="tokenize($custom, '\|')">
				<xsl:call-template name="quant">
					<xsl:with-param name="customQuery" select="."/>
				</xsl:call-template>
			</xsl:for-each>
		</xsl:if>
	</xsl:template>

	<xsl:template name="quant">
		<xsl:param name="facet"/>
		<xsl:param name="customQuery"/>
		<xsl:variable name="counts" as="element()*">
			<counts>
				<xsl:choose>
					<xsl:when test="string($facet)">
						<!-- if there is a $q parameter, gather data -->
						<xsl:if test="string($q)">
							<xsl:copy-of
								select="document(concat('cocoon:/get_vis_quant?q=', encode-for-uri($q), '&amp;category=', $facet, '&amp;type=', $type ))"/>
						</xsl:if>
						<!-- if there is a compare parameter, load get_hoard_quant with document() function -->
						<xsl:if test="string($compare)">
							<xsl:for-each select="tokenize($compare, '\|')">
								<xsl:copy-of
									select="document(concat('cocoon:/get_vis_quant?q=', encode-for-uri(.), '&amp;category=', $facet, '&amp;type=', $type ))"/>
							</xsl:for-each>
						</xsl:if>
					</xsl:when>
					<xsl:when test="string($customQuery)">
						<!-- if there is a $q parameter, gather data -->
						<xsl:if test="string($q)">
							<xsl:copy-of
								select="document(concat('cocoon:/get_vis_custom?q=', encode-for-uri($q), '&amp;customQuery=', $customQuery, '&amp;total=', $numFound, '&amp;type=', $type ))"
							/>
						</xsl:if>
						<!-- if there is a compare parameter, load get_hoard_quant with document() function -->
						<xsl:if test="string($compare)">
							<xsl:for-each select="tokenize($compare, '\|')">
								<xsl:copy-of
									select="document(concat('cocoon:/get_vis_custom?q=', encode-for-uri(.), '&amp;customQuery=', $customQuery, '&amp;total=', $numFound, '&amp;type=', $type ))"
								/>
							</xsl:for-each>
						</xsl:if>
					</xsl:when>
				</xsl:choose>
			</counts>
		</xsl:variable>

		<!-- only display chart if there are counts -->
		<xsl:if test="count($counts//name) &gt; 0">
			<div id="{.}-container" style="min-width: 400px; height: 400px; margin: 0 auto"/>
			<table class="calculate" id="{.}-table">
				<caption>
					<xsl:choose>
						<xsl:when test="$type='count'">
							<xsl:value-of select="numishare:normalizeLabel('numeric_count', $lang)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="numishare:normalizeLabel('numeric_percentage', $lang)"/>
						</xsl:otherwise>
					</xsl:choose>
					<xsl:text>: </xsl:text>
					<xsl:choose>
						<xsl:when test="string($facet)">
							<xsl:value-of select="numishare:normalize_fields($facet, $lang)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$customQuery"/>
						</xsl:otherwise>
					</xsl:choose>

				</caption>
				<thead>
					<tr>
						<th/>
						<xsl:if test="string($q)">
							<th>
								<xsl:value-of select="$q"/>
							</th>
						</xsl:if>
						<xsl:if test="string($compare)">
							<xsl:for-each select="tokenize($compare, '\|')">
								<th>
									<xsl:value-of select="."/>
								</th>
							</xsl:for-each>
						</xsl:if>
					</tr>
				</thead>
				<tbody>
					<xsl:for-each select="distinct-values($counts//name)">
						<xsl:sort/>
						<xsl:variable name="name" select="."/>
						<tr>
							<th>
								<xsl:value-of select="$name"/>
							</th>
							<xsl:if test="string($q)">
								<td>
									<xsl:choose>
										<xsl:when test="number($counts//query[@q=$q]/*[local-name()='name'][text()=$name]/@count)">
											<xsl:value-of select="$counts//query[@q=$q]/*[local-name()='name'][text()=$name]/@count"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:text>0</xsl:text>
										</xsl:otherwise>
									</xsl:choose>
								</td>
							</xsl:if>
							<xsl:if test="string($compare)">
								<xsl:for-each select="tokenize($compare, '\|')">
									<xsl:variable name="new-q" select="."/>
									<td>
										<xsl:choose>
											<xsl:when test="number($counts//query[@q=$new-q]/*[local-name()='name'][text()=$name]/@count)">
												<xsl:value-of select="$counts//query[@q=$new-q]/*[local-name()='name'][text()=$name]/@count"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:text>0</xsl:text>
											</xsl:otherwise>
										</xsl:choose>
									</td>
								</xsl:for-each>
							</xsl:if>
						</tr>
					</xsl:for-each>
				</tbody>
			</table>
		</xsl:if>
	</xsl:template>

	<xsl:template name="display_facets">
		<xsl:param name="tokens"/>

		<div class="remove_facets">
			<xsl:for-each select="$tokens">
				<xsl:variable name="val" select="."/>
				<xsl:variable name="new_query">
					<xsl:for-each select="$tokenized_q[not($val = .)]">
						<xsl:value-of select="."/>
						<xsl:if test="position() != last()">
							<xsl:text> AND </xsl:text>
						</xsl:if>
					</xsl:for-each>
				</xsl:variable>

				<!--<xsl:value-of select="."/>-->
				<xsl:choose>
					<xsl:when test="not(. = '*:*') and not(substring(., 1, 1) = '(')">
						<xsl:variable name="field" select="substring-before(., ':')"/>
						<xsl:variable name="name">
							<xsl:choose>
								<xsl:when test="string($field)">
									<xsl:value-of select="numishare:normalize_fields($field, $lang)"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="numishare:normalize_fields('fulltext', $lang)"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<xsl:variable name="term">
							<xsl:choose>
								<xsl:when test="string(substring-before(., ':'))">
									<xsl:value-of select="replace(substring-after(., ':'), '&#x022;', '')"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="replace(., '&#x022;', '')"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>

						<div class="ui-widget ui-state-default ui-corner-all stacked_term">
							<span>
								<b><xsl:value-of select="$name"/>: </b>
								<xsl:value-of select="if ($field = 'century_num') then numishare:normalize_century($term) else $term"/>
							</span>
						</div>

					</xsl:when>
					<!-- if the token contains a parenthisis, then it was probably sent from the search widget and the token must be broken down further to remove other facets -->
					<xsl:when test="substring(., 1, 1) = '('">
						<xsl:variable name="tokenized-fragments" select="tokenize(., ' OR ')"/>

						<div class="ui-widget ui-state-default ui-corner-all stacked_term">
							<span>
								<xsl:for-each select="$tokenized-fragments">
									<xsl:variable name="field" select="substring-before(translate(., '()', ''), ':')"/>
									<xsl:variable name="after-colon" select="substring-after(., ':')"/>

									<xsl:variable name="value">
										<xsl:choose>
											<xsl:when test="substring($after-colon, 1, 1) = '&#x022;'">
												<xsl:analyze-string select="$after-colon" regex="&#x022;([^&#x022;]+)&#x022;">
													<xsl:matching-substring>
														<xsl:value-of select="concat('&#x022;', regex-group(1), '&#x022;')"/>
													</xsl:matching-substring>
												</xsl:analyze-string>
											</xsl:when>
											<xsl:otherwise>
												<xsl:analyze-string select="$after-colon" regex="([0-9]+)">
													<xsl:matching-substring>
														<xsl:value-of select="regex-group(1)"/>
													</xsl:matching-substring>
												</xsl:analyze-string>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:variable>

									<xsl:variable name="q_string" select="concat($field, ':', $value)"/>

									<!--<xsl:variable name="value" select="."/>-->
									<xsl:variable name="new_multicategory">
										<xsl:for-each select="$tokenized-fragments[not(contains(.,$q_string))]">
											<xsl:variable name="other_field" select="substring-before(translate(., '()', ''), ':')"/>
											<xsl:variable name="after-colon" select="substring-after(., ':')"/>

											<xsl:variable name="other_value">
												<xsl:choose>
													<xsl:when test="substring($after-colon, 1, 1) = '&#x022;'">
														<xsl:analyze-string select="$after-colon" regex="&#x022;([^&#x022;]+)&#x022;">
															<xsl:matching-substring>
																<xsl:value-of select="concat('&#x022;', regex-group(1), '&#x022;')"/>
															</xsl:matching-substring>
														</xsl:analyze-string>
													</xsl:when>
													<xsl:otherwise>
														<xsl:analyze-string select="$after-colon" regex="([0-9]+)">
															<xsl:matching-substring>
																<xsl:value-of select="regex-group(1)"/>
															</xsl:matching-substring>
														</xsl:analyze-string>
													</xsl:otherwise>
												</xsl:choose>
											</xsl:variable>
											<xsl:value-of select="concat($other_field, ':', $other_value)"/>
											<xsl:if test="position() != last()">
												<xsl:text> OR </xsl:text>
											</xsl:if>
										</xsl:for-each>
									</xsl:variable>
									<xsl:variable name="multicategory_query">
										<xsl:choose>
											<xsl:when test="contains($new_multicategory, ' OR ')">
												<xsl:value-of select="concat('(', $new_multicategory, ')')"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="$new_multicategory"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:variable>

									<!-- display either the term or the regularized name for the century -->
									<b>
										<xsl:value-of select="numishare:normalize_fields($field, $lang)"/>
										<xsl:text>: </xsl:text>
									</b>
									<xsl:value-of select="if ($field='century_num') then numishare:normalize_century($value) else $value"/>
									<xsl:if test="position() != last()">
										<xsl:text> OR </xsl:text>
									</xsl:if>
								</xsl:for-each>
							</span>
						</div>
					</xsl:when>
					<xsl:when test="not(contains(., ':'))">
						<div class="stacked_term">
							<span>
								<b><xsl:value-of select="numishare:normalize_fields('fulltext', $lang)"/>: </b>
								<xsl:value-of select="."/>
							</span>
						</div>
					</xsl:when>
				</xsl:choose>
			</xsl:for-each>
		</div>
	</xsl:template>

	<xsl:template name="render_categories">
		<xsl:param name="category_fragment"/>

		<xsl:variable name="new_query">
			<xsl:for-each select="$tokenized_q[not(. = $category_fragment)]">
				<xsl:value-of select="."/>
				<xsl:if test="position() != last()">
					<xsl:text> AND </xsl:text>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>

		<div class="ui-widget ui-state-default ui-corner-all stacked_term">
			<span class="term">
				<b>Category: </b>
				<xsl:call-template name="recompile_category">
					<xsl:with-param name="category_fragment" select="$category_fragment"/>
					<xsl:with-param name="tokenized_fragment"
						select="tokenize(substring-after(replace(replace(replace($category_fragment, '\)', ''), '\(', ''), '\+', ''), 'category_facet:'), ' ')"/>
					<xsl:with-param name="level" as="xs:integer">1</xsl:with-param>
				</xsl:call-template>
			</span>
		</div>
	</xsl:template>

</xsl:stylesheet>
