xquery version "3.1";

(:~ 
: Ce document main permet d'utiliser les librairies de fonctions de project.xqm, root.xqm et project_metadata.xqm de DoTS
: @author École nationale des chartes - Philippe Pons
: @since 2023-06-23
: @version  1.0
:)

import module namespace cc = "https://github.com/chartes/dots/schema/utils/cc" at "utils/project.xqm";
import module namespace ccg = "https://github.com/chartes/dots/schema/utils/ccg" at "utils/root.xqm";
import module namespace cc2 = "https://github.com/chartes/dots/schema/utils/cc2" at "utils/project_metadata.xqm";

(:~ 
Cette fonction est la fonction principale de la librairie. Elle permet de:
: - créer ou mettre à jour la base de données BaseX "config" (qui sert de poste d'aiguillage)
: - créer le fichier de configuration (config.xml) de la base de données XML de son choix, comprenant éventuellement des métadonnées complémentaires
:
: Prérequis:
: - avoir créer une base de données XML dans BaseX 
: - s'assurer que les fichiers TEI de la base disposent bien d'un attribut @xml:id sur l'élément <TEI/>
:
: Résultat:
: - les fichiers de configuration créés permettent de rendre fonctionnel l'API DTS pour les urls suivantes: /api/dts/collections et /api/dts/document
:
: Paramètres (5):
: - $bdd: nom de la base de données XML dans BaseX (ex. "e-NDP", "ENCPOS")
: - $title: titre de la base de données (ex. "Positions de thèse")
: - $path: la valeur de ce paramètre doit être une chaîne de caractère vide "". Ce paramètre sert à parcourir la structure arborescente d'une base de données si nécessaire
: - $compteur: la valeur de ce paramètre doit être 0. Ce paramètre, combiné avec l'argument $path, permet d'identifier le niveau d'une collection dans le cas d'une structure arborescente.
: - $boolean: ce paramètre boolean permet de spécifier si la commande doit aller chercher des métadonnées supplémentaires pour compléter le fichier de configuration. Si la valeur est true(), il faut s'asurer au préalable qu'un fichier declaration.xml est présent dans la base de données $bdd
:
: Exemple: cc:create_config("e-NDP", "Édition des registres de Notre-Dame de Paris", "", 0, true())
:)
cc:create_config("", "", "", 0, false())







