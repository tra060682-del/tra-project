import Link from 'next/link';
import type {CatalogueArtwork} from '@/lib/catalogue';
import {inr} from '@/lib/format';

export function AvailabilityState({kind='empty',title,children}:{kind?:'empty'|'preview'|'blocked';title:string;children:React.ReactNode}){
  return <section className="public-state" data-kind={kind}><p className="eyebrow">{kind==='blocked'?'PENDING APPROVAL':kind==='preview'?'PREVIEW ONLY':'CURATION IN PROGRESS'}</p><h2>{title}</h2><div>{children}</div></section>;
}

export function PublishedArtworkImage({src,alt,className=''}:{src?:string;alt:string;className?:string}){
  if(!src)return <div className={`published-image-placeholder ${className}`} role="img" aria-label={`${alt} — approved image pending`}><span>Approved image pending</span></div>;
  return <img className={`published-artwork-image ${className}`} src={src} alt={alt} loading="lazy" decoding="async"/>;
}

export function ArtworkCards({artworks,preview=false}:{artworks:CatalogueArtwork[];preview?:boolean}){
  return <div className="public-card-grid">{artworks.map(art=><Link className="public-card" href={`/artworks/${art.id}${preview||art.isFixture?'?preview=approved-media':''}`} key={art.id}><PublishedArtworkImage src={art.imageUrls[0]} alt={art.imageAlt}/><div className="public-card-copy"><small>{art.form} · {art.size}</small><h2>{art.title}</h2><p>{art.artist}</p>{art.price>0&&<strong>{inr(art.price)}</strong>}<span className="catalogue-state">{art.isFixture?'Development reference · not inventory':'Published inventory'}</span></div></Link>)}</div>;
}

export function PreviewNotice({children}:{children:React.ReactNode}){return <div className="public-preview-notice" role="note"><strong>Preview only</strong><span>{children}</span></div>}
