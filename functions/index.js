const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.hideExpiredMoments = functions.database.ref("Moments/{momentId}")
    .onWrite(async (change, context) => {
      const now = Date.now();
      const momentId = context.params.momentId;
      const afterData = change.after.val();

      if (afterData &&
      afterData.expiresAt &&
      afterData.expiresAt <= now &&
      afterData.isMoments === true) {
        try {
          await change.after.ref.update({isMoments: false});
          console.log(`🔻 Ẩn bài đăng ${momentId}`);
        } catch (error) {
          console.error("❌ Lỗi khi ẩn bài đăng:", error);
        }
      }
    });
