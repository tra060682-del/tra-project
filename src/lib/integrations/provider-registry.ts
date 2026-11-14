import {IntegrationError} from './core.ts';
import {LocalCaptureEmailGateway,type EmailGateway} from './email.ts';
import {LocalPaymentGateway,type PaymentGateway} from './payment.ts';
import {executionApproved,readProviderEnvironment,validateProviderConfiguration} from './provider-config.ts';
import {RazorpayPaymentGateway} from './providers/razorpay.ts';
import {StripePaymentGateway} from './providers/stripe.ts';
import {ResendEmailGateway,SesEmailGateway} from './providers/email.ts';
import type {FetchLike} from './providers/http.ts';

export function createPaymentGateway(env:Record<string,string|undefined>,fetcher:FetchLike=fetch):PaymentGateway{
  const config=readProviderEnvironment(env),errors=validateProviderConfiguration(config,env);if(errors.some(error=>error.startsWith('RAZORPAY')||error.startsWith('STRIPE')||error.startsWith('PAYMENT')))throw new IntegrationError('PAYMENT_CONFIGURATION_INVALID');
  if(config.paymentMode==='local'&&config.paymentProvider==='local'&&executionApproved(config.paymentMode,config.paymentEnabled,config.paymentApproval))return new LocalPaymentGateway();
  if(config.paymentMode!=='sandbox'||!executionApproved(config.paymentMode,config.paymentEnabled,config.paymentApproval))throw new IntegrationError('PAYMENT_PROVIDER_DISABLED');
  if(config.paymentProvider==='stripe')return new StripePaymentGateway({secretKey:env.STRIPE_SECRET_KEY!,webhookSecret:env.STRIPE_WEBHOOK_SECRET!,enabled:true,approvalReference:config.paymentApproval},fetcher);
  if(config.paymentProvider==='razorpay')return new RazorpayPaymentGateway({keyId:env.RAZORPAY_KEY_ID!,keySecret:env.RAZORPAY_KEY_SECRET!,webhookSecret:env.RAZORPAY_WEBHOOK_SECRET!,enabled:true,approvalReference:config.paymentApproval},fetcher);
  throw new IntegrationError('PAYMENT_PROVIDER_DISABLED');
}

export function createEmailGateway(env:Record<string,string|undefined>,fetcher:FetchLike=fetch):EmailGateway{
  const config=readProviderEnvironment(env),errors=validateProviderConfiguration(config,env);if(errors.some(error=>error.startsWith('RESEND')||error.startsWith('SES')||error.startsWith('EMAIL')))throw new IntegrationError('EMAIL_CONFIGURATION_INVALID');
  if(config.emailMode==='local'&&config.emailProvider==='local'&&executionApproved(config.emailMode,config.emailEnabled,config.emailApproval))return new LocalCaptureEmailGateway();
  if(config.emailMode!=='sandbox'||!executionApproved(config.emailMode,config.emailEnabled,config.emailApproval))throw new IntegrationError('EMAIL_PROVIDER_DISABLED');
  const common={from:env.EMAIL_FROM_ADDRESS!,replyTo:env.EMAIL_REPLY_TO,allowedRecipients:(env.EMAIL_TEST_RECIPIENT_ALLOWLIST??'').split(',').map(value=>value.trim()).filter(Boolean),enabled:true,approvalReference:config.emailApproval};
  if(config.emailProvider==='resend')return new ResendEmailGateway({...common,apiKey:env.RESEND_API_KEY!},fetcher);
  if(config.emailProvider==='ses')return new SesEmailGateway({...common,region:env.SES_REGION!,accessKeyId:env.SES_ACCESS_KEY_ID!,secretAccessKey:env.SES_SECRET_ACCESS_KEY!,sessionToken:env.SES_SESSION_TOKEN},fetcher);
  throw new IntegrationError('EMAIL_PROVIDER_DISABLED');
}
