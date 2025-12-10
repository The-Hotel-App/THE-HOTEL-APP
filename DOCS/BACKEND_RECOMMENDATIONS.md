# Backend Service Recommendations for ROOMS.io

## 🎯 Requirements Summary
- Email/password auth + biometric data storage
- Real-time database with row-level security (RLS)
- File storage (ID photos, documents)
- Push notifications
- Multi-tenancy (hotel_id isolation)
- **Priority: FREE tier with scalability to thousands of users**

---

## 1. Authentication & Biometric Storage

| Service | Free Tier | Pros | Cons |
|---------|-----------|------|------|
| **Supabase** | 50K MAU | Built-in RLS, PostgreSQL security, JWT tokens | Requires custom biometric flow implementation |
| **Firebase** | 50K MAU | Mature SDKs, device-level biometric integration | No raw biometric storage (device-only) |
| **AWS Amplify** | 50K MAU (Cognito) | Deep AWS integration, flexible IAM | Complex setup, steep learning curve |
| **Appwrite** | 50K MAU | GDPR/CCPA compliant, custom token generation | Limited biometric documentation |
| **PocketBase** | Unlimited (self-hosted) | Full control, no vendor lock-in | Manual implementation, no built-in support |

**✅ CHOICE: Supabase** - Best balance of security (RLS), free tier generosity, and developer experience

---

## 2. Real-Time Database with RLS

| Service | Free Tier | Pros | Cons |
|---------|-----------|------|------|
| **Supabase** | 500MB, unlimited API | PostgreSQL RLS, real-time subscriptions, SQL power | SQL learning curve for NoSQL devs |
| **Firebase** | 1GB, 50K reads/20K writes daily | Offline-first, automatic sync, mature ecosystem | NoSQL only, quota limits hit fast |
| **AWS Amplify** | DynamoDB 25GB | Highly scalable, GraphQL subscriptions | Multi-service complexity, cost unpredictability |
| **Appwrite** | 500MB | Built-in teams/permissions, unified API | 2 projects max on free tier |
| **PocketBase** | Unlimited (self-hosted) | SQLite simplicity, embedded database | Single-server only, no horizontal scaling |

**✅ CHOICE: Supabase** - Database-level RLS enforcement, unlimited API requests, real-time built-in

---

## 3. File Storage (ID Photos)

| Service | Free Tier | Pros | Cons |
|---------|-----------|------|------|
| **Supabase** | 1GB storage, 2GB bandwidth | S3-compatible, signed URLs, RLS integration | Limited bandwidth on free tier |
| **Firebase** | ❌ Requires Blaze (paid) | Deep auth integration, CDN delivery | **NO FREE TIER** since Sept 2024 |
| **AWS Amplify** | S3 credits | Unlimited scalability, granular IAM | Credits expire, complex pricing |
| **Appwrite** | 1GB storage | Bucket-level permissions, simple API | Same storage limits as Supabase |
| **PocketBase** | Unlimited (self-hosted) | No storage costs, full control | Manual backup/CDN setup required |

**✅ CHOICE: Supabase** - Firebase eliminated (no free tier), Supabase offers best free option

---

## 4. Push Notifications

| Service | Free Tier | Pros | Cons |
|---------|-----------|------|------|
| **Firebase** | Unlimited FCM | Industry standard, unlimited free, topic-based | Requires separate FCM setup |
| **Supabase** | Via FCM integration | Trigger from DB events, Edge Functions | Not built-in, requires FCM anyway |
| **AWS Amplify** | 1M/month (SNS) | FIFO support, AWS integration | Charges after 1M, complex setup |
| **Appwrite** | 1K/month free, unlimited on Pro | Built-in messaging, multi-channel (push/email/SMS) | Only 1K free messages |
| **PocketBase** | ❌ None | N/A | Manual FCM integration required |

**✅ CHOICE: Firebase (FCM)** - Unlimited free, use with Supabase via Edge Functions

---

## 5. Multi-Tenancy Support

| Service | Free Tier | Pros | Cons |
|---------|-----------|------|------|
| **Supabase** | Full RLS support | Database-enforced isolation, hotel_id filtering | Requires RLS policy design |
| **Firebase** | Security Rules | Document-level isolation, role-based access | Rules complexity for nested logic |
| **AWS Amplify** | IAM/Cognito | Fine-grained permissions, enterprise-grade | Steep learning curve |
| **Appwrite** | Built-in Teams | Native team concept, automatic filtering | 2 projects limit on free tier |
| **PocketBase** | Manual implementation | Full customization | No built-in multi-tenancy |

**✅ CHOICE: Supabase** - Database-level RLS is most secure, prevents data leakage

---

## 📊 Overall Comparison

| Feature | Supabase | Firebase | AWS Amplify | Appwrite | PocketBase |
|---------|----------|----------|-------------|----------|------------|
| **Auth** | ✅ 50K MAU | ✅ 50K MAU | ✅ 50K MAU | ✅ 50K MAU | ✅ Unlimited |
| **Database** | ✅ 500MB | ⚠️ 1GB (quota limits) | ⚠️ Complex | ✅ 500MB | ✅ Unlimited |
| **Storage** | ✅ 1GB | ❌ Paid only | ⚠️ Credits | ✅ 1GB | ✅ Unlimited |
| **Push** | ⚠️ Via FCM | ✅ Unlimited | ⚠️ 1M/month | ⚠️ 1K/month | ❌ Manual |
| **Real-time** | ✅ Built-in | ✅ Built-in | ✅ AppSync | ✅ Built-in | ✅ Built-in |
| **RLS/Security** | ✅ PostgreSQL RLS | ✅ Security Rules | ⚠️ IAM | ✅ Teams | ⚠️ Manual |
| **Scalability** | ✅ Excellent | ⚠️ Quota limits | ✅ Excellent | ⚠️ 2 projects | ❌ Single server |
| **Complexity** | ⭐⭐ Medium | ⭐ Easy | ⭐⭐⭐⭐ Hard | ⭐⭐ Medium | ⭐⭐⭐ Medium-Hard |
| **Free Tier** | ✅ Generous | ⚠️ Limited | ⚠️ Credits expire | ⚠️ 2 projects | ✅ Unlimited |

---

## 🏆 FINAL RECOMMENDATION

### **Primary Backend: Supabase**
**Why:**
- ✅ Most generous FREE tier (50K MAU, unlimited API, 500MB DB)
- ✅ PostgreSQL RLS = database-level security for multi-tenancy
- ✅ Real-time subscriptions built-in
- ✅ File storage included (1GB)
- ✅ Transparent pricing ($25/month Pro tier when needed)
- ✅ No surprise costs or quota exhaustion
- ✅ Perfect for hotel management app requirements

### **Push Notifications: Firebase Cloud Messaging (FCM)**
**Why:**
- ✅ Unlimited FREE push notifications
- ✅ Industry standard, reliable
- ✅ Easy integration with Supabase via Edge Functions
- ✅ Topic-based messaging for hotel-specific notifications

### **Architecture:**
```
Flutter App
    ↓
Supabase (Auth, DB, Storage, Real-time)
    ↓
Supabase Edge Functions → Firebase FCM (Push Notifications)
```

---

## 💰 Cost Projection

### Free Tier Capacity:
- **Users:** 50,000 MAU (staff + guests)
- **Database:** 500MB (sufficient for 10K+ bookings)
- **Storage:** 1GB (1000+ ID photos at 1MB each)
- **API:** Unlimited requests
- **Bandwidth:** 2GB/month egress

### When to Upgrade (Pro $25/month):
- Database exceeds 500MB (historical bookings)
- Need 100GB storage (10K+ photos)
- Require SOC2 compliance
- Need 14-day backup retention

### Firebase Eliminated:
- ❌ Storage requires paid Blaze tier (no free option)
- ❌ Firestore quota limits (50K reads/day) too restrictive
- ❌ Unpredictable pay-as-you-go costs

---

## 🔐 Security Implementation

### Biometric Data:
- Store encrypted templates in Supabase `employee_biometrics` table
- Device-side matching only (never send raw biometric data)
- Use Supabase RLS to restrict access by hotel_id

### Multi-Tenancy:
```sql
-- Example RLS Policy
CREATE POLICY "Users access own hotel data"
ON bookings FOR SELECT
USING (
  hotel_id IN (
    SELECT hotel_id FROM staff_hotels 
    WHERE user_id = auth.uid()
  )
);
```

### File Storage:
- Use Supabase Storage with signed URLs
- RLS policies on storage buckets
- Automatic encryption at rest

---

## 🚀 Implementation Priority

1. **Week 1:** Supabase setup (auth, database schema, RLS policies)
2. **Week 2:** Real-time subscriptions (room status, bookings)
3. **Week 3:** File storage (ID photos with signed URLs)
4. **Week 4:** FCM integration via Edge Functions
5. **Week 5:** Multi-tenancy testing (hotel_id isolation)
6. **Week 6:** Production deployment

---

## ⚠️ Why NOT Others?

- **Firebase:** Storage no longer free, quota limits too restrictive
- **AWS Amplify:** Too complex, credits expire, unpredictable costs
- **Appwrite:** 2 projects limit kills dev/staging/prod workflow
- **PocketBase:** No horizontal scaling, manual push notifications, DevOps overhead

---

**Decision: Supabase + Firebase FCM = Best free, scalable solution for ROOMS.io**
