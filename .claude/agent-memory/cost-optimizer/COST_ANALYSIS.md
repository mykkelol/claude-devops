---
name: Cost Analysis - Portfolio Site Infrastructure
description: Detailed cost assessment of S3, CloudFront, and backend resources
type: project
---

# AWS Cost Optimization Review
**Reviewed**: 2026-03-21
**Project**: claude-devops (static portfolio site)

## Summary
Infrastructure is moderately cost-optimized for a static site. CloudFront PriceClass_200 is reasonable. Main opportunities: S3 lifecycle policies, error caching TTL, and terraform state backend optimization.

---

## Cost Findings by Resource

### 1. CloudFront Distribution
**Resource**: `aws_cloudfront_distribution.main`

**Current Configuration**:
- **Price Class**: `PriceClass_200` (includes NA, Europe, Asia, Australia)
- **Caching Policy**: AWS managed `CachingOptimized` (ID: 658327ea-f89d-4fab-a63d-7e88639e58f6)
- **Error Caching**: 404 error caching TTL set to 0 (no caching)
- **Viewer Protocol**: HTTPS redirect
- **Certificate**: CloudFront default (free)

**Cost Impact**: MEDIUM
- PriceClass_200 is optimal for global audience; downgrade to PriceClass_100 only if NA-only traffic
- Default certificate avoids custom domain costs
- 404 error TTL of 0 may increase origin requests on broken links

**Recommendations**:

| Issue | Current | Recommended | Impact |
|-------|---------|-------------|--------|
| 404 caching | TTL=0 | TTL=60-300 sec | LOW savings (prevents repeated origin hits) |
| Price Class | PriceClass_200 | Keep (unless traffic analysis shows NA-only) | N/A |

---

### 2. S3 Bucket (Storage)
**Resource**: `aws_s3_bucket.site`

**Current Configuration**:
- **Storage Class**: Standard (not specified, defaults to Standard)
- **Versioning**: Not enabled
- **Lifecycle Policies**: None
- **Bucket Encryption**: Not explicitly configured (server-side encryption default)
- **ACL**: Enforced (proper security)

**Cost Impact**: LOW (small static site)
- A portfolio site typically uses <10 MB storage ($0.023/month for 100 files ~10MB in Standard)
- No lifecycle or intelligent-tiering policies

**Recommendations**:

| Issue | Current | Recommended | Impact |
|-------|---------|-------------|--------|
| Lifecycle policies | None | Add policy to remove old versions/logs after 90 days | LOW (minimal if no versioning) |
| Storage Class | Standard | Keep (portfolio is <100MB, no I-A benefit) | N/A |
| Versioning | Disabled | Keep disabled (reduces cost) | POSITIVE (avoids storage overhead) |

---

### 3. S3 Bucket (Data Transfer)
**Current Configuration**:
- CloudFront caches content; S3 requests go via OAC (internal AWS)
- No cross-region replication
- No multipart upload configured

**Cost Impact**: LOW
- With CloudFront in front, origin requests are minimal (hit ratio typically >95%)
- Data transfer S3→CloudFront is free (same-region, internal)
- CloudFront→Viewer incurs data transfer costs (varies by PriceClass and region)

**Estimate**:
- 1000 unique visitors/month * 50KB avg page = 50MB/month = ~$0.85 CloudFront data transfer cost
- S3 storage + requests negligible

**Recommendations**:
- Keep CloudFront caching as-is; high cache hit ratio prevents S3 scaling issues
- No WAF needed (public site, no sensitive data)

---

### 4. Terraform State Backend
**Resource**: `backend.tf` (currently LOCAL, commented-out S3 config)

**Current Configuration**:
- **State Location**: Local filesystem (not production-ready)
- **Locking**: None (commented out)
- **Encryption**: Commented out

**Cost Impact**: LOW
- S3 backend bucket would cost ~$0.023/month (minimal)
- DynamoDB lock table would cost ~$1-2/month (on-demand pricing, state < 1MB)

**Recommendations**:

| Issue | Current | Recommended | Impact |
|-------|---------|-------------|--------|
| State backend | Local | Uncomment S3 + DynamoDB backend when multi-user CI/CD live | LOW cost, HIGH safety gain |
| DynamoDB pricing | N/A | Use on-demand pricing (not provisioned) | ~$1-2/month |

---

### 5. AWS Managed Caching Policy
**Current**: Using AWS managed `CachingOptimized` (ID: 658327ea-f89d-4fab-a63d-7e88639e58f6)

**Details**:
- Default TTL: 86400 seconds (24 hours) for most objects
- Max TTL: 31536000 seconds (1 year)
- Respects Cache-Control headers

**Cost Implication**: OPTIMAL
- Long TTL (24h) reduces origin requests
- Static files (HTML, CSS, images) benefit from maximum caching
- Gzip compression enabled

**Recommendations**: No changes needed. Policy is cost-effective.

---

## Unused/Unnecessary Resources
None identified. All resources serve a purpose:
- S3 bucket: required for site content
- CloudFront: required for CDN distribution
- OAC: required for secure S3 access
- Tags: required for cost allocation and governance

---

## Cost Summary

### Monthly Estimate (assuming moderate traffic)
| Resource | Estimated Monthly Cost | Notes |
|----------|----------------------|-------|
| S3 Storage | $0.023 | 100 MB portfolio |
| S3 Requests | $0.001 | ~100 requests (mostly cached) |
| CloudFront Data Transfer | $0.85 | ~50 MB outbound at $0.085/GB (NA avg) |
| CloudFront Requests | $0.01 | ~10k requests at $0.0075/10k |
| **Total** | **~$0.89** | *Standalone; would be ~$2-5 with domain+SSL* |

---

## Action Items (Priority Order)

1. **[LOW]** Increase 404 error caching TTL to 60-300 seconds to reduce origin hits on broken links
2. **[LOW]** When multi-user CI/CD is live, uncomment S3 backend + DynamoDB locking (minimal cost, improved safety)
3. **[OPTIONAL]** Review traffic patterns quarterly to confirm PriceClass_200 is optimal (downgrade to PriceClass_100 only if NA-only)
4. **[OPTIONAL]** If site grows >1 GB, add S3 Intelligent-Tiering for automatic archival of old versions

---

## Notes
- This is a **well-optimized** configuration for a static portfolio site
- Primary cost drivers are CloudFront data transfer + requests (unavoidable for public CDN)
- S3 costs are negligible for this use case
- No cost-saving changes are **critical**; recommendations are incremental optimizations
