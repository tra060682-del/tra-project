import Image from 'next/image';
import {mediaById} from '@/data/approved-media';
const toneMedia:Record<string,string>={lotus:'ravi-varma-lady',forest:'jahangir-jadrup',earth:'bharat-mata',water:'kalighat-vishnu',saffron:'pichwai'};
export function Art({tone,title,className=''}:{tone:string;title:string;className?:string}){const media=mediaById(toneMedia[tone]||'tagore-face');return <div className={`art art-${tone} ${className}`} role="img" aria-label={`${title}. ${media.alt}`}><Image src={media.src} alt="" fill sizes="(max-width: 700px) 100vw, 50vw"/><small>{media.license} · HERITAGE REFERENCE</small></div>}
