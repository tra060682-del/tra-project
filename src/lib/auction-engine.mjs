// Executable reference model. SQL remains authoritative; DB parity tests are required before activation.
export function resolveProxy({opening,increment,reserve=null,bids}) {
 if(!Number.isSafeInteger(opening)||opening<=0||!Number.isSafeInteger(increment)||increment<=0)throw Error('INVALID_TERMS');
 if(reserve!==null&&(!Number.isSafeInteger(reserve)||reserve<opening))throw Error('INVALID_RESERVE');
 if(bids.some(b=>!Number.isSafeInteger(b.maximum)||b.maximum<opening||!Number.isFinite(b.priority)))throw Error('INVALID_BID');
 if(new Set(bids.map(b=>b.user)).size!==bids.length)throw Error('DUPLICATE_BIDDER');
 const ranked=[...bids].sort((a,b)=>b.maximum-a.maximum||a.priority-b.priority||a.user.localeCompare(b.user));
 if(!ranked.length)return {winner:null,price:null,reserveMet:false};
 const [top,second]=ranked;let price=Math.max(opening,Math.min(top.maximum,second?second.maximum+increment:opening));
 if(reserve!==null)price=top.maximum<=reserve?top.maximum:Math.max(price,reserve);
 return {winner:top.user,price,reserveMet:reserve===null||price>=reserve};
}
export function extendClose(end,acceptedAt,seconds=120){if(acceptedAt>=end)throw Error('AUCTION_CLOSED');return end-acceptedAt<=seconds*1000?acceptedAt+seconds*1000:end;}
