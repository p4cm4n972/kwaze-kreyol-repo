# Configuration Supabase Realtime pour les Amis

## 🚨 IMPORTANT - À faire immédiatement

Pour que les notifications temps réel des demandes d'amis fonctionnent, vous **DEVEZ** activer la réplication Supabase sur les tables suivantes :

- `friend_requests`
- `friend_invitations`
- `friendships`

## Méthode 1 : Via SQL (Recommandé - Plus rapide)

1. Allez sur votre **Supabase Dashboard**
2. Ouvrez le **SQL Editor**
3. Copiez et exécutez cette commande :

```sql
-- Activer la réplication pour les tables d'amis
ALTER PUBLICATION supabase_realtime ADD TABLE friend_requests;
ALTER PUBLICATION supabase_realtime ADD TABLE friend_invitations;
ALTER PUBLICATION supabase_realtime ADD TABLE friendships;
```

4. Cliquez sur **RUN** (F5)

## Méthode 2 : Via l'Interface Supabase

1. Allez sur votre **Supabase Dashboard**
2. Naviguez vers **Database → Replication**
3. Dans la liste des tables, **cochez** les cases suivantes :
   - ✅ `friend_requests`
   - ✅ `friend_invitations`
   - ✅ `friendships`
4. Les changements sont automatiquement sauvegardés

## Vérification

Une fois la réplication activée :

1. **Utilisateur 1** se connecte et reste sur la page d'accueil
2. **Utilisateur 2** se connecte et envoie une demande d'ami à Utilisateur 1
3. **Utilisateur 1** devrait voir **immédiatement** :
   - Un badge rouge avec le chiffre "1" sur son avatar (en haut à droite)
   - Le badge apparaît aussi dans le menu "Mes Amis"

## Dépannage

Si les notifications ne fonctionnent toujours pas après activation :

1. **Vérifiez la réplication** : Retournez dans Database → Replication et assurez-vous que les 3 tables sont cochées
2. **Rechargez la page** : Faites F5 sur l'application Flutter
3. **Vérifiez les logs** : Ouvrez la console développeur et cherchez des erreurs Supabase
4. **Reconnectez-vous** : Déconnectez et reconnectez les deux utilisateurs

## Architecture

Les notifications temps réel fonctionnent de la manière suivante :

```
Utilisateur 2 envoie demande
        ↓
INSERT dans friend_requests (receiver_id = Utilisateur 1)
        ↓
Supabase Realtime détecte le changement (grâce à la réplication)
        ↓
WebSocket envoie notification à Utilisateur 1
        ↓
GamesHomeScreen.subscribeToFriendRequests() reçoit l'événement
        ↓
Badge rouge apparaît sur l'avatar de Utilisateur 1
```

## Tables concernées

### `friend_requests`
- Demandes d'amitié entre utilisateurs
- Statut : pending, accepted, declined
- Notifications envoyées au `receiver_id`

### `friend_invitations`
- Invitations par email
- Statut : sent, accepted, expired
- Notifications envoyées à l'`inviter_id`

### `friendships`
- Relations d'amitié confirmées
- Bidirectionnelles (user_id_a < user_id_b)
- Utilisé pour le leaderboard et invitations de jeux

## Support

Si vous rencontrez des problèmes, vérifiez :
- ✅ Les RLS policies sont correctes (déjà configurées dans la migration)
- ✅ La réplication est activée (cette étape)
- ✅ Les utilisateurs sont bien authentifiés
- ✅ Le serveur Flutter est redémarré après les modifications
