const express = require("express");
const cors = require("cors");
const { RtcTokenBuilder, RtcRole } = require("agora-access-token");
const admin = require("firebase-admin");

// 🔥 Khởi tạo Firebase Admin với serviceAccountKey.json
const serviceAccount = require("./serviceAccountKey.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const app = express();
app.use(cors());
app.use(express.json());

const PORT = 5000; // Sử dụng một cổng duy nhất cho cả hai API

// 🔹 Agora Credentials
const APP_ID = "bad34fda816e4c31a4d63a6761c653af";
const APP_CERTIFICATE = "908c997dc981497bbae97a71fb4f191b";

// ✅ API: Tạo token cho Agora
app.post("/rtc-token", async (req, res) => {
  const { channelName, uid, role, expireTime } = req.body;

  if (!channelName) {
    return res.status(400).json({ error: "Thiếu channelName" });
  }

  const expirationTimeInSeconds = expireTime && !isNaN(expireTime) ? expireTime : 3600;
  const currentTime = Math.floor(Date.now() / 1000);
  const privilegeExpireTime = currentTime + expirationTimeInSeconds;
  const rtcRole = role === "publisher" ? RtcRole.PUBLISHER : RtcRole.SUBSCRIBER;

  try {
    const token = RtcTokenBuilder.buildTokenWithUid(
      APP_ID,
      APP_CERTIFICATE,
      channelName,
      uid || 0,
      rtcRole,
      privilegeExpireTime
    );

    return res.json({ token });
  } catch (error) {
    console.error("Lỗi khi tạo token:", error);
    return res.status(500).json({ error: "Lỗi khi tạo token" });
  }
});

// ✅ API: Gửi thông báo cuộc gọi qua Firebase Cloud Messaging
app.post("/sendCallNotification", async (req, res) => {
  const { token, idFriend, channelId } = req.body;

  if (!token || !callerName || !channelId) {
    return res.status(400).json({ error: "Thiếu thông tin cần thiết" });
  }

  const message = {
    token: token,
    data: {
      type: "incoming_call",
      idFriend: idFriend,
      channelId: channelId,

    },
    notification: {
      title: `${callerName} đang gọi bạn`,
      body: `Cuộc gọi ${typeCall}`,
    },
  };

  try {
    await admin.messaging().send(message);
    res.status(200).send("Thông báo cuộc gọi đã gửi!");
  } catch (error) {
    console.error("Lỗi gửi thông báo:", error);
    res.status(500).send("Lỗi gửi thông báo!");
  }
});

// 🔥 Khởi động server
app.listen(PORT, () => {
  console.log(`🚀 Server đang chạy trên cổng ${PORT}`);
});
