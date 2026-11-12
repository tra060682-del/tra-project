'use client';
import {useEffect,useState} from 'react';

function remaining(target:string){
  const distance=Math.max(0,Date.parse(target)-Date.now());
  const days=Math.floor(distance/86400000),hours=Math.floor(distance/3600000)%24,minutes=Math.floor(distance/60000)%60,seconds=Math.floor(distance/1000)%60;
  return {distance,label:`${days}d ${String(hours).padStart(2,'0')}h ${String(minutes).padStart(2,'0')}m ${String(seconds).padStart(2,'0')}s`};
}
export function AuctionCountdown({target,prefix='Closes in'}:{target:string;prefix?:string}){
  const [value,setValue]=useState<ReturnType<typeof remaining>|null>(null);
  useEffect(()=>{const update=()=>setValue(remaining(target));update();const timer=setInterval(update,1000);return()=>clearInterval(timer);},[target]);
  return <span className="auction-countdown" aria-live="off">{value?(value.distance?`${prefix} ${value.label}`:'Auction closed'):'Auction timing loading…'}</span>;
}
