'use server';
import {redirect} from 'next/navigation';import {z} from 'zod';import {requireAuthContext} from '@/lib/auth';
export async function acceptInvitation(form:FormData){const token=z.string().trim().min(40).max(256).parse(form.get('token'));const {db}=await requireAuthContext();const {error}=await db.rpc('tra_accept_invitation',{p_token:token});if(error)redirect('/accept-invitation?error=This+invitation+is+invalid%2C+expired%2C+or+belongs+to+another+verified+email.');redirect('/workspace?message=Invitation+accepted.')}
