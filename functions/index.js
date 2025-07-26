const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

// Configure email transporter (you'll need to set up your email service)
const transporter = nodemailer.createTransporter({
  service: 'gmail', // or your preferred email service
  auth: {
    user: functions.config().email.user,
    pass: functions.config().email.pass
  }
});

exports.sendOtpEmail = functions.https.onCall(async (data, context) => {
  try {
    const { email, otp, type } = data;
    
    if (!email || !otp) {
      throw new functions.https.HttpsError('invalid-argument', 'Email and OTP are required');
    }
    
    const mailOptions = {
      from: functions.config().email.user,
      to: email,
      subject: 'Synapse - Email Verification Code',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 40px; text-align: center; color: white;">
            <h1 style="margin: 0; font-size: 28px;">Synapse</h1>
            <p style="margin: 10px 0 0 0; font-size: 16px; opacity: 0.9;">Email Verification</p>
          </div>
          
          <div style="padding: 40px; background: #f8f9fa;">
            <h2 style="color: #333; margin-bottom: 20px;">Verify Your Email Address</h2>
            <p style="color: #666; line-height: 1.6; margin-bottom: 30px;">
              Thank you for joining Synapse! To complete your account setup, please enter the following verification code:
            </p>
            
            <div style="background: white; border: 2px solid #667eea; border-radius: 12px; padding: 30px; text-align: center; margin: 30px 0;">
              <h3 style="color: #333; margin: 0 0 15px 0; font-size: 18px;">Your Verification Code</h3>
              <div style="font-size: 32px; font-weight: bold; color: #667eea; letter-spacing: 8px; font-family: 'Courier New', monospace;">
                ${otp}
              </div>
            </div>
            
            <p style="color: #666; line-height: 1.6; margin-bottom: 20px;">
              This code will expire in 15 minutes for security reasons.
            </p>
            
            <div style="background: #e8f4fd; border-left: 4px solid #667eea; padding: 15px; margin: 20px 0;">
              <p style="margin: 0; color: #333; font-size: 14px;">
                <strong>Security Tip:</strong> Never share this code with anyone. Synapse will never ask for your verification code via email or phone.
              </p>
            </div>
            
            <p style="color: #666; line-height: 1.6; margin-top: 30px;">
              If you didn't create a Synapse account, you can safely ignore this email.
            </p>
          </div>
          
          <div style="background: #333; padding: 20px; text-align: center; color: white;">
            <p style="margin: 0; font-size: 12px; opacity: 0.8;">
              © 2024 Synapse. All rights reserved.
            </p>
          </div>
        </div>
      `
    };
    
    await transporter.sendMail(mailOptions);
    
    return { success: true, message: 'OTP email sent successfully' };
    
  } catch (error) {
    console.error('Error sending OTP email:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send OTP email');
  }
}); 