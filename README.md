# next-skill-navigator

> Un skill pour **Claude Code** qui vous dit **quoi faire ensuite** : quelle commande lancer, et avec quel modèle d'IA pour obtenir un bon résultat sans gaspiller.

---

## À quoi ça sert ?

Vous avez installé des dizaines de skills dans Claude Code… et vous ne savez plus lequel lancer. Vous écrivez « je veux ajouter le paiement » ou « on attaque la sécurité », et vous vous demandez : **par où je commence ?**

`next-skill-navigator` répond à cette question. À la fin des réponses de Claude, il ajoute un petit bloc :

```
---
💡 **Prochaine étape**
1. `/test-driven-development` — verrouille la logique de facturation qu'on vient d'écrire
   🧠 Sonnet 5 · medium — spec claire, les tests rattrapent → `/model sonnet` puis `/effort medium`
```

Chaque suggestion vous donne deux choses :

1. **La commande à lancer**, avec ses arguments déjà remplis — vous n'avez qu'à la copier.
2. **Le modèle d'IA et le niveau d'effort** les moins chers qui feront quand même bien le travail (la ligne 🧠).

---

## C'est quoi, un « skill » ? *(si vous débutez)*

Imaginez un assistant très compétent, mais qui arrive chaque matin sans connaître vos habitudes. Un **skill**, c'est une **fiche de procédure** que vous posez sur son bureau : en haut, une étiquette qui dit *quand* la sortir ; en dessous, la méthode.

Concrètement, c'est un simple fichier texte `SKILL.md`, rangé dans le dossier `~/.claude/skills/`. Il n'y a pas de programme à compiler : Claude le lit, et il applique la méthode quand la situation correspond.

---

## Ce que fait le skill, étape par étape

```
1. Il situe la phase de votre projet
   (cadrage, données, interface, logique, qualité & sécurité, déploiement, lancement)
                         ↓
2. Il cherche parmi les skills que VOUS avez réellement installés
                         ↓
3. Il garde ceux qui débloquent votre situation actuelle
                         ↓
4. Il vérifie qu'ils existent avant de les citer — jamais de skill inventé
                         ↓
5. Il choisit le modèle d'IA et l'effort adaptés à la tâche
                         ↓
6. Il affiche 1 à 3 suggestions, jamais plus
```

**Il se tait** quand votre demande est une tâche simple à réponse unique (« donne-moi la météo », « renomme cette variable », « bonjour »), ou quand il vient déjà de faire la même suggestion sans que vous la suiviez.

---

## Pourquoi recommander un modèle ?

Claude Code propose plusieurs modèles d'IA. Plus un modèle est puissant, plus il coûte cher. Mais un modèle trop petit peut produire un résultat qu'il faudra refaire — ce qui coûte encore plus.

Le skill tranche avec une règle simple : **si le travail est raté, qui s'en aperçoit, et à quel prix ?**

| Si l'erreur est… | Modèle minimum |
|---|---|
| rattrapée automatiquement par les tests | Haiku |
| rattrapée par un humain qui relit | Sonnet |
| difficile à annuler (base de données, mise en production, sécurité) | Opus |
| résistante même à Opus, ou l'enjeu est maximal | Fable |

Le skill **ne change jamais le modèle à votre place** : il vous donne la commande (`/model sonnet`), c'est vous qui décidez de la lancer.

Le détail complet, avec les tarifs, est dans [`models.md`](models.md).

---

## Installation

### Ce qu'il vous faut

- **Claude Code** installé
- **macOS, Linux, ou Windows** (le script d'installation est écrit en bash — sur Windows, utilisez Git Bash ou WSL, voir plus bas)
- **git** (tapez `git --version` dans un terminal pour vérifier)

### Option 1 — Installation complète *(recommandée)*

Ouvrez un terminal et collez ces trois lignes :

```bash
git clone https://github.com/gabriel-delavaud/next-skill-navigator.git
cd next-skill-navigator
bash install.sh
```

Puis **redémarrez Claude Code**.

> ⚠️ **À savoir avant de lancer `install.sh`**
>
> Le script fait deux choses :
>
> 1. Il copie le skill dans `~/.claude/skills/next-skill-navigator/`.
> 2. **Il ajoute un paragraphe à votre fichier `~/.claude/CLAUDE.md`** — le fichier de préférences globales de Claude. Ce paragraphe demande à Claude d'utiliser le skill **automatiquement**, dès que vous lui confiez du travail.
>
> Il le fait prudemment : il sauvegarde d'abord votre fichier en `CLAUDE.md.bak`, il ne remplace rien, et il n'ajoute jamais le paragraphe deux fois. Mais c'est bien un changement du comportement de Claude **dans tous vos projets**. Si vous ne le voulez pas, prenez l'option 2.

### Option 2 — Installation minimale *(sans toucher à `CLAUDE.md`)*

```bash
git clone https://github.com/gabriel-delavaud/next-skill-navigator.git ~/.claude/skills/next-skill-navigator
```

Puis redémarrez Claude Code.

**La différence :** le skill est disponible, vous pouvez le lancer avec `/next-skill-navigator`, et Claude peut le déclencher de lui-même quand votre demande correspond à sa description. Mais Claude n'a pas reçu la consigne de s'en servir **systématiquement**.

### Installation sur Windows

`install.sh` est un script bash : Windows n'a pas nativement de quoi l'exécuter. Deux façons d'y arriver :

**Git Bash *(recommandé, aucune installation de plus)***

[Git pour Windows](https://git-scm.com/download/win) installe l'exécutable `git` **et** un terminal Git Bash capable d'exécuter des scripts bash. Ouvrez **Git Bash** (menu Démarrer → « Git Bash ») et collez exactement les mêmes commandes que l'option 1 ou l'option 2 ci-dessus — elles fonctionnent sans aucune modification.

**WSL (Windows Subsystem for Linux)**

Si vous avez déjà WSL (`wsl --install` dans PowerShell en administrateur si ce n'est pas le cas, puis redémarrez), ouvrez un terminal WSL (Ubuntu par défaut) et suivez les instructions macOS/Linux ci-dessus telles quelles : `~/.claude/skills/` y désigne le dossier de votre utilisateur Linux, qui est bien celui que lit Claude Code sous WSL.

**PowerShell, sans Git Bash ni WSL**

Seule l'option 2 (installation minimale) est possible sans bash, car elle se limite à un `git clone`. PowerShell n'interprète pas `~`, remplacez-le par `$HOME` :

```powershell
git clone https://github.com/gabriel-delavaud/next-skill-navigator.git "$HOME\.claude\skills\next-skill-navigator"
```

Puis redémarrez Claude Code. L'option 1 (script `install.sh`, ajout automatique du paragraphe dans `CLAUDE.md`) nécessite Git Bash ou WSL : sans bash, faites-le à la main en ajoutant vous-même le paragraphe **« Navigation méthodologique — suggérer est le défaut »** (visible plus haut dans le bloc de code de la section *À quoi ça sert ?*) à la fin de `%USERPROFILE%\.claude\CLAUDE.md`.

### Vérifier que ça marche

Dans Claude Code, ouvert sur un de vos projets, tapez :

```
/next-skill-navigator
```

Vous devez voir une phrase qui nomme la phase du projet, suivie d'un bloc **💡 Prochaine étape**.

---

## Utilisation

| Ce que vous tapez | Ce qu'il fait |
|---|---|
| *(rien — option 1)* | le bloc apparaît de lui-même quand vous confiez du travail |
| `/next-skill-navigator` | analyse votre projet et propose la suite |
| `/next-skill-navigator <objectif>` | part de l'objectif décrit, ex. `/next-skill-navigator ajouter le paiement Stripe` |
| `/next-skill-navigator modèle <tâche>` | ne donne que la ligne 🧠 : quel modèle pour cette tâche précise |

---

## Les fichiers du dépôt

| Fichier | Rôle |
|---|---|
| `SKILL.md` | le skill lui-même : quand suggérer, comment, dans quel format |
| `models.md` | la grille de choix du modèle et de l'effort |
| `catalogue-phases.md` | un catalogue de skills classés par phase de projet — voir la limite ci-dessous |
| `install.sh` | le script d'installation complète (option 1) |
| `evals/evals.json` | des scénarios de test du comportement, pour qui veut améliorer le skill |

---

## Limites à connaître

- **`catalogue-phases.md` reflète l'installation de l'auteur** (220 skills). Chez vous, beaucoup n'existeront pas. C'est sans danger : le skill vérifie toujours qu'un skill est réellement installé avant de le proposer, et ce catalogue n'est qu'un raccourci. Aucun script de régénération n'est fourni pour l'instant.
- **Les modèles et tarifs de `models.md` sont datés** (septembre 2026). Quand Anthropic change sa gamme, le fichier doit être mis à jour à la main.
- **Le bloc s'ajoute à beaucoup de réponses.** C'est voulu, mais si ça vous encombre, l'option 2 le rend moins systématique.
- **Conçu pour Claude Code**, qui fournit les commandes `/model` et `/effort`.

---

## Désinstaller

```bash
rm -rf ~/.claude/skills/next-skill-navigator
```

Sous Windows en PowerShell (sans Git Bash ni WSL) :

```powershell
Remove-Item -Recurse -Force "$HOME\.claude\skills\next-skill-navigator"
```

Si vous aviez pris l'option 1, ouvrez aussi `~/.claude/CLAUDE.md` (`%USERPROFILE%\.claude\CLAUDE.md` sous Windows) et supprimez le paragraphe **« Navigation méthodologique — suggérer est le défaut »**. Si vous n'avez rien modifié d'autre dans ce fichier depuis l'installation, vous pouvez à la place restaurer la sauvegarde :

```bash
mv ~/.claude/CLAUDE.md.bak ~/.claude/CLAUDE.md
```

```powershell
Move-Item -Force "$HOME\.claude\CLAUDE.md.bak" "$HOME\.claude\CLAUDE.md"
```

---

## Voir aussi

[**skillscout**](https://github.com/gabriel-delavaud/skillscout) — pour *trouver et installer* un nouveau skill en toute sécurité, quand celui dont vous avez besoin n'est pas encore sur votre machine.

---

## Licence

[MIT](LICENSE) — vous pouvez utiliser, modifier et redistribuer ce skill librement, en conservant la notice de licence.
