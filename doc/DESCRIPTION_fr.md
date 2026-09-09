Memo est un tableau de post-it sur lequel plusieurs personnes écrivent en même
temps. Déplacez une note, tapez dedans, regardez-la bouger sur l'écran des
autres. Il s'inspire de scrumblr, et garde chaque tableau dans un seul fichier
SQLite : aucun serveur de base de données à faire tourner à côté.

Un tableau contient deux choses. Des notes, les carrés colorés habituels, et
des wikicards, des cartes à deux faces construites depuis une page de wiki :
une question au recto, une réponse au verso. Les colonnes se renomment, se
réordonnent et se redimensionnent, les cartes se filtrent, et le tableau
entier se déplace et se zoome comme une carte.

Fonctionnalités :

- Édition en temps réel par WebSocket, sans rechargement de page
- Colonnes renommables, déplaçables et redimensionnables
- Notes et wikicards à deux faces, importées depuis un wiki ou un QR code
- Envoi d'images, Markdown, quatre langues d'interface (anglais, français, espagnol, russe)
- Export d'un tableau en CSV ou en texte brut
- Tableaux privés : verrouillez-en un pour ne laisser passer que les comptes nommés et les liens de partage
- Une page d'administration pour lister, chercher et supprimer les tableaux
