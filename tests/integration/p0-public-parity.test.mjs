import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
const read=path=>readFile(path,'utf8');

test('Emergent navigation taxonomy and account controls are preserved',async()=>{
  const header=await read('src/components/header.tsx');
  for(const label of ['Artworks','Artists','Collections','Auction Lobby','Art Advisory','For Artists','About','Join as Artist'])assert.match(header,new RegExp(label));
  for(const item of ['New Arrivals','Traditional Art','Commission an Artist','Verify Certificate','Sell from collection'])assert.match(header,new RegExp(item));
  assert.match(header,/getOptionalAuthContext/);assert.match(header,/logout/);
});

test('homepage follows the authoritative Emergent editorial sequence',async()=>{
  const page=await read('src/app/page.tsx');
  const sequence=['em-hero','em-trust','FEATURED ARTWORKS','THE tRA PLEDGE','Find art your way','CURATED COLLECTIONS','MEET THE MAKERS','LIVING TRADITIONS','AUCTION LOBBY','How collecting works','ART ADVISORY','COMMISSION ORIGINAL ART','ART JOURNAL','NOTES FROM tRA'];
  let cursor=-1;for(const marker of sequence){const next=page.indexOf(marker);assert.ok(next>cursor,`${marker} is missing or out of order`);cursor=next}
  assert.match(page,/Only original work/);assert.match(page,/Never prints/);
});

test('development visual fixtures fail closed and never read staging',async()=>{
  const [fixtures,artists,collections]=await Promise.all([read('src/lib/public-parity-fixtures.ts'),read('src/app/artists/page.tsx'),read('src/app/collections/page.tsx')]);
  assert.match(fixtures,/NODE_ENV==='production'/);assert.match(artists,/NODE_ENV!=='production'/);assert.match(collections,/NODE_ENV!=='production'/);
  for(const source of [fixtures,artists,collections])assert.doesNotMatch(source,/emergent_staging|staging_import|mongo/i);
  assert.match(fixtures,/not a current tRA artist account/i);assert.match(fixtures,/not inventory/i);
});

test('artwork detail restores gallery, enquiry, artist and certificate sections safely',async()=>{
  const [page,gallery]=await Promise.all([read('src/app/artworks/[slug]/page.tsx'),read('src/components/artwork-gallery.tsx')]);
  assert.match(page,/ArtworkGallery/);assert.match(page,/Enquire about this artwork/);assert.match(page,/THE ARTIST/);assert.match(page,/Authenticity and certificate/);assert.match(page,/Public certificate verification remains disabled/);
  assert.match(gallery,/showModal/);assert.match(gallery,/artwork-gallery-thumbs/);assert.match(gallery,/aria-current/);
});

test('public parity CSS includes mobile layouts without horizontal page overflow',async()=>{
  const css=await read('src/app/design-system.css');
  for(const selector of ['.nav-dropdown','.em-image-links','.artist-directory-grid','.collection-detail','.artwork-detail-top'])assert.match(css,new RegExp(selector.replace('.','\\.')));
  assert.match(css,/@media\(max-width:560px\)/);assert.match(css,/overflow:auto/);
});
