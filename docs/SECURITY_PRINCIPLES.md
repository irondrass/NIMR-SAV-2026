# Principes de sécurité

- Supabase Auth est l’unique mécanisme de session.
- La RLS est activée et testée sur toutes les tables métier.
- Aucune clé service, mot de passe ou token n’est stocké dans le dépôt.
- `localStorage` est réservé aux préférences UI non sensibles.
- Les rôles et permissions sont contrôlés côté interface pour l’ergonomie et côté PostgreSQL pour la sécurité réelle.
- Les actions critiques sont confirmées, atomiques et auditables.
- Les imports hors ligne ne pourront jamais être affichés comme approuvés/importés avant validation serveur.
