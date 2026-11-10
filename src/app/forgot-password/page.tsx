import Link from 'next/link';
import {requestPasswordReset} from '@/app/auth/actions';

type Props={searchParams:Promise<{message?:string}>};
export const metadata={title:'Reset password'};
export default async function ForgotPassword({searchParams}:Props){const {message}=await searchParams;return <section className="section narrow"><div className="eyebrow">ACCOUNT RECOVERY</div><h1>Reset your password.</h1><p className="intro">Enter the email used for your tRA account.</p>{message&&<p className="form-message" role="status">{message}</p>}<form className="auth-form" action={requestPasswordReset}><label>EMAIL ADDRESS<input name="email" type="email" autoComplete="email" required/></label><button className="button" type="submit">Send reset link ↗</button></form><p><Link href="/login">Return to sign in →</Link></p></section>}
