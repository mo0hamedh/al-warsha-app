const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// 1. تذكير صباحي (يعمل كل يوم الساعة 8 صباحاً بتوقيت مكة/القاهرة مثلاً)
// الإعداد هنا يعمل بتوقيت UTC، ستحتاج تظبيط الـ timezone عند الرفع أو كتابتها بصيغة CRON
exports.morningScheduleReminder = functions.pubsub.schedule('0 8 * * *').timeZone('Africa/Cairo').onRun(async (context) => {
    try {
        // نجلب المستخدمين اللي عندهم جدول نشط (للتسهيل المشتركين Premium)
        const premiumUsersSnapshot = await admin.firestore().collection('users').where('isPremium', '==', true).get();

        const tokens = [];
        premiumUsersSnapshot.docs.forEach(doc => {
            const data = doc.data();
            if (data.fcmToken) {
                tokens.push(data.fcmToken);
            }
        });

        if (tokens.length > 0) {
            const payload = {
                notification: {
                    title: '🌅 صباح الخير!',
                    body: 'لا تنسَ إنجاز مهام جدولك اليوم 📋',
                }
            };

            // إرسال الإشعار لكل التوكنز
            const response = await admin.messaging().sendToDevice(tokens, payload);
            console.log('Successfully sent message:', response);
        }
        return null;
    } catch (error) {
        console.error('Error sending morning reminders:', error);
        return null;
    }
});

// 2. إشعار المنافسة (يعمل آخر 3 أيام في الشهر الساعة 6 مساءً مثلاً)
exports.competitionReminder = functions.pubsub.schedule('0 18 28-31 * *').timeZone('Africa/Cairo').onRun(async (context) => {
    try {
        const usersSnapshot = await admin.firestore().collection('users')
            .where('monthlyPoints', '>', 0)
            .orderBy('monthlyPoints', 'desc')
            .get();

        const users = usersSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

        // حساب الفروق وإرسال الإشعارات
        for (let i = 1; i < users.length; i++) {
            const currentUser = users[i];
            const userAbove = users[i - 1];

            if (currentUser.fcmToken) {
                const diff = userAbove.monthlyPoints - currentUser.monthlyPoints;

                if (diff < 50 && diff > 0) {
                    const payload = {
                        notification: {
                            title: '🔥 المنافسة محتدمة!',
                            body: `أنت في المركز ${i + 1}، تفصلك ${diff} نقطة عن المركز اللي فوقك!`
                        }
                    };
                    await admin.messaging().sendToDevice(currentUser.fcmToken, payload);
                }
            }
        }
        console.log('Successfully processed competition reminders');
        return null;
    } catch (error) {
        console.error('Error sending competition reminders:', error);
        return null;
    }
});
