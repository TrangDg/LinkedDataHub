<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY def    "https://w3id.org/atomgraph/linkeddatahub/default#">
    <!ENTITY ldh    "https://w3id.org/atomgraph/linkeddatahub#">
    <!ENTITY ac     "https://w3id.org/atomgraph/client#">
    <!ENTITY rdf    "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY rdfs   "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY xsd    "http://www.w3.org/2001/XMLSchema#">
    <!ENTITY geo    "http://www.w3.org/2003/01/geo/wgs84_pos#">
    <!ENTITY acl    "http://www.w3.org/ns/auth/acl#">
    <!ENTITY ldt    "https://www.w3.org/ns/ldt#">
    <!ENTITY dh     "https://www.w3.org/ns/ldt/document-hierarchy#">
    <!ENTITY sd     "http://www.w3.org/ns/sparql-service-description#">
    <!ENTITY sioc   "http://rdfs.org/sioc/ns#">
    <!ENTITY sp     "http://spinrdf.org/sp#">
    <!ENTITY spin   "http://spinrdf.org/spin#">
    <!ENTITY dct    "http://purl.org/dc/terms/">
    <!ENTITY nfo    "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#">
]>
<xsl:stylesheet version="3.0"
xmlns="http://www.w3.org/1999/xhtml"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
xmlns:prop="http://saxonica.com/ns/html-property"
xmlns:xhtml="http://www.w3.org/1999/xhtml"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:map="http://www.w3.org/2005/xpath-functions/map"
xmlns:json="http://www.w3.org/2005/xpath-functions"
xmlns:array="http://www.w3.org/2005/xpath-functions/array"
xmlns:ac="&ac;"
xmlns:ldh="&ldh;"
xmlns:rdf="&rdf;"
xmlns:rdfs="&rdfs;"
xmlns:geo="&geo;"
xmlns:acl="&acl;"
xmlns:ldt="&ldt;"
xmlns:sioc="&sioc;"
xmlns:sd="&sd;"
xmlns:sp="&sp;"
xmlns:spin="&spin;"
xmlns:dct="&dct;"
xmlns:bs2="http://graphity.org/xsl/bootstrap/2.3.2"
extension-element-prefixes="ixsl"
exclude-result-prefixes="#all"
>

    <xsl:variable name="block-delete-string" as="xs:string">
        <!-- TO-DO: refactor to update the following index properties -->
        <![CDATA[
            PREFIX  rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

            DELETE
            {
                $this ?seq $block .
                $block ?p ?o .
            }
            WHERE
            {
                $this ?seq $block .
                FILTER(strstarts(str(?seq), concat(str(rdf:), "_")))
                OPTIONAL
                {
                    $block ?p ?o
                }
            }
        ]]>
    </xsl:variable>
    <xsl:variable name="block-swap-string" as="xs:string">
        <![CDATA[
            PREFIX  xsd:  <http://www.w3.org/2001/XMLSchema#>
            PREFIX  rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

            DELETE {
              $this ?sourceSeq $sourceBlock .
              $this ?targetSeq $targetBlock .
              $this ?seq ?block .
            }
            INSERT {
              $this ?newSourceSeq $sourceBlock .
              $this ?newTargetSeq $targetBlock .
              $this ?newSeq ?block .
            }
            WHERE
              { $this  ?sourceSeq  $sourceBlock
                FILTER(strstarts(str(?sourceSeq), concat(str(rdf:), "_")))
                BIND(xsd:integer(substr(str(?sourceSeq), 45)) AS ?sourceIndex)
                $this  ?targetSeq  $targetBlock
                FILTER(strstarts(str(?targetSeq), concat(str(rdf:), "_")))
                BIND(xsd:integer(substr(str(?targetSeq), 45)) AS ?targetIndex)
                BIND(if(( ?sourceIndex < ?targetIndex ), ( ?targetIndex - 1 ), ?targetIndex) AS ?newTargetIndex)
                BIND(if(( ?sourceIndex < ?targetIndex ), ?targetIndex, ( ?targetIndex + 1 )) AS ?newSourceIndex)
                BIND(IRI(concat(str(rdf:), "_", str(?newSourceIndex))) AS ?newSourceSeq)
                BIND(IRI(concat(str(rdf:), "_", str(?newTargetIndex))) AS ?newTargetSeq)
                OPTIONAL
                  { $this  ?sourceSeq  $sourceBlock
                    FILTER(strstarts(str(?sourceSeq), concat(str(rdf:), "_")))
                    BIND(xsd:integer(substr(str(?sourceSeq), 45)) AS ?sourceIndex)
                    $this  ?targetSeq  $targetBlock
                    FILTER(strstarts(str(?targetSeq), concat(str(rdf:), "_")))
                    BIND(xsd:integer(substr(str(?targetSeq), 45)) AS ?targetIndex)
                    $this  ?seq  ?block
                    FILTER strstarts(str(?seq), str(rdf:_))
                    BIND(xsd:integer(substr(str(?seq), 45)) AS ?index)
                    BIND(( ( ?index > ?sourceIndex ) && ( ?index < ?targetIndex ) ) AS ?isBetweenSourceAndTarget)
                    BIND(( ( ?index < ?sourceIndex ) && ( ?index > ?targetIndex ) ) AS ?isBetweenTargetAndSource)
                    FILTER ( ?isBetweenSourceAndTarget || ?isBetweenTargetAndSource )
                    BIND(( ?index + if(?isBetweenSourceAndTarget, -1, +1) ) AS ?newIndex)
                    BIND(IRI(concat(str(rdf:), "_", str(?newIndex))) AS ?newSeq)
                  }
              }
        ]]>
    </xsl:variable>
    
    <xsl:key name="element-by-about" match="*[@about]" use="@about"/>

    <!-- TEMPLATES -->

    <!-- identity transform -->
   
    <xsl:template match="@* | node()" mode="ldh:Identity">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- render row -->
    
    <xsl:template match="*" mode="ldh:RenderRow" as="(function(item()?) as map(*))*">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>

    <xsl:template match="text()" mode="ldh:RenderRow" as="(function(item()?) as map(*))*"/>
    
    <!-- hide type control -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&ldh;XHTML']" mode="bs2:TypeControl" priority="1">
        <xsl:next-match>
            <xsl:with-param name="hidden" select="true()"/>
        </xsl:next-match>
    </xsl:template>

    <!-- provide a property label which otherwise would default to local-name() client-side (since $property-metadata is not loaded) -->
    <xsl:template match="*[rdf:type/@rdf:resource = '&ldh;XHTML']/rdfs:label | *[rdf:type/@rdf:resource = '&ldh;XHTML']/ac:mode" mode="bs2:FormControl">
        <xsl:next-match>
            <xsl:with-param name="label" select="ac:property-label(.)"/>
        </xsl:next-match>
    </xsl:template>

    <xsl:template match="*[rdf:type/@rdf:resource = '&ldh;XHTML']/rdf:value/xhtml:*" mode="bs2:FormControlTypeLabel" priority="1"/>

    <!-- EVENT LISTENERS -->
    
    <!-- show block controls -->
    
    <xsl:template match="div[contains-token(@class, 'block')][key('elements-by-class', 'row-block-controls', .)][acl:mode() = '&acl;Write']" mode="ixsl:onmousemove"> <!-- TO-DO: better selector -->
        <xsl:variable name="dom-x" select="ixsl:get(ixsl:event(), 'clientX')" as="xs:double"/>
        <xsl:variable name="dom-y" select="ixsl:get(ixsl:event(), 'clientY')" as="xs:double"/>
        <xsl:variable name="rect" select="ixsl:call(., 'getBoundingClientRect', [])"/>
        <xsl:variable name="offset-x" select="$dom-x - ixsl:get($rect, 'x')" as="xs:double"/>
        <xsl:variable name="offset-y" select="$dom-y - ixsl:get($rect, 'y')" as="xs:double"/>
        <xsl:variable name="width" select="ixsl:get($rect, 'width')" as="xs:double"/>
        <xsl:variable name="offset-x-treshold" select="120" as="xs:double"/>
        <xsl:variable name="offset-y-treshold" select="20" as="xs:double"/>
        
        <!-- there might be multiple .row-block-controls in a block if the main block is followed by blocks rendered from ldh:template -->
        <xsl:variable name="row-block-controls" select="key('elements-by-class', 'row-block-controls', .)[1]" as="element()"/>
        <xsl:variable name="btn-edit" select="key('elements-by-class', 'btn-edit', $row-block-controls)" as="element()"/>
        <!-- check that the mouse is on the top edge and show the block controls if they're not already shown -->
        <xsl:if test="$offset-x &gt;= $width - $offset-x-treshold and $offset-y &lt;= $offset-y-treshold and ixsl:style($row-block-controls)?z-index = '-1'">
            <ixsl:set-style name="z-index" select="'1'" object="$row-block-controls"/>
            <ixsl:set-style name="display" select="'block'" object="$btn-edit"/>
        </xsl:if>
        <!-- check that the mouse is outside the top edge and hide the block controls if they're not already hidden -->
        <xsl:if test="$offset-x &lt; $width - $offset-x-treshold and $offset-y &gt; $offset-y-treshold and ixsl:style($row-block-controls)?z-index = '1'">
            <ixsl:set-style name="z-index" select="'-1'" object="$row-block-controls"/>
            <ixsl:set-style name="display" select="'none'" object="$btn-edit"/>
        </xsl:if>
    </xsl:template>

    <!-- override inline editing form for block types (do nothing if the button is disabled) - prioritize over form.xsl -->
    
    <xsl:template match="div[following-sibling::div[@typeof = ('&ldh;XHTML', '&ldh;Object')]]//button[contains-token(@class, 'btn-edit')][not(contains-token(@class, 'disabled'))]" mode="ixsl:onclick" priority="1">
        <xsl:param name="block" select="ancestor::div[contains-token(@class, 'block')][1]" as="element()"/>
        <!-- for block types, button.btn-edit is placed in its own div.row-fluid, therefore the next row is the actual container -->
        <xsl:param name="container" select="$block/descendant::div[@typeof][1]" as="element()"/> <!-- other resources can be nested within object -->
        
        <xsl:next-match>
<!--            <xsl:with-param name="container" select="$container"/>-->
        </xsl:next-match>
    </xsl:template>
    
    <!-- append new block form onsubmit (using POST) -->
    
    <xsl:template match="div[@typeof = ('&ldh;XHTML', '&ldh;Object')]//form[contains-token(@class, 'form-horizontal')][upper-case(@method) = 'POST']" mode="ixsl:onsubmit" priority="2"> <!-- prioritize over form.xsl -->
        <xsl:param name="elements" select=".//input | .//textarea | .//select" as="element()*"/>
        <xsl:param name="triples" select="ldh:parse-rdf-post($elements)" as="element()*"/>
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="container" select="ancestor::div[@typeof][1]" as="element()"/>
        <xsl:variable name="block" select="ancestor::div[contains-token(@class, 'block')][1]" as="element()"/>
        <xsl:variable name="block-uri" select="xs:anyURI(.//input[@name = 'su'] => ixsl:get('value'))" as="xs:anyURI"/>
        <xsl:variable name="sequence-number" select="count($block/preceding-sibling::div[@about]) + 1" as="xs:integer"/>
        <xsl:variable name="sequence-property" select="xs:anyURI('&rdf;_' || $sequence-number)" as="xs:anyURI"/>
        <xsl:variable name="sequence-triple" as="element()">
            <json:map>
                <json:string key="subject"><xsl:sequence select="ac:absolute-path(ldh:base-uri(.))"/></json:string>
                <json:string key="predicate"><xsl:sequence select="$sequence-property"/></json:string>
                <json:string key="object"><xsl:sequence select="$block-uri"/></json:string>
            </json:map>
        </xsl:variable>
        
        <xsl:next-match>
            <xsl:with-param name="block" select="$block"/>
            <!-- append $sequence-triple to $request-body that is sent with the HTTP request, but not to $resources which are rendered after the block update (don't want to show it) -->
            <xsl:with-param name="request-body" as="document-node()">
                <xsl:document>
                    <rdf:RDF>
                        <xsl:sequence select="ldh:triples-to-descriptions(($triples, $sequence-triple))"/>
                    </rdf:RDF>
                </xsl:document>
            </xsl:with-param>
        </xsl:next-match>
    </xsl:template>

    <!-- delete block onclick (increased priority to take precedence over form.xsl .btn-remove-resource) -->
    
    <xsl:template match="div[@typeof = ('&ldh;XHTML', '&ldh;Object')]//button[contains-token(@class, 'btn-remove-resource')]" mode="ixsl:onclick" priority="3">
        <xsl:variable name="block" select="ancestor::div[contains-token(@class, 'block')][1]" as="element()"/>

        <xsl:choose>
            <!-- delete existing block -->
            <xsl:when test="$block/@about">
                <!-- show a confirmation prompt -->
                <xsl:if test="ixsl:call(ixsl:window(), 'confirm', [ ac:label(key('resources', 'are-you-sure', document(resolve-uri('static/com/atomgraph/linkeddatahub/xsl/bootstrap/2.3.2/translations.rdf', $ac:contextUri)))) ])">
                    <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

                    <xsl:variable name="block-uri" select="$block/@about" as="xs:anyURI"/>
                    <xsl:variable name="update-string" select="replace($block-delete-string, '$this', '&lt;' || ac:absolute-path(ldh:base-uri(.)) || '&gt;', 'q')" as="xs:string"/>
                    <xsl:variable name="update-string" select="replace($update-string, '$block', '&lt;' || $block-uri || '&gt;', 'q')" as="xs:string"/>
                    <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path($ldh:requestUri), map{}, ac:absolute-path(ldh:base-uri(.)))" as="xs:anyURI"/>
                    <xsl:variable name="request" as="item()*">
                        <ixsl:schedule-action http-request="map{ 'method': 'PATCH', 'href': $request-uri, 'media-type': 'application/sparql-update', 'body': $update-string }">
                            <xsl:call-template name="onBlockDelete">
                                <xsl:with-param name="block" select="$block"/>
                            </xsl:call-template>
                        </ixsl:schedule-action>
                    </xsl:variable>
                    <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:if>
            </xsl:when>
            <!-- remove block that hasn't been saved yet -->
            <xsl:otherwise>
                <xsl:for-each select="$block">
                    <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- start dragging top-level block (or its descendants - necessary for Map and Graph modes to work correctly) -->
    
    <xsl:template match="div[@id = 'content-body']/div[ixsl:query-params()?mode = '&ldh;ContentMode'][@about][contains-token(@class, 'block')]/descendant-or-self::*" mode="ixsl:ondragstart">
        <xsl:choose>
            <!-- allow drag on the block element (not necessarily top-level) -->
            <!-- TO-DO: better condition for checking whether blocks are top-level? -->
            <xsl:when test="self::div[contains-token(@class, 'block')][parent::div[@id = 'content-body']]">
                <ixsl:set-property name="dataTransfer.effectAllowed" select="'move'" object="ixsl:event()"/>
                <xsl:variable name="block-uri" select="@about" as="xs:anyURI"/>
                <xsl:sequence select="ixsl:call(ixsl:get(ixsl:event(), 'dataTransfer'), 'setData', [ 'text/uri-list', $block-uri ])"/>
            </xsl:when>
            <!-- prevent drag on its descendants. This makes sure that content drag-and-drop doesn't interfere with drag events in the Map and Graph modes -->
            <xsl:otherwise>
                <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- dragging block over other block -->
    
    <xsl:template match="div[@id = 'content-body']/div[ixsl:query-params()?mode = '&ldh;ContentMode'][@about][contains-token(@class, 'block')][acl:mode() = '&acl;Write']" mode="ixsl:ondragover">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <ixsl:set-property name="dataTransfer.dropEffect" select="'move'" object="ixsl:event()"/>
    </xsl:template>

    <!-- change the style of blocks when block is dragged over them -->
    
    <xsl:template match="div[@id = 'content-body']/div[ixsl:query-params()?mode = '&ldh;ContentMode'][@about][contains-token(@class, 'block')][acl:mode() = '&acl;Write']" mode="ixsl:ondragenter">
        <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'drag-over', true() ])[current-date() lt xs:date('2000-01-01')]"/>
    </xsl:template>

    <xsl:template match="div[@id = 'content-body']/div[ixsl:query-params()?mode = '&ldh;ContentMode'][@about][contains-token(@class, 'block')][acl:mode() = '&acl;Write']" mode="ixsl:ondragleave">
        <xsl:variable name="related-target" select="ixsl:get(ixsl:event(), 'relatedTarget')" as="element()?"/> <!-- the element drag entered (optional) -->

        <!-- only remove class if the related target does not have this div as ancestor (is not its child) -->
        <xsl:if test="not($related-target/ancestor-or-self::div[. is current()])">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'drag-over', false() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:if>
    </xsl:template>

    <!-- dropping block over other top-level block -->
    
    <xsl:template match="div[@id = 'content-body']/div[ixsl:query-params()?mode = '&ldh;ContentMode'][@about][contains-token(@class, 'block')][acl:mode() = '&acl;Write']" mode="ixsl:ondrop">
        <xsl:sequence select="ixsl:call(ixsl:event(), 'preventDefault', [])"/>
        <xsl:variable name="block-uri" select="@about" as="xs:anyURI?"/>
        <xsl:variable name="drop-block-uri" select="ixsl:call(ixsl:get(ixsl:event(), 'dataTransfer'), 'getData', [ 'text/uri-list' ])" as="xs:anyURI"/>
        
        <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'drag-over', false() ])[current-date() lt xs:date('2000-01-01')]"/>

        <!-- only persist the change if the block is already saved and has an @about -->
        <xsl:if test="$block-uri">
            <!-- move dropped element after this element, if they're not the same -->
            <xsl:if test="not($block-uri = $drop-block-uri)">
                <ixsl:set-style name="cursor" select="'progress'" object="ixsl:page()//body"/>

                <xsl:variable name="drop-block" select="key('element-by-about', $drop-block-uri)" as="element()"/>
                <xsl:sequence select="ixsl:call(., 'after', [ $drop-block ])"/>
                <!-- TO-DO: use a VALUES block instead -->
                <xsl:variable name="update-string" select="replace($block-swap-string, '$this', '&lt;' || ac:absolute-path(ldh:base-uri(.)) || '&gt;', 'q')" as="xs:string"/>
                <xsl:variable name="update-string" select="replace($update-string, '$targetBlock', '&lt;' || $block-uri || '&gt;', 'q')" as="xs:string"/>
                <xsl:variable name="update-string" select="replace($update-string, '$sourceBlock', '&lt;' || $drop-block-uri || '&gt;', 'q')" as="xs:string"/>
                <xsl:variable name="request-uri" select="ldh:href($ldt:base, ac:absolute-path($ldh:requestUri), map{}, ac:absolute-path(ldh:base-uri(.)))" as="xs:anyURI"/>
                <xsl:variable name="request" as="item()*">
                    <ixsl:schedule-action http-request="map{ 'method': 'PATCH', 'href': $request-uri, 'media-type': 'application/sparql-update', 'body': $update-string }">
                        <xsl:call-template name="onBlockSwap"/>
                    </ixsl:schedule-action>
                </xsl:variable>
                <xsl:sequence select="$request[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:if>
        </xsl:if>
    </xsl:template>
    
    <!-- CALLBACKS -->
    
    <xsl:function name="ldh:load-block" ixsl:updating="yes" as="map(*)">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="thunk" as="function(map(*)) as item()*"/>
        <xsl:param name="ignored" as="item()?"/>

        <xsl:sequence select="
            $thunk($context) =>
                ixsl:then(
                    ldh:hide-block-progress-bar(
                        $context,
                        ?
                        )
                    )
          "/>
    </xsl:function>
    
    <xsl:function name="ldh:hide-block-progress-bar" as="map(*)" ixsl:updating="yes">
        <xsl:param name="context" as="map(*)"/>
        <xsl:param name="ignored" as="item()?"/>
              
        <xsl:variable name="container" select="$context('container')" as="element()"/>

        <xsl:message>ldh:hide-block-progress-bar $container/@typeof: <xsl:value-of select="$container/@typeof"/></xsl:message>
        
        <!-- hide the progress bar -->
        <xsl:for-each select="$container/ancestor::div[contains-token(@class, 'span12')][contains-token(@class, 'progress')][contains-token(@class, 'active')]">
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'progress', false() ])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'progress-striped', false() ])[current-date() lt xs:date('2000-01-01')]"/>
            <xsl:sequence select="ixsl:call(ixsl:get(., 'classList'), 'toggle', [ 'active', false() ])[current-date() lt xs:date('2000-01-01')]"/>
        </xsl:for-each>
        
        <xsl:sequence select="$context"/>
    </xsl:function>
    
    <!-- block delete -->

    <xsl:template name="onBlockDelete">
        <xsl:context-item as="map(*)" use="required"/>
        <xsl:param name="block" as="element()"/>

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>

        <xsl:choose>
            <xsl:when test="?status = (200, 204)">
                <xsl:for-each select="$block">
                    <xsl:sequence select="ixsl:call(., 'remove', [])[current-date() lt xs:date('2000-01-01')]"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ 'Could not delete block' ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- block swap (drag & drop) -->
    
    <xsl:template name="onBlockSwap">
        <xsl:context-item as="map(*)" use="required"/>

        <ixsl:set-style name="cursor" select="'default'" object="ixsl:page()//body"/>
        
        <xsl:choose>
            <xsl:when test="?status = 204">
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ixsl:call(ixsl:window(), 'alert', [ 'Could not swap block' ])[current-date() lt xs:date('2000-01-01')]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>