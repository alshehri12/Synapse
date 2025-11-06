# Age Rating Guide for Synapse

**Last Updated: January 2025**

## Overview

This guide explains Synapse's age rating for the Apple App Store and what to expect during the submission process.

---

## Your Requirements

Based on your specifications:
- **All ages allowed** - No minimum age restriction
- **Users under 13** - Require parental consent (COPPA compliance)
- **No adult content** - Content moderation actively filters inappropriate content
- **Safe environment** - AI-powered moderation ensures age-appropriate interactions

---

## Apple's Age Rating System

Apple uses age ratings to help parents make informed decisions:

- **4+**: No objectionable content
- **9+**: Mild or infrequent objectionable content
- **12+**: Moderate or frequent objectionable content
- **17+**: Frequent and intense objectionable content

---

## Recommended Rating for Synapse

### **Rating: 4+**

**Reasoning:**
- Content moderation filters inappropriate content
- No built-in adult content
- Suitable for all ages
- Safe collaborative environment

**However, Apple will likely add the designation:**
- "Frequent/Intense: Unrestricted Web Access" OR
- "Frequent/Intense: User Generated Content"

This is **normal and expected** for social/collaborative apps.

---

## App Store Rating Questionnaire

When submitting to App Store Connect, you'll answer these questions:

### Content Categories

**Answer "None" to all of these:**

1. **Cartoon or Fantasy Violence**: None
2. **Realistic Violence**: None
3. **Sexual Content or Nudity**: None
4. **Profanity or Crude Humor**: None (filtered by AI)
5. **Alcohol, Tobacco, or Drug Use**: None
6. **Mature/Suggestive Themes**: None
7. **Horror or Fear Themes**: None
8. **Medical/Treatment Information**: None
9. **Gambling**: None

### Special Features

**Answer "YES" to these:**

10. **Unrestricted Web Access**: No (app doesn't have a web browser)
11. **Simulated Gambling**: No
12. **Access to user-generated content**: **YES - Frequent/Intense**
    - Users can share ideas, comments, and messages
    - Content is moderated but user-created
    
13. **Unrestricted access to social networking**: **YES - Frequent/Intense**
    - Users can connect and collaborate with others
    - Messaging and commenting features

---

## Expected Result

Based on your answers, Apple will likely assign:

**Rating: 4+**

**With the designation:**
- "Unrestricted access to social networking"
- "User-generated content"

**Example App Store display:**
```
Rated 4+
Made for: Ages 4 and up
- Unrestricted access to social networking
- User-generated content that may not be suitable for children
```

---

## Content Moderation Explanation

When reviewers ask about content moderation:

**What to tell Apple reviewers:**

"Synapse uses OpenAI's Moderation API to automatically filter inappropriate content including:
- Hate speech
- Sexual content
- Violence
- Harassment
- Self-harm
- Illegal activities

All user-generated content (ideas, comments, messages) is scanned before being displayed. Flagged content is automatically blocked and users are notified.

Additionally, users can report inappropriate content for human review, and repeat violators have their accounts suspended."

---

## Parental Controls

Apple requires apps with user-generated content to explain parental controls:

**What to include in your App Store description:**

"Parental Guidance: Synapse includes AI-powered content moderation to ensure a safe environment. Parents can monitor their child's activity and should discuss online safety. For users under 13, parental consent is required per COPPA regulations."

---

## COPPA Compliance (Children Under 13)

### Requirements for Users Under 13:

1. **Verifiable Parental Consent**
   - Before creating an account
   - Can be obtained via email, credit card, or video conference
   - Must be documented

2. **Minimal Data Collection**
   - Only collect what's necessary for app functionality
   - Email, username, content created within app

3. **Parental Rights**
   - Parents can review their child's data
   - Parents can request deletion
   - Parents can revoke consent

4. **Privacy Policy**
   - Must clearly state practices for children under 13
   - Already included in your PRIVACY_POLICY.md

### Implementation Needed:

Consider adding an age gate during signup:
```
"Are you 13 years or older?"
- Yes, I'm 13 or older
- No, I'm under 13 (requires parental consent)
```

For users under 13:
```
"Please have a parent or guardian provide their email address to give consent."
```

---

## Comparison to Similar Apps

**Apps with similar ratings:**

- **Discord** (17+ due to unmoderated content)
- **Slack** (4+ for business, but 12+ for some features)
- **Trello** (4+, productivity focus)
- **Notion** (4+, productivity with collaboration)
- **Asana** (4+, task management with teams)

Synapse should aim for **4+** similar to Trello, Notion, and Asana.

---

## What Reviewers Will Test

Apple reviewers will specifically check:

1. **Sign Up Process**
   - Age verification (if implemented)
   - Parental consent flow (for under 13)

2. **Content Moderation**
   - Try posting inappropriate content
   - Check if it's filtered/blocked

3. **User Safety**
   - Reporting mechanism for inappropriate content
   - Block/mute features (if available)

4. **Privacy Compliance**
   - Privacy Policy accessible
   - Data collection matches what's declared

---

## Recommendations

### Immediate Actions:

1. **Implement Age Gate**
   - Ask user's age during signup
   - Require parental consent flow for under 13

2. **Add Reporting Feature**
   - Allow users to report inappropriate content
   - Show that you take safety seriously

3. **Test Content Moderation**
   - Verify OpenAI moderation catches inappropriate content
   - Document examples for reviewers

### Optional Enhancements:

1. **Parental Dashboard**
   - Let parents view their child's activity
   - Control privacy settings

2. **Block/Mute Users**
   - Allow users to block others
   - Reduces harassment concerns

3. **Content Warnings**
   - Display safety tips during onboarding
   - Remind users about appropriate behavior

---

## If Apple Requests Changes

**Common requests for apps with user-generated content:**

1. **"Strengthen Content Moderation"**
   - Response: Detail your OpenAI Moderation API implementation
   - Show examples of filtered content
   - Explain human review process for reports

2. **"Add Parental Controls"**
   - Response: Implement age gate if not already present
   - Add parental consent flow
   - Provide documentation

3. **"Clarify Age Rating"**
   - Response: Explain that 4+ is appropriate given moderation
   - Compare to similar apps (Trello, Notion)
   - Emphasize safety features

---

## Summary

**Your Answers for App Store Connect:**

| Question | Your Answer |
|----------|-------------|
| Violence | None |
| Sexual Content | None |
| Profanity | None |
| Gambling | None |
| User-Generated Content | **Yes - Frequent** |
| Social Networking | **Yes - Frequent** |
| Expected Rating | **4+** |

**Key Messages:**
- Suitable for all ages with parental guidance
- AI-powered content moderation active
- COPPA-compliant (parental consent for under 13)
- Safe, family-friendly environment

---

## Resources

- **COPPA Compliance**: https://www.ftc.gov/business-guidance/resources/complying-coppa-frequently-asked-questions
- **Apple Age Ratings**: https://developer.apple.com/app-store/age-ratings/
- **App Store Review Guidelines**: https://developer.apple.com/app-store/review/guidelines/

---

## Contact

**Questions?** support@mysynapses.com

---

**You're ready to select the appropriate age rating! ✅**
