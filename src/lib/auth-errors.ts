type AuthErrorLike = {
  code?: unknown;
  status?: unknown;
};

const ACCOUNT_EXISTS_MESSAGE =
  'An account may already exist for this email. Try signing in or resetting your password.';

export function registrationErrorMessage(error: AuthErrorLike): string {
  switch (error.code) {
    case 'over_email_send_rate_limit':
      return 'Verification email service is temporarily at capacity. Please wait a few minutes and try again.';
    case 'email_address_invalid':
      return 'Please use a valid, deliverable email address.';
    case 'weak_password':
      return 'Choose a stronger password with at least 8 characters.';
    case 'user_already_exists':
    case 'email_exists':
      return ACCOUNT_EXISTS_MESSAGE;
    case 'signup_disabled':
      return 'Registration is temporarily unavailable. Please try again later.';
    default:
      return 'We could not create the account. Please check the details or sign in if you already registered.';
  }
}

export function authErrorSummary(error: AuthErrorLike): {
  code: string;
  status: number | null;
} {
  return {
    code: typeof error.code === 'string' ? error.code : 'unknown_auth_error',
    status: typeof error.status === 'number' ? error.status : null,
  };
}
