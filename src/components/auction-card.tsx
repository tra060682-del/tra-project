import Link from 'next/link';
import {Art} from '@/components/art';
import {AuctionCountdown} from '@/components/auction-countdown';
import {formatInr,type AuctionLot} from '@/lib/auctions';

export function AuctionCard({lot}:{lot:AuctionLot}){
  const timed=lot.status==='upcoming'?<AuctionCountdown target={lot.startsAt} prefix="Opens in"/>:lot.status==='live'?<AuctionCountdown target={lot.endsAt}/>:<span className="auction-countdown">Completed</span>;
  return <article className="auction-card"><Link className="auction-art" href={`/auctions/${lot.id}`}><Art tone={lot.tone} title={lot.title}/><span className={`auction-state ${lot.status}`}>{lot.status}</span></Link><div className="auction-card-copy"><small>LOT {String(lot.lotNumber).padStart(2,'0')} · {lot.auctionTitle}</small><h3>{lot.title}</h3><p>{lot.artist} · {lot.medium}</p>{timed}<dl><div><dt>{lot.currentPaise?'Current bid':'Starting price'}</dt><dd>{formatInr(lot.currentPaise??lot.openingPaise)}</dd></div><div><dt>Bids</dt><dd>{lot.bidCount}</dd></div><div><dt>Reserve</dt><dd>{lot.reserveMet===null?'Not disclosed':lot.reserveMet?'Met':'Not met'}</dd></div></dl><Link className="auction-view" href={`/auctions/${lot.id}`}>View Auction <span>↗</span></Link></div></article>;
}
