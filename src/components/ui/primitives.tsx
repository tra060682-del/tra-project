import Link from 'next/link';
import type {ButtonHTMLAttributes,HTMLAttributes,InputHTMLAttributes,SelectHTMLAttributes,TextareaHTMLAttributes} from 'react';

const cx=(...values:(string|undefined|false)[])=>values.filter(Boolean).join(' ');

export function Button({variant='primary',className,...props}:ButtonHTMLAttributes<HTMLButtonElement>&{variant?:'primary'|'outline'|'ghost'|'danger'}){return <button className={cx('ui-button',className)} data-variant={variant} {...props}/>}
export function Input({className,...props}:InputHTMLAttributes<HTMLInputElement>){return <input className={cx('ui-input',className)} {...props}/>}
export function Select({className,...props}:SelectHTMLAttributes<HTMLSelectElement>){return <select className={cx('ui-select',className)} {...props}/>}
export function Textarea({className,...props}:TextareaHTMLAttributes<HTMLTextAreaElement>){return <textarea className={cx('ui-textarea',className)} {...props}/>}
export function Checkbox({className,...props}:InputHTMLAttributes<HTMLInputElement>){return <input type="checkbox" className={cx('ui-checkbox',className)} {...props}/>}
export function Field({label,htmlFor,children,hint}:{label:string;htmlFor:string;children:React.ReactNode;hint?:string}){return <div className="ui-field"><label className="ui-label" htmlFor={htmlFor}>{label}</label>{children}{hint&&<small>{hint}</small>}</div>}
export function Card({className,...props}:HTMLAttributes<HTMLElement>){return <article className={cx('ui-card',className)} {...props}/>}
export function CardHeader(props:HTMLAttributes<HTMLDivElement>){return <div className={cx('ui-card-header',props.className)} {...props}/>}
export function CardBody(props:HTMLAttributes<HTMLDivElement>){return <div className={cx('ui-card-body',props.className)} {...props}/>}
export function CardFooter(props:HTMLAttributes<HTMLDivElement>){return <div className={cx('ui-card-footer',props.className)} {...props}/>}
export function Badge({tone='neutral',className,...props}:HTMLAttributes<HTMLSpanElement>&{tone?:'neutral'|'gold'|'success'|'danger'}){return <span className={cx('ui-badge',className)} data-tone={tone} {...props}/>}
export function Table({caption,children}:{caption?:string;children:React.ReactNode}){return <div className="ui-table-wrap"><table className="ui-table">{caption&&<caption className="sr-only">{caption}</caption>}{children}</table></div>}
export function Pagination({page,pages,href}:{page:number;pages:number;href:(page:number)=>string}){return <nav className="ui-pagination" aria-label="Pagination"><Link href={href(Math.max(1,page-1))} aria-label="Previous page">←</Link>{Array.from({length:pages},(_,i)=>i+1).map(n=>n===page?<span key={n} aria-current="page">{n}</span>:<Link key={n} href={href(n)}>{n}</Link>)}<Link href={href(Math.min(pages,page+1))} aria-label="Next page">→</Link></nav>}
export function Notice({tone='info',children}:{tone?:'info'|'success'|'error';children:React.ReactNode}){return <div className="ui-notice" data-tone={tone} role={tone==='error'?'alert':'status'}>{children}</div>}
export function LoadingState({label='Loading'}:{label?:string}){return <div className="ui-state" role="status"><span className="ui-spinner" aria-hidden="true"/><span>{label}</span></div>}
export function EmptyState({title,body,action}:{title:string;body:string;action?:React.ReactNode}){return <div className="ui-state"><div><p className="eyebrow">Nothing here yet</p><h3>{title}</h3><p>{body}</p>{action}</div></div>}
export function ErrorState({title='Something went wrong',body}:{title?:string;body:string}){return <div className="ui-state" role="alert"><div><p className="eyebrow">Unable to continue</p><h3>{title}</h3><p>{body}</p></div></div>}
