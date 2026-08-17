import 'package:evobusiness/coeur/logos.dart';
import 'package:flutter_test/flutter_test.dart';

/// L'icône d'écran d'accueil se fabrique à partir du logo choisi. Deux règles
/// d'Apple s'y appliquent : fond plein — aucune transparence — et pas de coins
/// arrondis, iOS posant son propre masque.
void main() {
  group('Icône d\'écran d\'accueil', () {
    test('chaque piste de logo produit une icône carrée et pleine', () {
      for (final piste in pistesLogo) {
        final svg = logoSvgIcone(piste.cle, fond: '#6E1F46', accent: '#D9B45B');
        expect(svg, startsWith('<svg '), reason: piste.cle);
        expect(svg, contains('width="180" height="180"'), reason: piste.cle);
        // Le fond plein : c'est lui qui interdit la transparence.
        expect(svg, contains('<rect width="96" height="96" fill="#6E1F46"/>'),
            reason: piste.cle);
        expect(svg, endsWith('</svg>'), reason: piste.cle);
        // Aucun coin arrondi sur le carré de fond.
        expect(svg.contains('<rect width="96" height="96" fill="#6E1F46" rx'),
            isFalse, reason: piste.cle);
      }
    });

    test('l\'icône reprend bien la couleur de la marque', () {
      final prune = logoSvgIcone('boucle', fond: '#6E1F46', accent: '#D9B45B');
      final autre = logoSvgIcone('boucle', fond: '#1F4E46', accent: '#C08552');
      expect(prune, contains('#6E1F46'));
      expect(autre, contains('#1F4E46'));
      expect(autre, isNot(contains('#6E1F46')));
    });

    test('deux logos différents donnent deux icônes différentes', () {
      final couronne = logoSvgIcone('couronne', fond: '#6E1F46', accent: '#D9B45B');
      final boucle = logoSvgIcone('boucle', fond: '#6E1F46', accent: '#D9B45B');
      expect(couronne, isNot(equals(boucle)));
    });

    test('le monogramme porte les initiales, les autres pistes non', () {
      final mono = logoSvgIcone('monogramme',
          fond: '#6E1F46', accent: '#D9B45B', initiales: 'CA');
      expect(mono, contains('>CA<'));

      final boucle = logoSvgIcone('boucle',
          fond: '#6E1F46', accent: '#D9B45B', initiales: 'CA');
      expect(boucle, isNot(contains('>CA<')));
    });

    test('sans nom, le monogramme ne porte aucune lettre', () {
      final svg = logoSvgIcone('monogramme',
          fond: '#6E1F46', accent: '#D9B45B', initiales: initialesDe(''));
      expect(svg, isNot(contains('<text')));
    });

    test('le dessin garde une marge : iOS rogne les coins', () {
      final svg = logoSvgIcone('couronne', fond: '#6E1F46', accent: '#D9B45B');
      // Le logo est replacé dans un carré intérieur, jamais bord à bord.
      expect(svg, contains('x="18.24" y="18.24"'));
      expect(svg, contains('width="59.52" height="59.52"'));
    });
  });
}
