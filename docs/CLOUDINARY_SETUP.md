# Cloudinary next phase

Public artwork, profile and editorial images must use Cloudinary. Implement server-signed uploads only for authorised users; validate MIME, byte size, actual dimensions and ownership before persistence. Store public ID, secure URL, width/height, format, purpose, alt text and order in Supabase. Render responsive transformations. Keep API secret server-side. Private certificates and tax/identity documents must use private Supabase Storage and short-lived authorised access, never Cloudinary public URLs. No real uploads or media integration are enabled in this foundation.
