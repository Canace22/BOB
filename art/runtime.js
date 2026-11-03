// Both the local editor and the static Pages preview use the same UI.
export const readOnly = document.documentElement.dataset.mode === 'preview';
export const siteUrl = file => new URL(file.split('/').map(encodeURIComponent).join('/'), new URL('./', location.href)).href;
export const catalogUrl = readOnly ? siteUrl('catalog.json') : siteUrl('api/catalog');
