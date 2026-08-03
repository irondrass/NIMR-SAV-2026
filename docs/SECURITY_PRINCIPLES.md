# Principes de sécurité

- Supabase Auth est l’unique mécanisme de session.
- La RLS est activée et testée sur toutes les tables métier.
- Aucune clé service, mot de passe ou token n’est stocké dans le dépôt.
- `localStorage` est réservé aux préférences UI non sensibles.
- Les rôles et permissions sont contrôlés côté interface pour l’ergonomie et côté PostgreSQL pour la sécurité réelle.
- Les actions critiques sont confirmées, atomiques et auditables.
- Les imports hors ligne ne pourront jamais être affichés comme approuvés/importés avant validation serveur.
# Principes sécurité phase 3A

RLS deny-by-default, privilèges SQL minimaux, périmètre organisation/site
explicite, audit append-only et bucket privé sont obligatoires. `ADMIN_TECHNIQUE`
est une exception globale contrôlée ; `DIRECTEUR_SAV` reste limité à ses sites
attribués. Les imports sont réservés aux rôles métier explicitement autorisés.

Le frontend n’accepte que la clé anon/publishable ; la clé serveur à privilèges,
les secrets et les tokens ne doivent jamais apparaître dans le bundle ou les
logs. Les fichiers sources sont conservés et non supprimables par les rôles
applicatifs.
