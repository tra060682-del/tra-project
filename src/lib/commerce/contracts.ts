import {z} from 'zod';

export const currencySchema=z.string().regex(/^[A-Z]{3}$/).default('INR');
export const minorUnitsSchema=z.number().int().nonnegative().max(Number.MAX_SAFE_INTEGER);
export const positiveMinorUnitsSchema=minorUnitsSchema.refine(value=>value>0,'Amount must be positive');
export const commerceIdSchema=z.uuid();

export const OFFER_STATUSES=['submitted','under_review','sent_to_artist','countered','accepted','rejected','withdrawn','expired'] as const;
export const offerStatusSchema=z.enum(OFFER_STATUSES);export type OfferStatus=z.infer<typeof offerStatusSchema>;
export const offerCreateSchema=z.object({artworkId:commerceIdSchema,amountMinor:positiveMinorUnitsSchema,currency:currencySchema,expiresAt:z.iso.datetime(),message:z.string().trim().max(2000).optional()});
export const offerTransitionSchema=z.object({offerId:commerceIdSchema,action:z.enum(['review','send_to_artist','counter','accept','reject','withdraw','expire']),expectedVersion:z.number().int().positive(),amountMinor:positiveMinorUnitsSchema.optional(),note:z.string().trim().max(2000).optional()});

export const RESERVATION_STATUSES=['pending','active','released','cancelled','expired','converted'] as const;export type ReservationStatus=(typeof RESERVATION_STATUSES)[number];
export const reservationCreateSchema=z.object({artworkId:commerceIdSchema,expiresAt:z.iso.datetime(),source:z.enum(['direct','offer','bag'])});

export const SALE_STATUSES=['draft','reserved','awaiting_payment','paid','fulfilment','completed','cancelled','refunded'] as const;export type SaleStatus=(typeof SALE_STATUSES)[number];
export const PAYMENT_STATUSES=['created','requires_action','processing','succeeded','failed','cancelled','partially_refunded','refunded'] as const;export type PaymentStatus=(typeof PAYMENT_STATUSES)[number];
export const SHIPPING_STATUSES=['pending','awaiting_artist','packaging','ready_to_dispatch','dispatched','in_transit','delivery_attempted','delivered','exception','returned','cancelled'] as const;export type ShippingStatus=(typeof SHIPPING_STATUSES)[number];

export const notificationCategorySchema=z.enum(['artist_onboarding','artwork_submission','artwork_approval','artwork_rejection','buyer_enquiry','offer_received','counteroffer','order_update','shipping_update','certificate_issued','account_security']);
export const privateMediaPurposeSchema=z.enum(['artist_verification','legal_agreement','certificate','order_document','shipping_document','operational_attachment']);
export const certificateTokenSchema=z.string().regex(/^tra_coa_[A-Za-z0-9_-]{43}$/);

export type CommerceAvailability='available'|'reserved'|'sold'|'unpublished';
export type CommerceFeature='wishlist'|'recently-viewed'|'offers'|'reservations'|'shopping-bag'|'checkout'|'payments'|'refunds'|'settlements'|'certificate-verification'|'notifications'|'outbound-email'|'private-media'|'courier-integrations'|'live-auctions';

