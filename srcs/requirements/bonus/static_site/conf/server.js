const http = require('http');
const fs = require('fs');
const path = require('path');

const server = http.createServer((req, res) => {
    // Si la requête est à la racine, on charge index.html, sinon on cherche le fichier demandé (ex: /image1.jpg)
    let filePath = (req.url === '/' || req.url === '/cv/') ? '/index.html' : req.url;
    let fullPath = path.join('/var/www/static', filePath);

    // Détermine le type de contenu à renvoyer au navigateur
    let extname = path.extname(fullPath).toLowerCase();
    let contentType = 'text/html';
    if (extname === '.jpg' || extname === '.jpeg') contentType = 'image/jpeg';
    if (extname === '.png') contentType = 'image/png';

    // Lecture et envoi du fichier
    fs.readFile(fullPath, (err, content) => {
        if (err) {
            res.writeHead(404);
            res.end('Fichier introuvable');
        } else {
            res.writeHead(200, { 'Content-Type': contentType });
            res.end(content);
        }
    });
});

server.listen(3000, () => {
    console.log('Serveur statique en ligne sur le port 3000');
});