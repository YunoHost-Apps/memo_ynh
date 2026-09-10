## Où se trouvent les choses

| Quoi | Où |
| --- | --- |
| Le code, le runtime bun, node_modules | `/var/www/memo` |
| Tous les tableaux, dans un fichier SQLite | `/home/yunohost.app/memo/memo.sqlite` |
| Configuration | `/var/www/memo/.env` |
| Journal | `/var/log/memo/memo.log` |

Supprimer l'application laisse les tableaux en place. C'est
`yunohost app remove memo --purge` qui les efface.

## Comptes

Qui a la permission arrive déjà connecté, sous son nom YunoHost. memo ne crée
aucune session de son côté : se déconnecter du portail déconnecte aussi de
memo, et il n'y a pas de second mot de passe à gérer.

L'inverse vaut aussi. Le bouton « Déconnexion » de memo passe par la
déconnexion du portail, donc il ferme la session YunoHost et pas seulement
celle que memo croit avoir. Vous revenez sur la page quittée et le SSO vous
redemande de vous connecter. La redirection qui fait ça est dans la config
nginx de l'application, dans `/etc/nginx/conf.d/votre.domaine.d/memo.conf`.
Retirez-la et le bouton ne sert plus à rien : le cookie du portail reste en
place et vous reconnecte aussitôt.

Le lien « Connexion » n'apparaît que si vous ouvrez la permission aux
visiteurs, et il est redirigé de la même façon, vers le portail puis retour sur
memo une fois la personne connectée. Les deux redirections sont réécrites à
chaque mise à jour et à chaque `yunohost app change-url`.

Le compte choisi à l'installation a reçu la page d'administration de memo, sur
`https://votre.domaine/memo/admin`, qui liste, cherche et supprime les tableaux
et gère les comptes. Ce droit n'est accordé qu'une fois, tant que memo n'a
aucun admin. Modifier le réglage ensuite ne fait rien. Pour ajouter ou retirer
un admin plus tard, passez par cette page.

Les groupes YunoHost ne sont pas transmis : `ADMIN_GROUP` et le partage de
tableau par groupe n'ont rien à lire. Partagez un tableau privé nom par nom.

## Configuration

Trois réglages ont un panneau de configuration : la langue par défaut de
l'interface, et une URL de logo et de favicon pour remplacer ceux de memo. Tout
le reste est dans `/var/www/memo/.env`, un `CLÉ=valeur` par ligne, documenté
dans [le README de memo](https://codeberg.org/mrflos/memo#options). Après
modification :

```bash
systemctl restart memo
```

Une mise à jour réécrit ce fichier depuis le modèle du paquet. YunoHost voit
qu'il a changé, en garde une copie à côté, et vous dit où. Les trois réglages
du panneau survivent, YunoHost les stocke à part et les remet.

## Quand personne n'est connecté

Si memo voit tout le monde comme anonyme, la chaîne à vérifier est courte.
SSOwat pose `YNH_USER` sur la requête à partir du cookie du portail ; la config
nginx de l'app le transforme en l'en-tête `Remote-User` que memo lit. Cette
traduction, ce sont ces deux lignes de
`/etc/nginx/conf.d/votre.domaine.d/memo.conf` :

```nginx
proxy_set_header Remote-User $http_ynh_user;
proxy_set_header Remote-Name $http_ynh_user_fullname;
```

et elle n'a lieu que parce que la permission le demande, avec
`main.auth_header = true` dans le manifeste. Si l'en-tête n'arrive jamais,
faites lire à memo les noms de SSOwat directement : mettez
`PROXY_USER_HEADER=ynh_user` et `PROXY_NAME_HEADER=ynh_user_fullname` dans
`.env`, redémarrez, et retirez les deux lignes nginx.

## Sauvegardes

L'archive emporte tout le répertoire d'installation, dont une centaine de Mo de
runtime bun et de node_modules. Une restauration n'a alors besoin d'aucun
réseau. Si vous sauvegardez toutes les nuits et que la taille gêne, sauvegardez
le répertoire de données seul : les tableaux, c'est tout ce qu'il contient, et
une réinstallation suivie d'une restauration de `$data_dir` vous ramène au même
point.

## Architecture

Bun ne publie de binaires que pour x86-64 et aarch64. Une carte armhf ou une
machine 32 bits ne peut pas faire tourner ce paquet. Le binaire x86-64 livré
ici est le « baseline », qui fonctionne sur des processeurs antérieurs à 2013,
un peu moins vite.
