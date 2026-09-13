---
name: next-skill-navigator
description: Use whenever the user states a goal, mission, intention or phase instead of one precise action — « fais-moi un site web », « on va attaquer la sécurité », « je veux ajouter le paiement », « il faut déployer », « on s'occupe du design » — or asks what to do next, which skill or command to use, how to proceed, where the project stands. For each suggested step it also recommends which Claude model (Haiku 4.5, Sonnet 5, Opus 5, Fable 5.1) and which effort level to run it with, so the next command costs the fewest tokens that still give a quality result. This is the default for any vague or multi-step request; skip it only for atomic requests that have a single obvious answer.
user-invocable: true
argument-hint: "[suggestions | phase | <objectif>]"
---

# Next Skill Navigator

Traduire toute intention floue en 1 à 3 commandes exécutables tout de suite, choisies
parmi les skills **réellement installés**, et justifiées par le contexte réel. Chaque
commande vient avec le modèle Claude et l'effort qui la font aboutir au meilleur coût.

Le raccourci le plus court entre l'utilisateur et son objectif est toujours une commande,
jamais un paragraphe de conseils.

## Le défaut est de suggérer

Suggérer est le comportement par défaut, y compris quand l'utilisateur n'a rien demandé.
Il ne dira jamais « propose-moi un skill » : il annonce une intention, et attend que la
première marche lui soit tendue.

Cas typiques, tous déclencheurs :

| Ce que dit l'utilisateur | Nature |
|---|---|
| « fais-moi un site web » | mission large, aucune méthode donnée |
| « on va attaquer la sécurité » | changement de phase annoncé |
| « je veux ajouter le paiement » | objectif fonctionnel |
| « il faut que je déploie ça » | intention, plusieurs chemins possibles |
| « ce composant est moche » | problème énoncé, solution ouverte |
| « et maintenant ? », « quel skill ? » | demande explicite |
| une unité de travail vient de s'achever | transition de phase |

Le bloc s'ajoute **même quand tu exécutes déjà la demande**. Faire le travail et tendre
la marche suivante ne s'excluent pas.

## La seule exclusion : la tâche atomique

Ne pas suggérer quand la demande passe les **trois** tests :

1. **Une seule action** — elle se satisfait en un geste, pas en une suite d'étapes.
2. **Un seul résultat attendu** — il n'existe pas deux façons défendables de la traiter.
3. **Aucun arbitrage** — tu n'as choisi ni approche, ni outil, ni ordre.

Si les trois sont vrais → réponse nue. Sinon → bloc de suggestion.

| Demande | Verdict |
|---|---|
| « donne-moi la météo » | atomique → pas de bloc |
| « c'est quoi la syntaxe d'un map en Rust ? » | atomique → pas de bloc |
| « renomme cette variable en `total` » | atomique → pas de bloc |
| « bonjour », « merci », « ok » | pas une demande de travail → pas de bloc |
| « fais-moi un site web » | mission → bloc |
| « corrige ce bug » | arbitrage sur la méthode → bloc |
| « optimise cette page » | plusieurs axes possibles → bloc |

En cas d'hésitation entre atomique et vague : **suggérer**. Un bloc de trop se saute des
yeux ; un bloc manquant laisse l'utilisateur chercher seul.

Deuxième et dernière exclusion : la même suggestion a déjà été faite dans les 2 derniers
tours et n'a pas été suivie. Ne pas la répéter, en proposer une autre ou aucune.

## Procédure

1. **Situer la phase.** À partir des 3 derniers échanges et de l'état du dépôt (fichiers,
   `git log -3`, `git status`), nommer l'étape SDLC en cours. En cas de doute entre deux
   phases, prendre la plus en amont : on ne teste pas ce qui n'est pas spécifié.
   Sur une mission neuve sans code existant, la phase est toujours le cadrage.
2. **Chercher dans le catalogue vivant.** La source de vérité est la liste des skills
   chargés dans la session, plus `~/.claude/skills/` et `./.claude/skills/`.
   `catalogue-phases.md` (dans ce dossier) donne les piliers curés par phase — c'est un
   raccourci, pas la source de vérité. Le lire seulement si la phase est identifiée.
3. **Filtrer.** Garder les candidats qui font avancer *le blocage actuel*, pas ceux qui
   correspondent vaguement au domaine. Éliminer ce que l'utilisateur vient déjà de faire.
4. **Vérifier avant de citer.** Un skill non vérifié n'est pas proposé :
   ```bash
   ls ~/.claude/skills/ ./.claude/skills/ 2>/dev/null | grep -i <mot-clé>
   ```
5. **Choisir modèle & effort** pour chaque suggestion retenue, avec la grille de
   `models.md` (dans ce dossier) : quatre questions sur la tâche que la commande va
   lancer, puis un plancher de qualité qu'on ne franchit jamais vers le bas.
6. **Formater** selon le contrat ci-dessous, à la toute fin de la réponse.

**Inspecter une fois, réutiliser ensuite.** Les étapes 1, 2, 4 et 5 lisent l'état du système.
Dans une session où le bloc apparaît à presque chaque tour, les refaire à chaque fois coûte
plus cher que le skill lui-même. Donc : le `git log`/`git status` de l'étape 1, la lecture
de `catalogue-phases.md`, celle de `models.md` et les `ls`/`grep` de l'étape 4 ne se
relancent que si leur résultat n'est pas déjà dans la conversation, ou si la phase a
changé depuis. Un skill déjà vérifié dans la session reste vérifié ; une grille déjà
lue reste en mémoire.

## Contrat de sortie

Le bloc est composé, dans cet ordre, de : un séparateur `---`, la ligne titre, puis
1 suggestion (3 maximum). Chaque suggestion tient sur deux lignes :

- **Ligne de commande** : la commande complète **avec ses arguments déjà remplis**, un
  tiret, puis la raison en 10-15 mots qui cite l'élément concret du travail en cours.
- **Ligne 🧠** (indentée) : le modèle et l'effort recommandés, un tiret, la raison en
  3-8 mots tirée des quatre questions de `models.md`, puis soit `✔ session courante`
  si c'est déjà le modèle en cours, soit les commandes `/model` et `/effort` prêtes à
  coller. Pas d'effort pour Haiku (il l'ignore). Si la commande dispatch des
  sous-agents, ajouter leur modèle après un point-virgule.

```
---
💡 **Prochaine étape**
1. `/test-driven-development` — verrouille la logique de facturation qu'on vient d'écrire
   🧠 Sonnet 5 · medium — spec claire, les tests rattrapent → `/model sonnet` puis `/effort medium`
2. `/security-sentinel src/api` — audite les endpoints de paiement avant la mise en prod
   🧠 Opus 5 · high — faille manquée = irréversible ✔ session courante ; sous-agents Explore → haiku
```

Les 2ᵉ et 3ᵉ suggestions n'apparaissent que si chacune ouvre un **angle différent**
(autre phase, autre arbitrage), jamais une variante du même conseil. Une seule bonne
suggestion vaut mieux que trois tièdes ; trois est un plafond, pas un objectif.

## Modèle & effort : pourquoi une ligne de plus

L'utilisateur paie chaque tour en tokens et en minutes. Le bon skill lancé sur un
modèle trop gros gaspille ; lancé sur un modèle trop petit, il produit un résultat à
refaire, ce qui coûte encore plus. La ligne 🧠 tranche ce dilemme à l'avance, au moment
où l'utilisateur choisit sa prochaine commande, c'est-à-dire au seul moment où changer
de modèle ne coûte rien.

Trois règles, détaillées dans `models.md` :

1. **Plancher de qualité d'abord, coût ensuite, temps en dernier.** Le plancher vient de
   la réversibilité de l'erreur : rattrapée par les tests → Haiku possible ; rattrapée
   par un humain qui relit → Sonnet ; difficile à annuler (schéma, prod, sécu, archi)
   → Opus ; Opus a déjà échoué ou enjeu maximal → Fable.
2. **L'effort est le levier sûr, le modèle le levier risqué.** Pour économiser, baisser
   l'effort avant de baisser le modèle.
3. **Recommander, jamais appliquer.** Le changement de modèle ou d'effort est une
   décision de coût qui appartient à l'utilisateur : donner la commande, ne pas
   l'exécuter. Les sous-agents sont l'exception naturelle : leur modèle se choisit
   par le paramètre `model` de l'outil Agent sans toucher à la session.

## Carte des phases

| Phase | Signal dans la conversation | Domaines de skills à viser |
|---|---|---|
| 1. Cadrage | idée, besoin flou, « je voudrais faire… », projet vide | brainstorming, spec, PRD, arbitrage, diagramme |
| 2. Données & backend | entités, modèle, auth, paiement, API | schéma SQL, ORM, auth, Stripe, architecture |
| 3. UI/UX | composant, page, style, écran | design system, shadcn, Tailwind, accessibilité, motion |
| 4. Logique métier | fonction, règle, refacto, commit | TDD, patterns framework, git, doc, pre-commit |
| 5. Qualité & sécu | bug, faille, « ça marche pas », avant merge | debug systématique, tests E2E, audit sécu, vérification |
| 6. Déploiement | prod, CI, Docker, lenteur, coûts | déploiement, perf, infra, observabilité |
| 7. Conversion | landing, texte, prix, lancement | copywriting, CRO, offre, vidéo |
| Méta | « je cherche un outil pour… » | recherche de skills, création de skill |

Détail des skills curés par phase : `catalogue-phases.md`.

## Installation d'un skill manquant

Si le bon outil n'existe pas localement, le dire explicitement, puis fournir :

```bash
npx skills add <source>@<skill> -g -a claude-code -y
```

et le lien `https://skills.sh/<source>/<skill>`. Ne jamais proposer la commande d'un
skill non installé comme si elle était disponible.

## Erreurs courantes

| Erreur | Correction |
|---|---|
| Attendre une question pour suggérer | L'intention suffit. « on attaque la sécu » = déclencheur. |
| Se taire parce qu'on exécute déjà la demande | Faire le travail **et** ajouter le bloc. |
| Citer un skill de mémoire sans vérifier | Un `ls`/`grep` avant chaque citation. Aucune exception. |
| Suggérer 4+ pistes | 3 maximum. Au-delà, l'utilisateur ne choisit plus, il subit. |
| Commande sans arguments (`/impeccable`) | Pré-remplir la cible réelle (`/impeccable shape src/app/pricing`). |
| Raison générique (« utile pour tester ») | Citer le fichier, la table ou la fonction concernée. |
| Proposer la phase en cours | Proposer l'étape **suivante**, ou celle qui débloque. |
| Bloc après « bonjour » ou « donne-moi la météo » | Voir les trois tests de la tâche atomique. |
| Relancer `git status`/`ls` à chaque tour | Réutiliser l'inspection déjà faite dans la session. |
| Ligne 🧠 absente, ou « Opus » partout par réflexe | Passer les quatre questions de `models.md` pour la tâche réelle. |
| Descendre sous le plancher pour économiser | Une migration ou un audit sur Haiku coûte plus cher à refaire qu'à faire. |
| Fable par défaut | Réservé aux échecs d'Opus et aux enjeux maximaux ; deux fois le prix. |
| Changer le modèle de la session soi-même | Donner `/model` et `/effort`, laisser l'utilisateur les lancer. |
| Effort affiché pour Haiku | Haiku ignore l'effort ; ne rien afficher. |

## Invocation manuelle

`/next-skill-navigator` (ou `suggestions`) : analyser le workspace (arborescence,
`git log -5`, `git status`, TODO/FIXME), annoncer la phase SDLC détectée en une phrase,
puis produire le bloc de contrat de sortie.

`/next-skill-navigator <objectif>` : partir de l'objectif décrit plutôt que de l'historique,
et donner la première commande à lancer pour l'atteindre.

`/next-skill-navigator modèle <tâche>` : ne produire que la ligne 🧠 pour la tâche
décrite, avec la réponse aux quatre questions en une phrase chacune. Utile quand le
skill à lancer est déjà connu et que seule la question du coût reste ouverte.
