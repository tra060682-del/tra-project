'use server';

import {redirect} from 'next/navigation';
import {supabase} from '@/lib/supabase/server';

function value(data:FormData,name:string){return String(data.get(name)??'').trim()}
function safeNext(candidate:string,fallback:string){return candidate.startsWith('/')&&!candidate.startsWith('//')?candidate:fallback}
function siteUrl(){return (process.env.NEXT_PUBLIC_SITE_URL||'http://localhost:3000').replace(/\/$/,'')}
function destination(path:string,key:string,value:string){const params=new URLSearchParams({[key]:value});return `${path}?${params}`}

export async function registerArtist(data:FormData){
  const displayName=value(data,'displayName');
  const email=value(data,'email').toLowerCase();
  const password=value(data,'password');
  if(displayName.length<2||displayName.length>120||!email||password.length<8)redirect(destination('/join-as-artist','error','Please enter your name, a valid email, and a password of at least 8 characters.'));
  const db=await supabase();
  const {data:result,error}=await db.auth.signUp({email,password,options:{data:{display_name:displayName,signup_intent:'artist'},emailRedirectTo:`${siteUrl()}/auth/callback?intent=artist&next=/artist`}});
  if(error)redirect(destination('/join-as-artist','error','We could not create the account. Please check the details or sign in if you already registered.'));
  if(result.session){
    const {error:roleError}=await db.rpc('register_current_user_as_artist',{p_display_name:displayName});
    if(roleError){await db.auth.signOut();redirect(destination('/login','error','Your account was verified, but the artist workspace could not be prepared. Please contact support.'))}
    redirect('/artist');
  }
  redirect(destination('/join-as-artist','message','Check your email to verify your address and finish creating your artist account.'));
}

export async function registerIntermediary(data:FormData){
  const displayName=value(data,'displayName');
  const organisation=value(data,'organisation');
  const email=value(data,'email').toLowerCase();
  const password=value(data,'password');
  if(displayName.length<2||displayName.length>120||!email||password.length<8)redirect(destination('/join-as-intermediary','error','Please enter your name, a valid email, and a password of at least 8 characters.'));
  const db=await supabase();
  const {data:result,error}=await db.auth.signUp({email,password,options:{data:{display_name:displayName,organisation_name:organisation,signup_intent:'intermediary'},emailRedirectTo:`${siteUrl()}/auth/callback?intent=intermediary&next=/intermediary`}});
  if(error)redirect(destination('/join-as-intermediary','error','We could not create the account. Please check the details or sign in if you already registered.'));
  if(result.session){const {error:roleError}=await db.rpc('register_current_user_as_intermediary',{p_display_name:displayName,p_organisation:organisation||null});if(roleError){await db.auth.signOut();redirect(destination('/login','error','Your intermediary workspace could not be prepared. Please contact support.'))}redirect('/intermediary')}
  redirect(destination('/join-as-intermediary','message','Check your email to verify your address and finish creating your intermediary account.'));
}

export async function login(data:FormData){
  const email=value(data,'email').toLowerCase();
  const password=value(data,'password');
  const next=safeNext(value(data,'next'),'/artist');
  const db=await supabase();
  const {error}=await db.auth.signInWithPassword({email,password});
  if(error)redirect(destination('/login','error','Email or password was not recognised, or the email has not been verified.'));
  redirect(next);
}

export async function logout(){const db=await supabase();await db.auth.signOut();redirect('/login?message=You+have+been+signed+out.')}

export async function requestPasswordReset(data:FormData){
  const email=value(data,'email').toLowerCase();
  if(email){const db=await supabase();await db.auth.resetPasswordForEmail(email,{redirectTo:`${siteUrl()}/auth/callback?next=/reset-password`})}
  redirect(destination('/forgot-password','message','If an account exists for that email, a reset link is on its way.'));
}

export async function updatePassword(data:FormData){
  const password=value(data,'password');
  const confirmation=value(data,'confirmation');
  if(password.length<8||password!==confirmation)redirect(destination('/reset-password','error','Passwords must match and contain at least 8 characters.'));
  const db=await supabase();
  const {error}=await db.auth.updateUser({password});
  if(error)redirect(destination('/reset-password','error','The reset link is invalid or expired. Request a new one.'));
  redirect(destination('/login','message','Password updated. You can now sign in.'));
}
