# Grille modèle & effort

Compagnon de `SKILL.md`. Sert à remplir la ligne 🧠 sous chaque suggestion du bloc.
Grille figée le 2026-09-12 à partir de la table de tarifs du skill `claude-api` ; si un
modèle cité ici n'existe plus ou qu'un nouveau est sorti, mettre à jour ce fichier avant
de le citer — jamais recommander un modèle de mémoire.

## Les quatre modèles

| Modèle | Alias `/model` | Prix relatif (entrée / sortie) | Contexte | Effort | Ce qu'il apporte |
|---|---|---|---|---|---|
| Haiku 4.5 | `haiku` | 1× / 1× ($1 / $5 par M tokens) | 200K | non réglable (tourne comme `high`) | Vitesse. Exécute ce qui est déjà décidé et vérifiable. |
| Sonnet 5 | `sonnet` | 2× / 2× ($2 / $10) | 1M | low → max | Le rapport qualité/prix par défaut pour implémenter quelque chose de spécifié. |
| Opus 5 | `opus` | 5× / 5× ($5 / $25) | 1M | low → max | Jugement : conception, arbitrage, debug non trivial, revue. |
| Fable 5.1 | `fable` | 10× / 10× ($10 / $50) | 1M | low → max | Raisonnement le plus profond, sessions autonomes longues. Un tour peut durer plusieurs minutes. |

Deux faits qui gouvernent tout le reste :

- **Le coût se juge par tâche terminée, pas par requête.** Un modèle moins cher qui
  s'y reprend à trois fois, ou dont il faut relire et corriger la sortie, coûte plus
  cher qu'un modèle capable du premier coup. D'où le plancher de qualité ci-dessous.
- **L'effort ne change pas le prix du token, il change combien de tokens sont
  produits** (réflexion, nombre d'appels d'outils, longueur des tours). Baisser
  l'effort sur une tâche simple est le levier le moins risqué ; baisser le modèle sur
  une tâche irréversible est le plus risqué.

## Le plancher de qualité : quatre questions, dans cet ordre

Répondre aux quatre questions pour la tâche que la suggestion va lancer, pas pour le
projet en général. Chaque « oui » monte le plancher ; on ne descend jamais en dessous.

1. **Si c'est raté, qui s'en aperçoit et à quel prix ?**
   - Les tests, le lint, un diff court ou un `git revert` rattrapent l'erreur →
     plancher **Haiku**.
   - Rattrapable seulement par un humain qui relit (texte, UI, doc, copy) → plancher
     **Sonnet**.
   - Difficile ou coûteux à annuler : migration de schéma, suppression, publication,
     paiement, secret, règle de sécurité, choix d'architecture → plancher **Opus**.
2. **Y a-t-il quelque chose à décider, ou seulement à exécuter ?** Spec claire, un
   seul bon résultat → le plancher suffit. Compromis à arbitrer, ambiguïté à lever,
   cause inconnue à trouver → au moins **Opus**.
3. **Combien de temps le modèle doit-il tenir seul ?** Une action ou quelques fichiers
   → le plancher suffit. Une session autonome multi-fichiers, multi-heures, avec des
   décisions en chaîne → **Opus xhigh**, et **Fable** si les décisions sont
   structurantes.
4. **Opus a-t-il déjà échoué dessus, ou l'enjeu est-il maximal ?** Bug qui résiste,
   audit de sécurité avant une mise en prod à fort trafic, conception d'un système
   entier → **Fable**. Sinon, Fable est un gaspillage : deux fois le prix d'Opus pour
   une tâche qu'Opus finit aussi bien.

## Choisir l'effort

| Effort | Quand | Effet |
|---|---|---|
| `low` | Sous-agents d'exploration, tâches mécaniques, réponses courtes, formatage | Moins d'appels d'outils, moins de préambule, tours brefs |
| `medium` | Implémentation cadrée où la spec est claire et testée | Bon compromis quand la qualité tient à ce niveau |
| `high` | Implémentation avec un peu d'arbitrage, revue, debug ordinaire | Le point d'équilibre qualité / tokens sur la plupart du code |
| `xhigh` | Travail agentique long, plusieurs fichiers, décisions en chaîne | Défaut de Claude Code ; nécessaire sur Fable / Opus / Sonnet 5 pour l'agentique |
| `max` | La justesse compte plus que le coût : sécurité, données, bug résistant | À réserver aux cas où `xhigh` a montré ses limites |

Nuances utiles :

- Sur les modèles récents, un effort bas produit souvent une qualité équivalente à un
  modèle de la génération précédente à effort haut. Avant de monter de modèle, tester
  d'abord le modèle courant à effort plus bas sur le même type de tâche.
- Haiku ignore l'effort : ne pas afficher d'effort pour lui.
- Le mode `/fast` (Opus seulement) double le prix pour accélérer la sortie ; ne le
  suggérer que si l'utilisateur attend devant l'écran et que le tour est long.

## Sous-agents

C'est là que l'économie est la plus grande et la plus sûre : le modèle de la session
ne change pas, seul celui du sous-agent est choisi via le paramètre `model` de l'outil
Agent (`haiku`, `sonnet`, `opus`, `fable`).

| Rôle du sous-agent | Modèle | Pourquoi |
|---|---|---|
| Explorer, chercher, lire du code, résumer | `haiku` | Beaucoup de lecture, peu de décision, résultat vérifiable |
| Implémenter une tâche cadrée, écrire des tests, générer du boilerplate | `sonnet` | Qualité suffisante pour du code spécifié, 2,5× moins cher qu'Opus |
| Revoir, auditer, planifier, arbitrer, jouer un conseil | `opus` | La valeur du sous-agent est son jugement |
| Résoudre ce sur quoi les autres ont échoué | `fable` | Réservé, coûteux, et lent |

Quand le skill suggéré dispatch des sous-agents (`subagent-driven-development`,
`dispatching-parallel-agents`, `llm-council`, `Explore`, `Plan`), la ligne 🧠 donne
le modèle de l'orchestrateur **et** celui des sous-agents.

## Table de correspondance par famille de tâche

Raccourci pour les cas fréquents. Le raisonnement en quatre questions prime en cas de
doute ; cette table ne le remplace pas.

| Famille de tâche (exemples de skills) | Modèle | Effort | Raison courte |
|---|---|---|---|
| Cadrage, spec, PRD, grill, arbitrage (`brainstorming`, `prd`, `grill-me`, `llm-council`) | Opus | high | décisions structurantes, peu de tokens |
| Conception données / archi / auth / paiement (`domain-modeling`, `db-whisperer`, `auth-architect`, `stripe-best-practices`) | Opus | high → xhigh | erreurs coûteuses à annuler |
| Implémentation cadrée avec tests (`test-driven-development`, `executing-plans`) | Sonnet | medium → high | spec claire, tests rattrapent |
| UI depuis un design system existant (`shadcn`, `tailwind-design-system`) | Sonnet | medium | résultat visible, réversible |
| Direction artistique, finitions (`impeccable`, `emil-design-eng`, `frontend-design`) | Opus | high | goût et jugement |
| Debug ordinaire (`systematic-debugging`) | Opus | high | cause inconnue à trouver |
| Bug qui résiste après un passage Opus (`quantum-debugger`) | Fable | xhigh | Opus a échoué |
| Revue de code, audit sécu avant merge (`code-review`, `security-sentinel`, `security-audit`) | Opus | high → max | une faille manquée est irréversible |
| Tests E2E, couverture (`playwright-generate-test`, `pytest-coverage`) | Sonnet | medium | mécanique, vérifiable |
| Commit, branche, doc, pre-commit (`git-commit`, `documentation-writer`, `setup-pre-commit`) | Haiku | — | mécanique, diff court |
| Déploiement, CI, Docker (`deploy-to-vercel`, `multi-stage-dockerfile`, `deploy-ninja`) | Opus | high | prod = irréversible |
| Perf, observabilité (`performance`, `vercel-optimize`, `obs-guardian`) | Sonnet | high | mesurable, réversible |
| Copywriting, CRO, premier jet (`copywriting`, `cro`, `stop-slop`) | Sonnet | medium | relu par un humain de toute façon |
| Recherche de skills, catalogue (`find-skills`) | Haiku | — | recherche pure |
| Création de skill (`skill-creator`, `writing-skills`) | Opus | high | conception d'instructions réutilisées mille fois |

## Comment remplir la ligne 🧠

1. Identifier la tâche que la commande suggérée va réellement lancer (pas le domaine).
2. Passer les quatre questions → plancher → modèle.
3. Choisir l'effort avec la table ci-dessus.
4. Comparer au modèle de la session courante (connu par le prompt système). Identique
   → cocher « session courante », pas de commande. Différent → donner `/model <alias>`
   et `/effort <niveau>` prêts à coller.
5. Si la suggestion dispatch des sous-agents, ajouter leur modèle.

Ne jamais changer le modèle ou l'effort de la session soi-même : c'est une décision de
coût qui appartient à l'utilisateur, et un tour ne peut de toute façon pas se relancer
sur un autre modèle.
