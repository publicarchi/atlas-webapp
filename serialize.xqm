xquery version '3.0' ;
module namespace atlas.serialize = 'atlas.serialize' ;

(:~
 : This module is a RESTXQ for Atlas
 :
 : @author emchateau
 : @since 2020-04-20
 : @version 0.1
 : @see <https://github.com/publicarchi/atlas>
 : @licence GNU General Public Licence, <http://www.gnu.org/licenses/>
 :
 :)

import module namespace rest = 'http://exquery.org/ns/restxq';
import module namespace G = 'atlas.globals' at 'globals.xqm' ;

declare namespace cbc = 'http://conbavil.fr/namespace' ;
declare default function namespace 'atlas.serialize' ;

(:~
 : this function dispatches the treatment of the XML document
 :)
declare function dispatch($node as node()*, $options as map(*)) as item()* {
  typeswitch($node)
    case text() return $node
    case element(cbc:deliberation) return deliberation($node, $options)
    case element(cbc:title) return title($node, $options)
    case element(cbc:localisation) return localisation($node, $options)
    case element(cbc:report) return report($node, $options)
    case element(cbc:recommendation) return recommendation($node, $options)
    case element(cbc:categories) return categories($node, $options)
    case element(cbc:author) return author($node, $options)
    case element(cbc:div) return div($node, $options)
    case element(cbc:p) return p($node, $options)
    case element(cbc:item) return ''
    case element(cbc:pages) return ''
    default return passthru($node, $options)
};

(:~
 : This function pass through child nodes (xsl:apply-templates)
 :)
declare function passthru($nodes as node(), $options as map(*)) as item()* {
  for $node in $nodes/node()
  return dispatch($node, $options)
};

declare function deliberation($node, $options) {
  (
    <article id="{$node/@xml:id/fn:data()}">{
        (
          <label>{$node/@xml:id/fn:data()}</label>, 
          passthru($node, $options)
        )
    }</article>,
    <hr/>
  )
};

(:~
 : @todo treat text 
 :)
declare function title($node, $options) {
  <h2>{$node/text()}</h2>
};

declare function localisation($node, $options) {
  <h3>{(
    <emph>{$node/cbc:commune}</emph>,
    fn:concat(
      ' – ',
      $node/cbc:departement[fn:not(@type)],
      ' (',
      $node/cbc:departement[@type='decimal'],
      ')'
    )
  )}</h3>
};

declare function report($node, $options) {
  <div>{$node}</div>
};

declare function recommendation($node, $options) {
  <div>{$node}</div>
};

declare function categories($node, $options) {
  <list>{
    for $node in $node/cbc:category
    return <li>{$node/text()} </li>
  }</list>
};

declare function author($node, $options) {
  <label>{$node}</label>
};

declare function div($node, $options) {
  <div>{$node}</div>
};

declare function p($node, $options) {
  <p>{$node}</p>
};

