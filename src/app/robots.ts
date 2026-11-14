import type {MetadataRoute} from 'next';
export default function robots():MetadataRoute.Robots{
  const site=process.env.NEXT_PUBLIC_SITE_URL;
  if(!site)return {rules:{userAgent:'*',disallow:'/'}};
  return {rules:{userAgent:'*',allow:'/',disallow:['/admin/','/artist/','/intermediary/','/workspace/','/account/','/profile/','/design-preview/','/api/','/auth/']},sitemap:`${site.replace(/\/$/,'')}/sitemap.xml`};
}
