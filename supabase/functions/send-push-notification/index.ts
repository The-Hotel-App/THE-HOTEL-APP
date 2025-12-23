// Supabase Edge Function: Send Push Notifications via FCM
// Triggered by database changes (new bookings, room status changes)
// Polls notifications table and sends to FCM

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// FCM HTTP v1 API endpoint
const FCM_URL = "https://fcm.googleapis.com/v1/projects/rooms-app-d4f03/messages:send";

interface NotificationPayload {
    notification_id: string;
    hotel_id: string;
    user_id: string;
    type: string;
    title: string;
    body: string;
    data: Record<string, unknown>;
}

// Get OAuth2 access token from service account
async function getAccessToken(serviceAccount: Record<string, string>): Promise<string> {
    const now = Math.floor(Date.now() / 1000);
    const expiry = now + 3600;

    const header = { alg: "RS256", typ: "JWT" };
    const payload = {
        iss: serviceAccount.client_email,
        sub: serviceAccount.client_email,
        aud: "https://oauth2.googleapis.com/token",
        iat: now,
        exp: expiry,
        scope: "https://www.googleapis.com/auth/firebase.messaging",
    };

    // Import the key and sign the JWT
    const encoder = new TextEncoder();
    const headerB64 = btoa(JSON.stringify(header)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
    const payloadB64 = btoa(JSON.stringify(payload)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
    const unsignedToken = `${headerB64}.${payloadB64}`;

    // Parse the private key
    const pemContents = serviceAccount.private_key
        .replace("-----BEGIN PRIVATE KEY-----", "")
        .replace("-----END PRIVATE KEY-----", "")
        .replace(/\n/g, "");

    const binaryKey = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));

    const cryptoKey = await crypto.subtle.importKey(
        "pkcs8",
        binaryKey,
        { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
        false,
        ["sign"]
    );

    const signature = await crypto.subtle.sign(
        "RSASSA-PKCS1-v1_5",
        cryptoKey,
        encoder.encode(unsignedToken)
    );

    const signatureB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
        .replace(/=/g, "")
        .replace(/\+/g, "-")
        .replace(/\//g, "_");

    const jwt = `${unsignedToken}.${signatureB64}`;

    // Exchange JWT for access token
    const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
    });

    const tokenData = await tokenResponse.json();
    return tokenData.access_token;
}

// Send FCM notification
async function sendFcmNotification(
    accessToken: string,
    fcmToken: string,
    notification: NotificationPayload
): Promise<boolean> {
    try {
        const response = await fetch(FCM_URL, {
            method: "POST",
            headers: {
                Authorization: `Bearer ${accessToken}`,
                "Content-Type": "application/json",
            },
            body: JSON.stringify({
                message: {
                    token: fcmToken,
                    notification: {
                        title: notification.title,
                        body: notification.body,
                    },
                    data: {
                        type: notification.type,
                        hotel_id: notification.hotel_id,
                        notification_id: notification.notification_id,
                        click_action: "FLUTTER_NOTIFICATION_CLICK",
                        ...Object.fromEntries(
                            Object.entries(notification.data).map(([k, v]) => [k, String(v)])
                        ),
                    },
                    android: {
                        priority: "high",
                        notification: {
                            channel_id: "hotel_notifications",
                            icon: "ic_notification",
                            color: "#FFD700",
                        },
                    },
                },
            }),
        });

        if (!response.ok) {
            const error = await response.text();
            console.error("FCM error:", error);
            return false;
        }

        return true;
    } catch (error) {
        console.error("Error sending FCM:", error);
        return false;
    }
}

serve(async (req) => {
    // Handle CORS preflight
    if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders });
    }

    try {
        // Get service account from environment (Base64 encoded)
        const serviceAccountBase64 = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_BASE64");
        if (!serviceAccountBase64) {
            throw new Error("FIREBASE_SERVICE_ACCOUNT_BASE64 not configured");
        }

        // Decode the service account
        const serviceAccountJson = atob(serviceAccountBase64);
        const serviceAccount = JSON.parse(serviceAccountJson);

        // Get Supabase client
        const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
        const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
        const supabase = createClient(supabaseUrl, supabaseServiceKey);

        // Parse the request body
        const body = await req.json();
        const { notification_ids } = body;

        // If specific notification IDs provided, send those
        // Otherwise, find unprocessed notifications (for scheduled polling)
        let notificationsToSend;

        if (notification_ids && notification_ids.length > 0) {
            const { data, error } = await supabase
                .from("notifications")
                .select("*")
                .in("id", notification_ids);

            if (error) throw error;
            notificationsToSend = data;
        } else {
            // Get recent notifications (last 5 minutes) that haven't been sent
            // This is for scheduled/polling mode
            const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000).toISOString();

            const { data, error } = await supabase
                .from("notifications")
                .select("*")
                .gte("created_at", fiveMinutesAgo)
                .order("created_at", { ascending: true });

            if (error) throw error;
            notificationsToSend = data;
        }

        if (!notificationsToSend || notificationsToSend.length === 0) {
            return new Response(
                JSON.stringify({ success: true, message: "No notifications to send" }),
                { headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }

        // Get FCM access token
        const accessToken = await getAccessToken(serviceAccount);

        // Process each notification
        const results = [];
        for (const notification of notificationsToSend) {
            // Get FCM tokens for owners of this hotel
            const { data: tokens, error: tokenError } = await supabase
                .rpc("get_owner_fcm_tokens", { p_hotel_id: notification.hotel_id });

            if (tokenError) {
                console.error("Error getting tokens:", tokenError);
                continue;
            }

            // Send to each token
            for (const tokenRecord of tokens || []) {
                // Skip if this is the same user (don't notify yourself)
                if (tokenRecord.user_id === notification.user_id) continue;

                const success = await sendFcmNotification(accessToken, tokenRecord.fcm_token, {
                    notification_id: notification.id,
                    hotel_id: notification.hotel_id,
                    user_id: notification.user_id,
                    type: notification.type,
                    title: notification.title,
                    body: notification.body,
                    data: notification.data,
                });

                results.push({
                    notification_id: notification.id,
                    fcm_token: tokenRecord.fcm_token.substring(0, 20) + "...",
                    success,
                });
            }
        }

        return new Response(
            JSON.stringify({ success: true, results }),
            { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
    } catch (error) {
        console.error("Error:", error);
        const errorMessage = error instanceof Error ? error.message : String(error);
        return new Response(
            JSON.stringify({ error: errorMessage }),
            { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
    }
});
