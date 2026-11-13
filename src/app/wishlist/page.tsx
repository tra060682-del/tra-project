import Link from 'next/link';
import {EmptyState} from '@/components/ui/primitives';
export default function Wishlist(){return <section className="section"><div className="eyebrow">YOUR WISHLIST</div><h1>Art to return to.</h1><EmptyState title="Your wishlist is empty" body="Save functionality remains connected to the existing account roadmap and has not been activated in this design phase." action={<Link className="ui-button" href="/artworks">Explore artworks</Link>}/></section>}
