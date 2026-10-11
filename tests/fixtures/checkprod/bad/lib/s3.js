import { S3Client } from "@aws-sdk/client-s3"

export const s3 = new S3Client({
  region: "us-east-1",
  credentials: { accessKeyId: "AKIAIOSFODNN7EXAMPLE", secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY }
})
