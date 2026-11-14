import {approvedMediaRegister} from '@/data/approved-media-register';
import type {CatalogueArtwork} from '@/lib/catalogue';

export const catalogueCategories=[['painting','Painting'],['printmaking','Printmaking'],['digital-art','Digital Art'],['drawing','Drawing'],['prints','Prints'],['sculpture','Sculpture'],['photography','Photography']] as const;
export const moreCategories=[['mixed-media','Mixed Media'],['textile-art','Textile Art'],['ceramics','Ceramics'],['installation-art','Installation Art'],['traditional-indian-art','Traditional Indian Art'],['folk-art','Folk Art'],['miniature-art','Miniature Art'],['decorative-art','Decorative Art'],['other','Other']] as const;
export const subjectOptions=['Seascape','Botanical','Village','Music','Buildings','Figurative','Objects','Birds','People','Landscape','Portrait','Abstract','Nature','Wildlife','Spiritual','Mythology','Architecture','Still Life','Festivals','Culture','Heritage'];
export const artformOptions=['Madhubani','Pichwai','Gond','Warli','Kalamkari','Tanjore','Pattachitra','Rajasthani Miniature','Mughal Miniature','Pahari','Kerala Mural','Bengal School'];
export const styleOptions=['Traditional Indian','Folk & Tribal','Miniature','Modern Indian','Contemporary'];
export const mediumOptions=['Natural pigments on handmade paper','Natural pigments on cloth','Gold foil & gemstones on wood','Mineral pigments on wasli paper','Watercolour wash on paper','Vegetable dyes on cotton','Acrylic on canvas','Oil on canvas'];

export type CatalogueSort='featured'|'newest'|'price_asc'|'price_desc'|'popular';
export const catalogueSorts:Record<CatalogueSort,string>={featured:"Curator's order",newest:'Recently added',price_asc:'Price: low to high',price_desc:'Price: high to low',popular:'Most viewed'};
export type CatalogueSelection={q:string;category:string;subject:string[];artform:string[];style:string[];medium:string[];sort:CatalogueSort};
const normal=(value:string)=>value.trim().toLowerCase();
export function filterCatalogue(records:CatalogueArtwork[],selection:CatalogueSelection){
  const match=(chosen:string[],values:string[])=>!chosen.length||chosen.some(value=>values.map(normal).includes(normal(value)));
  const q=normal(selection.q);
  return records.filter(item=>(!q||normal([item.title,item.artist,item.description,item.medium,...item.subjects,...item.artforms,...item.styles].join(' ')).includes(q))&&(!selection.category||item.category===selection.category)&&match(selection.subject,item.subjects)&&match(selection.artform,item.artforms)&&match(selection.style,item.styles)&&match(selection.medium,[item.medium]));
}
export function sortCatalogue(records:CatalogueArtwork[],sort:CatalogueSort){
  return [...records].sort((a,b)=>sort==='price_asc'?(a.price||Number.MAX_SAFE_INTEGER)-(b.price||Number.MAX_SAFE_INTEGER):sort==='price_desc'?b.price-a.price:sort==='newest'?b.createdAt.localeCompare(a.createdAt):sort==='popular'?Number(b.featured)-Number(a.featured):Number(b.featured)-Number(a.featured)||a.title.localeCompare(b.title));
}
export function facetCounts(records:CatalogueArtwork[],field:'subjects'|'artforms'|'styles'|'medium'){
  const counts:Record<string,number>={};
  for(const item of records){const values=field==='medium'?[item.medium]:item[field];for(const value of new Set(values))counts[value]=(counts[value]||0)+1}
  return counts;
}

const titleFromSource=(source:string)=>decodeURIComponent(source.split('/').pop()||'Approved heritage reference').replace(/\.[^.]+$/,'').replaceAll('_',' ').replace(/^File:/i,'').replace(/\s+-\s+Google Art Project$/i,'').replace(/\s+/g,' ').trim();
const metadata=(title:string)=>{
  const text=normal(title);
  const artform=text.includes('madhubani')?'Madhubani':text.includes('pichwai')?'Pichwai':text.includes('gond')?'Gond':text.includes('warli')?'Warli':text.includes('kalamkari')?'Kalamkari':text.includes('tanjore')?'Tanjore':text.includes('pattachitra')?'Pattachitra':text.includes('mural')?'Kerala Mural':text.includes('kalighat')?'Bengal School':'';
  const subjects=[/portrait|face|lady|maharaja|artist/.test(text)?'Portrait':'',/vishnu|mata|krishna|temple|pichwai/.test(text)?'Spiritual':'',/painting|art/.test(text)?'Culture':''].filter(Boolean);
  return {artforms:artform?[artform]:[],subjects,styles:[artform?['Madhubani','Gond','Warli'].includes(artform)?'Folk & Tribal':'Traditional Indian':'Modern Indian']};
};

export function approvedMediaFixtures():CatalogueArtwork[]{
  if(process.env.NODE_ENV==='production')return [];
  return approvedMediaRegister.map((asset,index)=>{
    const title=titleFromSource(asset.source);const meta=metadata(title);const creator=(asset.credit.split('—')[0].trim()||'Rights-approved heritage reference').replace(/(.+?)\1$/,'$1');
    return {id:`00000000-0000-4000-8000-${String(index+1).padStart(12,'0')}`,title,artistId:'fixture',artist:creator,form:'Heritage reference',medium:'Reference metadata not supplied',size:'Reference dimensions not supplied',price:0,description:'Rights-approved development reference used only to verify catalogue presentation.',imageUrls:[`/media/heritage/${asset.file}`],imageAlt:title,status:'published',year:'Reference date not supplied',category:'painting',subjects:meta.subjects,artforms:meta.artforms,styles:meta.styles,featured:index<3,createdAt:new Date(Date.UTC(2026,0,26-index)).toISOString(),isFixture:true,sourceUrl:asset.source,rightsLabel:`${asset.license} · ${asset.credit}`};
  });
}
