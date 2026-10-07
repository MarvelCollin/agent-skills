# Input Validation and Output Shaping

Everything that crosses into the service is untrusted until a schema says otherwise. Everything that leaves goes through a deliberate shape.

## Validate at the Edge

- **One schema per input:** body, query string, path params, headers you rely on, cookies, uploaded files, queue messages, webhook payloads, and responses from third-party APIs
- **Parse, do not just check.** The validator returns a typed object and the handler uses only that object, never the raw request again
- **Check:** type, required, length (min and max for every string), numeric range, format (email, UUID, ISO date, URL), enums as allowlists, array min and max items, nesting depth
- **Unknown fields:** reject them (strict) or strip them. Never pass them through. This is the first defense against mass assignment
- **Normalize before validating:** trim, Unicode normalize (NFC or NFKC for identifiers), lowercase emails for comparison
- **Allowlists over denylists.** Say what is allowed. Lists of bad characters are always incomplete
- **Sort and filter params** map to an allowlist of columns. Never interpolate a client value into `ORDER BY`
- **Pagination params** have a default and a hard cap (`limit` from 1 to 100)
- **Business rules** (stock available, dates in order, the referenced record exists and belongs to the caller) are checked in the service layer after schema validation

## Global Limits

Set these once, in the server or gateway:

- JSON body: 100 KB to 1 MB for typical APIs. Raise per route only where needed
- Upload size per route, enforced while streaming, not after buffering
- Header size and count, URL length
- JSON nesting depth and array length, to stop parser and algorithmic DoS
- Request read timeout, so slow clients cannot hold connections (slowloris)

## Errors

Return 400 for malformed input or 422 for well-formed but invalid content, as RFC 9457 problem details with per-field errors:

```json
{
  "type": "https://api.example.com/problems/validation",
  "title": "Invalid request",
  "status": 422,
  "errors": [
    { "field": "email", "message": "must be a valid email" },
    { "field": "quantity", "message": "must be between 1 and 100" }
  ],
  "request_id": "01J9Z3K8V6M5"
}
```

Do not echo the rejected value back in full. It may be a secret or an injection payload.

## Output Shaping

- A response DTO or serializer per endpoint. Never return an ORM entity, a raw row, or `SELECT *` results, because new columns (`password_hash`, `stripe_customer_id`, internal flags) leak the day they are added
- Field-level authorization in the serializer (see [authorization.md](authorization.md))
- Consistent naming (one casing style across the API), ISO 8601 UTC timestamps, money as integer minor units or decimal strings with a currency, 64-bit ids as strings for JavaScript clients
- Leave out nulls or include them consistently, and document which

## File Uploads

- Prefer direct-to-storage uploads with presigned URLs (S3, GCS, Azure Blob). The API issues a short-lived URL with a size limit and content type, then verifies the object after upload
- Check type by content (magic bytes), not by extension or the client's `Content-Type`
- Generate the stored file name on the server. Never use the client's name in a path
- Store outside the web root, serve through a signed URL or a handler that checks authorization, with `Content-Disposition: attachment` for user content
- Scan for malware when files are shared with other users
- Strip metadata (EXIF GPS) from images when privacy matters
- Process images and video in a background job, with limits on pixel dimensions to stop decompression bombs
- Resize and compress images on upload. Cap the original by bytes and pixels, then generate a small set of bounded variants (thumbnail, medium, large) re-encoded as WebP or AVIF with a JPEG fallback, and store the dimensions. Serve variants through the CDN with long immutable caching. List and card views use the thumbnail and never the original. Keep the original only when the product needs it

## Libraries

| Stack | Validation |
|-------|------------|
| Node and TypeScript | zod, valibot, TypeBox with Fastify schemas, class-validator with NestJS pipes, Joi |
| Python | Pydantic (FastAPI), DRF serializers, marshmallow, attrs with cattrs |
| Go | go-playground/validator, ozzo-validation, or generated from OpenAPI with oapi-codegen |
| Java and Kotlin | Jakarta Bean Validation (`@Valid`, `@NotNull`, `@Size`) |
| .NET | DataAnnotations, FluentValidation |
| Ruby on Rails | Strong parameters plus model validations, dry-validation |
| PHP Laravel | Form Requests |

Generate request validators and types from an OpenAPI spec where possible so docs and enforcement never drift.

## Checklist

- [ ] Every input has a schema, with unknown fields rejected or stripped
- [ ] Global body, header and upload limits
- [ ] Sort, filter and pagination params allowlisted and capped
- [ ] 400 or 422 problem details with field errors
- [ ] Every response goes through a DTO
- [ ] Uploads checked by content, renamed, stored outside the web root
