---
name: static-site-infra-security-patterns
description: Security patterns and recurring findings for S3+CloudFront static site Terraform stacks reviewed in this project
type: project
---

Patterns observed during security audit of terraform/ (2026-03-21).

**Why:** These patterns recur in static site infra and should be checked on every future audit pass.

**How to apply:** On any future audit of this or similar stacks, immediately check these areas before doing a line-by-line review.

## Confirmed Good Patterns (do not flag these)
- OAC (not OAI) used for CloudFront-to-S3 access — correct modern approach
- S3 public access block has all four booleans set to true — correct
- BucketOwnerEnforced ownership control — correct, prevents ACL-based public access
- S3 bucket policy scoped to specific CloudFront distribution ARN via AWS:SourceArn condition — correct least-privilege
- IAM action scoped to s3:GetObject only (not s3:*) — correct
- viewer_protocol_policy = "redirect-to-https" — correct
- OIDC used for CI/CD auth (no long-lived keys in workflow) — correct
- No hardcoded account IDs or credentials in .tf files (aws_caller_identity data source used instead)

## Recurring Findings / Risk Areas
- S3 server-side encryption block (aws_s3_bucket_server_side_encryption_configuration) absent — flag as MEDIUM
- S3 access logging not enabled (aws_s3_bucket_logging) — flag as MEDIUM
- CloudFront access logging not enabled (logging_config block) — flag as MEDIUM
- CloudFront response headers policy absent — no security headers (CSP, X-Frame-Options, HSTS, etc.) — flag as HIGH
- Remote state backend commented out, meaning state is stored locally — flag as HIGH (state may contain sensitive resource metadata)
- cloudfront_default_certificate = true with no custom domain or ACM cert — acceptable for dev/staging, flag as LOW for production environments
- error_caching_min_ttl = 0 for 404 responses — minor operational concern, not a security issue
- No aws_s3_bucket_versioning resource — flag as LOW (protects against accidental state/content loss)
- domain_name variable present but unused (no aliases or ACM cert wiring) — flag as LOW (dead config)
- No provider-level default_tags — tags could drift; not a security issue but worth noting
