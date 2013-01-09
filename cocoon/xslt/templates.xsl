<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:exsl="http://exslt.org/common" xmlns:numishare="http://code.google.com/p/numishare/" xmlns:skos="http://www.w3.org/2004/02/skos/core#"
	xmlns:cinclude="http://apache.org/cocoon/include/1.0" xmlns:nuds="http://nomisma.org/nuds" xmlns:nh="http://nomisma.org/nudsHoard" xmlns:nm="http://nomisma.org/id/"
	xmlns:math="http://exslt.org/math" exclude-result-prefixes=" #all" version="2.0">

	<xsl:variable name="flickr-api-key" select="//config/flickr_api_key"/>

	<!-- ************** QUANTITATIVE ANALYSIS FUNCTIONS ************** -->
	<!-- this template should only apply for hoards, hence the nh namespace -->
	<xsl:template name="nh:quant">
		<xsl:param name="element"/>
		<xsl:param name="role"/>
		<xsl:variable name="counts">
			<counts>
				<!-- use get_hoard_quant to calculate -->
				<xsl:if test="$pipeline = 'display'">
					<xsl:copy-of select="document(concat($url, 'get_hoard_quant?id=', $id, '&amp;calculate=', if (string($role)) then $role else $element, '&amp;type=', $type))"/>
				</xsl:if>
				<!-- if there is a compare parameter, load get_hoard_quant with document() function -->
				<xsl:if test="string($compare) and string($calculate)">
					<xsl:for-each select="tokenize($compare, ',')">
						<xsl:copy-of select="document(concat($url, 'get_hoard_quant?id=', ., '&amp;calculate=', if (string($role)) then $role else $element, '&amp;type=', $type))"/>
					</xsl:for-each>
				</xsl:if>
			</counts>
		</xsl:variable>

		<div id="{.}-container" style="min-width: 400px; height: 400px; margin: 0 auto"/>
		<table class="calculate" id="{.}-table">
			<caption>
				<xsl:choose>
					<xsl:when test="$type='count'">Occurrences</xsl:when>
					<xsl:otherwise>Percentage</xsl:otherwise>
				</xsl:choose>
				<xsl:text> for </xsl:text>
				<xsl:choose>
					<xsl:when test="string($role)">
						<xsl:value-of select="concat(upper-case(substring($role, 1, 1)), substring($role, 2))"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="numishare:regularize_node($element, $lang)"/>
					</xsl:otherwise>
				</xsl:choose>
			</caption>
			<thead>
				<tr>
					<th/>
					<xsl:if test="$pipeline = 'display'">
						<th>
							<xsl:value-of select="$id"/>
						</th>
					</xsl:if>
					<xsl:if test="string($compare)">
						<xsl:for-each select="tokenize($compare, ',')">
							<th>
								<xsl:value-of select="."/>
							</th>
						</xsl:for-each>
					</xsl:if>
				</tr>
			</thead>
			<tbody>
				<xsl:for-each select="distinct-values(exsl:node-set($counts)//name)">
					<xsl:sort/>
					<xsl:variable name="name" select="if (string(.)) then . else 'Null value'"/>
					<tr>
						<th>
							<xsl:value-of select="$name"/>
						</th>
						<xsl:if test="$pipeline = 'display'">
							<td>
								<xsl:choose>
									<xsl:when test="number(exsl:node-set($counts)//hoard[@id=$id]/*[local-name()='name'][text()=$name]/@count)">
										<xsl:value-of select="exsl:node-set($counts)//hoard[@id=$id]/*[local-name()='name'][text()=$name]/@count"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:text>0</xsl:text>
									</xsl:otherwise>
								</xsl:choose>
							</td>
						</xsl:if>
						<xsl:if test="string($compare)">
							<xsl:for-each select="tokenize($compare, ',')">
								<xsl:variable name="hoard-id" select="."/>
								<td>
									<xsl:choose>
										<xsl:when test="number(exsl:node-set($counts)//hoard[@id=$hoard-id]/*[local-name()='name'][text()=$name]/@count)">
											<xsl:value-of select="exsl:node-set($counts)//hoard[@id=$hoard-id]/*[local-name()='name'][text()=$name]/@count"/>
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
	</xsl:template>

	<xsl:template name="visualization">
		<xsl:variable name="queryOptions">authority,deity,denomination,dynasty,issuer,material,mint,portrait,region</xsl:variable>
		<xsl:variable name="chartTypes">line,spline,area,areaspline,column,bar,scatter</xsl:variable>
		<xsl:variable name="action">
			<xsl:choose>
				<xsl:when test="$pipeline = 'analyze'">#visualization</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="concat('./', $id, '#quantitative')"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<p>Use this feature to visualize percentages or numeric occurrences of the following typologies.</p>
		<form action="{$action}" id="visualize-form" style="margin-bottom:40px;">
			<h2>Step 1: Select Numeric Response Type</h2>
			<input type="radio" name="type" value="percentage">
				<xsl:if test="$type != 'count'">
					<xsl:attribute name="checked">checked</xsl:attribute>
				</xsl:if>
			</input>
			<label for="type-radio">Percentage</label>
			<br/>
			<input type="radio" name="type" value="count">
				<xsl:if test="$type = 'count'">
					<xsl:attribute name="checked">checked</xsl:attribute>
				</xsl:if>
			</input>
			<label for="type-radio">Count</label>
			<br/>
			<div style="display:table;width:100%">
				<h2>Step 2: Select Chart Type</h2>
				<xsl:for-each select="tokenize($chartTypes, ',')">
					<span class="anOption">
						<input type="radio" name="chartType" value="{.}">
							<xsl:choose>
								<xsl:when test="$chartType = .">
									<xsl:attribute name="checked">checked</xsl:attribute>
								</xsl:when>
							</xsl:choose>
						</input>
						<label for="chartType-radio">
							<xsl:value-of select="."/>
						</label>
					</span>

				</xsl:for-each>
			</div>
			<div style="display:table;width:100%">
				<h2>Step 3: Select Categories for Analysis</h2>
				<xsl:for-each select="tokenize($queryOptions, ',')">
					<xsl:variable name="query_fragment" select="."/>
					<span class="anOption">
						<xsl:choose>
							<xsl:when test="$pipeline='analyze'">
								<xsl:call-template name="vis-checks">
									<xsl:with-param name="query_fragment" select="$query_fragment"/>
								</xsl:call-template>
							</xsl:when>
							<xsl:otherwise>
								<xsl:if test="count(exsl:node-set($nudsGroup)/descendant::*[local-name()=$query_fragment or @xlink:role=$query_fragment]) &gt; 0">
									<xsl:call-template name="vis-checks">
										<xsl:with-param name="query_fragment" select="$query_fragment"/>
									</xsl:call-template>
								</xsl:if>
							</xsl:otherwise>
						</xsl:choose>
					</span>
				</xsl:for-each>
			</div>

			<xsl:choose>
				<xsl:when test="$pipeline='analyze'">
					<h2>
						<xsl:text>Step 4: Select Hoards</xsl:text>
						<span style="font-size:60%;margin-left:10px;">
							<a href="#filterHoards" id="showFilter">Filter List</a>
						</span>
					</h2>
					<div class="filter-div" style="display:none">
						<b>Filter Query:</b>
						<span/>
						<a href="#" class="removeFilter">Remove Filter</a>
					</div>
					<xsl:call-template name="get-hoards"/>
				</xsl:when>
				<xsl:otherwise>
					<h2>Step 4: Select Hoards to Compare (optional)</h2>
					<xsl:choose>
						<xsl:when test="not(string($compare))">
							<div>
								<a href="#" class="compare-button"><img src="{$display_path}images/plus.gif" alt="Expand"/>Compare to Other Hoards</a>
								<div class="compare-div"/>
							</div>
						</xsl:when>
						<xsl:otherwise>
							<div class="compare-div">
								<cinclude:include src="cocoon:/get_hoards?compare={$compare}&amp;q=*"/>
							</div>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>

			<input type="hidden" name="calculate" id="calculate-input" value=""/>
			<input type="hidden" name="compare" class="compare-input" value=""/>
			<br/>
			<input type="submit" value="Calculate Selected" id="submit-calculate"/>
		</form>

		<!-- output charts and tables -->
		<xsl:for-each select="tokenize($calculate, ',')">
			<xsl:variable name="element">
				<xsl:choose>
					<xsl:when test=". = 'material' or .='denomination'">
						<xsl:value-of select="."/>
					</xsl:when>
					<xsl:when test=".='mint' or .='region'">
						<xsl:text>geogname</xsl:text>
					</xsl:when>
					<xsl:when test=".='dynasty'">
						<xsl:text>famname</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>persname</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:variable name="role">
				<xsl:if test=". != 'material' and . != 'denomination'">
					<xsl:value-of select="."/>
				</xsl:if>
			</xsl:variable>

			<xsl:call-template name="nh:quant">
				<xsl:with-param name="element" select="$element"/>
				<xsl:with-param name="role" select="$role"/>
			</xsl:call-template>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="data-download">
		<xsl:variable name="queryOptions">authority,deity,denomination,dynasty,issuer,material,mint,portrait,region</xsl:variable>

		<p>Use this feature to download a CSV for the given query and selected hoards.</p>
		<form action="{$display_path}hoards.csv" id="csv-form" style="margin-bottom:40px;">
			<h2>Step 1: Select Numeric Response Type</h2>
			<input type="radio" name="type" value="percentage">
				<xsl:if test="$type != 'count'">
					<xsl:attribute name="checked">checked</xsl:attribute>
				</xsl:if>
			</input>
			<label for="type-radio">Percentage</label>
			<br/>
			<input type="radio" name="type" value="count">
				<xsl:if test="$type = 'count'">
					<xsl:attribute name="checked">checked</xsl:attribute>
				</xsl:if>
			</input>
			<label for="type-radio">Count</label>
			<br/>
			<div style="width:100%;display:table">
				<h2>Step 2: Select Categories for Analysis</h2>
				<xsl:for-each select="tokenize($queryOptions, ',')">
					<xsl:variable name="query_fragment" select="."/>
					<span class="anOption">
						<xsl:choose>
							<xsl:when test="$pipeline='analyze'">
								<xsl:call-template name="vis-radios">
									<xsl:with-param name="query_fragment" select="$query_fragment"/>
								</xsl:call-template>
							</xsl:when>
							<xsl:otherwise>
								<xsl:if test="count(exsl:node-set($nudsGroup)/descendant::*[local-name()=$query_fragment or @xlink:role=$query_fragment]) &gt; 0">
									<xsl:call-template name="vis-radios">
										<xsl:with-param name="query_fragment" select="$query_fragment"/>
									</xsl:call-template>
								</xsl:if>
							</xsl:otherwise>
						</xsl:choose>
					</span>
				</xsl:for-each>
			</div>

			<xsl:choose>
				<xsl:when test="$pipeline='analyze'">
					<h2>
						<xsl:text>Step 3: Select Hoards</xsl:text>
						<div class="filter-div" style="display:none">
							<b>Filter Query:</b>
							<span/>
							<a href="#" class="removeFilter">Remove Filter</a>
						</div>
					</h2>
					<xsl:call-template name="get-hoards"/>
				</xsl:when>
				<xsl:otherwise>
					<h2>Step 3: Select Hoards to Compare (optional)</h2>
					<div>
						<a href="#" class="compare-button"><img src="{$display_path}images/plus.gif" alt="Expand"/>Compare to Other Hoards</a>
						<div class="compare-div"/>
					</div>
				</xsl:otherwise>
			</xsl:choose>

			<input type="hidden" name="compare" class="compare-input" value=""/>
			<br/>
			<input type="submit" value="Calculate Selected" id="submit-csv"/>
		</form>
	</xsl:template>

	<xsl:template name="vis-checks">
		<xsl:param name="query_fragment"/>
		<xsl:choose>
			<xsl:when test="contains($calculate, $query_fragment)">
				<input type="checkbox" id="{$query_fragment}-checkbox" checked="checked" value="{$query_fragment}" class="calculate-checkbox"/>
			</xsl:when>
			<xsl:otherwise>
				<input type="checkbox" id="{$query_fragment}-checkbox" value="{$query_fragment}" class="calculate-checkbox"/>
			</xsl:otherwise>
		</xsl:choose>
		<label for="{$query_fragment}-checkbox">
			<xsl:value-of select="concat(upper-case(substring($query_fragment, 1, 1)), substring($query_fragment, 2))"/>
		</label>
	</xsl:template>

	<xsl:template name="vis-radios">
		<xsl:param name="query_fragment"/>
		<input type="radio" name="calculate" id="{$query_fragment}-radio" value="{$query_fragment}"/>
		<label for="{$query_fragment}-checkbox">
			<xsl:value-of select="concat(upper-case(substring($query_fragment, 1, 1)), substring($query_fragment, 2))"/>
		</label>
	</xsl:template>

	<xsl:template name="get-hoards">
		<div class="compare-div">
			<cinclude:include src="cocoon:/get_hoards?compare={$compare}&amp;q=*"/>
		</div>
	</xsl:template>
	
	<xsl:template name="search_forms">
		<div class="search-form">
			<p>To conduct a free text search select ‘Keyword’ on the drop-down menu above and enter the text for which you wish to search. The search allows wildcard searches with the * and ?
				characters and exact string matches by surrounding phrases by double quotes (like Google). <a href="http://lucene.apache.org/java/2_9_1/queryparsersyntax.html#Term%20Modifiers"
					target="_blank">See the Lucene query syntax</a> documentation for more information.</p>
			<form id="advancedSearchForm" method="GET" action="results">
				<div id="inputContainer">
					<div class="searchItemTemplate">
						<select class="category_list">
							<xsl:call-template name="search_options"/>
						</select>
						<div style="display:inline;" class="option_container">
							<input type="text" id="search_text" class="search_text" style="display: inline;"/>
						</div>
						<a class="gateTypeBtn" href="#">add »</a>
						<!--<a class="removeBtn" href="#">« remove</a>-->
					</div>
				</div>
				<input name="q" id="q_input" type="hidden"/>
				<xsl:if test="string($lang)">
					<input name="lang" type="hidden" value="{$lang}"/>
				</xsl:if>
				<xsl:choose>
					<xsl:when test="$pipeline='analyze'">
						<input type="submit" value="Filter" id="filterButton"/>
					</xsl:when>
					<xsl:when test="$pipeline='visualize'">
						<input type="submit" value="Add Query" id="search_buttom"/>
					</xsl:when>
					<xsl:otherwise>
						<input type="submit" value="{numishare:normalizeLabel('header_search', $lang)}" id="search_button"/>
					</xsl:otherwise>
				</xsl:choose>
				
			</form>
			
			<xsl:if test="$pipeline='visualize'">
				<span style="display:none" id="paramName"/>
			</xsl:if>
		</div>
		
		<div id="searchItemTemplate" class="searchItemTemplate">
			<select class="category_list">
				<xsl:call-template name="search_options"/>
			</select>
			<div style="display:inline;" class="option_container">
				<input type="text" class="search_text" style="display: inline;"/>
			</div>
			<a class="gateTypeBtn" href="#">add »</a>
			<a class="removeBtn" href="#" style="display:none;">« remove</a>
		</div>
	</xsl:template>
	
	<xsl:template name="search_options">
		<xsl:variable name="fields">
			<xsl:text>fulltext,artist_text,authority_text,coinType_facet,color_text,deity_text,denomination_facet,department_facet,diameter_num,dynasty_facet,findspot_text,objectType_facet,identifier_display,issuer_text,legend_text,obv_leg_text,rev_leg_text,maker_text,manufacture_facet,material_facet,mint_text,portrait_text,reference_facet,region_text,taq_num,tpq_num,type_text,obv_type_text,rev_type_text,weight_num,year_num</xsl:text>
		</xsl:variable>
		
		<xsl:for-each select="tokenize($fields, ',')">
			<xsl:variable name="name" select="."/>
			<xsl:variable name="root" select="substring-before($name, '_')"/>
			<xsl:choose>
				<xsl:when test="$collection_type='hoard'">
					<xsl:if test="not($name='diameter_num') and not($name='weight_num') and not($name='year_num')">
						<xsl:choose>
							<!-- display only those search options when their facet equivalent has hits -->
							<xsl:when test="exsl:node-set($facets)//lst[starts-with(@name, $root)][number(int[@name='numFacetTerms']) &gt; 0]">
								<option value="{$name}" class="search_option">
									<xsl:value-of select="numishare:normalize_fields($name, $lang)"/>
								</option>
							</xsl:when>
							<!-- display those search options when they aren't connected to facets -->
							<xsl:when test="not(exsl:node-set($facets)//lst[starts-with(@name, $root)])">
								<option value="{$name}" class="search_option">
									<xsl:value-of select="numishare:normalize_fields($name, $lang)"/>
								</option>
							</xsl:when>
						</xsl:choose>
						
					</xsl:if>
				</xsl:when>
				<xsl:otherwise>
					<xsl:if test="not($name='taq_num') and not($name='tpq_num')">
						<xsl:choose>
							<!-- display only those search options when their facet equivalent has hits -->
							<xsl:when test="exsl:node-set($facets)//lst[starts-with(@name, $root)][number(int[@name='numFacetTerms']) &gt; 0]">
								<option value="{$name}" class="search_option">
									<xsl:value-of select="numishare:normalize_fields($name, $lang)"/>
								</option>
							</xsl:when>
							<!-- display those search options when they aren't connected to facets -->
							<xsl:when test="not(exsl:node-set($facets)//lst[starts-with(@name, $root)])">
								<option value="{$name}" class="search_option">
									<xsl:value-of select="numishare:normalize_fields($name, $lang)"/>
								</option>
							</xsl:when>
						</xsl:choose>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template name="recompile_category">
		<xsl:param name="level" as="xs:integer"/>
		<xsl:param name="category_fragment"/>
		<xsl:param name="tokenized_fragment"/>
		<xsl:value-of select="substring-after(replace($tokenized_fragment[contains(., concat('L', $level, '|'))], '&#x022;', ''), '|')"/>
		<!--<xsl:value-of select="substring-after(replace(., '&#x022;', ''), '|')"/>-->
		<xsl:if test="contains($category_fragment, concat('L', $level + 1, '|'))">
			<xsl:text>--</xsl:text>
			<xsl:call-template name="recompile_category">
				<xsl:with-param name="tokenized_fragment" select="$tokenized_fragment"/>
				<xsl:with-param name="category_fragment" select="$category_fragment"/>
				<xsl:with-param name="level" select="$level + 1"/>
			</xsl:call-template>
		</xsl:if>
		
	</xsl:template>
</xsl:stylesheet>