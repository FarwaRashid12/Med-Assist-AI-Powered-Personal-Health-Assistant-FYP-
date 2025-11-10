// app.config.js
export default ({ config }) => {
  return {
    ...config,
    extra: {
      googleVisionApiKey: process.env.GOOGLE_VISION_API_KEY,
    },
  };
};