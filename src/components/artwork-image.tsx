'use client';
import Image from 'next/image';
import {useId,useRef} from 'react';
import type {ApprovedMedia} from '@/data/approved-media';

export function ArtworkImage({media,ratio='4 / 5',fit='cover',zoom=false,priority=false,className=''}:{media:ApprovedMedia;ratio?:string;fit?:'cover'|'contain';zoom?:boolean;priority?:boolean;className?:string}){
  const dialog=useRef<HTMLDialogElement>(null);const titleId=useId();
  return <figure className={className}><div className="artwork-media" data-fit={fit} style={{aspectRatio:ratio}}><Image src={media.src} alt={media.alt} fill sizes="(max-width: 700px) 92vw, (max-width: 1100px) 48vw, 32vw" loading={priority?'eager':'lazy'}/>{zoom&&<button className="artwork-media-button" type="button" onClick={()=>dialog.current?.showModal()} aria-label={`Zoom ${media.alt}`}>View full image</button>}</div><figcaption className="artwork-credit"><a href={media.source} target="_blank" rel="noreferrer">{media.credit}</a> · {media.license}</figcaption>{zoom&&<dialog ref={dialog} className="ui-dialog" aria-labelledby={titleId} onClick={event=>{if(event.target===dialog.current)dialog.current.close()}}><h2 id={titleId} className="sr-only">{media.alt}</h2><div className="artwork-zoom"><Image src={media.src} alt={media.alt} fill sizes="100vw"/></div><div className="ui-dialog-actions"><button className="ui-button" data-variant="outline" onClick={()=>dialog.current?.close()}>Close</button></div></dialog>}</figure>;
}
