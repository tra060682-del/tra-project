'use client';
import {useId,useRef,useState} from 'react';

export function ArtworkGallery({images,alt}:{images:string[];alt:string}){
  const items=images.length?images:[''];const [selected,setSelected]=useState(0);const dialog=useRef<HTMLDialogElement>(null);const titleId=useId();
  return <div className="artwork-detail-gallery"><div className="artwork-gallery-main">{items[selected]?<img src={items[selected]} alt={selected?`${alt}, detail ${selected+1}`:alt}/>:<div className="published-image-placeholder" role="img" aria-label={`${alt} — approved image pending`}>Approved image pending</div>} {items[selected]&&<button type="button" onClick={()=>dialog.current?.showModal()}>View full image</button>}</div>{items.length>1&&<div className="artwork-gallery-thumbs" aria-label="Artwork images">{items.map((src,index)=><button type="button" aria-current={selected===index} onClick={()=>setSelected(index)} key={src}><img src={src} alt=""/></button>)}</div>}<dialog ref={dialog} className="artwork-zoom-dialog" aria-labelledby={titleId} onClick={event=>{if(event.target===dialog.current)dialog.current.close()}}><h2 className="sr-only" id={titleId}>{alt}</h2>{items[selected]&&<img src={items[selected]} alt={alt}/>}<button type="button" onClick={()=>dialog.current?.close()}>Close</button></dialog></div>;
}
