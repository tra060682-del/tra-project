import type {SVGProps} from 'react';

type IconProps=SVGProps<SVGSVGElement>;
function Icon({children,...props}:IconProps){return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true" {...props}>{children}</svg>}

export const SearchIcon=(props:IconProps)=><Icon {...props}><circle cx="11" cy="11" r="6.5"/><path d="m16 16 4 4"/></Icon>;
export const HeartIcon=(props:IconProps)=><Icon {...props}><path d="M20.8 5.8c-1.7-1.8-4.6-1.8-6.3 0L12 8.4 9.5 5.8a4.4 4.4 0 0 0-6.3 6.1L12 21l8.8-9.1a4.4 4.4 0 0 0 0-6.1Z"/></Icon>;
export const BagIcon=(props:IconProps)=><Icon {...props}><path d="M5 8h14l-1 13H6L5 8Z"/><path d="M9 9V6a3 3 0 0 1 6 0v3"/></Icon>;
export const MenuIcon=(props:IconProps)=><Icon {...props}><path d="M4 7h16M4 12h16M4 17h16"/></Icon>;
export const EnvelopeIcon=(props:IconProps)=><Icon {...props}><rect x="3" y="5" width="18" height="14" rx="1"/><path d="m4 7 8 6 8-6"/></Icon>;
export const PeopleIcon=(props:IconProps)=><Icon {...props}><circle cx="9" cy="8" r="3"/><circle cx="17" cy="9" r="2"/><path d="M3.5 19c.5-4 2.3-6 5.5-6s5 2 5.5 6M15 14c3 0 4.5 1.7 5 4.5"/></Icon>;
export const PaymentIcon=(props:IconProps)=><Icon {...props}><rect x="2.5" y="5" width="19" height="14" rx="2"/><path d="M2.5 9h19M15 15h3"/></Icon>;
export const ParcelIcon=(props:IconProps)=><Icon {...props}><path d="m4 8 8-4 8 4v9l-8 4-8-4V8Z"/><path d="m4 8 8 4 8-4M12 12v9M8 6l8 4"/></Icon>;
export const CertificateIcon=(props:IconProps)=><Icon {...props}><rect x="5" y="3" width="14" height="16" rx="1"/><path d="M8 7h8M8 10h8M8 13h5M9 19l-1 3 4-2 4 2-1-3"/></Icon>;
export const CareIcon=(props:IconProps)=><Icon {...props}><path d="M12 3 5 6v5c0 5 3 8 7 10 4-2 7-5 7-10V6l-7-3Z"/><path d="m8.5 11 2.2 2.2 4.8-5"/></Icon>;
export const PaletteIcon=(props:IconProps)=><Icon {...props}><path d="M12 3a9 9 0 1 0 0 18h1.5a2 2 0 0 0 0-4H12a2 2 0 0 1 0-4h3a6 6 0 0 0 0-12h-3Z"/><circle cx="7" cy="10" r=".7" fill="currentColor"/><circle cx="9" cy="6.5" r=".7" fill="currentColor"/><circle cx="14" cy="6" r=".7" fill="currentColor"/></Icon>;
export const BellIcon=(props:IconProps)=><Icon {...props}><path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9M10 21h4"/></Icon>;
export const UserIcon=(props:IconProps)=><Icon {...props}><circle cx="12" cy="8" r="4"/><path d="M4 21c.8-5 3.5-7 8-7s7.2 2 8 7"/></Icon>;
