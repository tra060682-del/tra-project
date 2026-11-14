import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile,readdir} from 'node:fs/promises';

const read=path=>readFile(new URL(`../${path}`,import.meta.url),'utf8');

test('catalogue preserves the authoritative Emergent navigation and headings',async()=>{const [page,browser,contract]=await Promise.all([read('src/app/artworks/page.tsx'),read('src/components/catalogue-browser.tsx'),read('src/lib/catalogue-parity.ts')]);assert.match(browser,/Browse original art/);for(const label of ['Painting','Printmaking','Digital Art','Drawing','Prints','Sculpture','Photography'])assert.match(contract,new RegExp(label));for(const label of ['Subject','Artform','Style','Medium'])assert.match(browser,new RegExp(`label="${label}"`));assert.doesNotMatch(page,/Art worth living with/)});

test('development fixtures fail closed in production and use the 26 approved files only',async()=>{const [page,fixtures,browser,register,files]=await Promise.all([read('src/app/artworks/page.tsx'),read('src/lib/catalogue-parity.ts'),read('src/components/catalogue-browser.tsx'),read('src/data/approved-media-register.ts'),readdir(new URL('../public/media/heritage/',import.meta.url))]);assert.match(page,/process\.env\.NODE_ENV!=='production'/);assert.match(fixtures,/process\.env\.NODE_ENV==='production'/);assert.match(browser,/not inventory/i);assert.equal(files.filter(name=>name.endsWith('.jpg')).length,26);assert.equal((register.match(/"file":/g)||[]).length,26);assert.doesNotMatch(fixtures,/emergent\.host|static\.prod-images|images\.unsplash|res\.cloudinary/)});

test('catalogue filters use repeated URL parameters and public records never query staging',async()=>{const [browser,catalogue]=await Promise.all([read('src/components/catalogue-browser.tsx'),read('src/lib/catalogue.ts')]);assert.match(browser,/getAll\('subject'\)/);assert.match(browser,/getAll\('artform'\)/);assert.match(browser,/next\.append\(key,item\)/);assert.match(browser,/router\.replace/);assert.match(catalogue,/eq\('status','published'\)/);assert.match(catalogue,/item=>item\.is_approved/);assert.doesNotMatch(catalogue,/emergent_staging/)});
