import {redirect} from 'next/navigation';
import {updatePassword} from '@/app/auth/actions';
import {supabase} from '@/lib/supabase/server';

type Props={searchParams:Promise<{error?:string}>};
export const metadata={title:'Choose a new password'};
export default async function ResetPassword({searchParams}:Props){if(!process.env.NEXT_PUBLIC_SUPABASE_URL||!process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY)return <section className="section narrow"><h1>Account recovery is unavailable.</h1><p className="notice">Supabase authentication has not been configured for this environment.</p></section>;const db=await supabase();const {data:{user}}=await db.auth.getUser();if(!user)redirect('/forgot-password');const {error}=await searchParams;return <section className="section narrow"><div className="eyebrow">ACCOUNT RECOVERY</div><h1>Choose a new password.</h1>{error&&<p className="form-message form-error" role="alert">{error}</p>}<form className="auth-form" action={updatePassword}><label>NEW PASSWORD<input name="password" type="password" autoComplete="new-password" minLength={8} required/></label><label>CONFIRM PASSWORD<input name="confirmation" type="password" autoComplete="new-password" minLength={8} required/></label><button className="button" type="submit">Update password ↗</button></form></section>}
