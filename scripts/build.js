import {mkdir,cp,rm} from 'node:fs/promises';
await rm('dist',{recursive:true,force:true});await mkdir('dist',{recursive:true});await cp('index.html','dist/index.html');await cp('src','dist/src',{recursive:true,filter:source=>!source.endsWith('/store.js')});console.log('Static application built in dist.');
