import Link from 'next/link';
import {Art} from '@/components/art';
import {CareIcon,CertificateIcon,EnvelopeIcon,HeartIcon,PaletteIcon,ParcelIcon,PaymentIcon,PeopleIcon} from '@/components/icons';

const studies=[
  {id:'forest-rhythms',title:'Forest rhythms',medium:'Acrylic on paper',size:'60 × 80 cm',tone:'forest'},
  {id:'lotus-hour',title:'The lotus hour',medium:'Natural pigments on cotton',size:'90 × 90 cm',tone:'lotus'},
  {id:'earth-and-memory',title:'Earth & memory',medium:'Mixed media on canvas',size:'80 × 100 cm',tone:'earth'},
  {id:'song-of-water',title:'Song of water',medium:'Ink and acrylic on paper',size:'45 × 60 cm',tone:'water'},
  {id:'forest-rhythms',title:'Untitled catalogue study',medium:'Medium pending approval',size:'Dimensions pending',tone:'saffron'},
];

const values=[
  {title:'Curated with Care',copy:'Every submission is reviewed before publication.',icon:<CareIcon/>},
  {title:'Assisted Purchase',copy:'Human guidance from enquiry through delivery.',icon:<PeopleIcon/>},
  {title:'Artist Empowerment',copy:'Supporting independent Indian artists.',icon:<PaletteIcon/>},
  {title:'Authenticity Assured',copy:'Certificate evidence is verified before sale.',icon:<CertificateIcon/>},
];

const steps=[
  {number:'01',title:'Enquire',copy:'Tell us which work speaks to you.',icon:<EnvelopeIcon/>},
  {number:'02',title:'We Connect',copy:'Our team responds personally.',icon:<PeopleIcon/>},
  {number:'03',title:'Secure Purchase',copy:'A payment link is shared manually.',icon:<PaymentIcon/>},
  {number:'04',title:'Artist Ships',copy:'The artist packs and dispatches.',icon:<ParcelIcon/>},
  {number:'05',title:'Certificate',copy:'Verified evidence travels with the work.',icon:<CertificateIcon/>},
];

export default function Home(){return <div className="home-layout">
  <section className="home-hero" aria-labelledby="home-title"><div className="hero-copy"><span className="hero-kicker">THE REVERENCE OF ART</span><h1 id="home-title">Original Indian<br/>Paintings. Curated<br/>with Reverence.</h1><i className="gold-rule"/><p>tRA is a curated assisted-commerce platform that connects art lovers with original Indian art through a trustworthy, human-assisted process.</p><div className="hero-actions"><Link className="primary-action" href="/artworks">Explore Artworks</Link><Link className="secondary-action" href="/how-it-works">How It Works</Link></div></div><div className="hero-visual"><Art tone="lotus" title="Indian portrait composition inspired by the editorial reference"/><div className="carousel-indicator" aria-label="Illustrative artwork one of one"><button type="button" disabled aria-label="Previous artwork">‹</button><button type="button" disabled aria-label="Next artwork">›</button><span>1</span><i>2</i><i>3</i></div></div></section>

  <section className="value-strip" aria-label="Our values">{values.map(value=><article key={value.title}><div className="value-icon">{value.icon}</div><h2>{value.title}</h2><p>{value.copy}</p></article>)}</section>

  <section className="curated-section" aria-labelledby="curated-title"><div className="section-title-row"><h2 id="curated-title">Curated Artworks</h2><Link href="/artworks">View all artworks <span>→</span></Link></div><p className="catalogue-disclosure">Illustrative catalogue studies — approved artwork photography and listing details are not yet available.</p><div className="artwork-row">{studies.map((study,index)=><article className="artwork-card" key={`${study.title}-${index}`}><Link href={`/artworks/${study.id}`} aria-label={`View ${study.title}`}><Art tone={study.tone} title={study.title}/></Link><div className="artwork-card-copy"><div><small>ILLUSTRATIVE PREVIEW</small><h3>{study.title}</h3></div><button type="button" disabled aria-label="Wishlist coming soon"><HeartIcon/></button><p>{study.medium}</p><p>{study.size} · Year pending</p><strong>Price pending approval</strong></div></article>)}</div></section>

  <section className="featured-section" aria-labelledby="featured-title"><div className="section-title-row"><h2 id="featured-title">Featured Artwork</h2><span className="feature-arrows" aria-hidden="true">‹　›</span></div><div className="featured-content"><Art tone="water" title="Featured illustrative riverside composition"/><div className="featured-copy"><div className="featured-heading"><div><small>ILLUSTRATIVE PREVIEW</small><h3>Featured catalogue study</h3></div><strong>Price pending</strong></div><p>Artist identity pending approval</p><dl><dt>Medium</dt><dd>Details pending</dd><dt>Dimensions</dt><dd>Pending</dd><dt>Year</dt><dd>Pending</dd></dl><div className="feature-badges"><span>Illustrative image</span><span>Certificate not yet verified</span></div><p className="feature-description">This composition demonstrates the intended presentation only. It is not a published artwork listing and is not available for purchase.</p><div className="featured-actions"><Link href="/artworks/forest-rhythms">View Details</Link><Link href="/contact?artwork=featured-study">Enquire Now</Link></div></div></div></section>

  <section className="collections-section" id="collections" aria-labelledby="collections-title"><div className="section-title-row"><h2 id="collections-title">Curated Collections</h2><Link href="/artworks">View all collections <span>→</span></Link></div><div className="collection-grid">{[
    ['Traditional Masters','lotus'],['Contemporary India','water'],['Spiritual Expressions','saffron'],['Nature & Landscapes','forest'],
  ].map(([title,tone])=><Link className="collection-card" href="/artworks" key={title}><Art tone={tone} title={`${title} illustrative collection`}/><span><strong>{title}</strong><small>Explore the collection</small></span></Link>)}</div></section>

  <section className="process-section" aria-labelledby="process-title"><div className="section-title-row"><h2 id="process-title">How It Works</h2><Link href="/how-it-works">View process <span>→</span></Link></div><div className="process-row">{steps.map(step=><article key={step.number}><div className="process-icon">{step.icon}</div><span>{step.number}</span><h3>{step.title}</h3><p>{step.copy}</p></article>)}</div></section>

  <section className="dashboard-previews" aria-label="Protected dashboard previews"><article className="dashboard-preview artist-preview"><div className="preview-heading"><h2>Artist Dashboard Lite</h2><Link href="/artist">View Profile →</Link></div><div className="dashboard-shell"><aside><div className="avatar">MJ</div><strong>Demo artist</strong><small>Preview only</small>{['Dashboard','My Profile','Legal Documents','My Artworks','Submissions','Certificates','Shipping','Settlements'].map(item=><span key={item}>{item}</span>)}</aside><div className="submission-preview"><h3>My Submissions</h3>{['Artwork study 01','Artwork study 02','Artwork study 03'].map((item,index)=><div className="submission-row" key={item}><Art tone={['forest','water','lotus'][index]} title={item}/><span><strong>{item}</strong><small>{index===0?'Review workflow':'Draft preview'}</small></span></div>)}</div></div></article><article className="dashboard-preview admin-preview"><div className="preview-heading"><h2>Admin Dashboard</h2><Link href="/admin">Protected access →</Link></div><div className="admin-overview"><h3>Overview</h3><div className="admin-cards">{['Artist review','Artwork review','Open enquiries','Fulfilment'].map(label=><div key={label}><strong>—</strong><span>{label}</span></div>)}</div><h3>Workflow preview</h3>{['Artist approval queue','Artwork classification','Certificate verification','Shipping and settlement'].map(item=><p key={item}><i/> {item}<small>Demo only</small></p>)}</div></article><p className="privacy-note">These are illustrative interface previews. No private artist, buyer, enquiry, or administrative data is displayed.</p></section>
</div>}
