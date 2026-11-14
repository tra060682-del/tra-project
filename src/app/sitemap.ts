import type {MetadataRoute} from 'next';
import {catalogue} from '@/lib/catalogue';
import {journalEntries,publicArtists,publicCollections} from '@/lib/public-content';
export default async function sitemap():Promise<MetadataRoute.Sitemap>{
  const base=(process.env.NEXT_PUBLIC_SITE_URL||'http://localhost:3000').replace(/\/$/,'');
  const paths=['','/artworks','/artists','/collections','/journal','/about','/for-artists','/art-advisory','/commissions','/corporate-art','/resale','/contact','/legal','/privacy','/terms','/authenticity'];
  const [artworks,artists,collections,journal]=await Promise.all([catalogue(),publicArtists(),publicCollections(),journalEntries()]);
  return [...paths.map(path=>({url:`${base}${path}`,changeFrequency:'weekly' as const,priority:path===''?1:.7})),...artworks.map(item=>({url:`${base}/artworks/${item.id}`,lastModified:new Date(),changeFrequency:'weekly' as const,priority:.8})),...artists.map(item=>({url:`${base}/artists/${item.id}`,changeFrequency:'monthly' as const,priority:.6})),...collections.map(item=>({url:`${base}/collections/${item.slug}`,changeFrequency:'weekly' as const,priority:.7})),...journal.map(item=>({url:`${base}/journal/${item.slug}`,lastModified:new Date(item.updatedAt),changeFrequency:'monthly' as const,priority:.6}))];
}
