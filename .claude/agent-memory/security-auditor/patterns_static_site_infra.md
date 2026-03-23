---
name: static-site-infra-security-patterns
description: Security patterns and recurring findings for S3+CloudFront static site Terraform stacks reviewed in this project
type: project
---

Patterns observed during security audit of terraform/ (2026-03-21, updated 2026-03-22, re-audited 2026-03-22).

**Why:** These patterns recur in static site infra and should be checked on every future audit pass.

**How to apply:** On any future audit of this or similar stacks, immediately check these areas before doing a line-by-line review.

## Confirmed Good Patterns (do not flag these)
- OAC (not OAI) used for CloudFront-to-S3 access — correct modern approach
- S3 public access block has all four booleans set to true — correct
- BucketOwnerEnforced ownership control — correct, prevents ACL-based public access
- S3 bucket policy scoped to specific CloudFront distribution ARN via AWS:SourceArn condition — correct least-privilege
- IAM action scoped to s3:GetObject only (not s3:*) — correct
- viewer_protocol_policy = "redirect-to-https" — correct
- OIDC used for CI/CD auth (no long-lived keys in workflow) — correct (documented, not yet in .tf files)
- No hardcoded account IDs or credentials in .tf files (aws_caller_identity data source used instead)
- aws_s3_bucket_server_side_encryption_configuration present with AES256 + bucket_key_enabled + blocked_encryption_types = ["SSE-C"] — fully hardened as of 2026-03-22 audit
- blocked_encryption_types = ["SSE-C"] added to encryption block — prevents client-supplied keys bypassing server-managed encryption

## Recurring Findings / Risk Areas
- S3 server-side encryption block: RESOLVED in this stack — AES256 with bucket_key_enabled is present. Do not flag.
- S3 access logging not enabled (aws_s3_bucket_logging) — flag as MEDIUM
- CloudFront access logging not enabled (logging_config block) — flag as MEDIUM
- CloudFront response headers policy absent — no security headers (CSP, X-Frame-Options, HSTS, etc.) — flag as HIGH
- Remote state backend commented out in backend.tf — state stored locally — flag as HIGH. State contains account ID and resource ARNs.
- cloudfront_default_certificate = true with no custom domain or ACM cert — flag as LOW for production (acceptable for dev/staging)
- error_caching_min_ttl = 0 for 404 responses — minor operational concern, not a security issue
- No aws_s3_bucket_versioning resource — flag as LOW (protects against accidental content loss)
- domain_name variable present but no aliases or ACM cert wiring — flag as LOW (dead config creates confusion)
- No provider-level default_tags — tags could drift; not a security issue but worth noting
- When cloudfront_default_certificate = true is used without minimum_protocol_version, AWS deploys with TLSv1 (confirmed in terraform.tfstate line 167). Flag as HIGH. Fix: add minimum_protocol_version = "TLSv1.2_2021" to viewer_certificate block. NOTE: AWS only allows setting this when using a custom certificate (acm_certificate_arn or iam_certificate_id); with cloudfront_default_certificate=true AWS ignores the field and enforces TLSv1 itself. The real fix is to provision an ACM cert and set minimum_protocol_version = "TLSv1.2_2021".
- OIDC/IAM role for GitHub Actions absent from all .tf files — flag as HIGH. CI/CD OIDC role is not managed in Terraform, creating drift risk.
- terraform.tfstate in terraform/ directory and NOT in .gitignore at file level (only .terraform/ dir is ignored) — flag as HIGH. State contains AWS account ID (113772157645) in plaintext.
- compress = false on default_cache_behavior in deployed state — flag as MEDIUM. Compression should be enabled for performance and to reduce data egress.
- is_ipv6_enabled = false in deployed state — flag as LOW. IPv6 support should be considered.
