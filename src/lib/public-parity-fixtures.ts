import {approvedMediaFixtures} from '@/lib/catalogue-parity';
import type {PublicArtist,PublicCollection} from '@/lib/public-content';

const works=()=>approvedMediaFixtures();
const by=(fragment:string)=>works().filter(item=>item.artist.toLowerCase().includes(fragment.toLowerCase()));

export function approvedArtistFixtures():PublicArtist[]{
  if(process.env.NODE_ENV==='production')return [];
  const records=works();
  return [
    {id:'reference-abanindranath-tagore',name:'Abanindranath Tagore',location:'Heritage reference',portrait:'/media/heritage/d3cd3b44af03f7.jpg',biography:'Rights-approved heritage material used to verify the Emergent artist-profile presentation. This is not a current tRA artist account.',statement:'Historical reference only — no representation, availability or commercial relationship is implied.',website:'',artworks:[...by('Abanindranath')]},
    {id:'reference-amrita-sher-gil',name:'Amrita Sher-Gil',location:'Heritage reference',portrait:'/media/heritage/04a304ebe342d0.jpg',biography:'Rights-approved heritage material used to verify the Emergent artist-profile presentation. This is not a current tRA artist account.',statement:'Historical reference only — no representation, availability or commercial relationship is implied.',website:'',artworks:[...by('Sher-Gil')]},
    {id:'reference-rabindranath-tagore',name:'Rabindranath Tagore',location:'Heritage reference',portrait:'/media/heritage/7f46a00094cbb0.jpg',biography:'Rights-approved heritage material used to verify the Emergent artist-profile presentation. This is not a current tRA artist account.',statement:'Historical reference only — no representation, availability or commercial relationship is implied.',website:'',artworks:[...by('Rabindranath')]},
    {id:'reference-raja-ravi-varma',name:'Raja Ravi Varma',location:'Heritage reference',portrait:'/media/heritage/ac69d36caeea57.jpg',biography:'Rights-approved heritage material used to verify the Emergent artist-profile presentation. This is not a current tRA artist account.',statement:'Historical reference only — no representation, availability or commercial relationship is implied.',website:'',artworks:[...by('Raja Ravi Varma')]},
    {id:'reference-jamini-roy',name:'Jamini Roy',location:'Heritage reference',portrait:'/media/heritage/6fd1e4773aeb14.jpg',biography:'Rights-approved heritage material used to verify the Emergent artist-profile presentation. This is not a current tRA artist account.',statement:'Historical reference only — no representation, availability or commercial relationship is implied.',website:'',artworks:records.filter(item=>item.title.toLowerCase().includes('jamini roy'))},
    {id:'reference-sh-raza',name:'S. H. Raza',location:'Heritage reference',portrait:'/media/heritage/c2cc7aefa5c3b6.jpg',biography:'Rights-approved heritage material used to verify the Emergent artist-profile presentation. This is not a current tRA artist account.',statement:'Historical reference only — no representation, availability or commercial relationship is implied.',website:'',artworks:records.filter(item=>item.title.toLowerCase().includes('raza'))},
  ].map(item=>({...item,isFixture:true}));
}

export function approvedCollectionFixtures():PublicCollection[]{
  if(process.env.NODE_ENV==='production')return [];
  const records=works();
  const take=(indexes:number[])=>indexes.map(index=>records[index]).filter(Boolean);
  return [
    {id:'reference-living-traditions',slug:'reference-living-traditions',title:'Living Traditions',description:'A development-only grouping of rights-approved heritage references used to verify the Emergent collection experience.',artworks:take([0,2,5,6,7,11,14,15,17,19,23])},
    {id:'reference-modern-india',slug:'reference-modern-india',title:'Modern India',description:'A development-only visual reference. These images are not inventory and are not offered for sale.',artworks:take([3,4,8,9,12,16,18,20,21,22,24,25])},
    {id:'reference-spiritual-expressions',slug:'reference-spiritual-expressions',title:'Spiritual Expressions',description:'A development-only grouping for layout review, assembled only from the approved media register.',artworks:take([2,10,13,14,16,17,19])},
  ].map(item=>({...item,isFixture:true}));
}
