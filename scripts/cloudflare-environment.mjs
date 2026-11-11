const DEVELOPMENT_REF = 'ocstvctvmychromkcurw';
const PRODUCTION_REF = 'aewoiynwpyqawiluwlkj';

function isPublishableKey(key) {
  if (!key || key.startsWith('sb_secret_')) return false;
  if (key.split('.').length !== 3) return true;
  try {
    const payload = JSON.parse(Buffer.from(key.split('.')[1], 'base64url').toString('utf8'));
    return payload.role === 'anon';
  } catch {
    return false;
  }
}

export function validateCloudflareEnvironment(environment = process.env) {
  const deploymentEnvironment = environment.CLOUDFLARE_DEPLOY_ENV;
  if (!['development', 'production'].includes(deploymentEnvironment)) {
    throw new Error('CLOUDFLARE_DEPLOY_ENV must be development or production');
  }

  const expectedRef = environment.SUPABASE_EXPECTED_PROJECT_REF;
  const requiredRef = deploymentEnvironment === 'production' ? PRODUCTION_REF : DEVELOPMENT_REF;
  if (expectedRef !== requiredRef) {
    throw new Error(`Refusing ${deploymentEnvironment} build: expected Supabase project is not approved for this context`);
  }

  const supabaseUrl = new URL(environment.NEXT_PUBLIC_SUPABASE_URL || 'https://invalid.local');
  if (supabaseUrl.protocol !== 'https:' || supabaseUrl.hostname !== `${expectedRef}.supabase.co`) {
    throw new Error(`Refusing ${deploymentEnvironment} build: Supabase project does not match the expected context`);
  }
  if (!isPublishableKey(environment.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY || '')) {
    throw new Error(`Refusing ${deploymentEnvironment} build: a publishable Supabase key is required`);
  }

  const siteUrl = new URL(environment.NEXT_PUBLIC_SITE_URL || 'https://invalid.local');
  if (siteUrl.protocol !== 'https:' || siteUrl.pathname !== '/' || siteUrl.search || siteUrl.hash) {
    throw new Error('NEXT_PUBLIC_SITE_URL must be a canonical HTTPS origin');
  }
  if (deploymentEnvironment === 'production' && siteUrl.origin !== 'https://therealart.in') {
    throw new Error('Refusing production build: canonical site origin must be https://therealart.in');
  }
  if (deploymentEnvironment === 'development' && siteUrl.hostname === 'therealart.in') {
    throw new Error('Refusing development build: production site origin is not allowed');
  }

  return { deploymentEnvironment };
}
