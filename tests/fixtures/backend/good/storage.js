const { data } = await supabase.storage.createBucket('avatars', { public: false, fileSizeLimit: '2MB' })
const { data: signed } = await supabase.storage.from('avatars').createSignedUrl(path, 60)
