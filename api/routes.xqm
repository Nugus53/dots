xquery version "3.1";

(:~ 
: Ce module regroupe les urls à servir pour la mise en oeuvre de l'API DTS
: @author École nationale des chartes - Philippe Pons
: @since 2023-05-15
: @version  1.0
:)

module namespace routes="https://github.com/chartes/dots/api/routes";

import module namespace functx = "http://www.functx.com";
import module namespace G = "https://github.com/chartes/dots/globals" at "../globals.xqm";
import module namespace utils = "https://github.com/chartes/dots/api/utils" at "utils.xqm";

declare namespace dots = "https://github.com/chartes/dots/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:~  
: Cette fonction gère le point d'entrée de l'API DTS
: @return réponse JSON pour le endpoint EntryPoint
: @see https://distributed-text-services.github.io/specifications/Entry.html#base-api-endpoint
:)
declare
  %rest:path("/api/dts")
  %rest:GET
  %output:method("json")
  %rest:produces("application/ld+json")
  %output:json("format=attributes")
function routes:entryPoint() {
 <json type="object">
   <pair name="@context">https://distributed-text-services.github.io/specifications/context/1-alpha1.json</pair>
   <pair name="dtsVersion">1-alpha</pair>
   <pair name="@id">/api/dts</pair>
   <pair name="@type">EntryPoint</pair>
   <pair name="collection">{string("/api/dts/collection/{?id,nav}")}</pair>
   <pair name="navigation">{string("/api/dts/navigation/{?resource,ref,start,end,down,tree}")}</pair>
   <pair name="documents">{string("/api/dts/document/{?resource,ref,start,end,tree,mediaType}")}</pair>
 </json>
};

(:~  
: Cette fonction gère le endpoint Collection. Elle dispatche vers les fonctions permettant de donner les informations concernants la/les collection(s) DTS existante(s) si le paramètre $id n'est pas précisé. Sinon, les informations concernant la collection DTS identifiée par le paramètre $id
: @return réponse JSON pour le endpoints Collection de la spécification d'API DTS
: @param $id chaîne de caractère qui permet d'identifier une collection DTS
: @param $nav chaîne de caractère dont la valeur est children (par défaut) ou parents. Ce paramètre permet de définir si les membres à lister sont les enfants ou les parents
: @see https://distributed-text-services.github.io/specifications/Collections-Endpoint.html
: @see utils.xqm;utils:collectionById
: @see utils.xqm;utils:collections
:) 
declare
  %rest:path("/api/dts/collection")
  %rest:GET
  %output:method("json")
  %rest:produces("application/ld+json")
  %output:json("format=attributes")
  %rest:query-param("id", "{$id}", "")
  %rest:query-param("nav", "{$nav}", "")
  %rest:query-param("filter", "{$filter}")
function routes:collections($id as xs:string, $nav as xs:string, $filter) {
  if (db:exists($G:dots))
  then 
    if ($id)
    then
      let $dbName := normalize-space(db:get($G:dots)//dots:member/node()[@dtsResourceId = $id]/@dbName)
      return
        if ($dbName != "") 
        then 
          utils:collectionById($id, $nav, $filter)
        else
          routes:badIdResource(xs:string($id))
     else
       utils:collections()
  else
    utils:noCollection()
};

(:~  
: Cette fonction gère le endpoint Navigation. Elle dispatche vers les fonctions permettant de donner les informations du endpoint Navigation pour la collection $id
: @return réponse JSON pour le endpoint Navigation de la spécification d'API DTS
: @param $id chaîne de caractère qui permet d'identifier une collection DTS
: @param $ref chaîne de caractère qui permet d'identifier un élément citable dans le document
: @param $start chaîne de caractère. Identifiant du premier élément d'une séquence
: @param $end chaîne de caractère. Identifiant du dernier élément d'une séquence 
: @param $down entier qui permet de spécifier la profondeur des membres descendant attendus dans la réponse d'API
: @see https://distributed-text-services.github.io/specifications/Navigation-Endpoint.html
: @todo revoir la gestion des erreurs HTTP 4XX. Particulièrement après avoir mieux intégré le param 'tree'
:) 
declare
  %rest:path("/api/dts/navigation")
  %rest:GET
  %output:method("json")
  %rest:produces("application/ld+json")
  %output:json("format=attributes")
  %rest:query-param("resource", "{$resource}", "")
  %rest:query-param("ref", "{$ref}", "")
  %rest:query-param("start", "{$start}", "")
  %rest:query-param("end", "{$end}", "")
  %rest:query-param("tree", "{$tree}", "")
  %rest:query-param("down", "{$down}", "-2")
  %rest:query-param("filter", "{$filter}", "")
function routes:navigation($resource as xs:string, $ref as xs:string, $start as xs:string, $end as xs:string, $tree as xs:string, $filter, $down as xs:integer) {
  if (not($resource) or ($ref and ($start or $end)) or ($start and not($end)) or ($end and not($start)) )
  then
    let $message := "Error 400 : Bad request"
    return
      web:error(400, $message)
  else
    let $dbName := normalize-space(db:get($G:dots)//dots:member/node()[@dtsResourceId = $resource]/@dbName)
    return
      if ($dbName != "") 
      then 
        if($down != -2)
        then
          utils:navigation($resource, $ref, $start, $end, $tree, $filter, $down) 
        else
          let $query := request:query()
          return
            if (contains($query, "ref=") or contains($query, "start=") or contains($query, "filter="))
            then
              utils:navigation($resource, $ref, $start, $end, $tree, $filter, $down) 
            else
             web:redirect(concat("/api/dts/navigation?", request:query(), "&amp;down=1"))
      else
        routes:badIdResource(xs:string($resource))

};

(:~ 
: Cette fonction gère le endpoint Document. Elle permet de renvoyer un document ou un fragment du document XML identifié par le paramètre $id
: @return réponse XML-TEI pour les endpoints Document de la spécification d'API DTS
: @param $id chaîne de caractère qui permet d'identifier le document XML (obligatoire)
: @param $ref chaîne de caractère qui permet d'identifier un élément citable dans le document
: @param $start chaîne de caractère. Identifiant du premier élément d'une séquence
: @param $end chaîne de caractère. Identifiant du dernier élément d'une séquence 
: @param $format chaîne de caractère pour spécifier le format de sortie attendu. Les formats possibles sont: XML (par défaut), html et txt.
: @see https://distributed-text-services.github.io/specifications/Documents-Endpoint.html
:)
declare
  %rest:path("/api/dts/document")
  %rest:GET
  %output:method("xml")
  %rest:produces("application/tei+xml")
  %rest:query-param("resource", "{$resource}", "")
  %rest:query-param("ref", "{$ref}", "")
  %rest:query-param("start", "{$start}", "")
  %rest:query-param("end", "{$end}", "")
  %rest:query-param("tree", "{$tree}", "")
  %rest:query-param("mediaType", "{$mediaType}", "")
  %rest:query-param("filter", "{$filter}", "")
  %rest:query-param("excludeFragments", "{$excludeFragments}", false())
function routes:document($resource as xs:string, $ref as xs:string, $start as xs:string, $end as xs:string, $tree as xs:string, $mediaType as xs:string, $filter, $excludeFragments as xs:boolean) {
  let $mapMedia := $G:xsl
  return 
  if (not($resource) or ($ref and ($start or $end)) or ($start and not($end)) or ($end and not($start)) or ($filter and $excludeFragments) )
  then
    let $message := "Error 400 : Bad request"
    return
      web:error(400, $message)
  else
    let $dbName := db:get($G:dots)//dots:member/node()[@dtsResourceId = $resource]/@dbName
    return
      if ($dbName) 
      then 
        let $result := utils:document($resource, $ref, $start, $end, $tree, $filter, $excludeFragments)
        let $arg := map:entry('urlQuery',request:query())       
        return
          if ($mediaType)
          then 
            if (map:contains($mapMedia,$mediaType))
            then(
                let $contentType := map:get(map:get($mapMedia,$mediaType),'Content-Type')
                let $style := map:get(map:get($mapMedia,$mediaType),'xsl')
                let $result := switch (map:get(map:get($mapMedia,$mediaType),'method'))
                case 'text' 
                   return xslt:transform-text($result, $style, $arg)
                case 'xml' 
                   return xslt:transform($result, $style, $arg)
               default
                     return "unknown"
                return 
                (
                <rest:response>
                  <http:response status="200">
                    <http:header name="Content-Type" value="{concat($contentType)}"/>
                  </http:response> 
                </rest:response>,
                  $result))
            else(
                 <rest:response>
                  <http:response status="200">
                    <http:header name="Content-Type" value="application/xml+tei"/>
                  </http:response>
                </rest:response>,
                $result
            )
          else
            $result
      else
        routes:badIdResource(xs:string($resource))
};

declare 
  %rest:error("err:badIdResource")
  %rest:error-param("description", "{$id}")
function routes:badIdResource($id) {
  let $message :=
    if ($id)
    then concat("Error 400 : resource ID ", "'", $id, "' not found")
    else "Error 400 : no resource ID specified"
  return
    web:error(400, $message)
};

