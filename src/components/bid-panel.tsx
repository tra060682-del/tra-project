'use client';
import {useState} from 'react';
import {formatInr} from '@/lib/currency';

export function BidPanel({lotId,minimumPaise,enabled}:{lotId:string;minimumPaise:number;enabled:boolean}){
  const [message,setMessage]=useState('');
  const [pending,setPending]=useState(false);
  async function submit(formData:FormData){
    setPending(true);setMessage('');
    const rupees=Number(formData.get('maximumRupees'));
    const response=await fetch('/api/bids',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({auctionId:lotId,maximumPaise:Math.round(rupees*100),requestId:crypto.randomUUID()})});
    const result=await response.json().catch(()=>({error:'UNKNOWN'})) as {message?:string;error?:string};
    setMessage(response.ok?'Your maximum bid was accepted. Refresh to see the auction position.':result.message||result.error||'Bid rejected.');
    setPending(false);
  }
  return <div className="bid-panel"><div className="eyebrow">SECURE MAXIMUM BID</div><h2>{enabled?'Place your bid':'Bidding is not activated'}</h2><p>Your maximum remains private. The database advances only as required by the next eligible bid and approved increment.</p><form action={submit}><label htmlFor="maximumRupees">Maximum bid in INR</label><input id="maximumRupees" name="maximumRupees" type="number" min={Math.ceil(minimumPaise/100)} step="1" required disabled={!enabled}/><small>Minimum next maximum: {formatInr(minimumPaise)}</small><button className="button" type="submit" disabled={!enabled||pending}>{pending?'Validating…':'Place Bid'}</button></form>{message&&<p className="form-message" role="status">{message}</p>}<p className="bid-gate">{enabled?'Verified account, approved bidder status and accepted auction terms are required.':'Preview only. No real-money bid can be accepted while the operational feature flag is off.'}</p></div>;
}
