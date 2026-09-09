Memo is a board of sticky notes that several people write on at once. Drag a
note, type in it, watch it move on everyone else's screen. It was built after
scrumblr, and it keeps every board in a single SQLite file, so there is no
database server to run alongside it.

A board holds two things. Notes, which are the usual coloured squares, and
wikicards, two-sided cards built from a wiki page: a question on the front, an
answer on the back. Columns can be renamed, reordered and resized, cards can be
filtered, and the whole board pans and zooms like a map.

Features:

- Real-time editing over a WebSocket, with no page reloads
- Columns you can rename, drag and resize
- Notes and two-sided wikicards, imported from a wiki or from a QR code
- Image upload, Markdown, four interface languages (English, French, Spanish, Russian)
- Export a board to CSV or plain text
- Private boards: lock one so only named accounts and share links reach it
- An admin page for listing, searching and deleting boards
