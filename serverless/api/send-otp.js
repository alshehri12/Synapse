// Simple Vercel-style serverless function to send OTP via SMTP (MailerSend)
// Env vars required (set in your hosting platform):
// - SMTP_HOST
// - SMTP_PORT (e.g., 587)
// - SMTP_USER
// - SMTP_PASS
// - SMTP_FROM (e.g., no-reply@mysynapses.com)
// - SMTP_FROM_NAME (e.g., Synapse)
// - OTP_API_SECRET (shared secret; client sends in x-api-key header)

import nodemailer from 'nodemailer';

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const apiKey = req.headers['x-api-key'];
  if (!process.env.OTP_API_SECRET || apiKey !== process.env.OTP_API_SECRET) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  const { email, otp, type } = req.body || {};
  if (!email || !otp) {
    return res.status(400).json({ error: 'Missing email or otp' });
  }

  try {
    const transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port: Number(process.env.SMTP_PORT || 587),
      secure: false,
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
      },
    });

    const fromName = process.env.SMTP_FROM_NAME || 'Synapse';
    const from = process.env.SMTP_FROM;
    if (!from) {
      return res.status(500).json({ error: 'Missing SMTP_FROM env' });
    }

    const subject = type === 'test' ? 'Your test code' : 'Your Synapse verification code';
    const html = `
      <div style="font-family: system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial;">
        <h2>${fromName}</h2>
        <p>Your verification code is:</p>
        <div style="font-size: 28px; font-weight: 700; letter-spacing: 4px;">${otp}</div>
        <p style="color:#666; font-size: 12px;">This code expires in 15 minutes.</p>
      </div>
    `;

    await transporter.sendMail({
      from: `${fromName} <${from}>`,
      to: email,
      subject,
      html,
    });

    return res.status(200).json({ success: true });
  } catch (err) {
    console.error('Email send failed:', err);
    return res.status(500).json({ error: 'Failed to send email' });
  }
}



