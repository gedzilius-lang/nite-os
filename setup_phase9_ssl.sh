#!/bin/bash

echo "--- 🔒 PHASE 9: HTTPS & SSL Setup ---"

# 1. Install Certbot and Nginx Plugin
echo "1. Installing Certbot..."
apt-get update -y
apt-get install -y certbot python3-certbot-nginx

# 2. Request Certificate
echo "2. Requesting SSL Certificate for os.peoplewelike.club..."
# We use --register-unsafely-without-email to avoid prompt in script
# In production for real clients, you'd want an email for expiry warnings.
certbot --nginx -d os.peoplewelike.club --non-interactive --agree-tos --register-unsafely-without-email --redirect

# 3. Auto-Renew Test
echo "3. Testing Auto-Renewal..."
certbot renew --dry-run

# 4. Update Documentation
echo "4. Updating Roadmap..."
cat << 'DOCEOF' >> /opt/nite-os/docs/V8-Roadmap.md

## Phase 9 – HTTPS & SSL (DONE)
- Installed Certbot.
- Enabled HTTPS for \`os.peoplewelike.club\`.
- Configured HTTP -> HTTPS redirection.
DOCEOF

cat << 'DOCEOF' >> /opt/nite-os/docs/V8-Phase-Log.md

## 2025-12-06 – Phase 9 – SSL Security
- Secured domain with Let's Encrypt SSL.
- Enabled auto-renewal via Certbot.
DOCEOF

echo "✅ Phase 9 Complete! Your site is now SECURE."
echo "👉 Visit: https://os.peoplewelike.club"
