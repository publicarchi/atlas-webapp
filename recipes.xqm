xquery version '3.0' ;
module namespace atlas.recipes = 'atlas.recipes' ;

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
declare default function namespace 'atlas.recipes' ;

(:~ 
 : This function return meetings by years
 :
 : @param $year searched years
 : @return meetings from a given sequence of years
 :)
declare function meetingsByYears( $years as xs:integer* ) as element()* {
  let $cbc := db:open('cbc')
  return $cbc//cbc:meeting[ fn:year-from-date(cbc:date/@when) = xs:integer($years) ]
};

(:~ 
 : This function return number of meetings by years
 :
 : @param $year searched year
 : @return number of meetings from a given sequence of years
 :)
declare function nbMeetingsByYears( $year as xs:integer* ) as xs:integer* {
  let $cbc := db:open('cbc')
  return fn:count($cbc//cbc:meeting[ fn:year-from-date(cbc:date/@when) = $year ])
};

(:~ 
 : This function return number of meetings by years
 :
 : @return number of meetings from a given sequence of years
 : @todo regex pour intervalle
 :)
declare function listNbMeetingsByYears($years as xs:string*) as array(*) {
  let $cbc := db:open('cbc')
  
  return switch ($years)
  case $years = '' return array {
    for $meeting in $cbc//cbc:meeting
    group by $year := fn:year-from-date($meeting/cbc:date/@when)
    return map{
        'année' : $year,
        'quantité' : fn:count($meeting)
      }
  }
  case fn:contains($years, '-') return ''
  default return array {
    for $year in $years
    return map{
        'année' : $year,
        'quantité' : fn:count($cbc//cbc:meeting[fn:year-from-date(cbc:date/@when) = xs:integer($year)])
      }
  }
};

(:~ 
 : This function return number of deliberations by building category
 :
 : @return number of deliberations by building category
 :
 : @todo optimiser temps de traitement
:)
declare function listNbDeliberationsByCategory() as array(*) {
  let $cbc := db:open('cbc')
  let $categories := fn:distinct-values($cbc//cbc:deliberation/cbc:categories/cbc:category[@type="buildingCategory"]) 
  return array {
    for $category in $categories 
    let $deliberations := $cbc//cbc:deliberation[cbc:categories/cbc:category[@type="buildingCategory"][text()= $category]]
    order by fn:count($deliberations)
    return map{
        'building category' : $category,
        'quantity' : fn:count($deliberations)
      }
  }
};

(:~ 
 : This function returns a random deliberation 
 :
 : @return complete description of a random deliberation

:)
declare function randomDeliberation() {
  let $cbc := db:open('cbc')
  let $max := (fn:count($cbc//cbc:deliberation)-1)
  let $fiche:= $cbc//cbc:deliberation[random:integer($max)+1]
  
  return $fiche
};

(:~ 
 : This function execute a search in the db
 : @param $dpt departement
 : @param $commune city
 : @param $categorie building category
 : @return a list of deliberations
 :)
declare function search($dpt as xs:string, $commune as xs:string, $categorie as xs:string) as element()* {
  let $cbc := db:open('conbavil')
  return 
    (:Seule la commune est renseignée:)
    if (fn:not($dpt = '') and fn:not($categorie = '')) then
      for $delibs in $cbc//cbc:deliberation[cbc:localisation/cbc:commune[.=$commune] and cbc:categories/cbc:category[@type="buildingCategory"][text()=$categorie]]
      where $cbc//cbc:deliberation[cbc:localisation/cbc:departement[.=$dpt]]
      return $delibs
    (:Le département et la commune sont renseignés mais la catégorie est vide:)
    else if (($categorie = '') and fn:not($dpt= '')) then 
        for $delibs in $cbc//cbc:deliberation[cbc:localisation/cbc:commune[.=$commune]]
        where $cbc//cbc:deliberation[cbc:localisation/cbc:departement[.=$dpt]]
        return $delibs 
     (:La catégorie et la commune sont renseignés mais le département est vide:)
     else if (($dpt ='') and fn:not($categorie = '')) then
        for $delibs in $cbc//cbc:deliberation[cbc:localisation/cbc:commune[.=$commune]]
        where $cbc//cbc:deliberation[cbc:categories/cbc:category[@type="buildingCategory"][text()=$categorie]]
        return $delibs  
     (:Tout est renseigné:)
     else
        for $delibs in $cbc//cbc:deliberation[cbc:localisation/cbc:commune[.=$commune]]
        return $delibs   
}; 
 
 