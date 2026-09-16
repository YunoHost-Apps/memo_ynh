## Où se trouvent les choses

| Quoi | Où |
| --- | --- |
| Le binaire memo, avec toutes les pages et polices dedans | `/var/www/memo/memo` |
| Tous les tableaux, dans un fichier SQLite | `/home/yunohost.app/memo/memo.sqlite` |
| Les instantanés pris depuis la page d'administration | `/home/yunohost.app/memo/backups` |
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
redemande de vous connecter. Le lien « Connexion » en est le miroir, et
n'apparaît que si vous ouvrez la permission aux visiteurs.

Les deux adresses sont `PROXY_LOGIN_URL` et `PROXY_LOGOUT_URL` dans
`/var/www/memo/.env`, réécrites à chaque mise à jour et à chaque
`yunohost app change-url`. Videz l'une des deux et memo cesse d'afficher le lien
correspondant, ce qui est plus honnête qu'un bouton qui ne déconnecte personne.
Jusqu'à la 0.9.1~ynh1 ces deux redirections étaient dans la config nginx de
l'application. memo s'en charge lui-même maintenant, donc une personnalisation
laissée là n'a plus rien à remplacer.

Ouvrir un tableau et y écrire ne demande jamais de compte. En créer un si, sauf
si le panneau de configuration en décide autrement, question qui ne se pose que
sur une installation ouverte aux visiteurs.

Le compte choisi à l'installation a reçu la page d'administration de memo, sur
`https://votre.domaine/memo/admin`, qui liste, cherche et supprime les tableaux,
gère les comptes et prend un instantané de la base. Ce droit n'est accordé
qu'une fois, tant que memo n'a aucun admin. Modifier le réglage ensuite ne fait
rien. Pour ajouter ou retirer un admin plus tard, passez par cette page.

Les groupes YunoHost ne sont pas transmis : `ADMIN_GROUP` et le partage de
tableau par groupe n'ont rien à lire. Partagez un tableau privé nom par nom.

## Configuration

Quatre réglages ont un panneau de configuration : la langue par défaut de
l'interface, une URL de logo et une de favicon pour remplacer ceux de memo, et
la possibilité pour un visiteur sans compte de créer un tableau. Tout le reste
est dans `/var/www/memo/.env`, un `CLÉ=valeur` par ligne, documenté dans
[le README de memo](https://codeberg.org/mrflos/memo#options). Après
modification :

```bash
systemctl restart memo
```

Une mise à jour réécrit ce fichier depuis le modèle du paquet. YunoHost voit
qu'il a changé, en garde une copie à côté, et vous dit où. Les réglages du
panneau survivent, YunoHost les stocke à part et les remet.

Les images de fond des tableaux vont dans le même fichier SQLite que les
tableaux, seize par tableau par défaut. Augmentez `MAX_IMAGES` si c'est juste,
et attendez-vous à ce que le fichier grossisse : une photo pèse cent fois une
carte. Le plafond de 16 Mo par envoi, c'est le `client_max_body_size` de la
config nginx de l'application.

## Quand personne n'est connecté

Si memo voit tout le monde comme anonyme, la chaîne à vérifier est courte.
SSOwat pose `ynh_user` sur la requête à partir du cookie du portail, et
`proxy_params_with_auth`, un fichier fourni par YunoHost que la config nginx de
l'app inclut, le transforme en l'en-tête `Ynh-User` que memo lit. Cela n'a lieu
que parce que la permission le demande, avec `main.auth_header = true` dans le
manifeste. Les deux lignes qui reprennent ces noms sont dans le `.env` :

```ini
PROXY_USER_HEADER=Ynh-User
PROXY_NAME_HEADER=Ynh-User-Fullname
```

Ne les faites pas pointer sur `Remote-User` ni sur un autre nom. SSOwat efface
les en-têtes envoyés par le client dont le nom commence par `ynh_` ou `ynh-`, et
seulement ceux-là : tout autre nom est un en-tête qu'un visiteur peut poser
lui-même pour se faire passer pour qui il veut.

## Sauvegardes

L'archive YunoHost emporte tout le répertoire d'installation, dont la quasi
totalité est le binaire de 90 Mo. Une restauration n'a alors besoin d'aucun
réseau. Si vous sauvegardez toutes les nuits et que la taille gêne, sauvegardez
le répertoire de données seul : les tableaux, c'est tout ce qu'il contient, et
une réinstallation suivie d'une restauration de `$data_dir` vous ramène au même
point.

memo prend aussi ses propres instantanés, depuis la page d'administration. Le
`VACUUM INTO` copie la base pendant que le serveur continue de servir, la copie
est ouverte et vérifiée avant qu'une plus ancienne soit supprimée, et elle
arrive dans `/home/yunohost.app/memo/backups`. Sept sont conservés, ce que
`BACKUP_KEEP` dans le `.env` change. Ils sont dans le répertoire de données,
donc une archive YunoHost les emporte avec les tableaux. C'est le prix de
pouvoir en prendre un au milieu d'un atelier sans passer par un shell.

## Architecture

memo est un seul binaire compilé, environ 90 Mo, qui contient le runtime bun,
le serveur et chaque page, police et image de fond qu'il sert. Rien d'autre
n'est installé : pas de dépôt cloné, pas de node_modules, aucun registre npm à
joindre.

Il est compilé avec bun, qui ne fournit pas de runtime pour armhf ni pour les
machines 32 bits, donc ce paquet ne s'installe que sur x86-64 et aarch64.

Chaque version publie trois binaires et l'installation en choisit un. Sur
aarch64 il n'y a que le binaire arm64. Sur x86-64 elle lit les drapeaux du
processeur dans `/proc/cpuinfo` : AVX2, c'est-à-dire tout ce qui date d'après
2013 environ, reçoit le binaire rapide, et une machine plus ancienne reçoit le
« baseline », qui fait la même chose un peu moins vite. Le binaire choisi est
ensuite lancé une fois avec `--help` avant que le service démarre, pour qu'une
machine qui annonce AVX2 sans vraiment le faire retombe sur le baseline plutôt
que de vous laisser un service qui meurt sur `Illegal instruction`.

Chaque mise à jour refait ce choix. Une restauration non : l'archive emporte le
binaire retenu sur l'ancienne machine, donc après une restauration sur un autre
processeur, lancez `yunohost app upgrade -F memo` pour obtenir le bon.
