const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotification = functions.firestore
    .document('announcements/{announcementId}')
    .onCreate(async (snap, context) => {
        const data = snap.data();
        const usersSnapshot = await admin.firestore().collection('users').get();
        const tokens = usersSnapshot.docs.map(doc => doc.data().fcmToken).filter(token => token);

        if (tokens.length === 0) return null;

        const message = {
            notification: {
                title: data.title || "New Announcement",
                body: data.message || "Check the app for updates.",
            },
            tokens: tokens,
        };

        return admin.messaging().sendMulticast(message);
    });