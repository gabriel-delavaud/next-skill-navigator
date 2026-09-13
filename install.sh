#!/usr/bin/env bash
# next-skill-navigator — installation sur une nouvelle machine.
# Idempotent : relancable sans risque. Ne remplace jamais un CLAUDE.md existant,
# il y ajoute seulement le bloc s'il est absent (avec sauvegarde .bak).
set -euo pipefail

DIR="$HOME/.claude/skills/next-skill-navigator"
mkdir -p "$DIR"

cat > "$DIR/SKILL.md" <<'NSN_SKILL_EOF'
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
NSN_SKILL_EOF

cat > "$DIR/catalogue-phases.md" <<'NSN_CAT_EOF'
# Catalogue des skills installés, par phase SDLC

Généré automatiquement depuis `~/.claude/skills/` — chaque description est reprise du
`SKILL.md` réel du skill, jamais réécrite de mémoire.

**220 skills** au total. Ce fichier est un **raccourci**, pas la source de vérité :
le catalogue vivant fait foi. Vérifie toujours l'existence d'un skill avant de le citer.

> Régénérer après chaque fournée d'installations, sinon ce fichier prend du retard.

---

## Phase 1 : Cadrage Produit, Idéation & Spécifications
*22 skills*

- `/ask-matt` : Ask which skill or flow fits your situation.
- `/brainstorming` : You MUST use this before any creative work - creating features, building components, adding functionality, or…
- `/competitor-profiling` : When the user wants to research, profile, or analyze competitors from their URLs.
- `/customer-research` : When the user wants to conduct, analyze, or synthesize customer research.
- `/domain-modeling` : Build and sharpen a project's domain model.
- `/excalidraw-diagram-generator` : Generate Excalidraw diagrams from natural language descriptions.
- `/firecrawl-agent` : Autonomous multi-page extraction into structured JSON.
- `/ghost-scraper` : Extracts structured data from websites — static HTML, JavaScript-rendered SPAs, paginated listings, and…
- `/grill-me` : A relentless interview to sharpen a plan or design.
- `/grill-with-docs` : A relentless interview to sharpen a plan or design, which also creates docs (ADR's and glossary) as we go.
- `/grilling` : Grill the user relentlessly about a plan, decision, or idea.
- `/llm-council` : Convoque un conseil de 5 agents Claude indépendants, dans Claude Code uniquement, qui répondent séparément à…
- `/loop-me` : Grill me about specs for the workflows I want to build, within this workspace.
- `/prd` : Generate high-quality Product Requirements Documents (PRDs) for software systems and AI-powered features.
- `/project-development` : This skill should be used for project-level decisions about LLM-powered systems: whether an LLM is the right…
- `/prototype` : Build a throwaway prototype to answer a design question.
- `/research` : Investigate a question against high-trust primary sources and capture the findings as a Markdown file in the repo.
- `/to-questionnaire` : Turn a decision you can't fully answer into a questionnaire for someone else to fill in.
- `/to-spec` : Turn the current conversation into a spec and publish it to the project issue tracker: no interview, just…
- `/to-tickets` : Break a plan, spec, or the current conversation into a set of tracer-bullet tickets, each declaring its…
- `/wayfinder` : Plan a huge chunk of work (more than one agent session can hold) as a shared map of decision tickets on your…
- `/writing-plans` : Use when you have a spec or requirements for a multi-step task, before touching code

## Phase 2 : Architecture Données, Schémas & Conception Backend
*21 skills*

- `/agents-sdk` : Build, debug, or review Cloudflare Agents SDK applications using the agents package.
- `/api-sculptor` : Designs and implements APIs: REST, GraphQL, gRPC, and WebSocket.
- `/auth-architect` : Designs and implements authentication and identity systems.
- `/better-auth-best-practices` : Configure Better Auth server and client, set up database adapters, manage sessions, add plugins, and handle…
- `/clerk-nextjs-patterns` : Advanced Next.js patterns - middleware, Server Actions, caching with Clerk.
- `/codebase-design` : Shared vocabulary for designing deep modules.
- `/db-whisperer` : Diagnoses and improves application-layer databases: Postgres, MySQL, SQLite, and MongoDB.
- `/mcp-builder` : Guide for creating high-quality MCP (Model Context Protocol) servers that enable LLMs to interact with external…
- `/mcp-conductor` : Decomposes complex tasks into subtasks and coordinates multiple tools or agents to execute them.
- `/neon` : Overview of Neon, a complete set of cloud backend primitives for apps and agents, spanning Lakebase Postgres,…
- `/neon-postgres` : Guides and best practices for working with Lakebase Postgres, the database behind Neon.
- `/organization-best-practices` : Configure multi-tenant organizations, manage members and invitations, define custom roles and permissions, set…
- `/pipeline-architect` : Designs and implements data pipelines: ETL/ELT, streaming, batch processing, schema migrations, and data…
- `/prisma-cli` : Prisma ORM CLI commands reference covering init, generate, migrate, db, dev, complete, studio, validate,…
- `/prisma-client-api` : Prisma Client API reference covering model queries, filters, operators, and client methods.
- `/prisma-database-setup` : Guides for configuring Prisma with different database providers (PostgreSQL, MySQL, SQLite, MongoDB, etc.).
- `/setup-ts-deep-modules` : Wire dependency-cruiser into a TypeScript repo so each package is a deep module, with implementation hidden in…
- `/stripe-best-practices` : Guides Stripe integration decisions across API selection (Checkout Sessions vs PaymentIntents), Connect…
- `/supabase` : Use when doing ANY task involving Supabase.
- `/supabase-postgres-best-practices` : Postgres best practices maintained by Supabase, for Postgres running anywhere.
- `/two-factor-authentication-best-practices` : Configure TOTP authenticator apps, send OTP codes via email/SMS, manage backup codes, handle trusted devices,…

## Phase 3 : Design Système, UI/UX & Intégration Frontend
*29 skills*

- `/accessibility` : Audit and improve web accessibility following WCAG 2.2 guidelines.
- `/animate` : Build an animation from scratch, making the decisions in the order that determines whether it feels right —…
- `/apple-design` : Apple's approach to interface design and fluid, physical motion, translated for the web.
- `/banner-design` : Design banners for social media, ads, website heroes, creative assets, and print.
- `/canvas-design` : Create beautiful visual art in .png and .pdf documents using design philosophy.
- `/design` : Comprehensive design skill: brand identity, design tokens, UI styling, logo generation (55 styles, Gemini,…
- `/design-system` : Token architecture, component specifications, and slide generation.
- `/design-taste-frontend` : Anti-slop frontend skill for landing pages, portfolios, and redesigns.
- `/emil-design-eng` : This skill encodes Emil Kowalski's philosophy on UI polish, component design, animation decisions, and the…
- `/expo-dev-client` : Framework (OSS).
- `/expo-router` : Framework (OSS).
- `/frontend-design` : Guidance for distinctive, intentional visual design when building new UI or reshaping an existing one.
- `/gsap-react` : Official GSAP skill for React — useGSAP hook, refs, gsap.context(), cleanup.
- `/high-end-visual-design` : Teaches the AI to design like a high-end agency.
- `/i18n-expert` : This skill should be used when setting up, auditing, or enforcing internationalization/localization in UI…
- `/impeccable` : Use when the user wants to design, redesign, shape, critique, audit, polish, clarify, distill, harden,…
- `/nextjs-app-router-patterns` : Master Next.js 14+ App Router with Server Components, streaming, parallel routes, and advanced data fetching.
- `/pick-ui-library` : Pick the right library for a given frontend task from a curated, opinionated list — numbers, OTP inputs,…
- `/review-animations` : Reviews animation and motion code against a high craft bar derived from Emil Kowalski's design engineering…
- `/shadcn` : Manages shadcn components and projects — adding, searching, fixing, debugging, styling, and composing UI,…
- `/tailwind-design-system` : Build scalable design systems with Tailwind CSS v4, design tokens, component libraries, and responsive patterns.
- `/ui-styling` : Create beautiful, accessible user interfaces with shadcn/ui components (built on Radix UI + Tailwind), Tailwind…
- `/ui-ux-pro-max` : UI/UX design intelligence for web, mobile, and desktop.
- `/vercel-composition-patterns` : React composition patterns that scale.
- `/vercel-react-best-practices` : React and Next.js performance optimization guidelines from Vercel Engineering.
- `/vercel-react-native-skills` : React Native and Expo best practices for building performant mobile apps.
- `/vercel-react-view-transitions` : Guide for implementing smooth, native-feeling animations using React's View Transition API (`<ViewTransition>`…
- `/web-artifacts-builder` : Suite of tools for creating elaborate, multi-component claude.ai HTML artifacts using modern frontend web…
- `/web-design-guidelines` : Review UI code for Web Interface Guidelines compliance.

## Phase 4 : Développement Fonctionnel, Logique Métier & TDD
*22 skills*

- `/claude-handoff` : Hand the current conversation off to a fresh background agent that picks up the work immediately.
- `/documentation-writer` : Diátaxis Documentation Expert.
- `/executing-plans` : Use when you have a written implementation plan to execute in a separate session with review checkpoints
- `/finishing-a-development-branch` : Use when implementation is complete, all tests pass, and you need to decide how to integrate the work
- `/git-commit` : Execute git commit with conventional commit message analysis, intelligent staging, and message generation.
- `/git-flow-branch-creator` : Intelligent Git Flow branch creator that analyzes git status/diff and creates appropriate branches following…
- `/git-guardrails-claude-code` : Set up Claude Code hooks to block dangerous git commands (push, reset --hard, clean, branch -D, etc.) before…
- `/handoff` : Compact the current conversation into a handoff document for another agent to pick up.
- `/implement` : Implement a piece of work based on a spec or set of tickets.
- `/implement-spec` : Implement a specification in code.
- `/improve-codebase-architecture` : Scan a codebase for deepening opportunities, present them as a visual HTML report, then grill through whichever…
- `/migrate-to-shoehorn` : Migrate test files from `as` type assertions to @total-typescript/shoehorn.
- `/resolving-merge-conflicts` : Use when you need to resolve an in-progress git merge/rebase conflict.
- `/retro` : Conduct a retrospective on a coding session.
- `/scaffold-exercises` : Create exercise directory structures with sections, problems, solutions, and explainers that pass linting.
- `/setup-pre-commit` : Set up Husky pre-commit hooks with lint-staged (Prettier), type checking, and tests in the current repo.
- `/subagent-driven-development` : Use when executing implementation plans with independent tasks in the current session
- `/tdd` : Test-driven development.
- `/test-driven-development` : Use when implementing any feature or bugfix, before writing implementation code
- `/typescript-advanced-types` : Master TypeScript's advanced type system including generics, conditional types, mapped types, template…
- `/using-git-worktrees` : Use when starting feature work that needs isolation from current workspace or before executing implementation…
- `/wizard` : Generate an interactive bash wizard that walks a human through steps only they can perform.

## Phase 5 : Sécurité Applicative, Tests, Revue & Débogage Profond
*20 skills*

- `/advanced-evaluation` : This skill should be used for advanced LLM evaluation: LLM-as-judge systems, direct scoring, pairwise…
- `/agent-browser` : Browser automation CLI for AI agents.
- `/code-review` : Review the changes since a fixed point (commit, branch, tag, or merge-base) along two axes: Standards (does the…
- `/code-review-and-quality` : Conducts multi-axis code review.
- `/diagnosing-bugs` : Diagnosis loop for hard bugs and performance regressions.
- `/evaluation` : This skill should be used when building agent evaluation systems: deterministic checks, regression suites,…
- `/firebase-security-rules-auditor` : Audits Firebase (Firestore, Cloud Storage) security rules for vulnerabilities, privilege escalation, role…
- `/google-agents-cli-eval` : This skill should be used when the user wants to "run an evaluation", "evaluate my agent", "evaluate my ADK…
- `/playwright-cli` : Automate browser interactions, test web pages and work with Playwright tests.
- `/playwright-generate-test` : Generate a Playwright test based on a scenario using Playwright MCP
- `/pytest-coverage` : Run pytest tests with coverage, discover lines missing coverage, and increase coverage to 100%.
- `/quantum-debugger` : Debugs complex, hard-to-reproduce issues: race conditions, memory leaks, deadlocks, performance regressions,…
- `/receiving-code-review` : Use when receiving code review feedback, before implementing suggestions, especially if feedback seems unclear…
- `/requesting-code-review` : Use when completing tasks, implementing major features, or before merging to verify work meets requirements
- `/security-audit` : Security audit of a codebase — web apps, APIs, services, CLI tools, libraries, daemons, and more.
- `/security-sentinel` : Performs security audits, vulnerability assessments, SSL/TLS hardening, DNSSEC configuration, and compliance…
- `/systematic-debugging` : Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes
- `/triage` : Move issues and external PRs through a state machine of triage roles, categorise, verify, grill if needed, and…
- `/verification-before-completion` : Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires…
- `/webapp-testing` : Toolkit for interacting with and testing local web applications using Playwright.

## Phase 6 : Performance, Déploiement & Infrastructure DevOps
*11 skills*

- `/azure-kubernetes` : Plan, create, and configure production-ready Azure Kubernetes Service (AKS) clusters.
- `/create-github-action-workflow-specification` : Create a formal specification for an existing GitHub Actions CI/CD workflow, optimized for AI consumption and…
- `/deploy-ninja` : Handles zero-downtime deployments: blue-green, canary releases, rolling updates, and feature flag rollouts.
- `/deploy-to-vercel` : Deploy applications and websites to Vercel.
- `/infra-automation` : Manages infrastructure operations: DNS records, SSL certificates, Cloudflare Workers, CDN configuration, and…
- `/multi-stage-dockerfile` : Create optimized multi-stage Dockerfiles for any language or framework
- `/obs-guardian` : Builds observability, monitoring, alerting, and incident visibility for production systems.
- `/performance` : Optimize web performance for faster loading and better user experience.
- `/python-appservice-deploy` : Deploy Python (Flask/Django/FastAPI) code to Azure App Service Linux.
- `/vercel-cli-with-tokens` : Deploy and manage projects on Vercel using token-based authentication.
- `/vercel-optimize` : Use for Vercel cost and performance optimization on deployed projects, especially Next.js, SvelteKit, Nuxt, and…

## Phase 7 : Copywriting, Conversion, Growth & Lancement
*70 skills*

- `/ab-testing` : When the user wants to plan, design, or implement an A/B test or experiment, or build a growth experimentation…
- `/ad-creative` : When the user wants to generate, iterate, or scale ad creative — headlines, descriptions, primary text, or full…
- `/ads` : When the user wants help with paid advertising campaigns on Google Ads, Meta (Facebook/Instagram), LinkedIn,…
- `/ai-seo` : When the user wants to optimize content for AI search engines, get cited by LLMs, or appear in AI-generated…
- `/analytics` : When the user wants to set up, improve, or audit analytics tracking and measurement.
- `/aso` : When the user wants to audit or optimize an App Store or Google Play listing.
- `/attribution` : When the user wants to figure out which marketing actually drives conversions and revenue, choose or interpret…
- `/brand` : Brand voice, visual identity, messaging frameworks, asset management, brand consistency.
- `/churn-prevention` : When the user wants to reduce churn, build cancellation flows, set up save offers, recover failed payments, or…
- `/co-marketing` : When the user wants to find co-marketing partners, plan joint campaigns, or brainstorm partnership opportunities.
- `/cold-email` : Write B2B cold emails and follow-up sequences that get replies.
- `/community-marketing` : Build and leverage online communities to drive product growth and brand loyalty.
- `/competitors` : When the user wants to create competitor comparison or alternative pages for SEO and sales enablement.
- `/content-strategy` : When the user wants to plan a content strategy, decide what content to create, or figure out what topics to cover.
- `/copy-editing` : When the user wants to edit, review, or improve existing marketing copy, or refresh outdated content.
- `/copywriting` : When the user wants to write, rewrite, or improve marketing copy for any page — including homepage, landing…
- `/cro` : When the user wants to optimize, improve, or increase conversions on any marketing page or form — including…
- `/directory-submissions` : When the user wants to submit their product to startup, SaaS, AI, agent, MCP, no-code, or review directories…
- `/emails` : When the user wants to create or optimize an email sequence, drip campaign, automated email flow, or lifecycle…
- `/events` : When the user wants to plan, run, sponsor, speak at, or get pipeline from events — webinars, conferences, trade…
- `/free-tools` : When the user wants to plan, evaluate, or build a free tool for marketing purposes — lead generation, SEO…
- `/image` : When the user wants to create, generate, edit, or optimize images for marketing — blog heroes, social graphics,…
- `/influencer-marketing` : When the user wants to run influencer, creator, or ambassador partnerships to promote their product — finding…
- `/launch` : When the user wants to plan a product launch, feature announcement, or release strategy.
- `/lead-magnets` : When the user wants to create, plan, or optimize a lead magnet for email capture or lead generation.
- `/marketing-council` : When the user wants multiple expert perspectives on a marketing question — a simulated board of advisors…
- `/marketing-ideas` : When the user needs marketing ideas, inspiration, or strategies for their SaaS or software product.
- `/marketing-loops` : When the user wants to set up a recurring, self-running marketing workflow — a repeatable loop an AI agent runs…
- `/marketing-plan` : When the user needs a comprehensive marketing plan for a client, a company they advise, or their own product.
- `/marketing-psychology` : When the user wants to apply psychological principles, mental models, or behavioral science to marketing.
- `/marketing-skills` : Pack marketing tout-en-un par Corey Haines (50 skills) : audit SEO, copywriting, optimisation CRO, séquences…
- `/offers` : When the user wants to design, construct, or improve an offer — the thing they actually sell — including value…
- `/onboarding` : When the user wants to optimize post-signup onboarding, user activation, first-run experience, or time-to-value.
- `/paywalls` : When the user wants to create or optimize in-app paywalls, upgrade screens, upsell modals, or feature gates.
- `/popups` : When the user wants to create or optimize popups, modals, overlays, slide-ins, or banners for conversion purposes.
- `/pricing` : When the user wants help with pricing decisions, packaging, or monetization strategy.
- `/product-marketing` : When the user wants to create or update their product marketing context document.
- `/programmatic-seo` : When the user wants to create SEO-driven pages at scale using templates and data.
- `/prospecting` : When the user wants to find, qualify, and build a list of prospects to reach out to — across B2B SaaS, general…
- `/public-relations` : When the user wants help with public relations, earned media, press coverage, journalist outreach, or media…
- `/referrals` : When the user wants to create, optimize, or analyze a referral program, affiliate program, or word-of-mouth…
- `/remotion` : Framework vidéo programmatique officiel Remotion : création, animation, sous-titres, studio et rendu de vidéos…
- `/remotion-best-practices` : Router for all Remotion skills
- `/remotion-captions` : Transcribing, displaying and animating captions
- `/remotion-create` : Create a new Remotion video
- `/remotion-docs` : Search Remotion documentation
- `/remotion-interactivity` : Structure Remotion markup for interactivity
- `/remotion-maps` : Remotion Map animation knowledge
- `/remotion-markup` : Content, animation and effects best practices
- `/remotion-multimedia` : Interacting with Mediabunny
- `/remotion-render` : Export a Remotion video
- `/remotion-saas` : Build an app with Remotion
- `/remotion-skills` : Framework vidéo programmatique officiel Remotion : création, animation, sous-titres, studio et rendu de vidéos…
- `/remotion-studio` : Preview a Remotion video
- `/remotion-upgrade` : Upgrade Remotion, and related packages
- `/revops` : When the user wants help with revenue operations, lead lifecycle management, or marketing-to-sales handoff…
- `/sales-enablement` : When the user wants to create sales collateral, pitch decks, one-pagers, objection handling docs, or demo scripts.
- `/schema` : When the user wants to add, fix, or optimize schema markup and structured data on their site.
- `/seo-audit` : When the user wants to audit, review, or diagnose SEO issues on their site.
- `/signup` : When the user wants to optimize signup, registration, account creation, or trial activation flows.
- `/site-architecture` : When the user wants to plan, map, or restructure their website's page hierarchy, navigation, URL structure, or…
- `/slides` : Create strategic HTML presentations with Chart.js, design tokens, responsive layouts, copywriting formulas, and…
- `/sms` : When the user wants to plan, build, or optimize SMS or MMS marketing — including welcome flows, abandoned cart…
- `/social` : When the user wants help creating, scheduling, or optimizing social media content for LinkedIn, Twitter/X,…
- `/stop-slop` : Remove AI writing patterns from prose.
- `/video` : When the user wants to create, generate, or produce video content using AI tools or programmatic frameworks.
- `/writing-beats` : Writing, exploit; assemble raw material into a journey of beats, grounding each term before a beat leans on it.
- `/writing-fragments` : Writing, explore: mine raw fragments, no structure yet.
- `/writing-guidelines` : Review docs/prose for Writing Guidelines compliance.
- `/writing-shape` : Writing, exploit: shape raw material into an article, paragraph by paragraph.

## Méta-Outils : Skills, Agents & Ingénierie de Contexte
*25 skills*

- `/bdi-mental-states` : This skill should be used when modeling agent mental states with BDI concepts: beliefs, desires, intentions,…
- `/context-compression` : This skill should be used when long-running agent sessions need context compression, structured summarization,…
- `/context-degradation` : This skill should be used for diagnosing and mitigating context degradation: lost-in-middle failures, context…
- `/context-engineering` : Framework d'ingénierie et d'optimisation de contexte : réduction de tokens, compression d'historique,…
- `/context-fundamentals` : This skill should be used to explain or reason about the foundational concepts of context engineering: what…
- `/context-optimization` : This skill should be used for improving context efficiency: context budgeting, observation masking, prefix or…
- `/filesystem-context` : This skill should be used when agent work needs file-backed context: durable scratchpads, tool-output…
- `/find-skills` : Helps users discover and install agent skills when they ask questions like "how do I do X", "find a skill for…
- `/harness-engineering` : This skill should be used when designing autonomous agent harnesses: research loops, evaluation scaffolds,…
- `/hosted-agents` : This skill should be used when designing hosted or background agent infrastructure: sandboxed execution, remote…
- `/latent-briefing` : This skill should be used when the user asks to "share memory between agents", "KV cache compaction for…
- `/long-horizon-prompting` : This skill should be used when writing, enhancing, or evaluating the launch prompt for a long-running…
- `/memory-systems` : This skill should be used for persistent semantic memory in agent systems: cross-session knowledge retention,…
- `/multi-agent-patterns` : This skill should be used when designing multi-agent systems that need context isolation, supervisor or swarm…
- `/next-skill-navigator` : Use whenever the user states a goal, mission, intention or phase instead of one precise action — « fais-moi un…
- `/prediction-alpha` : Analyzes prediction markets: Polymarket, Manifold Markets, Kalshi.
- `/prompt-forge` : Engineers and optimizes prompts for LLMs: system prompts, few-shot examples, chain-of-thought structures, agent…
- `/self-improvement-loops` : This skill should be used when the harness, scaffold, workflow, or optimizer itself is the optimization target:…
- `/setup-matt-pocock-skills` : Configure this repo for the engineering skills: set up its issue tracker, triage label vocabulary, and domain…
- `/skill-creator` : Create new skills, modify and improve existing skills, and measure skill performance.
- `/teach` : Teach the user a new skill or concept, within this workspace.
- `/tool-design` : This skill should be used for the tool-interface layer of an agent system specifically: writing tool…
- `/wait-what` : Stop.
- `/writing-for-agents` : Writing documents for agents.
- `/writing-skills` : Use when creating new skills, editing existing skills, or verifying skills work before deployment
NSN_CAT_EOF

cat > "$DIR/models.md" <<'NSN_MODELS_EOF'
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
NSN_MODELS_EOF

CLAUDE_MD="$HOME/.claude/CLAUDE.md"
if [ -f "$CLAUDE_MD" ] && grep -q "next-skill-navigator" "$CLAUDE_MD"; then
  echo "CLAUDE.md : bloc deja present, fichier non modifie."
else
  if [ -f "$CLAUDE_MD" ]; then
    cp "$CLAUDE_MD" "$CLAUDE_MD.bak"
    echo "" >> "$CLAUDE_MD"
    echo "CLAUDE.md : sauvegarde en CLAUDE.md.bak, bloc ajoute a la suite."
  else
    echo '# Préférences globales' > "$CLAUDE_MD"
    echo "" >> "$CLAUDE_MD"
    echo "CLAUDE.md : cree."
  fi
  cat >> "$CLAUDE_MD" <<'NSN_CLAUDE_EOF'
## Navigation méthodologique — suggérer est le défaut

Invoque le skill `next-skill-navigator` dès que je te donne du travail, **sans attendre
que je le demande**. Cela couvre aussi bien les questions explicites (« et maintenant ? »,
« quel skill ? », « par quoi je commence ? ») que les simples intentions (« fais-moi un
site web », « on va attaquer la sécurité », « je veux ajouter le paiement », « il faut
déployer », « ce composant est moche »).

N'invoque pas le skill uniquement si ma demande passe les trois tests de la tâche
atomique : une seule action, un seul résultat possible, aucun arbitrage de méthode.
Exemples de tâches atomiques : « donne-moi la météo », « c'est quoi la syntaxe de X ? »,
« renomme cette variable ». Les salutations et réactions courtes n'en sont pas non plus.

En cas d'hésitation entre atomique et vague : invoque le skill.
NSN_CLAUDE_EOF
fi

echo
echo "  $DIR/SKILL.md"
echo "  $DIR/catalogue-phases.md"
echo "  $DIR/models.md"
echo "  $CLAUDE_MD"
echo
echo "Redemarre Claude Code : la regle globale n'est lue qu'au demarrage d'une session."
