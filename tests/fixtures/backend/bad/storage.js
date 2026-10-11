const { data } = await supabase.storage.createBucket('avatars', { public: true })
await s3.putObject({ Bucket: 'uploads', Key: key, Body: body, ACL: 'public-read' })
