xquery version '3.0' ;
module namespace atlas.atlas = 'atlas.atlas' ;

(:~
 : This module is a RESTXQ for Atlas
 :
 : @author emchateau
 : @since 2020-03-28
 : @version 0.1
 : @see <https://github.com/publicarchi/atlas>
 : @licence GNU General Public Licence, <http://www.gnu.org/licenses/>
 :
 :)

import module namespace rest = 'http://exquery.org/ns/restxq';
import module namespace G = 'atlas.globals' at 'globals.xqm' ;
import module namespace atlas.recipes = 'atlas.recipes' at 'recipes.xqm' ;
import module namespace atlas.serialize = 'atlas.serialize' at 'serialize.xqm' ;

declare namespace cbc = 'http://conbavil.fr/namespace' ;
declare default function namespace 'atlas.atlas' ;
declare default element namespace 'http://conbavil.fr/namespace' ;

(:~
 : resource function
 : @param $cote
 : @return
 :)
declare
  %rest:path('/files')
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
function getFiles() {
  let $files := db:open('conbavil')//cbc:files/cbc:file
  return getFilesMap($files)
};

(:~
 : resource function
 : @param $cote
 : @return
 :)
declare
  %rest:path('/files/{$id}')
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
function getFileById( $id as xs:integer) {
  let $file := db:open('conbavil')//cbc:files/cbc:file[fn:substring-after(cbc:idno, 'FRAN/F/21/') = fn:string($id)]
  return getFilesMap($file)
};

declare function getFilesMap($files as item()*) as array(*) {
  array{
    for $file in $files
    return map{
      'title' : fn:normalize-space($file/cbc:title),
      'idno' : fn:normalize-space($file/cbc:idno)
    }
  }
};

(:~
 : resource function meetings
 : @return
 :)
declare
  %rest:path('/meetings')
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
function getMeetings( ) {
  let $meetings := db:open('conbavil')//cbc:meeting
  return array{
    for $meeting in $meetings
    return map{
      'title' : fn:normalize-space($meeting/cbc:title),
      'date' : fn:normalize-space($meeting/cbc:date),
      'deliberations' : getDeliberationsMap($meeting/cbc:deliberations)
    }
  }
};

(:~
 : resource function meetings by year
 : @param $year the requested year
 : @return a meeting list by year
 :)
declare
  %rest:path('/meetings/{$id}')
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
function getMeetingById($id as xs:string) {
  let $meeting := db:open('conbavil')//cbc:meeting[cbc:date/@when=$id]
  return map{
    'title' : fn:normalize-space($meeting/cbc:title),
    'date' : fn:normalize-space($meeting/cbc:date),
    'deliberations' : getDeliberationsMap($meeting/cbc:deliberations)
  }
};

declare function getDeliberationsMap($deliberations) {
  array {
    for $deliberation in $deliberations/cbc:deliberation
    return map{
      'id' : fn:normalize-space($deliberation/@xml:id),
      'commune' : fn:string-join($deliberation/cbc:localisation/cbc:commune, ', '),
      'departement' : fn:string-join($deliberation/cbc:departement[fn:not(@type='decimal')], ', '),
      'item' : fn:normalize-space($deliberation/cbc:item),
      'page' : fn:normalize-space($deliberation/cbc:pages)
    }
  }
};

(:~
 : resource function meetings
 : @return
 :)
declare
  %rest:path('/deliberations')
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
function getDeliberations( ) {
  ''
};

(:~
 : resource function meetings by year
 : @param $year the requested year
 : @return a meeting list by year
 :)
declare
  %rest:path('/deliberations/{$id}')
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
function getDeliberationById($id as xs:integer) {
  ''
};

(:~
 : resource function random deliberation
 :
 : @return the complete data of a random deliberation
 :)
declare
  %rest:path('/atlas/random')
  %output:method('xml')
function getRandomDeliberation() {
  atlas.recipes:randomDeliberation()
};


(:~
 : resource function
 :)
declare
  %rest:path('/atlas/search')
  %output:method('html')
  %output:html-version('5.0')
function search() {
  <html>
  <h1>Recherche</h1>
  <form action="/atlas/result" method="post">
     <div>
        <label for="name">Département : </label>
        <input type="text" name="dpt" id="id" value=''/>
     </div>
     <div>
        <label for="name">Commune : </label>
        <input type="text" name="commune" id="commune" required=""/>
      </div>
      <div>
        <label for="name">Catégorie: </label>
        <input type="text" name="categorie" id="categorie" value=''/>
      </div>
      <div>
        <input type="submit" value="Envoyer"/>
      </div>
    </form>
  </html>
};

(:~
 : resource function
 :)
declare
  %rest:path('/atlas/result')
  %output:method('html')
  %output:html-version('5.0')
  %rest:POST
  %rest:form-param("dpt", "{$dpt}")
  %rest:form-param("commune", "{$commune}")
  %rest:form-param("categorie", "{$categorie}")
function result(
  $dpt as xs:string,
  $commune as xs:string,
  $categorie as xs:string
) {
  <html>
    <h1>Résultats</h1>
    <p>Termes de la recherche :
    <ul>
      <li>{$dpt}</li>
      <li>{$commune}</li>
      <li>{$categorie}</li>
    </ul>
    </p>
    {
      for $delib in atlas.recipes:search($dpt, $commune, $categorie)
      return atlas.serialize:dispatch($delib, map{})
    }
    <p><a href="/atlas/search">Revenir à la recherche</a></p>
  </html>
};


(:~
 : this function dispatches the treatment of the XML document
 :)
declare
  %output:indent('no')
function dispatch($node as node()*, $options as map(*)) as item()* {
  typeswitch($node)
    case text() return $node[fn:normalize-space(.)!='']
    case element(cbc:hi) return $node ! hi(., $options)
    case element(cbc:emph) return $node ! hi(., $options)
    default return $node ! passthru(., $options)
};

(:~
 : This function pass through child nodes (xsl:apply-templates)
 :)
declare
  %output:indent('no')
function passthru($nodes as node(), $options as map(*)) as item()* {
  for $node in $nodes/node()
  return dispatch($node, $options)
};

(:~
 : ~:~:~:~:~:~:~:~:~
 : tei inline
 : ~:~:~:~:~:~:~:~:~
 :)
declare function hi($node as element(cbc:hi)+, $options as map(*)) {
  switch ($node)
  case ($node[@rend='italic' or @rend='it']) return <em>{ passthru($node, $options) }</em>
  case ($node[@rend='bold' or @rend='b']) return <strong>{ passthru($node, $options) }</strong>
  case ($node[@rend='superscript' or @rend='sup']) return <sup>{ passthru($node, $options) }</sup>
  case ($node[@rend='underscript' or @rend='sub']) return <sub>{ passthru($node, $options) }</sub>
  case ($node[@rend='underline' or @rend='u']) return <u>{ passthru($node, $options) }</u>
  case ($node[@rend='strikethrough']) return <del class="hi">{ passthru($node, $options) }</del>
  case ($node[@rend='caps' or @rend='uppercase']) return <span calss="uppercase">{ passthru($node, $options) }</span>
  case ($node[@rend='smallcaps' or @rend='sc']) return <span class="small-caps">{ passthru($node, $options) }</span>
  default return <span class="{$node/@rend}">{ passthru($node, $options) }</span>
};

declare function emph($node as element(cbc:emph), $options as map(*)) {
  <em>{ passthru($node, $options) }</em>
};